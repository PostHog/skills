# Business Types Reference

Events, metrics, and tracking patterns by business type.

## B2B SaaS

**Key Metrics:** DAC/WAC, account retention, seat utilization, NRR, time to value

**Core Events:**
| Event | Properties |
|-------|------------|
| `user_signed_up` | `signup_method`, `company_name`, `referral_source` |
| `account_created` | `company_size`, `industry`, `plan` |
| `invite_sent` | `invitee_role`, `invite_method` |
| `invite_accepted` | `time_to_accept`, `inviter_id` |
| `seat_added` | `role`, `new_seat_count` |
| `project_created` | `project_type`, `template_used` |
| `[core_feature]_used` | `feature_name`, `items_processed` |
| `report_exported` | `report_type`, `format`, `row_count` |
| `integration_connected` | `integration_name`, `connection_method` |
| `subscription_started` | `plan`, `mrr`, `seats`, `billing_interval` |
| `subscription_upgraded` | `from_plan`, `to_plan`, `trigger` |

**Groups:** company (`name`, `plan`, `mrr`, `seat_count`, `industry`, `created_at`)

**Key Insights:** Company activation funnel, seat utilization, feature adoption by tier, account retention

---

## B2C SaaS

**Key Metrics:** DAU/MAU, user retention, trial conversion, churn, stickiness

**Core Events:**
| Event | Properties |
|-------|------------|
| `user_signed_up` | `signup_method`, `referral_source`, `device_type` |
| `onboarding_started` | `onboarding_variant` |
| `onboarding_step_completed` | `step_name`, `step_number`, `time_on_step` |
| `onboarding_completed` | `total_time`, `steps_skipped` |
| `[activation_event]` | `time_from_signup`, `method_used` |
| `[core_feature]_used` | `feature_name`, `duration`, `items_count` |
| `streak_achieved` | `streak_type`, `streak_length` |
| `subscription_started` | `plan`, `price`, `trial_converted` |
| `share_completed` | `destination`, `content_type` |

**Person Properties:** `signup_source`, `plan`, `trial_end_date`, `streak_count`, `lifetime_value`

**Key Insights:** Onboarding funnel, D1/D7/D30 retention, stickiness, trial conversion

---

## E-commerce

**Key Metrics:** Conversion rate, AOV, cart abandonment, LTV, repeat purchase

**Core Events:**
| Event | Properties |
|-------|------------|
| `product_viewed` | `product_id`, `product_name`, `category`, `price`, `source` |
| `product_searched` | `query`, `results_count`, `category_filter` |
| `product_added_to_cart` | `product_id`, `quantity`, `cart_value` |
| `product_removed_from_cart` | `product_id`, `quantity`, `reason` |
| `cart_viewed` | `item_count`, `cart_value` |
| `checkout_started` | `cart_value`, `item_count` |
| `checkout_step_completed` | `step_name` (shipping/payment/review) |
| `order_completed` | `order_id`, `order_value`, `item_count`, `payment_method` |
| `order_refunded` | `order_id`, `refund_amount`, `reason` |

**Person Properties:** `lifetime_value`, `order_count`, `first_order_date`, `favorite_category`

**Key Insights:** Purchase funnel, cart abandonment by step, product performance, repeat cohorts

---

## Marketplace

**Key Metrics:** GMV, take rate, buyer/seller ratio, liquidity, time to first transaction

**Core Events:**
| Event | Properties |
|-------|------------|
| `user_signed_up` | `user_type` (buyer/seller), `signup_method` |
| `listing_created` | `category`, `price`, `has_images`, `description_length` |
| `listing_published` | `listing_id`, `time_to_publish` |
| `listing_viewed` | `listing_id`, `source`, `viewer_type` |
| `search_performed` | `query`, `filters`, `results_count` |
| `message_sent` | `sender_type`, `listing_id`, `is_first_contact` |
| `offer_made` | `listing_id`, `offer_amount`, `asking_price` |
| `transaction_completed` | `listing_id`, `amount`, `payment_method`, `take_rate` |
| `review_submitted` | `rating`, `reviewer_type`, `listing_id` |

