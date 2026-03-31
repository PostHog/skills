import React, { useState } from 'react';

/*
 * WORKLOAD ANALYSIS TEMPLATE
 * 
 * Instructions:
 * 1. Replace [ACCOUNT_NAME] with actual account name
 * 2. Fill in billingData from postgres.prod.billing_usagereport query
 * 3. Fill in vitallySpend from Vitally account traits
 * 4. Update sdkBreakdown based on billing data
 * 5. Adjust workloads array based on SDK proportions
 * 6. Fill in opportunities and risks based on framework
 */

// ============================================
// RAW BILLING DATA - FILL FROM POSTHOG QUERY
// ============================================
const billingData = {
  date: '[DATE]', // e.g., '2025-12-17'
  org_totals: {
    event_count_in_period: 0,
    recording_count_in_period: 0,
    mobile_recording_count_in_period: 0,
    mobile_billable_recording_count_in_period: 0,
    decide_requests_count_in_period: 0,
    enhanced_persons_event_count_in_period: 0,
    exceptions_captured_in_period: 0,
    survey_responses_count_in_period: 0,
    rows_synced_in_period: 0,
    ai_event_count_in_period: 0,
    billable_feature_flag_requests_count_in_period: 0,
  },
  // ⚠️ CRITICAL: Include ALL SDKs - don't miss Flutter/React Native!
  sdk_breakdown: {
    // Web
    web_events_count_in_period: 0,
    // Backend
    node_events_count_in_period: 0,
    python_events_count_in_period: 0,
    go_events_count_in_period: 0,
    ruby_events_count_in_period: 0,
    php_events_count_in_period: 0,
    java_events_count_in_period: 0,
    // Mobile Native
    ios_events_count_in_period: 0,
    android_events_count_in_period: 0,
    // Mobile Cross-Platform (OFTEN MISSED!)
    flutter_events_count_in_period: 0,
    react_native_events_count_in_period: 0,
  },
};

// ============================================
// VITALLY SPEND DATA - FILL FROM VITALLY
// ============================================
const vitallySpend = {
  product_analytics: 0,
  session_replay: 0,
  mobile_replay: 0,
  feature_flags: 0,
  llm_analytics: 0,
  identified_events: 0,
  error_tracking: 0,
  data_warehouse: 0,
  surveys: 0,
  batch_exports: 0,
  group_analytics: 0,
  teams: 0,
  scale: 0,
  total_mrr: 0,
  forecasted_mrr: 0,
  diff_dollars: 0,
};

// ============================================
// ACCOUNT SUMMARY - FILL FROM VITALLY
// ============================================
const accountSummary = {
  name: '[ACCOUNT_NAME]',
  arr: 0,
  mrr: 0,
  employees: 0,
  industry: '[INDUSTRY]',
  fundingStage: '[FUNDING_STAGE]',
  users: 0,
  projects: 0,
  dashboards: 0,
  featureFlags: 0,
  healthScore: 0,
  contractType: 'Monthly', // or 'Annual'
  renewalDate: '[DATE]',
  stripeBalance: 0,
  npsScore: null,
};

// ============================================
// CALCULATED PROPORTIONS
// ============================================
const sdkBreakdown = billingData.sdk_breakdown;
const totalSdkEvents = Object.values(sdkBreakdown).reduce((a, b) => a + b, 0) || 1;

// ⚠️ Include ALL SDKs in proportions
const sdkProportions = {
  web: sdkBreakdown.web_events_count_in_period / totalSdkEvents,
  node: sdkBreakdown.node_events_count_in_period / totalSdkEvents,
  python: sdkBreakdown.python_events_count_in_period / totalSdkEvents,
  go: sdkBreakdown.go_events_count_in_period / totalSdkEvents,
  ruby: sdkBreakdown.ruby_events_count_in_period / totalSdkEvents,
  php: sdkBreakdown.php_events_count_in_period / totalSdkEvents,
  java: sdkBreakdown.java_events_count_in_period / totalSdkEvents,
  ios: sdkBreakdown.ios_events_count_in_period / totalSdkEvents,
  android: sdkBreakdown.android_events_count_in_period / totalSdkEvents,
  flutter: sdkBreakdown.flutter_events_count_in_period / totalSdkEvents,
  react_native: sdkBreakdown.react_native_events_count_in_period / totalSdkEvents,
};

