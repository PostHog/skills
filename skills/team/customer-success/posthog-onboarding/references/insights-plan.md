# Insights Plan Reference

Prescribe specific insights based on customer's stated problem and analytics maturity.

## Analytics Maturity Levels

### Beginner
- No analytics or just Google Analytics
- No custom event tracking beyond pageviews
- No dashboards or regular reporting
- Team unfamiliar with product analytics concepts

### Intermediate
- Has used Mixpanel, Amplitude, or similar
- Some custom event tracking in place
- Basic dashboards exist
- Knows what funnels/cohorts are

### Advanced
- Mature tracking plan with consistent naming
- Data warehouse integration
- Uses cohorts, experiments, feature flags
- Has dedicated analytics/data person

---

## Problem: "Understand why users churn"

| Maturity | Insight Type | Specific Insight | What It Shows | PostHog Feature |
|----------|-------------|------------------|---------------|-----------------|
| Beginner | Retention | Week-over-week retention by signup cohort | Basic retention patterns | Retention insight |
| Beginner | Replay | Recordings filtered to churned users | What they did before leaving | Session Replay |
| Beginner | Trend | Active users over time (7d, 30d) | Is retention improving? | Trends |
| Intermediate | Funnel | Activation funnel with conversion time | Where users drop off | Funnels |
| Intermediate | Cohort | "Did X" vs "Didn't do X" cohorts | Features correlated with retention | Cohorts |
| Intermediate | Retention | Retention by initial referrer/campaign | Which channels bring retained users | Retention |
| Advanced | Correlation | Funnel correlation analysis | Statistical churn predictors | Funnel correlation |
| Advanced | SQL | LTV by signup source | Which sources most valuable | SQL insights |
| Advanced | Experiment | Test onboarding variants | Prove changes improve retention | Experiments |

### Quick Wins (< 30 min total)
1. Build retention chart (5 min)
2. Watch 10 replays of churned users (20 min)
3. Create "Active" vs "Churned" cohorts (5 min)

---

## Problem: "Improve trial-to-paid conversion"

| Maturity | Insight Type | Specific Insight | What It Shows | PostHog Feature |
|----------|-------------|------------------|---------------|-----------------|
| Beginner | Funnel | Signup → Activation → Conversion | Where trials fail | Funnels |
| Beginner | Trend | Daily trial starts vs conversions | Conversion rate over time | Trends |
| Beginner | Replay | Trial users who didn't convert | What blocked them | Session Replay |
| Intermediate | Funnel | Onboarding steps funnel | Which steps cause drop-off | Funnels |
| Intermediate | Breakdown | Conversion by signup source | Which channels convert best | Trends + Breakdown |
| Intermediate | Retention | Trial engagement by day | When engagement drops | Retention |
| Advanced | Correlation | Trial behaviors → conversion | What predicts conversion | Correlation |
| Advanced | Experiment | Test pricing page variants | Optimize conversion | Experiments |
| Advanced | Survey | Exit survey for non-converters | Why they didn't convert | Surveys |

### Quick Wins
1. Build trial funnel: Signup → [Activation] → Payment (10 min)
2. Add breakdown by signup_source (5 min)
3. Watch 5 replays of trials that dropped at activation (15 min)

---

## Problem: "Improve onboarding completion"

| Maturity | Insight Type | Specific Insight | What It Shows | PostHog Feature |
|----------|-------------|------------------|---------------|-----------------|
| Beginner | Funnel | Onboarding steps (Step 1 → 2 → 3 → Done) | Where users drop off | Funnels |
| Beginner | Replay | Users who didn't complete onboarding | UX friction points | Session Replay |
| Beginner | Trend | Onboarding completion rate over time | Is it improving? | Trends |
| Intermediate | Breakdown | Completion by device type | Mobile vs desktop differences | Funnels + Breakdown |
| Intermediate | Path | Paths from signup to first feature | Actual vs designed flow | User Paths |
| Intermediate | Cohort | "Completed onboarding" vs "Skipped" | Behavioral differences | Cohorts |
| Advanced | Experiment | Test onboarding flow variants | A/B test improvements | Experiments |
| Advanced | Flag | Progressive onboarding rollout | Gradual improvement | Feature Flags |
| Advanced | SQL | Time-to-complete by cohort | Trend over time | SQL |

### Quick Wins
1. Build step-by-step onboarding funnel (15 min)
2. Add breakdown by device_type (5 min)
3. Watch 5 replays of drop-offs at biggest friction point (10 min)

---

## Problem: "Understand feature adoption"

