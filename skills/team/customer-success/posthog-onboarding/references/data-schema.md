# Data Schema Reference

Prescriptive recommendations for person properties, group properties, and events with stakeholder value explanations.

## Person Properties

Set on signup/login. Persist across all events.

### Core Properties

| Property | Type | Example | Why Overall | Why PM | Why PE | Why DE | Why Marketer |
|----------|------|---------|-------------|--------|--------|--------|--------------|
| `email` | string | "user@co.com" | Identification | Contact for feedback | Debug user issues | Join external data | Email campaigns |
| `name` | string | "Jane Smith" | Personalization | Humanize research | Support tickets | Data enrichment | Personalized outreach |
| `signup_date` | datetime | "2024-01-15" | Cohort analysis | Compare cohorts | Debug time issues | Lifecycle calcs | Campaign timing |
| `signup_source` | string | "google_ads" | Attribution | Channel quality | n/a | Attribution joins | Optimize spend |
| `initial_referrer` | string | "blog.competitor.com" | First-touch | Understand discovery | n/a | Attribution models | Content strategy |
| `initial_utm_source` | string | "linkedin" | Campaign tracking | Campaign ROI | n/a | Multi-touch | Optimize campaigns |
| `initial_utm_campaign` | string | "q1_launch" | Campaign tracking | Campaign performance | n/a | Attribution | Campaign reporting |
| `plan` | string | "pro" | Monetization | Adoption by tier | Flag targeting | Revenue analysis | Upsell targeting |
| `subscription_status` | string | "active" | Churn analysis | At-risk users | Trial logic | Churn prediction | Retention campaigns |
| `is_paying` | boolean | true | Revenue segment | Paying vs free behavior | Paywall logic | Revenue metrics | Conversion campaigns |
| `trial_start_date` | datetime | "2024-01-15" | Trial analysis | Trial optimization | Trial experience | Trial metrics | Trial nurture |
| `trial_end_date` | datetime | "2024-01-29" | Trial urgency | Conversion timing | Trial cutoff | Trial metrics | Urgency campaigns |
| `first_activated_at` | datetime | "2024-01-16" | Activation | Time-to-value | Onboarding | Activation metrics | Onboarding campaigns |
| `user_role` | string | "admin" | Role analysis | Role journeys | Permission logic | Role segmentation | Role messaging |
| `job_title` | string | "Product Manager" | Persona | Persona behavior | n/a | Persona enrichment | Persona targeting |
| `country` | string | "US" | Geo analysis | Localization | i18n decisions | Regional analysis | Geo campaigns |
| `is_employee` | boolean | false | Filter internal | Exclude from analysis | Test filtering | Data quality | Exclude from campaigns |

### B2B-Specific Person Properties

| Property | Type | Example | Why Overall | Why PM | Why PE | Why DE | Why Marketer |
|----------|------|---------|-------------|--------|--------|--------|--------------|
| `company_name` | string | "Acme Corp" | Account context | Account insights | Support context | Account joins | ABM |
| `company_size` | string | "50-200" | Segmentation | SMB vs Enterprise | Pricing logic | Size analysis | Segment targeting |
| `company_industry` | string | "fintech" | Vertical analysis | Industry patterns | Compliance flags | Benchmarks | Vertical campaigns |

## Group Properties (B2B)

Configure "company" or "organization" as group type. Enables account-level analytics.

| Property | Type | Example | Why Overall | Why PM | Why PE | Why DE | Why Marketer |
|----------|------|---------|-------------|--------|--------|--------|--------------|
| `name` | string | "Acme Corp" | Identification | Account health | Support lookup | Account joins | Personalization |
| `plan` | string | "enterprise" | Revenue segment | Feature access | Entitlements | Revenue analysis | Upsell targeting |
| `mrr` | number | 5000 | Revenue tracking | Revenue vs engagement | n/a | Revenue metrics | High-value focus |
| `employee_count` | number | 150 | Size segment | Size patterns | Capacity planning | Sizing analysis | Segment campaigns |
| `industry` | string | "healthcare" | Vertical | Industry patterns | Compliance | Benchmarks | Industry content |
| `created_at` | datetime | "2023-06-01" | Account age | Maturity analysis | n/a | Cohort analysis | Lifecycle campaigns |
| `owner_email` | string | "admin@acme.com" | Primary contact | Champion ID | Escalation | Owner joins | Primary contact |
| `contract_end_date` | datetime | "2024-12-31" | Renewal | Renewal risk | n/a | Renewal metrics | Renewal campaigns |
| `seat_count` | number | 25 | License util | Expansion opportunity | Seat enforcement | Utilization | Expansion campaigns |
| `active_users_30d` | number | 18 | Health scoring | Engagement health | n/a | Health metrics | Re-engagement |

### What Groups Unlock