// ============================================
// WORKLOAD DEFINITIONS - CUSTOMIZE PER ACCOUNT
// ============================================
const workloads = [
  // Example: Web Application workload
  {
    id: 'web-app',
    name: 'Web Application',
    type: 'primary', // 'primary', 'secondary', or 'inactive'
    sdk: 'posthog-js',
    description: '[DESCRIPTION]',
    dailyEvents: sdkBreakdown.web_events_count_in_period,
    eventShare: sdkProportions.web,
    products: [
      { 
        name: 'Product Analytics', 
        spend: vitallySpend.product_analytics * sdkProportions.web,
        dailyUsage: Math.round(billingData.org_totals.event_count_in_period * sdkProportions.web),
        unit: 'events/day',
        status: 'significant', // 'significant', 'adopted', 'experimenting', 'opportunity'
      },
      // Add more products...
    ],
    teams: ['Product', 'Engineering'],
  },
  // Add more workloads based on SDK breakdown...
];

// Calculate workload totals
const workloadTotals = workloads.map(w => ({
  ...w,
  totalSpend: w.products.reduce((sum, p) => sum + p.spend, 0),
})).sort((a, b) => b.totalSpend - a.totalSpend);

// ============================================
// OPPORTUNITIES - CUSTOMIZE PER ACCOUNT
// ============================================
const opportunities = [
  {
    priority: 1,
    type: 'conversion', // 'conversion', 'expansion', 'cross-sell'
    product: '[OPPORTUNITY]',
    workloads: ['[WORKLOAD]'],
    currentUsage: '[CURRENT]',
    potentialMRR: '$X-Y',
    confidence: 'XX%',
    rationale: '[WHY]',
    action: '[NEXT STEP]',
  },
];

// ============================================
// RISKS - CUSTOMIZE PER ACCOUNT
// ============================================
const risks = [
  // Only include if account has risks
  // {
  //   severity: 'high', // 'high', 'medium', 'low'
  //   issue: '[ISSUE]',
  //   details: '[DETAILS]',
  //   impact: '[IMPACT]',
  //   action: '[ACTION]',
  // },
];

// ============================================
// STYLING CONSTANTS
// ============================================
const statusColors = {
  significant: '#22c55e',
  adopted: '#3b82f6',
  experimenting: '#f59e0b',
  opportunity: '#e5e7eb',
};

const workloadTypeColors = {
  primary: '#3b82f6',
  secondary: '#8b5cf6',
  platform: '#6b7280',
  inactive: '#9ca3af',
};

const riskColors = {
  high: '#ef4444',
  medium: '#f59e0b',
  low: '#6b7280',
};

// ============================================
// UTILITY FUNCTIONS
// ============================================
const formatCurrency = (amount) => {
  if (amount === 0) return '$0';
  if (amount < 1) return '<$1';
  return `$${amount.toLocaleString(undefined, { maximumFractionDigits: 0 })}`;
};

const formatNumber = (num) => {
  if (num >= 1000000) return `${(num / 1000000).toFixed(1)}M`;
  if (num >= 1000) return `${(num / 1000).toFixed(1)}K`;
  return num.toString();
};

// ============================================
// COMPONENTS
// ============================================

