# $2K+ Monthly Spend Likelihood Scoring Model

Score the probability that an onboarding referral account will cross $2K/month within 3-6 months. Max score: 115 (raw), normalized to 0-100 for the tier thresholds.

## Scoring Categories

### 1. Company Growth Trajectory (0-25 points)

Based on company research from Step 1.

| Signal | Points |
|--------|--------|
| Accelerating — recent fundraise (<12 months), hiring surge, new product launches | +25 |
| Steady growth — consistent hiring, stable funding, growing customer base | +15 |
| Early stage — Seed/A but high velocity (fast hiring, strong product traction) | +10 |
| Flat/uncertain — no recent funding, unclear growth, maintenance mode | +0 |
| Declining — layoffs, restructuring, downsizing | -10 |

### 2. Business Growth Momentum (0-15 points)

Based on Step 5 business growth trajectory analysis. This captures whether the company's business growth will *pull* PostHog spend upward beyond what the current billing trajectory alone predicts.

| Signal | Points |
|--------|--------|
| Revenue doubling or faster (disclosed >80% ARR growth, Inc. 5000 ranking) | +15 |
| Strong revenue growth (disclosed 30-80% growth, significant new customer wins) | +10 |
| Moderate growth signals (hiring, some new products, no disclosed revenue) | +5 |
| No discernible revenue growth signals | +0 |

**Multiplier bonuses (pick up to 2):**
- New product launches in last 12 months (each = new instrumentation surface): +3
- Platform/marketplace/clearinghouse play (multiplicative event growth): +3
- Expanding into new customer segments or geographies: +2
- GTM hiring surge (go-to-market spend = more PostHog internal users): +2

Cap this category at +15 even with bonuses.

### 2. Current Spend & Billing Momentum (0-25 points)

From Vitally billing data.

| Signal | Points |
|--------|--------|
| Already at $1.5K+/month and growing month-over-month | +25 |
| At $1.2-1.5K/month with upward trend | +20 |
| At $1-1.2K/month with upward trend | +15 |
| At $1-1.5K/month but flat or inconsistent | +10 |
| Below $1K/month (early in ramp) | +5 |
| Spend declining month-over-month | +0 |

### 3. Product Usage Breadth (0-20 points)

From Vitally product usage data.

| Signal | Points |
|--------|--------|
| Using 3+ PostHog products actively | +20 |
| Using 2 products actively | +15 |
| Using 1 product but exploring others (products enabled > products used) | +10 |
| Using 1 product only, no exploration signals | +5 |

**Product-specific bonuses:**
- Session Replay active: +3 (high-volume, high-cost product — drives spend fast)
- Feature Flags active with evaluations: +2 (sticky, hard to migrate away from)
- Experiments running: +3 (indicates sophisticated usage, high retention)

### 4. Engineering Team & Company Size (0-15 points)

From web research.

| Signal | Points |
|--------|--------|
| 100-500 employees, strong engineering ratio (>30%) | +15 |
| 50-100 employees, growing engineering team | +12 |
| 500+ employees (large org, potentially large budget) | +10 |
| 20-50 employees, engineering-heavy | +8 |
| <20 employees | +3 |

### 5. User Count & Activity (0-10 points)

From Vitally user data.

| Signal | Points |
|--------|--------|
| 5+ active users in last 30 days | +10 |
| 3-4 active users in last 30 days | +8 |
| 2 active users in last 30 days | +5 |
| 1 active user | +2 |
| Users declining or going inactive | +0 |

### 6. Engagement Quality (0-5 points)

From onboarding team notes and conversations.

| Signal | Points |
|--------|--------|
| Customer engaged in calls, asked strategic questions, discussed expansion | +5 |
| Customer replied to emails, implemented recommendations | +3 |
| Customer partially engaged — some replies but no deep conversations | +2 |
| Customer never responded to onboarding team | +0 |

## Negative Adjustments

Apply these after the positive scoring:

