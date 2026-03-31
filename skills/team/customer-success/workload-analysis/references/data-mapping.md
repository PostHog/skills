# Data Mapping Reference

## Vitally Account Fields → Analysis Variables

### Revenue Fields
| Vitally Field | Variable | Usage |
|---------------|----------|-------|
| `mrr` | currentMrr | Current monthly recurring revenue |
| `traits.forecasted_mrr` | forecastedMrr | Projected MRR based on usage |
| `traits.diff_dollars` | mrrDelta | forecastedMrr - currentMrr |
| `traits.ltv` | ltv | Lifetime value |
| `traits.stripe.subscriptionInterval` | contractType | "month" or "year" |

### Product Spend Fields (Monthly)
| Vitally Field | Product |
|---------------|---------|
| `traits.product_analytics_forecasted_mrr` | Product Analytics |
| `traits.session_replay_forecasted_mrr` | Session Replay (Web) |
| `traits.mobile_replay_forecasted_mrr` | Mobile Replay |
| `traits.feature_flags_forecasted_mrr` | Feature Flags |
| `traits.llm_analytics_forecasted_mrr` | LLM Analytics |
| `traits.enhanced_persons_forecasted_mrr` | Identified Events |
| `traits.error_tracking_forecasted_mrr` | Error Tracking |
| `traits.data_warehouse_forecasted_mrr` | Data Warehouse |
| `traits.surveys_forecasted_mrr` | Surveys |
| `traits.batch_exports_forecasted_mrr` | Batch Exports |
| `traits.group_analytics_forecasted_mrr` | Group Analytics |
| `traits.enterprise_forecasted_mrr` | Enterprise/Scale addon |

### Product Plan Fields (Boolean - has plan)
| Vitally Field | Indicates |
|---------------|-----------|
| `traits.product_analytics_plan` | Enrolled in Product Analytics |
| `traits.session_replay_plan` | Enrolled in Session Replay |
| `traits.feature_flags_plan` | Enrolled in Feature Flags |
| `traits.surveys_plan` | Enrolled in Surveys |
| `traits.data_warehouse_plan` | Enrolled in Data Warehouse |
| `traits.enhanced_persons_plan` | Enrolled in Identified Events |
| `traits.group_analytics_plan` | Enrolled in Group Analytics |
| `traits.llm_observability_plan` | Enrolled in LLM Analytics |

### Usage Metrics (30-day)
| Vitally Field | Metric |
|---------------|--------|
| `traits.vitally.custom.replayCountLast30DaysIfSendingData` | Session recordings |
| `traits.vitally.custom.featureFlagRequestsLast30DaysIfSendingData` | FF requests |
| `traits.vitally.custom.rowsSyncedLast30DaysIfSendingData` | Data pipeline rows |

### Account Health
| Vitally Field | Variable |
|---------------|----------|
| `healthScore` | healthScore (0-10) |
| `lastSeenTimestamp` | lastActivity |
| `traits.vitally.custom.supportTickets` | openTickets |
| `npsScore` | npsScore |

## Billing Report Fields (Daily)

### SDK Event Counts (INCLUDE ALL - DON'T MISS ANY)
```javascript
// Extract ALL SDKs from report JSON - check every one
const sdkEvents = {
  // Web
  web: report.web_events_count_in_period || 0,
  
  // Backend
  node: report.node_events_count_in_period || 0,
  python: report.python_events_count_in_period || 0,
  go: report.go_events_count_in_period || 0,
  ruby: report.ruby_events_count_in_period || 0,
  php: report.php_events_count_in_period || 0,
  java: report.java_events_count_in_period || 0,
  
  // Mobile Native
  ios: report.ios_events_count_in_period || 0,
  android: report.android_events_count_in_period || 0,
  
  // Mobile Cross-Platform (OFTEN MISSED!)
  flutter: report.flutter_events_count_in_period || 0,
  react_native: report.react_native_events_count_in_period || 0,
  
  // Other
  api: report.api_events_count_in_period || 0,
};

// CRITICAL: Sum ALL and verify against event_count_in_period
const sdkTotal = Object.values(sdkEvents).reduce((a, b) => a + b, 0);
const reportedTotal = report.event_count_in_period;
if (Math.abs(sdkTotal - reportedTotal) > reportedTotal * 0.05) {
  console.warn('SDK total mismatch - check for missing SDKs');
}
```

**⚠️ COMMON MISTAKE:** Only checking web/node/ios/android/python misses Flutter and React Native, which can be the dominant SDK for mobile-first companies.

### Other Key Metrics
| Field | Description |
|-------|-------------|
| `event_count_in_period` | Total analytics events |
| `ai_event_count_in_period` | LLM/AI events |
| `recording_count_in_period` | Web session recordings |
| `mobile_recording_count_in_period` | Mobile recordings |
| `mobile_billable_recording_count_in_period` | Billable mobile recordings |
| `exceptions_captured_in_period` | Error tracking exceptions |
| `billable_feature_flag_requests_count_in_period` | Billable FF requests |
| `local_evaluation_requests_count_in_period` | Local eval FF requests |
| `enhanced_persons_event_count_in_period` | Identified events |
| `rows_synced_in_period` | Data pipeline rows |
| `survey_responses_count_in_period` | Survey responses |

### Exception Breakdown
```javascript
const exceptionsBySource = {
  web: report.web_exceptions_captured_in_period,
  node: report.node_exceptions_captured_in_period,
  ios: report.ios_exceptions_captured_in_period,
  android: report.android_exceptions_captured_in_period,
  python: report.python_exceptions_captured_in_period,
};
```

### Project-Level Data
Billing report includes `teams` object with per-project breakdown:
```javascript
report.teams['PROJECT_ID'] = {
  event_count_in_period: number,
  recording_count_in_period: number,
  ai_event_count_in_period: number,
  dashboard_count: number,
  ff_count: number,
  ff_active_count: number,
  active_external_data_schemas_in_period: number,
  // ... all metrics available at project level
};
```

Use project-level data to identify:
- Production vs staging/dev projects
- Which project drives most usage
- Feature adoption by project