const SummaryCards = () => {
  const totalSpend = workloadTotals.reduce((sum, w) => sum + w.totalSpend, 0);
  const hasRisks = risks.length > 0;
  const isMonthly = accountSummary.contractType === 'Monthly';
  const isDeclining = vitallySpend.diff_dollars < 0;

  return (
    <div className="grid grid-cols-6 gap-3 mb-4">
      <div className="bg-white p-4 rounded-lg shadow border">
        <div className="text-2xl font-bold text-gray-900">{formatCurrency(totalSpend)}</div>
        <div className="text-xs text-gray-500">Monthly Spend</div>
      </div>
      {isDeclining ? (
        <div className="bg-red-50 p-4 rounded-lg shadow border border-red-200">
          <div className="text-2xl font-bold text-red-600">{formatCurrency(vitallySpend.diff_dollars)}</div>
          <div className="text-xs text-red-600">MRR Trend ⚠️</div>
        </div>
      ) : (
        <div className="bg-green-50 p-4 rounded-lg shadow border border-green-200">
          <div className="text-2xl font-bold text-green-600">+{formatCurrency(vitallySpend.diff_dollars)}</div>
          <div className="text-xs text-green-600">MRR Trend ✓</div>
        </div>
      )}
      <div className={`p-4 rounded-lg shadow border ${accountSummary.healthScore < 6 ? 'bg-amber-50 border-amber-200' : 'bg-white'}`}>
        <div className={`text-2xl font-bold ${accountSummary.healthScore < 6 ? 'text-amber-600' : 'text-gray-900'}`}>
          {accountSummary.healthScore.toFixed(1)}
        </div>
        <div className={`text-xs ${accountSummary.healthScore < 6 ? 'text-amber-600' : 'text-gray-500'}`}>
          Health Score {accountSummary.healthScore < 6 ? '⚠️' : ''}
        </div>
      </div>
      <div className="bg-white p-4 rounded-lg shadow border">
        <div className="text-2xl font-bold text-blue-600">{workloadTotals.filter(w => w.type !== 'inactive').length}</div>
        <div className="text-xs text-gray-500">Active Workloads</div>
      </div>
      <div className="bg-white p-4 rounded-lg shadow border">
        <div className="text-2xl font-bold text-green-600">
          {new Set(workloadTotals.flatMap(w => w.products.filter(p => p.spend > 0).map(p => p.name))).size}
        </div>
        <div className="text-xs text-gray-500">Paying Products</div>
      </div>
      <div className={`p-4 rounded-lg shadow border ${isMonthly && accountSummary.mrr > 3000 ? 'bg-red-50 border-red-200' : 'bg-white'}`}>
        <div className={`text-2xl font-bold ${isMonthly && accountSummary.mrr > 3000 ? 'text-red-600' : 'text-gray-900'}`}>
          {accountSummary.contractType}
        </div>
        <div className={`text-xs ${isMonthly && accountSummary.mrr > 3000 ? 'text-red-600' : 'text-gray-500'}`}>
          Contract {isMonthly && accountSummary.mrr > 3000 ? '⚠️' : ''}
        </div>
      </div>
    </div>
  );
};

const SdkBreakdownBar = () => {
  // Build SDK list dynamically from all non-zero SDKs
  const sdkColorMap = {
    web: '#3b82f6',
    node: '#22c55e',
    python: '#ec4899',
    go: '#06b6d4',
    ruby: '#ef4444',
    php: '#8b5cf6',
    java: '#f97316',
    ios: '#a855f7',
    android: '#84cc16',
    flutter: '#0ea5e9',      // Flutter blue
    react_native: '#61dafb', // React blue
  };
  
  const sdkNameMap = {
    web: 'Web',
    node: 'Node.js',
    python: 'Python',
    go: 'Go',
    ruby: 'Ruby',
    php: 'PHP',
    java: 'Java',
    ios: 'iOS',
    android: 'Android',
    flutter: 'Flutter',
    react_native: 'React Native',
  };
  
  const sdks = Object.entries(sdkProportions)
    .filter(([_, value]) => value > 0.005) // Only show SDKs with >0.5%
    .map(([key, value]) => ({
      name: sdkNameMap[key] || key,
      value,
      color: sdkColorMap[key] || '#6b7280',
      events: sdkBreakdown[`${key}_events_count_in_period`] || 0,
    }))
    .sort((a, b) => b.value - a.value); // Sort by proportion descending

  return (
    <div className="bg-white p-4 rounded-lg shadow border mb-4">
      <div className="text-sm font-bold text-gray-700 mb-3">Event Volume by SDK (Daily)</div>
      <div className="flex h-8 rounded-lg overflow-hidden mb-3">
        {sdks.map((sdk, i) => (
          <div 
            key={i}
            className="flex items-center justify-center text-white text-xs font-medium"
            style={{ width: `${Math.max(sdk.value * 100, 5)}%`, backgroundColor: sdk.color }}
          >
            {sdk.value >= 0.08 ? `${(sdk.value * 100).toFixed(0)}%` : ''}
          </div>
        ))}
      </div>
      <div className="flex flex-wrap gap-4 text-xs">
        {sdks.map((sdk, i) => (
          <div key={i} className="flex items-center gap-2">
            <div className="w-3 h-3 rounded" style={{ backgroundColor: sdk.color }}></div>
            <span className="font-medium">{sdk.name}:</span>
            <span className="text-gray-600">{formatNumber(sdk.events)}/day ({(sdk.value * 100).toFixed(1)}%)</span>
          </div>
        ))}
      </div>
    </div>
  );
};