| Maturity | Insight Type | Specific Insight | What It Shows | PostHog Feature |
|----------|-------------|------------------|---------------|-----------------|
| Beginner | Trend | Feature usage over time (each feature) | What's used most | Trends |
| Beginner | Stickiness | Days/week users use each feature | Feature engagement depth | Stickiness |
| Beginner | Replay | Users discovering features | How they find and use features | Session Replay |
| Intermediate | Retention | Feature-specific retention | Which features drive retention | Retention |
| Intermediate | Path | Paths to feature discovery | How users find features | User Paths |
| Intermediate | Breakdown | Usage by plan tier | Premium vs free behavior | Trends + Breakdown |
| Advanced | Correlation | Feature usage → retention | Which features matter most | Correlation |
| Advanced | Experiment | Test feature discovery flows | Improve adoption | Experiments |
| Advanced | Survey | Feature satisfaction surveys | Qualitative feedback | Surveys |

### Quick Wins
1. Create feature usage dashboard with all major features (20 min)
2. Build stickiness chart for top 3 features (10 min)
3. Compare retention: users who used Feature X vs didn't (10 min)

---

## Problem: "Measure product-market fit"

| Maturity | Insight Type | Specific Insight | What It Shows | PostHog Feature |
|----------|-------------|------------------|---------------|-----------------|
| Beginner | Retention | 12-week unbounded retention | Classic PMF metric | Retention |
| Beginner | Trend | WAU/MAU ratio | Engagement intensity | Trends (formula) |
| Beginner | Survey | NPS survey | Customer satisfaction | Surveys |
| Intermediate | Cohort | Power users (top 10% by usage) | Who loves the product | Cohorts |
| Intermediate | Stickiness | Days active per week distribution | Usage patterns | Stickiness |
| Intermediate | Retention | Retention by referral source | Organic vs paid quality | Retention |
| Advanced | Survey | "Very disappointed" % (Sean Ellis) | PMF survey metric | Surveys + SQL |
| Advanced | Correlation | Power user behaviors vs churned | What differentiates success | Correlation |
| Advanced | Lifecycle | New/Returning/Resurrecting/Dormant | User health distribution | Lifecycle |

### Quick Wins
1. Build 12-week retention chart (10 min)
2. Calculate WAU/MAU ratio in trends (10 min)
3. Create "Power User" cohort (top 10% by events) (10 min)

---

## Problem: "Replace [competitor tool]"

| Maturity | Insight Type | Specific Insight | What It Shows | PostHog Feature |
|----------|-------------|------------------|---------------|-----------------|
| All | Dashboard | Replicate their top 3 dashboards | Parity demonstration | Dashboards |
| All | Trend | Compare event counts to old tool | Data accuracy | Trends |
| All | Replay | Watch recordings (new capability) | Added value | Session Replay |
| All | Funnel | Recreate their key funnel | Workflow parity | Funnels |
| Intermediate | Cohort | Recreate their key segments | Cohort parity | Cohorts |
| Advanced | SQL | Complex queries from old tool | Query capability | SQL |

### Quick Wins
1. List their top 3 dashboards, recreate first one (30 min)
2. Compare one key metric between tools (15 min)
3. Show session replay as net-new capability (10 min)

---

## Bonus Capabilities

Always recommend 2-3 based on use case:

| Capability | When to Recommend | What It Unlocks | Pitch |
|------------|-------------------|-----------------|-------|
| Session Replay + Filters | Any UX problem | Watch exactly the sessions where something went wrong | "Filter replays to churned users and see what happened" |
| Correlation Analysis | Churn/conversion | Statistically identify success predictors | "Find behaviors that predict conversion without guessing" |
| Feature Flags | Deployment risk | Safe rollouts, instant rollback | "Ship to 10% of users, measure, then expand" |
| Experiments | A/B testing needs | Statistical significance, auto analysis | "Run real experiments with automatic winner detection" |
| Surveys | Qualitative gaps | In-product surveys triggered by events | "Ask users why right after they do something" |
| User Paths | Navigation confusion | Visualize actual user flows | "See real paths users take vs designed ones" |
| Lifecycle Analysis | Retention concerns | New/Returning/Dormant breakdown | "See if acquiring faster than churning" |
| Group Analytics | B2B multi-user | Account-level metrics | "Track companies, not just users" |
| Data Warehouse | External data | Combine PostHog with revenue/CRM | "Join Stripe data with product behavior" |
| HogQL (SQL) | Power users | Arbitrary event queries | "Query your data however you want" |
