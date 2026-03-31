---
name: workload-analysis
description: Generate comprehensive workload analysis visualizations for PostHog customer accounts. Use when user requests account analysis, workload breakdown, SDK analysis, spend allocation, or expansion opportunity assessment. Triggers include "analyze [account]", "workload analysis for [account]", "SDK breakdown for [account]", "show me how [account] uses PostHog", or any request to understand customer usage patterns across products and platforms.
---

# Workload Analysis Skill

Generate interactive React visualizations showing how customer spend flows from products → workloads → teams, with SDK breakdowns, opportunity identification, and risk assessment.

## Workflow

### Step 1: Collect Account Data

1. **Find account in Vitally:**
   ```
   vitally:find_account_by_name → get externalId (organization_id)
   vitally:get_account_full with filterUnnecessaryFields=false
   ```

2. **Query billing data from PostHog:**
   ```sql
   SELECT date, report 
   FROM postgres.prod.billing_usagereport
   WHERE organization_id = '[externalId]'
   ORDER BY date DESC LIMIT 3
   ```

3. **Extract key fields** (see references/data-mapping.md for complete field list):
   - Vitally: MRR, forecasted_mrr, diff_dollars, product spend fields
   - Billing: SDK event counts, AI events, recordings, exceptions, feature flag requests

### Step 2: Calculate SDK Proportions

**⚠️ CRITICAL: Check ALL SDKs, not just common ones. Flutter/React Native are often the dominant SDK for mobile-first companies.**

From billing data, extract COMPLETE SDK breakdown:
```javascript
const sdkBreakdown = {
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
  // Mobile Cross-Platform (DON'T MISS THESE!)
  flutter: report.flutter_events_count_in_period || 0,
  react_native: report.react_native_events_count_in_period || 0,
};
const total = Object.values(sdkBreakdown).reduce((a, b) => a + b, 0);

// Verify: SDK total should ≈ event_count_in_period
// If big gap, you're missing an SDK!
```

### Step 3: Define Workloads

Create workloads based on SDK proportions and product usage patterns:

| Pattern | Workload Type | Examples |
|---------|---------------|----------|
| Web >80% | Web Application (primary) | SaaS dashboard |
| Node/Python/Go/Ruby/PHP/Java >80% | Backend API (primary) | API-first product |
| iOS + Android >20% | Native Mobile Apps (primary) | Consumer iOS/Android |
| **Flutter >20%** | **Flutter Mobile App (primary)** | Cross-platform mobile |
| **React Native >20%** | **React Native App (primary)** | Cross-platform mobile |
| AI events >0 | LLM/AI Platform | AI-first company |
| External schemas >0 | Data Platform | Data warehouse usage |

**Mobile Priority:** If Flutter or React Native dominates, that's the primary mobile workload (not iOS/Android native).

### Step 4: Allocate Spend to Workloads

Apply allocation rules from references/spend-allocation.md:

| Product | Allocation Rule |
|---------|-----------------|
| Product Analytics | By SDK event proportion |
| Identified Events | By SDK event proportion |
| Session Replay (Web) | 100% to Web workload |
| Mobile Replay | Split by iOS/Android event ratio |
| Feature Flags | 100% to primary SDK consumer |
| Error Tracking | By exception source (web vs node) |
| LLM Analytics | 100% to LLM Platform workload |
| Data Warehouse | 100% to Data Platform workload |
| Group Analytics | 100% to primary workload |
| Teams/Scale | Platform-wide (separate) |

### Step 5: Identify Opportunities & Risks

Apply frameworks from references/opportunity-framework.md:

**Opportunities (check in order):**
1. Monthly → Annual conversion (if not annual)
2. Product gaps (enrolled but $0 spend)
3. Cross-sell (missing products for their profile)
4. Usage expansion (approaching limits)

**Risks (flag if present):**
1. Declining MRR (forecasted < current)
2. No annual contract (>$3K MRR monthly)
3. Low health score (<6)
4. Single product dependency (>50% of spend)

