# Spend Allocation Rules

## Core Principle

Allocate product spend to workloads based on which SDK/platform consumes the product.

## Allocation by Product

### 1. Product Analytics
**Rule:** Allocate by SDK event proportion
```javascript
const paSpend = vitally.product_analytics_forecasted_mrr;
workloads.web.pa = paSpend * sdkProportions.web;
workloads.backend.pa = paSpend * (sdkProportions.node + sdkProportions.python);
workloads.ios.pa = paSpend * sdkProportions.ios;
workloads.android.pa = paSpend * sdkProportions.android;
```

### 2. Identified Events (Enhanced Persons)
**Rule:** Allocate by SDK event proportion (same as PA)
```javascript
const epSpend = vitally.enhanced_persons_forecasted_mrr;
// Same allocation logic as Product Analytics
```

### 3. Session Replay (Web)
**Rule:** 100% to Web workload
```javascript
workloads.web.sessionReplay = vitally.session_replay_forecasted_mrr;
```

### 4. Mobile Replay
**Rule:** Split by iOS/Android event ratio
```javascript
const mobileTotal = sdkEvents.ios + sdkEvents.android;
const iosRatio = sdkEvents.ios / mobileTotal;
const androidRatio = sdkEvents.android / mobileTotal;

workloads.ios.mobileReplay = vitally.mobile_replay_forecasted_mrr * iosRatio;
workloads.android.mobileReplay = vitally.mobile_replay_forecasted_mrr * androidRatio;
```

### 5. Feature Flags
**Rule:** Allocate to primary SDK consumer (usually where decide requests originate)
```javascript
// Most FF requests come from web or backend
// Check which has more decide_requests or FF usage
// Default: 100% to highest-volume SDK workload
```

### 6. Error Tracking
**Rule:** Allocate by exception source
```javascript
const totalExceptions = Object.values(exceptionsBySource).reduce((a, b) => a + b, 0);
workloads.web.errorTracking = etSpend * (exceptionsBySource.web / totalExceptions);
workloads.backend.errorTracking = etSpend * (exceptionsBySource.node / totalExceptions);
// etc.
```

### 7. LLM Analytics
**Rule:** 100% to LLM Platform workload (create if AI events > 0)
```javascript
if (billing.ai_event_count_in_period > 0) {
  workloads.llmPlatform = {
    products: [{ name: 'LLM Analytics', spend: vitally.llm_analytics_forecasted_mrr }],
  };
}
```

### 8. Data Warehouse
**Rule:** 100% to Data Platform workload
```javascript
workloads.dataPlatform.dataWarehouse = vitally.data_warehouse_forecasted_mrr;
```

### 9. Batch Exports / Data Pipelines
**Rule:** 100% to Data Platform workload
```javascript
workloads.dataPlatform.batchExports = vitally.batch_exports_forecasted_mrr;
```

### 10. Group Analytics
**Rule:** 100% to primary workload (the one with most events)
```javascript
const primaryWorkload = getWorkloadWithHighestEvents();
primaryWorkload.groupAnalytics = vitally.group_analytics_forecasted_mrr;
```

### 11. Surveys
**Rule:** 100% to Web workload (surveys are web-only)
```javascript
workloads.web.surveys = vitally.surveys_forecasted_mrr;
```

### 12. Platform Add-ons (Teams, Scale, Enterprise)
**Rule:** Separate "Platform" workload or exclude from workload allocation
```javascript
// These are org-wide, not workload-specific
workloads.platform = {
  products: [
    { name: 'Scale Plan', spend: vitally.enterprise_forecasted_mrr },
    { name: 'Teams', spend: vitally.teams_forecasted_mrr },
  ],
};
```

## Workload Creation Logic

