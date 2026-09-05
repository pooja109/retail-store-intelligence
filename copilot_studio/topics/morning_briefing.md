# Topic: Morning Briefing

## Trigger Phrases
- "Morning briefing"
- "What happened yesterday?"
- "Daily summary"
- "Give me today's briefing"
- "Start of day report"
- "Weekly briefing"
- "Weekly performance"
- "Weekly snapshot"

## Behavior
When triggered, the orchestrator should:

1. **Determine the time window** from the trigger phrase:
   - "Yesterday" / "daily" / "morning briefing" → last 7 days (with focus on yesterday)
   - "Weekly" → last 7 days vs. prior 7 days
2. **Query all three agents** with expanded prompts:
   - **Sales Agent**: "For the last 7 days: show total revenue and week-over-week % change, total order count, gross margin %, average basket size, top 3 and bottom 3 stores by revenue, and department-level revenue breakdown with week-over-week % change. Also show top 3 products by units sold."
   - **Inventory Agent**: "For the last 7 days: show overall on-shelf availability (OSA) rate and week-over-week trend, out-of-stock classification breakdown (count of TRUE_OOS, CHRONIC_OOS, PHANTOM_OOS, AT_RISK_OOS), count of perishable products with lead-time risk, and top 5 stores with lowest OSA."
   - **Labor Agent**: "Show total associate headcount, stores with single-associate shifts, stores understaffed vs. store-type average (with delta), average orders managed per associate, and average tasks completed per associate."
3. **Synthesize** into a two-part briefing using the response template below.

### Response Template

The response has two sections: a **Weekly Podcast** narrative on top and a **Weekly Performance Snapshot** below.

---

#### Part 1 — Weekly Podcast

Write 7–10 sentences in a conversational, podcast-style tone — as if a knowledgeable colleague is giving a verbal briefing. Follow this arc:

1. Open with a one-sentence hook summarizing the week (e.g., "Let me give you a quick snapshot of this week's store performance and what's driving the numbers.").
2. Cover overall sales performance — revenue, WoW change, and whether the trajectory is positive or concerning.
3. Call out department-level trends — which departments are driving growth, which are soft, and any notable brand-level highlights.
4. Transition to inventory — OSA rate, direction of the trend, and the most important OOS classification (e.g., "We've got X chronic out-of-stocks that have persisted for two weeks").
5. Touch on staffing — headcount, coverage risks, and productivity.
6. Highlight 1–2 cross-domain connections (e.g., "Store 12 has both the lowest OSA and a single-associate morning shift — that's worth a visit").
7. Close with what to watch or act on this week.

**Tone guidance**: Direct, confident, insight-led. No filler. Speak to DMs and SMs who need to prioritize their day.

---

#### Part 2 — Weekly Performance Snapshot — Store Operations

> **Weekly Performance Snapshot — Store Operations**
> Week Ending [Date]
>
> ---
>
> **Headline**
>
> [One sentence summarizing the week — e.g., "Revenue rose X% WoW driven by [department], while OSA dipped to X% on X chronic out-of-stocks."]
>
> ---
>
> **Key Metrics**
>
> - **Weekly Revenue**: $X vs $X PW (+X.X% WoW)
> - **Orders**: X,XXX
> - **Gross Margin**: X.X%
> - **Avg Basket Size**: $X.XX
> - **On-Shelf Availability (OSA)**: X.X% vs X.X% PW
> - **Total Headcount**: X associates across X stores
>
> ---
>
> **Department Read**
>
> - **[Top Dept]**: $X revenue (+X.X% WoW)
> - **[2nd Dept]**: $X revenue (+X.X% WoW)
> - **[3rd Dept]**: $X revenue (-X.X% WoW)
> - *Brand highlights*: [Brand A] +X% WoW; [Brand B] -X% WoW on a small base
>
> ---
>
> **Inventory Health**
>
> - **OOS Breakdown**: X TRUE_OOS · X CHRONIC_OOS · X PHANTOM_OOS · X AT_RISK_OOS
> - **Perishable Lead-Time Risks**: X products where lead time exceeds shelf life
> - **Lowest OSA Stores**: [Store A] X%, [Store B] X%, [Store C] X%
>
> ---
>
> **Labor Coverage**
>
> - **Understaffed Stores**: X stores below store-type average headcount
> - **Coverage Risks**: X stores with single-associate shifts ([list store names])
> - **Avg Productivity**: X.X orders/associate · X.X tasks/associate
>
> ---
>
> **Store Watchouts**
>
> - **[Store X]**: [Cross-domain issue — e.g., "3 TRUE_OOS products AND single-associate morning shift — potential replenishment gap"]
> - **[Store Y]**: [e.g., "Bottom 3 in revenue, OSA at X% — investigate shelf availability impact on sales"]
> - **[Store Z]**: [e.g., "Understaffed by X associates vs. type average, tasks/associate X% above norm — team stretched thin"]
>
> ---
>
> **Recommended Actions**
>
> 1. [Highest priority action with specific store/product/shift]
> 2. [Second priority action]
> 3. [Third priority action]
>
> ---
>
> *Prepared for District & Store Managers · [Date Generated]*
