# Opportunity & Risk Framework

## Opportunity Identification

### Priority 1: Annual Contract Conversion
**Trigger:** `stripe.subscriptionInterval === "month"` AND MRR > $3,000

| Confidence | Value | Action |
|------------|-------|--------|
| 85-95% | MRR × 12 | Propose annual with 10-20% discount |

**Talking points:**
- "Lock in current pricing"
- "10-20% discount on annual commitment"
- "Simplify budget planning"

### Priority 2: Product Gaps (Enrolled but $0)
**Trigger:** Has `*_plan` but `*_forecasted_mrr === 0`

| Product | Typical MRR | Confidence |
|---------|-------------|------------|
| Surveys (enrolled) | $50-200 | 60% |
| Error Tracking (enrolled) | $100-400 | 70% |
| Feature Flags (enrolled) | $100-500 | 65% |

**Action:** "I see you have [product] enabled but haven't used it yet. Would you like help setting it up?"

### Priority 3: Cross-sell by Profile

#### Web-Heavy (web > 80%)
| Missing Product | Opportunity | Confidence |
|-----------------|-------------|------------|
| Session Replay | $100-500 MRR | 80% |
| Error Tracking (web) | $100-400 MRR | 75% |
| Surveys | $50-200 MRR | 60% |

#### Mobile-Heavy (ios + android > 30% OR flutter > 20% OR react_native > 20%)
| Missing Product | Opportunity | Confidence |
|-----------------|-------------|------------|
| Mobile Replay | $200-4000 MRR | 85% |
| Error Tracking (mobile) | $200-800 MRR | 80% |

**Note:** Flutter/React Native often have HIGHER event volumes than native - check these first!

#### Backend-Heavy (node/python > 80%)
| Missing Product | Opportunity | Confidence |
|-----------------|-------------|------------|
| Error Tracking (backend) | $100-500 MRR | 75% |
| Feature Flags (local eval) | $200-800 MRR | 70% |

#### AI Company (ai_events > 0)
| Missing Product | Opportunity | Confidence |
|-----------------|-------------|------------|
| LLM Analytics expansion | $500-2000 MRR | 85% |
| Surveys (AI feedback) | $100-300 MRR | 60% |

#### B2B Company (Company_Type__c === "private" AND employees > 20)
| Missing Product | Opportunity | Confidence |
|-----------------|-------------|------------|
| Group Analytics | $300-1000 MRR | 80% |
| Teams addon ($450/mo) | $450 MRR | 75% |

### Priority 4: Usage Expansion
**Trigger:** Usage at 80%+ of billing limit

| Metric | Action |
|--------|--------|
| Near recording limit | Propose limit increase |
| Near FF request limit | Propose local evaluation |
| Near DW limit | Propose limit increase |

### Priority 5: Data Platform
**Trigger:** Using batch exports OR external schemas > 5

| Opportunity | Potential | Confidence |
|-------------|-----------|------------|
| Data Warehouse expansion | $200-1000 MRR | 65% |
| Additional destinations | $100-500 MRR | 55% |

## Risk Assessment

### Severity: HIGH 🔴

#### 1. Usage Declining
**Trigger:** `forecasted_mrr < mrr` (diff_dollars negative)

| Decline | Risk Level | Action |
|---------|------------|--------|
| >20% | Critical | Immediate outreach, investigate cause |
| 10-20% | High | Schedule call within 1 week |
| 5-10% | Medium | Monitor, send check-in email |

#### 2. Monthly at High MRR
**Trigger:** Monthly billing AND MRR > $5,000

| Risk | Impact |
|------|--------|
| Churn exposure | Full ARR at risk any month |
| No commitment | Easy to switch competitors |

**Action:** Priority annual conversion

#### 3. Payment Issues
**Trigger:** `stripe.delinquent === true` OR `accountBalance < -1000`

**Action:** Immediate escalation to billing team

### Severity: MEDIUM 🟡

#### 4. Low Health Score
**Trigger:** `healthScore < 6`

| Score | Risk Level |
|-------|------------|
| 4-6 | Medium - investigate |
| <4 | High - immediate action |

**Action:** Review engagement metrics, schedule check-in

#### 5. No Recent Activity
**Trigger:** `lastSeenTimestamp > 30 days ago`

**Action:** Outreach to re-engage, check for implementation issues

#### 6. Single Product Dependency
**Trigger:** One product > 50% of total MRR

| Risk | Mitigation |
|------|------------|
| If they stop that product, lose >50% | Cross-sell other products |

### Severity: LOW 🟢

#### 7. Support Ticket Volume
**Trigger:** `supportTickets > 5` in 30 days

**Action:** Review tickets for patterns, offer proactive help

#### 8. Single Point of Contact
**Trigger:** Only 1 admin user

| Risk | Action |
|------|--------|
| Champion leaves = relationship lost | Identify additional stakeholders |

## Risk Score Calculation

```javascript
function calculateRiskScore(account) {
  let score = 0;
  
  // Usage decline (0-40 points)
  if (account.diff_dollars < 0) {
    const declinePercent = Math.abs(account.diff_dollars / account.mrr);
    score += Math.min(declinePercent * 200, 40);
  }
  
  // Monthly billing (0-25 points)
  if (account.subscriptionInterval === 'month' && account.mrr > 3000) {
    score += 25;
  }
  
  // Health score (0-20 points)
  if (account.healthScore < 6) {
    score += (6 - account.healthScore) * 5;
  }
  
  // No activity (0-15 points)
  const daysSinceActive = daysSince(account.lastSeenTimestamp);
  if (daysSinceActive > 14) {
    score += Math.min(daysSinceActive - 14, 15);
  }
  
  return score; // 0-100, higher = more risk
}
```

## Opportunity Value Calculation

```javascript
function calculateOpportunityValue(opportunity) {
  const [minMrr, maxMrr] = opportunity.potentialMrr;
  const avgMrr = (minMrr + maxMrr) / 2;
  const confidence = opportunity.confidence / 100;
  
  return {
    expectedValue: avgMrr * confidence,
    annualizedValue: avgMrr * confidence * 12,
    priorityScore: avgMrr * confidence, // Higher = more urgent
  };
}
```

## Confidence Guidelines

| Confidence | Meaning |
|------------|---------|
| 90-95% | Fixed pricing, clear trigger (e.g., annual conversion) |
| 75-89% | Usage-based calculation, strong signal |
| 60-74% | Profile match, moderate signal |
| 40-59% | Speculative, early signal |
| <40% | Long shot, worth mentioning |
