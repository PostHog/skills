# Survey Question Templates

Proven question templates organized by use case. Match user needs to these templates when possible, but adapt or create custom surveys when none fit.

## Table of Contents

1. [Classic Measurement Frameworks](#classic-measurement-frameworks)
   - NPS, CSAT, CES, PMF, SUS, GCR
2. [Product & Growth Surveys](#product--growth-surveys)
   - JTBD, Pricing, Competitive Intel, Feature Adoption, Beta Feedback, Trial Conversion
3. [Lifecycle & Journey Surveys](#lifecycle--journey-surveys)
   - Welcome, Activation, Milestone, Dormant User, Account Expansion, Churn/Exit
4. [Operational Surveys](#operational-surveys)
   - Support CSAT, Documentation, Event Feedback, Website Intent
5. [Targeting Patterns](#targeting-patterns-by-use-case)
6. [Branching Examples](#branching-examples)

---

## Classic Measurement Frameworks

### Net Promoter Score (NPS)

**Purpose:** Measure customer loyalty and likelihood to recommend.

**Standard NPS:**
```
Q1 (rating, scale 10, display number):
"How likely are you to recommend [Product] to a friend or colleague?"
lowerBoundLabel: "Not at all likely"
upperBoundLabel: "Extremely likely"

Q2 (open, optional: true):
"What's the primary reason for your score?"
```

**Targeting:** Active users, 30+ days old | **Schedule:** Recurring 90 days

**Scoring:** Detractors (0-6), Passives (7-8), Promoters (9-10). NPS = % Promoters - % Detractors

---

### Customer Satisfaction Score (CSAT)

**Purpose:** Measure satisfaction with specific interaction or experience.

**Post-interaction CSAT:**
```
Q1 (rating, scale 5, display emoji):
"How satisfied are you with your experience today?"
lowerBoundLabel: "Very dissatisfied"
upperBoundLabel: "Very satisfied"
```

**Feature-specific CSAT:**
```
Q1 (rating, scale 5):
"How satisfied are you with [Feature]?"

Q2 (single_choice, hasOpenChoice: true):
"What's the main reason for your rating?"
choices: ["Easy to use", "Saves me time", "Missing features", "Hard to understand", "Other"]
```

**Targeting:** After completing key action | **Schedule:** Once per action

---

### Customer Effort Score (CES)

**Purpose:** Measure how easy it was to complete a task. Lower effort = higher retention.

**Standard CES (7-point):**
```
Q1 (rating, scale 7, display number):
"How easy was it to [complete specific task]?"
lowerBoundLabel: "Very difficult"
upperBoundLabel: "Very easy"

Q2 (open, optional: true, branching on scores 1-3):
"What made this difficult?"
```

**CES for support:**
```
Q1 (rating, scale 7):
"[Company] made it easy to resolve my issue."
lowerBoundLabel: "Strongly disagree"
upperBoundLabel: "Strongly agree"
```

**Task-specific CES:**
```
Q1 (rating, scale 5):
"How easy was it to [set up your first dashboard / connect your data / invite your team]?"

Q2 (single_choice, branching on low scores):
"What was the biggest obstacle?"
choices: ["Confusing interface", "Missing documentation", "Technical issues", "Took too long", "Other"]
```

**Targeting:** Immediately after task completion | **Schedule:** Once per task type

**Scoring:** Average score. Industry benchmark: 5+ out of 7 is good.

---

### Product-Market Fit (PMF) - Sean Ellis Test

**Purpose:** Determine if product has achieved product-market fit. 40%+ "very disappointed" = PMF.

**Standard PMF Survey:**
```
Q1 (single_choice):
"How would you feel if you could no longer use [Product]?"
choices: ["Very disappointed", "Somewhat disappointed", "Not disappointed"]

Q2 (open):
"What type of people do you think would benefit most from [Product]?"

Q3 (open):
"What is the main benefit you receive from [Product]?"

Q4 (open):
"How can we improve [Product] for you?"
```

**Abbreviated PMF (single question):**
```
Q1 (single_choice):
"How would you feel if you could no longer use [Product]?"
choices: ["Very disappointed", "Somewhat disappointed", "Not disappointed (it's not really useful)"]
```

**Targeting:** Active users who've experienced core value (7-14 days, completed key actions) | **Schedule:** Once

**Scoring:** % who answered "Very disappointed". 40%+ indicates PMF.

---

### System Usability Scale (SUS)

**Purpose:** Standardized 10-question usability benchmark. Allows comparison across products.

**Full SUS (10 questions, all rating scale 5):**
```
Q1: "I think that I would like to use [Product] frequently."
Q2: "I found [Product] unnecessarily complex."
Q3: "I thought [Product] was easy to use."
Q4: "I think I would need technical support to use [Product]."
Q5: "I found the various functions in [Product] were well integrated."
Q6: "I thought there was too much inconsistency in [Product]."
Q7: "I imagine most people would learn to use [Product] very quickly."
Q8: "I found [Product] very cumbersome to use."
Q9: "I felt very confident using [Product]."
Q10: "I needed to learn a lot before I could get going with [Product]."

All questions use:
lowerBoundLabel: "Strongly disagree"
upperBoundLabel: "Strongly agree"
```

**Abbreviated SUS (4 questions):**
```
Q1: "I thought [Product] was easy to use."
Q2: "I found [Product] unnecessarily complex."
Q3: "I felt very confident using [Product]."
Q4: "I needed to learn a lot before I could get going with [Product]."
```

**Targeting:** Users with 2+ weeks of usage | **Schedule:** Quarterly

**Scoring:** Complex formula—scores range 0-100. Average SUS score is 68; 80+ is excellent.

---

### Goal Completion Rate (GCR)

**Purpose:** Did users accomplish what they came to do?

**Standard GCR:**
```
Q1 (single_choice):
"Did you accomplish what you came here to do today?"
choices: ["Yes", "Partially", "No"]

Q2 (open, branching on "Partially" or "No"):
"What prevented you from completing your goal?"

Q3 (open, branching on "Yes"):
"What did you accomplish?" (optional)
```

**Intent + Completion:**
```
Q1 (single_choice):
"What brought you here today?"
choices: ["Research/learning", "Complete a specific task", "Troubleshooting", "Just browsing", "Other"]

Q2 (single_choice):
"Were you able to accomplish this?"
choices: ["Yes, completely", "Yes, partially", "No"]

Q3 (open, optional: true):
"Any feedback on your experience?"
```

**Targeting:** Time on page (2+ minutes) or exit intent | **Schedule:** Once per session

---

## Product & Growth Surveys

### Jobs-to-be-Done (JTBD)

**Purpose:** Understand why users "hire" your product and what progress they're trying to make.

**JTBD Discovery:**
```
Q1 (open):
"What were you trying to accomplish when you signed up for [Product]?"

Q2 (open):
"What solutions had you tried before [Product]? What didn't work about them?"

Q3 (open):
"What would you be doing if [Product] didn't exist?"
```

**JTBD with structure:**
```
Q1 (single_choice):
"What's your primary goal with [Product]?"
choices: ["Track and analyze data", "Run experiments", "Understand user behavior", "Improve conversion", "Other"]

Q2 (open):
"Describe a recent situation where [Product] helped you make a decision."

Q3 (single_choice):
"How critical is [Product] to achieving your goal?"
choices: ["Essential - couldn't do it without", "Very helpful", "Somewhat helpful", "Not very important"]
```

**Targeting:** New users (day 3-7) or during onboarding | **Schedule:** Once

---

### Pricing Sensitivity (Van Westendorp)

**Purpose:** Find optimal price point and acceptable price range.

**Van Westendorp Price Sensitivity:**
```
Q1 (open, number input):
"At what price would [Product] be so cheap that you'd question its quality?"

Q2 (open, number input):
"At what price would [Product] be a bargain—a great buy for the money?"

Q3 (open, number input):
"At what price would [Product] start to seem expensive, but still worth considering?"

Q4 (open, number input):
"At what price would [Product] be too expensive to consider?"
```

**Simplified pricing feedback:**
```
Q1 (single_choice):
"How do you feel about [Product]'s current pricing?"
choices: ["Great value", "Fairly priced", "Somewhat expensive", "Too expensive"]

Q2 (single_choice, branching on "Too expensive"):
"What would make the price feel more justified?"
choices: ["More features", "Better support", "Usage-based pricing", "Team discounts", "Other"]

Q3 (open, optional: true):
"Any other feedback on pricing?"
```

**Targeting:** Active paying users or trial users near conversion | **Schedule:** Once, before pricing changes

---

### Competitive Intelligence

**Purpose:** Understand what alternatives users considered and why they chose you.

**New user competitive survey:**
```
Q1 (multiple_choice):
"What other solutions did you consider before choosing [Product]?"
choices: ["Competitor A", "Competitor B", "Competitor C", "Built in-house", "Spreadsheets", "None", "Other"]

Q2 (single_choice):
"What was the main reason you chose [Product]?"
choices: ["Price", "Features", "Ease of use", "Integrations", "Reputation", "Recommendation", "Other"]

Q3 (open, optional: true):
"Is there anything competitors do better that you wish [Product] had?"
```

**Win/loss analysis:**
```
Q1 (single_choice):
"Before choosing [Product], what was your top alternative?"
choices: [List competitors + "Other"]

Q2 (open):
"What made you choose [Product] over [alternative]?"

Q3 (single_choice):
"How close was the decision?"
choices: ["Easy choice - [Product] was clearly better", "Moderate - had to think about it", "Very close - could have gone either way"]
```

**Targeting:** New signups (day 1-3) | **Schedule:** Once

---

### Feature Adoption Barriers

**Purpose:** Understand why users aren't using a specific feature.

**Non-adoption survey:**
```
Q1 (single_choice):
"Have you tried [Feature] yet?"
choices: ["Yes, I use it regularly", "Yes, but I stopped", "I tried it once", "No, haven't tried it"]

Q2 (single_choice, branching on non-users):
"What's the main reason you haven't used [Feature]?"
choices: ["Didn't know it existed", "Don't understand what it does", "Doesn't seem relevant to me", "Tried but found it confusing", "Too busy to explore", "Other"]

Q3 (open, optional: true):
"What would make [Feature] more useful to you?"
```

**Feature awareness:**
```
Q1 (single_choice):
"Did you know [Product] can [feature capability]?"
choices: ["Yes, I use it", "Yes, but I don't use it", "No, I didn't know"]

Q2 (single_choice, branching on aware non-users):
"Why haven't you tried it?"
choices: ["No need for it", "Seems complicated", "Not sure how to start", "Other"]
```

**Targeting:** Users who haven't used feature (based on events) | **Schedule:** Once, 14+ days after signup

---

### Beta/Early Access Feedback

**Purpose:** Gather feedback on new features before full launch.

**Beta feature feedback:**
```
Q1 (rating, scale 5):
"How would you rate your experience with [Beta Feature]?"
lowerBoundLabel: "Poor"
upperBoundLabel: "Excellent"

Q2 (single_choice):
"How likely are you to use [Beta Feature] regularly once it's released?"
choices: ["Definitely", "Probably", "Not sure", "Probably not", "Definitely not"]

Q3 (multiple_choice):
"What did you like most? (Select all that apply)"
choices: ["Easy to use", "Solves a real problem", "Fast/performant", "Good design", "Other"]

Q4 (open):
"What's the #1 thing we should improve before launch?"
```

**Early access NPS:**
```
Q1 (rating, scale 10):
"Based on your early access experience, how likely are you to recommend [Feature] to a colleague?"

Q2 (open):
"What feedback do you have for the team?"
```

**Targeting:** Beta feature flag enabled | **Schedule:** After 3+ uses of feature

---

### Trial-to-Paid Conversion

**Purpose:** Understand conversion drivers and blockers.

**End of trial (non-converter):**
```
Q1 (single_choice):
"What's the main reason you haven't upgraded to a paid plan?"
choices: ["Still evaluating", "Too expensive", "Missing features I need", "Not enough time to test", "Found alternative", "Other"]

Q2 (single_choice, branching on "Missing features"):
"What feature would make you upgrade?"
choices: [List key paid features + "Other"]

Q3 (open, optional: true):
"Is there anything we could do to help you decide?"
```

**Post-conversion:**
```
Q1 (single_choice):
"What was the deciding factor in upgrading?"
choices: ["Saw clear value", "Needed specific feature", "Team expansion", "Good experience during trial", "Other"]

Q2 (open, optional: true):
"What almost stopped you from upgrading?"
```

**Targeting:** Trial users at day 12-14 (non-converters) or immediately post-conversion | **Schedule:** Once

---

## Lifecycle & Journey Surveys

### Welcome/Intent Survey

**Purpose:** Understand new user goals to personalize their experience.

**Signup intent:**
```
Q1 (single_choice):
"What's your primary goal with [Product]?"
choices: ["Track analytics", "Run A/B tests", "Understand user behavior", "Replace another tool", "Just exploring"]

Q2 (single_choice):
"What's your role?"
choices: ["Product Manager", "Engineer", "Data Analyst", "Marketing", "Founder/Executive", "Other"]

Q3 (single_choice):
"How quickly do you need to get set up?"
choices: ["ASAP - this week", "Next few weeks", "No rush - just exploring"]
```

**Targeting:** First login / signup flow | **Schedule:** Once

---

### Activation Checkpoint

**Purpose:** Check progress toward value and identify blockers.

**Day 3-7 check-in:**
```
Q1 (rating, scale 5, display emoji):
"How's your experience with [Product] so far?"
lowerBoundLabel: "Struggling"
upperBoundLabel: "Great"

Q2 (single_choice):
"Have you been able to [key activation action] yet?"
choices: ["Yes", "Working on it", "Not yet", "Not sure how"]

Q3 (single_choice, branching on "Not yet" or "Not sure how"):
"What's blocking you?"
choices: ["Need help setting up", "Waiting on team/data", "Confused about next steps", "Not a priority right now", "Other"]
```

**Targeting:** New users, day 3-7, haven't completed activation | **Schedule:** Once

---

### Milestone Celebration

**Purpose:** Reinforce success and gather feedback at positive moments.

**First success:**
```
Q1 (rating, scale 5, display emoji):
"Congrats on [achievement]! How was the experience getting here?"

Q2 (open, optional: true):
"What would have made it easier?"
```

**Usage milestone:**
```
Q1 (single_choice):
"You've now [milestone - e.g., analyzed 10,000 events]! What's been most valuable so far?"
choices: ["Insights/analytics", "Ease of use", "Integrations", "Team collaboration", "Other"]

Q2 (rating, scale 10):
"How likely are you to recommend [Product] based on your experience so far?"
```

**Targeting:** Event-triggered after milestone completion | **Schedule:** Once per milestone

---

### Dormant User Re-engagement

**Purpose:** Understand why users stopped engaging.

**Win-back survey:**
```
Q1 (single_choice):
"We noticed you haven't logged in recently. What's been going on?"
choices: ["Busy with other priorities", "Got what I needed", "Ran into issues", "Switched to something else", "Other"]

Q2 (single_choice, branching on "Ran into issues"):
"What issues did you experience?"
choices: ["Technical problems", "Confusing to use", "Missing features", "Too expensive", "Other"]

Q3 (single_choice):
"Would you consider coming back if we addressed your concerns?"
choices: ["Yes, definitely", "Maybe", "Probably not"]
```

**Targeting:** Users inactive 14-30 days | **Schedule:** Once

---

### Account Expansion

**Purpose:** Identify upsell opportunities with satisfied power users.

**Expansion readiness:**
```
Q1 (rating, scale 5):
"How well does [Product] meet your current needs?"
lowerBoundLabel: "Not at all"
upperBoundLabel: "Completely"

Q2 (single_choice):
"Are you interested in any of these capabilities?"
choices: ["More team seats", "Advanced features", "Higher usage limits", "Priority support", "Not interested in expanding"]

Q3 (single_choice):
"Who else on your team might benefit from [Product]?"
choices: ["Engineering", "Product", "Marketing", "Leadership", "No one else", "Other"]
```

**Targeting:** Power users (high usage, 90+ days) | **Schedule:** Once or quarterly

---

### Churn/Exit Survey

**Purpose:** Understand why users are leaving to reduce future churn.

**Cancellation survey:**
```
Q1 (single_choice, hasOpenChoice: true):
"What's the main reason you're canceling?"
choices: ["Too expensive", "Missing features I need", "Too difficult to use", "Switched to competitor", "Project ended / no longer needed", "Poor support experience", "Other"]

Q2 (open):
"Is there anything we could have done differently to keep you?"

Q3 (rating, scale 5, optional: true):
"How likely are you to consider [Product] again in the future?"
lowerBoundLabel: "Very unlikely"
upperBoundLabel: "Very likely"
```

**Downgrade survey:**
```
Q1 (single_choice):
"What's the main reason for downgrading?"
choices: ["Cost savings", "Don't need premium features", "Reduced usage", "Testing before canceling", "Other"]

Q2 (open, optional: true):
"What would make the higher tier more valuable to you?"
```

**Targeting:** Cancellation page or post-downgrade | **Schedule:** Once

---

## Operational Surveys

### Support Satisfaction (Support CSAT)

**Purpose:** Measure quality of support interactions.

**Post-ticket CSAT:**
```
Q1 (rating, scale 5, display emoji):
"How satisfied are you with the support you received?"
lowerBoundLabel: "Very dissatisfied"
upperBoundLabel: "Very satisfied"

Q2 (single_choice, branching on low scores):
"What could we have done better?"
choices: ["Faster response", "Clearer explanation", "Actually solve my issue", "More empathy", "Other"]

Q3 (open, optional: true):
"Any additional feedback for our support team?"
```

**Targeting:** After ticket closed/resolved | **Schedule:** Once per ticket

---

### Documentation Feedback

**Purpose:** Improve help content and documentation.

**Docs page feedback:**
```
Q1 (single_choice):
"Was this article helpful?"
choices: ["Yes", "Somewhat", "No"]

Q2 (single_choice, branching on "Somewhat" or "No"):
"What was missing?"
choices: ["More examples", "Clearer explanation", "Out of date", "Didn't answer my question", "Other"]

Q3 (open, optional: true):
"What were you trying to do?"
```

**Targeting:** Documentation pages, after 60+ seconds | **Schedule:** Once per page per user

---

### Event/Webinar Feedback

**Purpose:** Improve future events and content.

**Post-event survey:**
```
Q1 (rating, scale 5):
"How would you rate this [event/webinar]?"
lowerBoundLabel: "Poor"
upperBoundLabel: "Excellent"

Q2 (multiple_choice):
"What did you find most valuable?"
choices: ["Content/information", "Speaker(s)", "Q&A session", "Networking", "Demos", "Other"]

Q3 (single_choice):
"How likely are you to attend future events?"
choices: ["Definitely", "Probably", "Not sure", "Probably not"]

Q4 (open, optional: true):
"What topics would you like us to cover next?"
```

**Targeting:** Event attendees (via email or post-event page) | **Schedule:** Once, within 24 hours

---

### Website Visitor Intent

**Purpose:** Understand why visitors came and if they succeeded.

**Exit intent survey:**
```
Q1 (single_choice):
"What brought you to our site today?"
choices: ["Researching solutions", "Comparing options", "Ready to sign up", "Looking for help/docs", "Just browsing"]

Q2 (single_choice):
"Did you find what you were looking for?"
choices: ["Yes", "Partially", "No"]

Q3 (open, branching on "No"):
"What were you looking for?"
```

**Targeting:** Exit intent or 2+ minutes on site | **Schedule:** Once per session

---

## Targeting Patterns by Use Case

| Survey Type | Targeting | Timing |
|-------------|-----------|--------|
| NPS | Active users, 30+ days | Recurring 90 days |
| CSAT | After key action | Once per action |
| CES | After task completion | Once per task |
| PMF | Active 7-14 days, completed activation | Once |
| SUS | 2+ weeks usage | Quarterly |
| GCR | Time on page or exit intent | Once per session |
| JTBD | New users day 3-7 | Once |
| Pricing | Active paying or late trial | Once |
| Competitive | New signups day 1-3 | Once |
| Feature Adoption | Non-users of feature, 14+ days | Once |
| Beta Feedback | Beta flag enabled, 3+ uses | Once |
| Trial Conversion | Trial day 12-14 | Once |
| Welcome | First login | Once |
| Activation | Day 3-7, not activated | Once |
| Milestone | After achievement event | Once per milestone |
| Dormant | 14-30 days inactive | Once |
| Expansion | Power users, 90+ days | Quarterly |
| Churn | Cancellation page | Once |
| Support CSAT | Post-ticket resolution | Once per ticket |
| Docs Feedback | Docs pages, 60+ seconds | Once per page |
| Event Feedback | Event attendees | Once post-event |
| Website Intent | Exit intent or 2+ min | Once per session |

---

## Branching Examples

**NPS with sentiment-based follow-up:**
```
Q1 (rating, scale 10):
"How likely are you to recommend us?"
branching:
  type: response_based
  responseValues:
    detractors: 1    # Scores 0-6 → Q2
    passives: 2      # Scores 7-8 → Q3
    promoters: 3     # Scores 9-10 → Q4

Q2 (open): "We're sorry to hear that. What's the biggest issue?"
Q3 (open): "Thanks! What would make us a 9 or 10?"
Q4 (open): "Amazing! What do you love most?"
```

**Single choice branching:**
```
Q1 (single_choice):
"Did you accomplish your goal today?"
choices: ["Yes", "Partially", "No"]
branching:
  type: response_based
  responseValues:
    "0": "end"       # "Yes" → end survey
    "1": 1           # "Partially" → Q2
    "2": 1           # "No" → Q2

Q2 (open): "What got in the way?"
```

**Rating with threshold branching:**
```
Q1 (rating, scale 5):
"How easy was this task?"
branching:
  type: response_based
  responseValues:
    negative: 1      # Scores 1-2 → Q2
    neutral: "end"   # Score 3 → end
    positive: "end"  # Scores 4-5 → end

Q2 (open): "What made this difficult?"
```