const WorkloadCards = () => (
  <div className="grid grid-cols-2 gap-4 mb-4">
    {workloadTotals.filter(w => w.type !== 'inactive' && w.type !== 'platform').map((workload, idx) => (
      <div 
        key={idx} 
        className="bg-white p-4 rounded-lg shadow border"
        style={{ borderLeftWidth: '4px', borderLeftColor: workloadTypeColors[workload.type] }}
      >
        <div className="flex justify-between items-start mb-3">
          <div>
            <div className="font-bold text-gray-900">{workload.name}</div>
            <div className="text-xs text-gray-500">{workload.sdk} • {workload.description}</div>
          </div>
          <div className="text-right">
            <div className="text-lg font-bold text-green-600">{formatCurrency(workload.totalSpend)}/mo</div>
            {workload.eventShare > 0 && (
              <div className="text-xs text-gray-500">{(workload.eventShare * 100).toFixed(0)}% of events</div>
            )}
          </div>
        </div>
        <div className="space-y-2">
          {workload.products.map((product, pIdx) => (
            <div key={pIdx} className="flex items-center justify-between text-sm">
              <div className="flex items-center gap-2">
                <div className="w-2 h-2 rounded-full" style={{ backgroundColor: statusColors[product.status] }}></div>
                <span className={product.status === 'opportunity' ? 'text-gray-400' : 'text-gray-700'}>{product.name}</span>
              </div>
              <div className="text-right">
                {product.spend > 0 ? (
                  <span className="text-green-600 font-medium">{formatCurrency(product.spend)}</span>
                ) : (
                  <span className="text-gray-400 text-xs">{product.note || formatNumber(product.dailyUsage) + ' ' + product.unit}</span>
                )}
              </div>
            </div>
          ))}
        </div>
        <div className="mt-3 pt-3 border-t border-gray-100 text-xs text-gray-500">
          <span className="font-medium">Teams:</span> {workload.teams.join(', ')}
        </div>
      </div>
    ))}
  </div>
);

const OpportunitiesTable = () => (
  <div className="bg-white p-4 rounded-lg shadow border mb-4">
    <div className="text-sm font-bold text-gray-700 mb-3">🎯 Opportunities (Ranked)</div>
    <table className="w-full text-sm">
      <thead>
        <tr className="text-left text-xs text-gray-500 uppercase">
          <th className="p-2">#</th>
          <th className="p-2">Type</th>
          <th className="p-2">Opportunity</th>
          <th className="p-2">Current</th>
          <th className="p-2">Potential</th>
          <th className="p-2">Confidence</th>
          <th className="p-2">Action</th>
        </tr>
      </thead>
      <tbody>
        {opportunities.map((opp, idx) => (
          <tr key={idx} className="border-t border-gray-100">
            <td className="p-2 font-bold text-gray-400">{opp.priority}</td>
            <td className="p-2">
              <span className={`px-2 py-1 rounded text-xs font-medium ${
                opp.type === 'conversion' ? 'bg-purple-100 text-purple-700' : 
                opp.type === 'expansion' ? 'bg-blue-100 text-blue-700' : 
                'bg-green-100 text-green-700'
              }`}>{opp.type}</span>
            </td>
            <td className="p-2 font-medium">{opp.product}</td>
            <td className="p-2 text-xs text-gray-500">{opp.currentUsage}</td>
            <td className="p-2 font-medium text-green-600">{opp.potentialMRR}</td>
            <td className="p-2">
              <span className={`px-2 py-1 rounded text-xs ${
                parseInt(opp.confidence) >= 70 ? 'bg-green-100 text-green-700' :
                parseInt(opp.confidence) >= 50 ? 'bg-yellow-100 text-yellow-700' :
                'bg-gray-100 text-gray-600'
              }`}>{opp.confidence}</span>
            </td>
            <td className="p-2 text-xs text-gray-600">{opp.action}</td>
          </tr>
        ))}
      </tbody>
    </table>
  </div>
);