```javascript
function createWorkloads(sdkProportions, billing, vitally) {
  const workloads = [];
  
  // Web Application (if web SDK > 5%)
  if (sdkProportions.web > 0.05) {
    workloads.push({
      id: 'web-app',
      name: 'Web Application',
      type: sdkProportions.web > 0.5 ? 'primary' : 'secondary',
      sdk: 'posthog-js',
      eventShare: sdkProportions.web,
    });
  }
  
  // Backend API (if node/python/go/ruby/php/java > 5%)
  const backendShare = (sdkProportions.node || 0) + (sdkProportions.python || 0) + 
                       (sdkProportions.go || 0) + (sdkProportions.ruby || 0) + 
                       (sdkProportions.php || 0) + (sdkProportions.java || 0);
  if (backendShare > 0.05) {
    // Find dominant backend SDK
    const backendSdks = ['node', 'python', 'go', 'ruby', 'php', 'java'];
    const dominantBackend = backendSdks.reduce((a, b) => 
      (sdkProportions[a] || 0) > (sdkProportions[b] || 0) ? a : b
    );
    workloads.push({
      id: 'backend-api',
      name: 'Backend API',
      type: backendShare > 0.5 ? 'primary' : 'secondary',
      sdk: `posthog-${dominantBackend}`,
      eventShare: backendShare,
    });
  }
  
  // Flutter App (if flutter > 5%) - CHECK THIS FIRST FOR MOBILE!
  if ((sdkProportions.flutter || 0) > 0.05) {
    workloads.push({
      id: 'flutter-app',
      name: 'Flutter Mobile App',
      type: sdkProportions.flutter > 0.3 ? 'primary' : 'secondary',
      sdk: 'posthog-flutter',
      eventShare: sdkProportions.flutter,
    });
  }
  
  // React Native App (if react_native > 5%)
  if ((sdkProportions.react_native || 0) > 0.05) {
    workloads.push({
      id: 'react-native-app',
      name: 'React Native App',
      type: sdkProportions.react_native > 0.3 ? 'primary' : 'secondary',
      sdk: 'posthog-react-native',
      eventShare: sdkProportions.react_native,
    });
  }
  
  // iOS App (if ios > 5% AND no Flutter/RN dominating)
  if ((sdkProportions.ios || 0) > 0.05 && 
      (sdkProportions.flutter || 0) < 0.2 && 
      (sdkProportions.react_native || 0) < 0.2) {
    workloads.push({
      id: 'ios-app',
      name: 'iOS App',
      type: sdkProportions.ios > 0.3 ? 'primary' : 'secondary',
      sdk: 'posthog-ios',
      eventShare: sdkProportions.ios,
    });
  }
  
  // Android App (if android > 5% AND no Flutter/RN dominating)
  if ((sdkProportions.android || 0) > 0.05 && 
      (sdkProportions.flutter || 0) < 0.2 && 
      (sdkProportions.react_native || 0) < 0.2) {
    workloads.push({
      id: 'android-app',
      name: 'Android App',
      type: sdkProportions.android > 0.3 ? 'primary' : 'secondary',
      sdk: 'posthog-android',
      eventShare: sdkProportions.android,
    });
  }
  
  // LLM Platform (if AI events > 0)
  if (billing.ai_event_count_in_period > 0) {
    workloads.push({
      id: 'llm-platform',
      name: 'LLM/AI Platform',
      type: 'primary',
      sdk: 'posthog-node (AI)',
      eventShare: 0, // AI events tracked separately
    });
  }
  
  // Data Platform (if external schemas > 0 or rows synced > 0)
  if (billing.active_external_data_schemas_in_period > 0 || billing.rows_synced_in_period > 0) {
    workloads.push({
      id: 'data-platform',
      name: 'Data Platform',
      type: 'secondary',
      sdk: 'N/A',
      eventShare: 0,
    });
  }
  
  return workloads;
}
```

## Edge Cases

### Flutter / React Native (Cross-Platform Mobile)
These are mobile SDKs but NOT iOS/Android native. They should:
- Get their own workload (not combined with iOS/Android)
- Receive Mobile Replay allocation (not Web Session Replay)
- Be checked for Error Tracking opportunity

### Multiple Backend SDKs
If both Node and Python have significant usage, create separate workloads or combine into "Backend API" with notation.

### Native iOS/Android alongside Flutter/React Native
If Flutter dominates (>50%) but iOS/Android also have events, the native events may be from:
- A separate native module
- SDK detection issues
- Legacy native code
Usually safe to ignore if <5% each.

### Web Lite
Combine with Web Application workload.

### Zero Events for a Product
If product has spend but zero events in billing data, check if it's:
- Data Warehouse (usage-based on queries, not events)
- Teams/Scale addon (flat fee)
- Recent enrollment (hasn't generated events yet)