**Groups:** seller (`rating`, `listing_count`, `total_sales`), buyer (`purchase_count`, `total_spent`)

**Key Insights:** Listing → Transaction funnel, time to first sale, buyer/seller conversion

---

## Developer Tools

**Key Metrics:** API calls/day, SDK adoption, error rates, build success, docs engagement

**Core Events:**
| Event | Properties |
|-------|------------|
| `api_key_created` | `key_type`, `permissions`, `environment` |
| `sdk_initialized` | `sdk_version`, `language`, `framework` |
| `api_call_made` | `endpoint`, `method`, `response_code`, `latency_ms` |
| `build_started` | `build_id`, `trigger`, `config` |
| `build_completed` | `build_id`, `duration`, `status`, `error_type` |
| `deployment_created` | `environment`, `method`, `version` |
| `error_occurred` | `error_type`, `error_message`, `stack_trace` |
| `documentation_viewed` | `page`, `section`, `time_on_page` |

**Person Properties:** `organization`, `api_tier`, `total_api_calls`, `primary_language`

**Key Insights:** Time to first API call, call volume by endpoint, error trends, docs journey

---

## Fintech

**Key Metrics:** Account funded rate, transaction volume, AUM, activation, compliance

**Core Events:**
| Event | Properties |
|-------|------------|
| `user_signed_up` | `signup_method`, `referral_source` |
| `kyc_started` | `document_type` |
| `kyc_completed` | `verification_level`, `time_to_complete` |
| `account_funded` | `amount`, `funding_method`, `first_funding` |
| `transaction_initiated` | `type`, `amount`, `currency` |
| `transaction_completed` | `type`, `amount`, `fee`, `status` |
| `transfer_sent` | `amount`, `destination_type`, `method` |
| `investment_made` | `asset_type`, `amount`, `strategy` |

**Person Properties:** `kyc_status`, `account_tier`, `total_invested`, `risk_score`

**Key Insights:** Signup → KYC → Funded funnel, funding distribution, transaction frequency

---

## Healthcare/Medtech

**Key Metrics:** Patient activation, booking rate, adherence, provider utilization

**Core Events:**
| Event | Properties |
|-------|------------|
| `user_signed_up` | `user_type` (patient/provider), `referral_source` |
| `profile_completed` | `profile_completeness`, `health_data_added` |
| `appointment_booked` | `appointment_type`, `provider_id`, `lead_time_days` |
| `appointment_completed` | `appointment_id`, `duration`, `outcome` |
| `appointment_cancelled` | `reason`, `advance_notice_hours` |
| `prescription_filled` | `medication_type`, `refill` |
| `health_metric_logged` | `metric_type`, `value`, `source` |
| `message_sent` | `recipient_type`, `message_type` |

**Compliance Notes:** Enable Session Replay privacy controls. Consider HIPAA data residency. Use hashed IDs if needed.

---

## Content/Media

**Key Metrics:** Consumption, completion rate, subscription conversion, ad revenue, return visits

**Core Events:**
| Event | Properties |
|-------|------------|
| `content_viewed` | `content_id`, `content_type`, `category`, `source` |
| `content_started` | `content_id`, `start_position` |
| `content_completed` | `content_id`, `completion_percent`, `duration` |
| `content_shared` | `content_id`, `destination`, `method` |
| `content_saved` | `content_id`, `collection` |
| `search_performed` | `query`, `results_count` |
| `subscription_started` | `plan`, `price`, `trial` |
| `ad_viewed` | `ad_id`, `placement`, `duration` |
| `ad_clicked` | `ad_id`, `destination` |

**Person Properties:** `subscription_status`, `preferred_categories`, `total_consumed`

**Key Insights:** Completion by type, subscription funnel, share viral loop, return frequency
