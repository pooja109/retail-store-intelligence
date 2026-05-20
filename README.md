# Retail Store Intelligence

Analyzes real-time and historical store data across sales, inventory, and labor to surface actionable insights, risks, and opportunities through conversational AI agents.

## Implementations

This repo contains two agent orchestration patterns, each covering sales, labor, and inventory:

| # | Orchestrator | Backend Agents |
|---|---|---|
| 1 | Copilot Studio | Fabric Data Agents |
| 2 | Azure AI Foundry Agent | Fabric Data Agents |

## Architecture

### Option 1: Copilot Studio + Fabric Data Agents

```mermaid
graph LR
    User -->|Natural Language| CPS[Copilot Studio Orchestrator]
    CPS --> SA[Sales Data Agent]
    CPS --> LA[Labor Data Agent]
    CPS --> IA[Inventory Data Agent]
    SA --> LH
    LA --> LH
    IA --> LH
    subgraph Fabric
        SA
        LA
        IA
        subgraph LH[Lakehouse]
            Tables[(Tables)]
            Views[(SQL Views)]
        end
    end
    style Fabric fill:#d4edda,stroke:#28a745
```

- No-code orchestrator configured via system prompt and topic definitions
- Routes questions to the appropriate Fabric Data Agent based on domain (sales, inventory, labor)
- Fabric Data Agents are added as connected agents in Copilot Studio 
- Supports multi-agent fan-out for cross-domain queries (e.g. "morning briefing", "store health check")
- Built-in topic templates: morning briefing, risk summary, store health check

### Option 2: Foundry Agent + Fabric Data Agents

```mermaid
graph LR
    User -->|Natural Language| FA[Foundry Agent Orchestrator]
    FA --> SA[Sales Data Agent]
    FA --> LA[Labor Data Agent]
    FA --> IA[Inventory Data Agent]
    SA --> LH
    LA --> LH
    IA --> LH
    subgraph Fabric
        SA
        LA
        IA
        subgraph LH[Lakehouse]
            Tables[(Tables)]
            Views[(SQL Views)]
        end
    end
    style Fabric fill:#d4edda,stroke:#28a745
```
- Authenticates to Fabric via MSAL client credentials and calls published agent REST endpoints
- Supports automatic multi-agent routing and cross-domain synthesis
- Fully code-driven — customizable routing logic and response formatting

## Repo Structure

| Folder | Purpose |
|--------|---------|
| `sql/views/` | SQL views (inventory health, labor coverage, OOS classification, OSA daily, sales summary) |
| `dataagents/` | Fabric Data Agents — one per domain (sales, labor, inventory) |
| `copilot_studio/` | Copilot Studio orchestrator instructions and topics |
| `foundry_agent/` | Azure AI Foundry orchestrator agent |

## Getting Started

See [SETUP_GUIDE.md](SETUP_GUIDE.md) for deployment instructions.