| Signal | Adjustment |
|--------|-----------|
| Non-ICP industry (HealthTech, FinTech, EdTech, GovTech, Insurance) | -15 |
| Heavy existing data team (3+ data roles — may outgrow PostHog or prefer warehouse-native) | -10 |
| Competitor tools deeply embedded (e.g. Amplitude contract, LaunchDarkly enterprise) | -10 |
| Customer expressed dissatisfaction or churn risk in onboarding notes | -15 |
| Usage declining despite onboarding engagement | -10 |
| Single product user with no expansion signals after 2+ months | -5 |

## Tier Thresholds

Raw scores can exceed 100 due to bonuses. Normalize to 0-100 by capping at 100.

| Score | Tier | Meaning |
|-------|------|---------|
| 80-100 | **High confidence** | Strong growth signals, multi-product, expanding team, business momentum pulling spend upward. Will likely hit $2K+ organically. Engage proactively. |
| 60-79 | **Moderate confidence** | Good signals but some uncertainty. May need a nudge — suggest new products, optimize config, or present annual pricing. Business growth may close the gap. |
| 40-59 | **Low confidence** | Mixed signals. Could go either way. Engage but temper expectations — focus on value realization, not commercial push. |
| 0-39 | **Unlikely** | Flat usage, small team, no growth signals, business not expanding. Light touch — check back in a quarter. |

## Example Scoring

**Strong lead:**
- Accelerating growth (raised Series B 6 months ago): +25
- Business momentum (106% ARR growth, Inc. 5000, 3 product launches, clearinghouse play): +15
- Spending $1.4K/month, growing MoM: +20
- Using Analytics + Replay + Flags: +20 (+3 replay, +2 flags)
- 150 employees, 40% engineers: +15
- 4 active users: +8
- Engaged with onboarding team, had 2 calls: +5
- **Raw total: 113 → Capped at 100 → High confidence**

**Moderate lead (billing lags business growth):**
- Accelerating growth (raised Series C recently): +25
- Business momentum (disclosed 50% growth, 2 new products, expanding geographies): +10 (+3 +2 = +15 capped)
- Spending $1.1K/month with upward trend: +15
- Using Analytics + Replay: +15 (+3 replay)
- 150 employees, 22% engineers: +12
- 5+ active users: +10
- Engaged with onboarding team: +5
- Non-ICP industry (but SaaS-like product): -3 (reduced penalty — see note on HealthTech infra vs. direct care)
- **Raw total: 97 → Capped at 97 → High confidence**
- *Note: without Step 5 business momentum, this scores 82. The business growth analysis adds confidence that billing will catch up.*

**Uncertain lead:**
- Steady growth (no recent funding, stable headcount): +15
- Business momentum (no disclosed growth, some hiring): +5
- Spending $1.1K/month, trend unclear: +15
- Using Analytics only: +5
- 60 employees, unknown eng ratio: +8
- 2 active users: +5
- Partially engaged — replied to one email: +2
- **Total: 55 → Low confidence**

**Weak lead:**
- Flat/uncertain (no funding data, no hiring signals): +0
- Business momentum (none): +0
- Spending $1K/month, flat: +10
- Using Analytics only: +5
- 25 employees: +3
- 1 active user: +2
- Never responded to onboarding: +0
- HealthTech industry: -15
- **Total: 5 → Unlikely**

## Industry Nuance for Negative Adjustments

The -15 penalty for non-ICP industries (HealthTech, FinTech, etc.) should be modulated based on what the company *actually does*:

- **Direct care provider, clinic, health system** → full -15 penalty (regulatory overhead, slow procurement, different analytics needs)
- **HealthTech SaaS / infrastructure** (sells software TO healthcare orgs, like a credentialing platform or telehealth SaaS) → reduced penalty: -3 to -5 (these are really B2B SaaS companies that happen to serve healthcare; they have engineering teams, ship features, and need product analytics like any SaaS)
- **FinTech SaaS / infrastructure** (sells software TO financial institutions) → reduced penalty: -5 to -8 (still SaaS, but may have heavier compliance requirements that slow PostHog adoption)

The key question: does the company *build software products with end-user UIs*? If yes, the industry penalty is less relevant than the business model.
