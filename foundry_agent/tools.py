"""Tool functions that call published Fabric Data Agents via the
OpenAI Assistants-compatible API.

Fabric Data Agents expose an Assistants-API-compatible endpoint at the
published URL (base URL ends in `/aiassistant/openai`). We use the OpenAI
SDK with a custom auth header carrying a Fabric bearer token obtained via
service-principal client credentials.
"""

import time
import typing as t
import uuid

import msal
from openai import OpenAI
from openai._models import FinalRequestOptions
from openai._types import Omit
from openai._utils import is_given

from config import (
    FABRIC_TENANT_ID,
    FABRIC_CLIENT_ID,
    FABRIC_CLIENT_SECRET,
    FABRIC_SALES_AGENT_ENDPOINT,
    FABRIC_INVENTORY_AGENT_ENDPOINT,
    FABRIC_LABOR_AGENT_ENDPOINT,
)

_AUTHORITY = f"https://login.microsoftonline.com/{FABRIC_TENANT_ID}"
_SCOPES = ["https://api.fabric.microsoft.com/.default"]

_msal_app = msal.ConfidentialClientApplication(
    FABRIC_CLIENT_ID,
    authority=_AUTHORITY,
    client_credential=FABRIC_CLIENT_SECRET,
)

_TERMINAL_STATES = {"completed", "failed", "cancelled", "expired", "requires_action"}
_POLL_INTERVAL_SEC = 2
_POLL_TIMEOUT_SEC = 300


def _get_fabric_token() -> str:
    """Acquire an access token for Fabric API using client credentials."""
    result = _msal_app.acquire_token_for_client(scopes=_SCOPES)
    if "access_token" not in result:
        raise RuntimeError(
            f"Failed to acquire Fabric token: {result.get('error_description', result)}"
        )
    return result["access_token"]


class _FabricOpenAI(OpenAI):
    """OpenAI client that injects a fresh Fabric bearer token per request and
    pins the Fabric Assistants API version."""

    def __init__(self, base_url: str, api_version: str = "2024-05-01-preview") -> None:
        self._api_version = api_version
        super().__init__(
            api_key="not-used",
            base_url=base_url,
            default_query={"api-version": api_version},
        )

    def _prepare_options(self, options: FinalRequestOptions) -> None:
        headers: dict[str, t.Any] = (
            {**options.headers} if is_given(options.headers) else {}
        )
        headers["Authorization"] = f"Bearer {_get_fabric_token()}"
        headers.setdefault("Accept", "application/json")
        headers.setdefault("ActivityId", str(uuid.uuid4()))
        options.headers = headers
        return super()._prepare_options(options)


def _extract_assistant_text(messages) -> str:
    """Return the latest assistant message text from a thread message list."""
    for msg in reversed(messages.data):
        if msg.role == "assistant" and msg.content:
            parts = []
            for c in msg.content:
                if getattr(c, "type", None) == "text":
                    parts.append(c.text.value)
            if parts:
                return "\n".join(parts)
    return "(No assistant response)"


def _call_fabric_agent(endpoint: str, question: str) -> str:
    """Send a question to a published Fabric Data Agent and return the response."""
    client = _FabricOpenAI(base_url=endpoint)

    assistant = client.beta.assistants.create(model="not-used")
    thread = client.beta.threads.create()
    try:
        client.beta.threads.messages.create(
            thread_id=thread.id, role="user", content=question
        )
        run = client.beta.threads.runs.create(
            thread_id=thread.id, assistant_id=assistant.id
        )

        start = time.time()
        while run.status not in _TERMINAL_STATES:
            if time.time() - start > _POLL_TIMEOUT_SEC:
                raise TimeoutError(
                    f"Fabric agent run timed out after {_POLL_TIMEOUT_SEC}s "
                    f"(last status={run.status})"
                )
            time.sleep(_POLL_INTERVAL_SEC)
            run = client.beta.threads.runs.retrieve(
                thread_id=thread.id, run_id=run.id
            )

        if run.status != "completed":
            err = getattr(run, "last_error", None)
            return f"Fabric agent run ended with status={run.status}, error={err}"

        messages = client.beta.threads.messages.list(thread_id=thread.id, order="asc")
        return _extract_assistant_text(messages)
    finally:
        try:
            client.beta.threads.delete(thread_id=thread.id)
        except Exception:
            pass


def query_sales_agent(question: str) -> str:
    """Query the Fabric Sales Data Agent.

    Use for questions about revenue, orders, margins, product/category/store
    sales performance, trends, and comparisons.

    Args:
        question: The sales-related question to answer.

    Returns:
        The agent's response with sales data and analysis.
    """
    return _call_fabric_agent(FABRIC_SALES_AGENT_ENDPOINT, question)


def query_inventory_agent(question: str) -> str:
    """Query the Fabric Inventory Data Agent.

    Use for questions about stock levels, out-of-stock classification
    (chronic, true, phantom, at-risk), reorder points, warehouse inventory,
    demand signals, and supply-chain risk.

    Args:
        question: The inventory-related question to answer.

    Returns:
        The agent's response with inventory data and analysis.
    """
    return _call_fabric_agent(FABRIC_INVENTORY_AGENT_ENDPOINT, question)


def query_labor_agent(question: str) -> str:
    """Query the Fabric Labor Data Agent.

    Use for questions about staffing, associate assignments, shift coverage,
    roles, tasks completed, orders managed, and labor efficiency.

    Args:
        question: The labor-related question to answer.

    Returns:
        The agent's response with labor data and analysis.
    """
    return _call_fabric_agent(FABRIC_LABOR_AGENT_ENDPOINT, question)
