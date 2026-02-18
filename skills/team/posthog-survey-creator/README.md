# PostHog Survey Creator

A Claude skill that helps Product Managers create surveys in PostHog through guided conversation.

## What it does

This skill guides users through creating effective surveys by:

1. **Understanding goals** – Matches user needs to proven survey templates (NPS, CSAT, CES, PMF, etc.)
2. **Designing questions** – Recommends question types and wording based on best practices
3. **Configuring targeting** – Uses PostHog MCP to find events and properties, or falls back to asking users
4. **Creating surveys** – Builds surveys as drafts so users can review before launching

## Features

- **22 survey templates** covering classic frameworks (NPS, CSAT, CES, PMF, SUS, GCR), product & growth surveys, lifecycle surveys, and operational surveys
- **One question at a time** – Conversational flow that doesn't overwhelm users
- **PostHog MCP integration** – Automatically queries PostHog for events, properties, and existing surveys when available
- **Graceful fallback** – Works without MCP by asking users for configuration details
- **Draft-only creation** – Surveys are always created as drafts for review

## Requirements

- **Claude** with skills support
- **PostHog MCP** (optional but recommended) – Enables automatic querying of events, properties, and existing surveys

## Usage

Simply ask Claude to create a survey:

```
"I want to create a survey to measure how easy our new feature is to use"
```

Claude will guide you through:
1. Goal clarification
2. Template selection or custom design
3. Question customization
4. Audience targeting
5. Timing configuration
6. Survey creation

## Included Survey Templates

### Classic Measurement Frameworks
- Net Promoter Score (NPS)
- Customer Satisfaction (CSAT)
- Customer Effort Score (CES)
- Product-Market Fit (PMF)
- System Usability Scale (SUS)
- Goal Completion Rate (GCR)

### Product & Growth
- Jobs-to-be-Done (JTBD)
- Pricing Sensitivity
- Competitive Intelligence
- Feature Adoption Barriers
- Beta/Early Access Feedback
- Trial-to-Paid Conversion

### Lifecycle & Journey
- Welcome/Intent Survey
- Activation Checkpoint
- Milestone Celebration
- Dormant User Re-engagement
- Account Expansion
- Churn/Exit Survey

### Operational
- Support CSAT
- Documentation Feedback
- Event/Webinar Feedback
- Website Visitor Intent

## Files

```
posthog-survey-creator/
├── README.md                    # This file
├── SKILL.md                     # Main skill instructions
├── posthog-survey-creator.skill # Packaged skill (ready to upload)
└── references/
    └── question-examples.md     # Survey templates and examples
```