### Step 6: Generate React Visualization

Use the template from assets/workload-template.jsx. **ALL components below are REQUIRED:**

**MANDATORY Components (include ALL of these):**
1. **SummaryCards** - MRR, health score, contract type, alerts
2. **SdkBreakdownBar** - Visual SDK proportion bar
3. **WorkloadCards** - Cards for each workload with products
4. **OpportunitiesTable** - Ranked opportunities with confidence
5. **RisksTable** - If risks present, severity-ranked
6. **TreeView** - REQUIRED: Hierarchical view showing Account → Workloads → Products → Teams with connecting lines
7. **SankeyView** - REQUIRED: SVG revenue flow diagram showing Products (left bars) flowing to Workloads (right bars) with curved paths
8. **MatrixView** - Products × Workloads grid with spend cells

**View Tabs (MUST include all 5):**
```javascript
const tabs = [
  { id: 'overview', label: '📊 Overview' },
  { id: 'risks', label: '🚨 Risks' },      // Show if risks.length > 0
  { id: 'tree', label: '🌳 Tree View' },   // REQUIRED
  { id: 'sankey', label: '💰 Revenue Flow' }, // REQUIRED
  { id: 'matrix', label: '📋 Matrix' },
];
```

**⚠️ DO NOT SKIP TreeView or SankeyView. These are the most valuable visualizations for understanding account structure.**

### Required Component: TreeView

Copy this component exactly:
```jsx
const TreeView = () => {
  const activeWorkloads = workloadTotals.filter(w => w.type !== 'inactive');
  return (
    <div className="bg-white p-4 rounded-lg shadow border mb-4">
      <div className="text-sm font-bold text-gray-700 mb-4">Hierarchical View: Account → Workloads → Products → Teams</div>
      <div className="flex flex-col items-start">
        <div className="bg-gray-900 text-white px-4 py-2 rounded font-bold mb-4">
          {accountSummary.name} (${(accountSummary.arr/1000).toFixed(0)}k ARR)
          <span className="text-gray-400 text-sm ml-2">| {accountSummary.employees} employees | {accountSummary.fundingStage}</span>
        </div>
        <div className="ml-8 border-l-2 border-gray-300">
          {activeWorkloads.map((workload, wIdx) => (
            <div key={wIdx} className="ml-4 mb-6">
              <div className="flex items-center">
                <div className="w-6 h-px bg-gray-300 mr-2"></div>
                <div className="px-3 py-2 rounded text-sm font-medium"
                  style={{ backgroundColor: workload.type === 'primary' ? '#dbeafe' : '#f3e8ff',
                    color: workload.type === 'primary' ? '#1e40af' : '#6b21a8',
                    borderLeft: `4px solid ${workloadTypeColors[workload.type]}` }}>
                  <div className="font-bold">{workload.name}</div>
                  <div className="text-xs opacity-75">{workload.sdk} • {formatNumber(workload.dailyEvents)} events/day • {formatCurrency(workload.totalSpend)}/mo</div>
                </div>
              </div>
              <div className="ml-10 mt-2 border-l border-gray-200">
                {workload.products.map((product, pIdx) => (
                  <div key={pIdx} className="ml-4 mb-2 flex items-center">
                    <div className="w-4 h-px bg-gray-200 mr-2"></div>
                    <div className="w-3 h-3 rounded-full mr-2" style={{ backgroundColor: statusColors[product.status] }}></div>
                    <span className={`text-sm ${product.status === 'opportunity' ? 'text-gray-400' : 'text-gray-700'}`}>
                      <span className="font-medium">{product.name}</span>
                      {product.spend > 0 && <span className="text-green-600 ml-2">({formatCurrency(product.spend)}/mo)</span>}
                    </span>
                  </div>
                ))}
              </div>
              <div className="ml-10 mt-2 flex items-center gap-2">
                <div className="w-4 h-px bg-gray-200"></div>
                <span className="text-xs text-gray-500">Teams:</span>
                {workload.teams.map((team, tIdx) => (
                  <span key={tIdx} className="bg-purple-100 text-purple-700 px-2 py-0.5 rounded text-xs">{team}</span>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
```