- **PM:** "How many companies completed onboarding?" not just users
- **PE:** Feature flags by company. Roll out to Acme Corp first.
- **DE:** Company-level retention. DAC (Daily Active Companies) metrics.
- **Marketer:** Account-based reporting. Which companies at risk?

## Core Events (AARRR Framework)

### Acquisition

| Event | Trigger | Properties | Why Overall | Why PM | Why PE | Why DE | Why Marketer |
|-------|---------|------------|-------------|--------|--------|--------|--------------|
| `user_signed_up` | Account created | `signup_method`, `referral_source`, `utm_source`, `utm_campaign` | Track new users | Acquisition funnel | Debug signup | Signup metrics | Attribution |
| `account_created` | Org created (B2B) | `company_name`, `company_size`, `industry` | Track accounts | Account acquisition | Setup flow | Account metrics | ABM attribution |
| `invite_accepted` | User joins via invite | `inviter_id`, `invite_method`, `days_to_accept` | Viral growth | Invite optimization | Invite debugging | Viral metrics | Referral programs |

### Activation

| Event | Trigger | Properties | Why Overall | Why PM | Why PE | Why DE | Why Marketer |
|-------|---------|------------|-------------|--------|--------|--------|--------------|
| `[activation_event]` | First value achieved | `time_to_activate`, `activation_path`, `features_used` | Core success | Activation optimization | Onboarding improvements | Activation cohorts | Onboarding campaigns |
| `onboarding_step_completed` | Each step done | `step_name`, `step_number`, `time_on_step` | Onboarding funnel | Step optimization | UX improvements | Funnel metrics | Onboarding nudges |
| `onboarding_completed` | All steps done | `total_time`, `steps_skipped`, `help_viewed` | Onboarding success | Completion rate | Flow optimization | Onboarding metrics | Graduation campaigns |

### Retention

| Event | Trigger | Properties | Why Overall | Why PM | Why PE | Why DE | Why Marketer |
|-------|---------|------------|-------------|--------|--------|--------|--------------|
| `[core_feature]_used` | Feature usage | `feature_variant`, `items_count`, `duration` | Engagement | Feature health | Feature performance | Usage metrics | Engagement campaigns |
| `session_started` | App opened | `session_id`, `referrer`, `device_type` | Session analysis | Session patterns | Performance | Session metrics | Re-engagement |
| `project_created` | New workspace | `project_type`, `template_used` | Depth of use | Expansion | Project features | Usage depth | Use case education |

### Revenue

| Event | Trigger | Properties | Why Overall | Why PM | Why PE | Why DE | Why Marketer |
|-------|---------|------------|-------------|--------|--------|--------|--------------|
| `subscription_started` | New subscription | `plan`, `mrr`, `billing_interval`, `payment_method` | Revenue | Conversion optimization | Payment flow | Revenue metrics | Conversion campaigns |
| `subscription_upgraded` | Plan upgrade | `from_plan`, `to_plan`, `mrr_change`, `upgrade_trigger` | Expansion | Upgrade patterns | Upgrade UX | Expansion metrics | Upsell campaigns |
| `subscription_cancelled` | Cancellation | `plan`, `mrr_lost`, `reason`, `months_active` | Churn | Churn analysis | Offboarding | Churn metrics | Win-back campaigns |
| `payment_failed` | Failed charge | `amount`, `failure_reason`, `retry_count` | Revenue risk | Payment issues | Payment debugging | Failed metrics | Dunning campaigns |

### Referral

| Event | Trigger | Properties | Why Overall | Why PM | Why PE | Why DE | Why Marketer |
|-------|---------|------------|-------------|--------|--------|--------|--------------|
| `invite_sent` | User invites | `invite_method`, `invitee_role`, `message_included` | Viral growth | Invite optimization | Invite UX | Viral metrics | Referral incentives |
| `share_completed` | Content shared | `share_type`, `destination`, `content_type` | Word of mouth | Shareability | Share UX | Virality metrics | Share prompts |
| `referral_completed` | Referred converts | `referrer_id`, `referral_code`, `time_to_convert` | Referral success | Referral program | Referral tracking | Referral metrics | Referral rewards |

## Naming Conventions

- `snake_case` for all properties
- `is_` prefix for booleans: `is_first_time`, `is_premium`
- `has_` prefix for existence: `has_attachment`, `has_team`
- `_count` suffix for numbers: `item_count`, `member_count`
- `_at` suffix for timestamps: `created_at`, `completed_at`
- `_id` suffix for identifiers: `project_id`, `team_id`

## Context Properties (Include on Every Event)

| Property | Purpose |
|----------|---------|
| `source` | Where triggered: "dashboard", "email", "api" |
| `method` | How done: "drag_drop", "keyboard", "button" |
| `duration_seconds` | Time taken (for timed actions) |
| `previous_value` / `new_value` | For state changes |