const RisksTable = () => {
  if (risks.length === 0) return null;
  return (
    <div className="bg-white p-4 rounded-lg shadow border mb-4">
      <div className="text-sm font-bold text-gray-700 mb-3">🚨 Risk Assessment</div>
      <table className="w-full text-sm">
        <thead>
          <tr className="text-left text-xs text-gray-500 uppercase">
            <th className="p-2">Severity</th>
            <th className="p-2">Issue</th>
            <th className="p-2">Details</th>
            <th className="p-2">Impact</th>
            <th className="p-2">Action</th>
          </tr>
        </thead>
        <tbody>
          {risks.map((risk, idx) => (
            <tr key={idx} className="border-t border-gray-100">
              <td className="p-2">
                <span className="px-2 py-1 rounded text-xs font-bold text-white" style={{ backgroundColor: riskColors[risk.severity] }}>
                  {risk.severity.toUpperCase()}
                </span>
              </td>
              <td className="p-2 font-medium">{risk.issue}</td>
              <td className="p-2 text-xs text-gray-600">{risk.details}</td>
              <td className="p-2 text-xs text-red-600 font-medium">{risk.impact}</td>
              <td className="p-2 text-xs text-gray-600">{risk.action}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

const TreeView = () => {
  const activeWorkloads = workloadTotals.filter(w => w.type !== 'inactive');
  
  return (
    <div className="bg-white p-4 rounded-lg shadow border mb-4">
      <div className="text-sm font-bold text-gray-700 mb-4">Hierarchical View: Account → Workloads → Products → Teams</div>
      
      <div className="flex flex-col items-start">
        {/* Account Node */}
        <div className="bg-gray-900 text-white px-4 py-2 rounded font-bold mb-4">
          {accountSummary.name} (${(accountSummary.arr/1000).toFixed(0)}k ARR)
          <span className="text-gray-400 text-sm ml-2">| {accountSummary.employees} employees | {accountSummary.fundingStage}</span>
        </div>
        
        {/* Workloads */}
        <div className="ml-8 border-l-2 border-gray-300">
          {activeWorkloads.map((workload, wIdx) => (
            <div key={wIdx} className="ml-4 mb-6">
              {/* Workload Node */}
              <div className="flex items-center">
                <div className="w-6 h-px bg-gray-300 mr-2"></div>
                <div 
                  className="px-3 py-2 rounded text-sm font-medium"
                  style={{ 
                    backgroundColor: workload.type === 'primary' ? '#dbeafe' : '#f3e8ff',
                    color: workload.type === 'primary' ? '#1e40af' : '#6b21a8',
                    borderLeft: `4px solid ${workloadTypeColors[workload.type]}`
                  }}
                >
                  <div className="font-bold">{workload.name}</div>
                  <div className="text-xs opacity-75">{workload.sdk} • {formatNumber(workload.dailyEvents)} events/day • {formatCurrency(workload.totalSpend)}/mo</div>
                </div>
              </div>
              
              {/* Products */}
              <div className="ml-10 mt-2 border-l border-gray-200">
                {workload.products.map((product, pIdx) => (
                  <div key={pIdx} className="ml-4 mb-2">
                    <div className="flex items-center">
                      <div className="w-4 h-px bg-gray-200 mr-2"></div>
                      <div className="w-3 h-3 rounded-full mr-2 flex-shrink-0" style={{ backgroundColor: statusColors[product.status] }}></div>
                      <span className={`text-sm ${product.status === 'opportunity' ? 'text-gray-400' : 'text-gray-700'}`}>
                        <span className="font-medium">{product.name}</span>
                        {product.spend > 0 && <span className="text-green-600 ml-2">({formatCurrency(product.spend)}/mo)</span>}
                        {product.spend === 0 && product.dailyUsage > 0 && (
                          <span className="text-amber-600 ml-2">({formatNumber(product.dailyUsage)} {product.unit})</span>
                        )}
                        {product.note && <span className="text-gray-400 ml-2 text-xs italic">[{product.note}]</span>}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
              
              {/* Teams */}
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

const SankeyView = () => {
  // Get unique products with spend
  const productsWithSpend = [];
  const productSpendMap = {};
  workloadTotals.forEach(w => {
    w.products.forEach(p => {
      if (p.spend > 0) {
        if (!productSpendMap[p.name]) {
          productSpendMap[p.name] = 0;
        }
        productSpendMap[p.name] += p.spend;
      }
    });
  });
  
  Object.entries(productSpendMap).forEach(([name, amount]) => {
    productsWithSpend.push({ name, amount, color: statusColors.significant });
  });
  productsWithSpend.sort((a, b) => b.amount - a.amount);
  
  const totalSpend = productsWithSpend.reduce((s, p) => s + p.amount, 0) || 1;
  const activeWorkloads = workloadTotals.filter(w => w.type !== 'inactive' && w.totalSpend > 0);
  
  // Assign colors
  const productColors = ['#3b82f6', '#8b5cf6', '#22c55e', '#f59e0b', '#ec4899', '#06b6d4', '#84cc16', '#f97316'];
  productsWithSpend.forEach((p, i) => { p.color = productColors[i % productColors.length]; });
  
  const workloadColors = ['#3b82f6', '#8b5cf6', '#22c55e', '#f59e0b'];
  activeWorkloads.forEach((w, i) => { w.color = workloadColors[i % workloadColors.length]; });

  // SVG dimensions
  const svgWidth = 800;
  const svgHeight = Math.max(300, Math.max(productsWithSpend.length, activeWorkloads.length) * 60 + 60);
  const leftX = 140;
  const rightX = svgWidth - 200;
  const barWidth = 30;
  const gap = 8;
  
  // Position left bars (products)
  let leftY = 40;
  const leftBars = productsWithSpend.map(p => {
    const height = Math.max((p.amount / totalSpend) * (svgHeight - 80), 25);
    const bar = { ...p, x: leftX, y: leftY, width: barWidth, height };
    leftY += height + gap;
    return bar;
  });
  
  // Position right bars (workloads)
  let rightY = 40;
  const rightBars = activeWorkloads.map(w => {
    const height = Math.max((w.totalSpend / totalSpend) * (svgHeight - 80), 25);
    const bar = { ...w, amount: w.totalSpend, x: rightX, y: rightY, width: barWidth, height };
    rightY += height + gap;
    return bar;
  });

  // Build flows
  const flows = [];
  const leftOffsets = {};
  const rightOffsets = {};
  leftBars.forEach(b => { leftOffsets[b.name] = b.y; });
  rightBars.forEach(b => { rightOffsets[b.name] = b.y; });
  
  activeWorkloads.forEach(workload => {
    workload.products.forEach(product => {
      if (product.spend > 0) {
        flows.push({ from: product.name, to: workload.name, amount: product.spend, color: leftBars.find(b => b.name === product.name)?.color || '#888' });
      }
    });
  });

  return (
    <div className="bg-white p-4 rounded-lg shadow border mb-4">
      <div className="text-sm font-bold text-gray-700 mb-4">Revenue Flow: Products → Workloads</div>
      
      <svg width={svgWidth} height={svgHeight} className="mx-auto">
        {/* Flow paths */}
        {flows.filter(f => f.amount > 0).map((flow, idx) => {
          const fromBar = leftBars.find(b => b.name === flow.from);
          const toBar = rightBars.find(b => b.name === flow.to);
          if (!fromBar || !toBar) return null;
          
          const flowHeight = Math.max((flow.amount / totalSpend) * (svgHeight - 80), 3);
          const startY = leftOffsets[flow.from] || fromBar.y;
          const endY = rightOffsets[flow.to] || toBar.y;
          
          leftOffsets[flow.from] = (leftOffsets[flow.from] || fromBar.y) + flowHeight;
          rightOffsets[flow.to] = (rightOffsets[flow.to] || toBar.y) + flowHeight;
          
          const path = `
            M ${fromBar.x + barWidth} ${startY}
            C ${fromBar.x + barWidth + 100} ${startY},
              ${toBar.x - 100} ${endY},
              ${toBar.x} ${endY}
            L ${toBar.x} ${endY + flowHeight}
            C ${toBar.x - 100} ${endY + flowHeight},
              ${fromBar.x + barWidth + 100} ${startY + flowHeight},
              ${fromBar.x + barWidth} ${startY + flowHeight}
            Z
          `;
          
          return <path key={idx} d={path} fill={flow.color} fillOpacity={0.3} stroke={flow.color} strokeWidth={0.5} />;
        })}
        
        {/* Left bars (Products) */}
        {leftBars.map((bar, idx) => (
          <g key={`left-${idx}`}>
            <rect x={bar.x} y={bar.y} width={bar.width} height={bar.height} fill={bar.color} rx={4} />
            <text x={bar.x - 10} y={bar.y + bar.height / 2} textAnchor="end" dominantBaseline="middle" fontSize={11} fill="#374151" fontWeight="500">
              {bar.name.length > 18 ? bar.name.slice(0, 16) + '...' : bar.name}
            </text>
            <text x={bar.x - 10} y={bar.y + bar.height / 2 + 13} textAnchor="end" dominantBaseline="middle" fontSize={10} fill="#6b7280">
              {formatCurrency(bar.amount)}
            </text>
          </g>
        ))}
        
        {/* Right bars (Workloads) */}
        {rightBars.map((bar, idx) => (
          <g key={`right-${idx}`}>
            <rect x={bar.x} y={bar.y} width={bar.width} height={bar.height} fill={bar.color} rx={4} />
            <text x={bar.x + bar.width + 10} y={bar.y + bar.height / 2} textAnchor="start" dominantBaseline="middle" fontSize={11} fill="#374151" fontWeight="500">
              {bar.name}
            </text>
            <text x={bar.x + bar.width + 10} y={bar.y + bar.height / 2 + 13} textAnchor="start" dominantBaseline="middle" fontSize={10} fill="#6b7280">
              {formatCurrency(bar.amount)} ({((bar.amount / totalSpend) * 100).toFixed(0)}%)
            </text>
          </g>
        ))}
        
        {/* Labels */}
        <text x={leftX + barWidth/2} y={20} textAnchor="middle" fontSize={11} fill="#6b7280" fontWeight="bold">PRODUCTS</text>
        <text x={rightX + barWidth/2} y={20} textAnchor="middle" fontSize={11} fill="#6b7280" fontWeight="bold">WORKLOADS</text>
      </svg>
      
      <div className="text-xs text-gray-500 text-center mt-2">Flow width represents dollar allocation</div>
    </div>
  );
};

const MatrixView = () => {
  const allProducts = [...new Set(workloadTotals.flatMap(w => w.products.map(p => p.name)))];
  
  return (
    <div className="bg-white p-4 rounded-lg shadow border mb-4 overflow-x-auto">
      <div className="text-sm font-bold text-gray-700 mb-3">Product × Workload Matrix</div>
      <table className="w-full text-xs">
        <thead>
          <tr>
            <th className="p-2 text-left font-bold text-gray-700 border-b-2">Workload</th>
            {allProducts.map(p => (
              <th key={p} className="p-2 text-center font-medium text-gray-600 border-b-2 whitespace-nowrap">{p}</th>
            ))}
            <th className="p-2 text-center font-bold text-gray-700 border-b-2">Total</th>
          </tr>
        </thead>
        <tbody>
          {workloadTotals.filter(w => w.type !== 'platform').map((workload, idx) => (
            <tr key={idx}>
              <td className="p-2 font-medium border-b" style={{ color: workloadTypeColors[workload.type] }}>
                {workload.name}
              </td>
              {allProducts.map(productName => {
                const product = workload.products.find(p => p.name === productName);
                const bgColor = !product ? '#f9fafb' : 
                  product.status === 'significant' ? '#dcfce7' :
                  product.status === 'adopted' ? '#dbeafe' :
                  product.status === 'experimenting' ? '#fef3c7' : '#f9fafb';
                return (
                  <td key={productName} className="p-2 text-center border-b" style={{ backgroundColor: bgColor }}>
                    {product?.spend > 0 ? formatCurrency(product.spend) : '—'}
                  </td>
                );
              })}
              <td className="p-2 text-center border-b font-bold">{formatCurrency(workload.totalSpend)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

const RawDataReference = () => {
  const [expanded, setExpanded] = useState(false);
  return (
    <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
      <button onClick={() => setExpanded(!expanded)} className="flex items-center gap-2 text-sm font-medium text-gray-700">
        <span>{expanded ? '▼' : '▶'}</span>
        <span>Raw Data Reference</span>
      </button>
      {expanded && (
        <div className="mt-4 text-xs font-mono bg-white p-4 rounded border overflow-x-auto">
          <pre>{JSON.stringify({ accountSummary, vitallySpend, sdkProportions, billingData: billingData.org_totals }, null, 2)}</pre>
        </div>
      )}
    </div>
  );
};

// ============================================
// MAIN COMPONENT
// ============================================
export default function WorkloadAnalysis() {
  const [activeView, setActiveView] = useState('overview');
  const hasRisks = risks.length > 0;

  return (
    <div className="min-h-screen bg-gray-100 p-6">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="flex justify-between items-start mb-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">{accountSummary.name} - Workload Analysis</h1>
            <p className="text-gray-600">
              {accountSummary.industry} | {accountSummary.fundingStage} | {accountSummary.employees} employees
            </p>
          </div>
          <div className="text-right">
            <div className="text-sm text-gray-500">{accountSummary.contractType} Contract</div>
            <div className="text-xl font-bold text-green-600">${(accountSummary.arr / 1000).toFixed(0)}k ARR</div>
            <div className="text-xs text-gray-400">Renews: {accountSummary.renewalDate}</div>
          </div>
        </div>

        <SummaryCards />
        <SdkBreakdownBar />
        
        {/* View Tabs */}
        <div className="flex flex-wrap gap-2 mb-4">
          {[
            { id: 'overview', label: '📊 Overview' },
            ...(hasRisks ? [{ id: 'risks', label: '🚨 Risks' }] : []),
            { id: 'tree', label: '🌳 Tree View' },
            { id: 'sankey', label: '💰 Revenue Flow' },
            { id: 'matrix', label: '📋 Matrix' },
          ].map(tab => (
            <button
              key={tab.id}
              onClick={() => setActiveView(tab.id)}
              className={`px-4 py-2 rounded text-sm font-medium transition-colors ${
                activeView === tab.id ? 'bg-gray-900 text-white' : 'bg-white text-gray-700 hover:bg-gray-100 border'
              }`}
            >{tab.label}</button>
          ))}
        </div>

        {activeView === 'overview' && (
          <>
            <WorkloadCards />
            <OpportunitiesTable />
          </>
        )}
        {activeView === 'risks' && (
          <>
            <RisksTable />
            <OpportunitiesTable />
          </>
        )}
        {activeView === 'tree' && <TreeView />}
        {activeView === 'sankey' && <SankeyView />}
        {activeView === 'matrix' && <MatrixView />}

        <RawDataReference />
      </div>
    </div>
  );
}