### Required Component: SankeyView

Copy this component exactly:
```jsx
const SankeyView = () => {
  const productsWithSpend = [];
  const productSpendMap = {};
  workloadTotals.forEach(w => {
    w.products.forEach(p => {
      if (p.spend > 0) {
        productSpendMap[p.name] = (productSpendMap[p.name] || 0) + p.spend;
      }
    });
  });
  Object.entries(productSpendMap).forEach(([name, amount]) => {
    productsWithSpend.push({ name, amount });
  });
  productsWithSpend.sort((a, b) => b.amount - a.amount);
  
  const totalSpend = productsWithSpend.reduce((s, p) => s + p.amount, 0) || 1;
  const activeWorkloads = workloadTotals.filter(w => w.type !== 'inactive' && w.totalSpend > 0);
  
  const productColors = ['#3b82f6', '#8b5cf6', '#22c55e', '#f59e0b', '#ec4899', '#06b6d4'];
  productsWithSpend.forEach((p, i) => { p.color = productColors[i % productColors.length]; });
  activeWorkloads.forEach((w, i) => { w.color = productColors[i % productColors.length]; });

  const svgWidth = 800;
  const svgHeight = Math.max(300, Math.max(productsWithSpend.length, activeWorkloads.length) * 60 + 60);
  const leftX = 140, rightX = svgWidth - 200, barWidth = 30, gap = 8;
  
  let leftY = 40;
  const leftBars = productsWithSpend.map(p => {
    const height = Math.max((p.amount / totalSpend) * (svgHeight - 80), 25);
    const bar = { ...p, x: leftX, y: leftY, width: barWidth, height };
    leftY += height + gap;
    return bar;
  });
  
  let rightY = 40;
  const rightBars = activeWorkloads.map(w => {
    const height = Math.max((w.totalSpend / totalSpend) * (svgHeight - 80), 25);
    const bar = { ...w, amount: w.totalSpend, x: rightX, y: rightY, width: barWidth, height };
    rightY += height + gap;
    return bar;
  });

  const flows = [];
  const leftOffsets = {}, rightOffsets = {};
  leftBars.forEach(b => { leftOffsets[b.name] = b.y; });
  rightBars.forEach(b => { rightOffsets[b.name] = b.y; });
  
  activeWorkloads.forEach(workload => {
    workload.products.forEach(product => {
      if (product.spend > 0) {
        flows.push({ from: product.name, to: workload.name, amount: product.spend, 
          color: leftBars.find(b => b.name === product.name)?.color || '#888' });
      }
    });
  });

  return (
    <div className="bg-white p-4 rounded-lg shadow border mb-4">
      <div className="text-sm font-bold text-gray-700 mb-4">Revenue Flow: Products → Workloads</div>
      <svg width={svgWidth} height={svgHeight} className="mx-auto">
        {flows.map((flow, idx) => {
          const fromBar = leftBars.find(b => b.name === flow.from);
          const toBar = rightBars.find(b => b.name === flow.to);
          if (!fromBar || !toBar) return null;
          const flowHeight = Math.max((flow.amount / totalSpend) * (svgHeight - 80), 3);
          const startY = leftOffsets[flow.from], endY = rightOffsets[flow.to];
          leftOffsets[flow.from] += flowHeight;
          rightOffsets[flow.to] += flowHeight;
          const path = `M ${fromBar.x + barWidth} ${startY} C ${fromBar.x + barWidth + 100} ${startY}, ${toBar.x - 100} ${endY}, ${toBar.x} ${endY} L ${toBar.x} ${endY + flowHeight} C ${toBar.x - 100} ${endY + flowHeight}, ${fromBar.x + barWidth + 100} ${startY + flowHeight}, ${fromBar.x + barWidth} ${startY + flowHeight} Z`;
          return <path key={idx} d={path} fill={flow.color} fillOpacity={0.3} stroke={flow.color} strokeWidth={0.5} />;
        })}
        {leftBars.map((bar, idx) => (
          <g key={`left-${idx}`}>
            <rect x={bar.x} y={bar.y} width={bar.width} height={bar.height} fill={bar.color} rx={4} />
            <text x={bar.x - 10} y={bar.y + bar.height / 2} textAnchor="end" dominantBaseline="middle" fontSize={11} fill="#374151" fontWeight="500">{bar.name}</text>
            <text x={bar.x - 10} y={bar.y + bar.height / 2 + 13} textAnchor="end" dominantBaseline="middle" fontSize={10} fill="#6b7280">{formatCurrency(bar.amount)}</text>
          </g>
        ))}
        {rightBars.map((bar, idx) => (
          <g key={`right-${idx}`}>
            <rect x={bar.x} y={bar.y} width={bar.width} height={bar.height} fill={bar.color} rx={4} />
            <text x={bar.x + bar.width + 10} y={bar.y + bar.height / 2} textAnchor="start" dominantBaseline="middle" fontSize={11} fill="#374151" fontWeight="500">{bar.name}</text>
            <text x={bar.x + bar.width + 10} y={bar.y + bar.height / 2 + 13} textAnchor="start" dominantBaseline="middle" fontSize={10} fill="#6b7280">{formatCurrency(bar.amount)} ({((bar.amount / totalSpend) * 100).toFixed(0)}%)</text>
          </g>
        ))}
        <text x={leftX + barWidth/2} y={20} textAnchor="middle" fontSize={11} fill="#6b7280" fontWeight="bold">PRODUCTS</text>
        <text x={rightX + barWidth/2} y={20} textAnchor="middle" fontSize={11} fill="#6b7280" fontWeight="bold">WORKLOADS</text>
      </svg>
      <div className="text-xs text-gray-500 text-center mt-2">Flow width represents dollar allocation</div>
    </div>
  );
};
```

### Output Format

Generate a complete React component file named `{account-name}-workload-analysis.jsx` that:
- Contains all raw data in variables (for reference)
- Calculates proportions and allocations
- Defines workloads with products array
- Includes all visualization components
- Has view tabs for different perspectives

## Quick Reference

### Status Thresholds
- **Significant**: ≥$500/mo (green)
- **Adopted**: $100-499/mo (blue)  
- **Experimenting**: $1-99/mo (amber)
- **Opportunity**: $0/mo (gray)

### Key SQL Fields
```
event_count_in_period, recording_count_in_period, 
ai_event_count_in_period, exceptions_captured_in_period,
billable_feature_flag_requests_count_in_period,
enhanced_persons_event_count_in_period
```

### Vitally Spend Fields
```
product_analytics_forecasted_mrr, session_replay_forecasted_mrr,
feature_flags_forecasted_mrr, llm_analytics_forecasted_mrr,
enhanced_persons_forecasted_mrr, error_tracking_forecasted_mrr,
data_warehouse_forecasted_mrr, surveys_forecasted_mrr
```

## Pre-Delivery Checklist

Before presenting the React artifact, verify ALL of these are included:

- [ ] SummaryCards component with MRR, health, contract type
- [ ] SdkBreakdownBar showing ALL SDKs (including Flutter/React Native if present)
- [ ] WorkloadCards for each identified workload
- [ ] OpportunitiesTable with ranked opportunities
- [ ] RisksTable (if any risks identified)
- [ ] **TreeView component** - hierarchical Account → Workloads → Products → Teams
- [ ] **SankeyView component** - SVG with curved flow paths from Products to Workloads
- [ ] MatrixView with Products × Workloads grid
- [ ] View tabs including: Overview, Risks, 🌳 Tree View, 💰 Revenue Flow, Matrix
- [ ] Raw data reference section (collapsible)
