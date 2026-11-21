---
name: creating-product-tours
description: >-
  Build an in-app product tour that guides users through a feature inside the
  user's own application. Targeting via PostHog feature flags, tracking via
  PostHog events, custom reusable UI components. Use when a user asks to create
  a product tour, onboarding walkthrough, feature spotlight, or step-by-step
  guide in their app.
metadata:
  author: PostHog
  version: dev
---

# Building an in-app product tour with PostHog

Product tours use PostHog feature flags for targeting (who sees the tour and when) and PostHog events for tracking (completion, drop-off, step funnel). UI components should be custom-built but reusable across multiple tours.

**Local-dev behavior**: the tour renders locally even when PostHog isn't initialized (no project token, provider not mounted, ad blocker active). The feature flag infrastructure is still scaffolded for production rollout — it just isn't a hard gate in dev. This lets engineers iterate on the tour without needing a PostHog project wired up. See "Local development" below for how the fail-open works and how to opt out.

## Step 1: gather requirements

Ask the user these questions before writing any code:

1. **Goal** — What should the user be able to do after completing this tour? (e.g., "create their first dashboard", "connect a data source")
2. **Steps** — List all steps: what element should it point to, what does it say, how does the user advance? (e.g, "Step 1: Highlight the Create project button and ask the user to click it. Step 2: Highlight the SDK install command and explain how to copy it. Step 3: Highlight the dashboard page and prompt the user to create their first insight.")
3. **Audience** — Who sees it? All users, new users only, users on a specific plan, users who haven't done something yet?
4. **Trigger** — Auto-show on page load, trigger from a button, or chain from another tour?
5. **Show frequency** — Once ever, once per session, or every time the user visits?
6. **Tech stack** — React, Vue, vanilla JS? This determines component shape.

Do not proceed until you have goal, at least one step, and the tech stack.

## Step 2: create the feature flag

Create one feature flag per tour in PostHog. This controls targeting independently of the code.

Naming convention: `tour-<feature-area>-<what-it-teaches>` — e.g. `tour-dashboards-first-chart`, `tour-onboarding-data-source`.

Use the PostHog MCP tool or the PostHog UI (Flags → New feature flag):

- **Key**: `tour-<name>` (lowercase, hyphens)
- **Rollout**: set to the target audience using person/group properties or a percentage rollout
- **Enabled state**: Leave the feature flag disabled – the user enables it when ready.
- **Payload** (optional): store the step config as JSON so tours can be updated without deploys:

```json
{
  "steps": [
    {
      "target": "#new-dashboard-btn",
      "title": "Create a dashboard",
      "body": "Click here to start.",
      "placement": "bottom"
    },
    {
      "target": ".dashboard-name-input",
      "title": "Name your dashboard",
      "body": "Give it a memorable name.",
      "placement": "right"
    }
  ]
}
```

## Step 3: build reusable tour components

Build these once and reuse them for every tour. Do not create one-off components per tour. If not using react, adapt the strategy to what makes most sense for the platform.

### Core hook: `useTour`

```tsx
// hooks/useTour.ts
import { useEffect, useState, useCallback } from "react";
import posthog from "posthog-js";

export interface TourStep {
  target: string; // CSS selector for the anchor element
  title: string;
  body: string;
  placement?: "top" | "bottom" | "left" | "right";
}

interface UseTourOptions {
  flagKey: string;
  steps: TourStep[]; // inline step definitions — required so the tour renders without a PostHog payload
  storageKey?: string; // localStorage key to remember completion; defaults to `tour-${flagKey}`
  // When true, the flag check is enforced even if PostHog isn't initialized
  // (the tour won't render locally without PostHog wired up). Default false:
  // fail-open in dev so engineers can iterate without a project token.
  requireFlag?: boolean;
}

// posthog-js sets __loaded = true once init() succeeds. We use it to detect
// whether PostHog is actually wired up before treating its flag answer as truth.
function isPosthogReady(): boolean {
  return Boolean((posthog as unknown as { __loaded?: boolean }).__loaded);
}

export function useTour({
  flagKey,
  steps: staticSteps,
  storageKey,
  requireFlag = false,
}: UseTourOptions) {
  const key = storageKey ?? `tour-${flagKey}`;
  const [active, setActive] = useState(false);
  const [stepIndex, setStepIndex] = useState(0);
  const [steps, setSteps] = useState<TourStep[]>(staticSteps);

  useEffect(() => {
    if (localStorage.getItem(key) === "done") return;

    const ready = isPosthogReady();
    if (ready) {
      // Production path: PostHog is wired, the flag decides.
      const result = posthog.getFeatureFlagResult(flagKey);
      if (!result?.enabled) return;
      const payload = result.payload as {
        steps?: TourStep[];
      } | null;
      if (payload?.steps) setSteps(payload.steps);
    } else if (requireFlag) {
      // Strict mode: no PostHog, no tour.
      return;
    }
    // else: fail-open — render with the inline staticSteps so local dev works.

    setActive(true);
    posthog.capture("tour started", { tour_id: flagKey });
  }, [flagKey, key, requireFlag]);

  const advance = useCallback(() => {
    const next = stepIndex + 1;
    posthog.capture("tour step completed", {
      tour_id: flagKey,
      step: stepIndex,
    });
    if (next >= steps.length) {
      localStorage.setItem(key, "done");
      setActive(false);
      posthog.capture("tour completed", { tour_id: flagKey });
    } else {
      setStepIndex(next);
      posthog.capture("tour step viewed", { tour_id: flagKey, step: next });
    }
  }, [flagKey, key, stepIndex, steps.length]);

  const dismiss = useCallback(() => {
    localStorage.setItem(key, "done");
    setActive(false);
    posthog.capture("tour dismissed", { tour_id: flagKey, at_step: stepIndex });
  }, [flagKey, key, stepIndex]);

  return {
    active,
    step: steps[stepIndex] ?? null,
    stepIndex,
    totalSteps: steps.length,
    advance,
    dismiss,
  };
}
```

### Display component: `TourTooltip`

```tsx
// components/TourTooltip.tsx
import { useEffect, useRef, useState } from "react";
import type { TourStep } from "../hooks/useTour";

interface TourTooltipProps {
  step: TourStep;
  stepIndex: number;
  totalSteps: number;
  onNext: () => void;
  onDismiss: () => void;
}

export function TourTooltip({
  step,
  stepIndex,
  totalSteps,
  onNext,
  onDismiss,
}: TourTooltipProps) {
  const [position, setPosition] = useState({ top: 0, left: 0 });
  const tooltipRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const target = document.querySelector(step.target);
    if (!target || !tooltipRef.current) return;

    const rect = target.getBoundingClientRect();
    const tip = tooltipRef.current.getBoundingClientRect();
    const placement = step.placement ?? "bottom";

    const GAP = 12;
    const pos = {
      top:
        placement === "bottom"
          ? rect.bottom + GAP + window.scrollY
          : placement === "top"
            ? rect.top - tip.height - GAP + window.scrollY
            : rect.top + rect.height / 2 - tip.height / 2 + window.scrollY,
      left:
        placement === "left"
          ? rect.left - tip.width - GAP + window.scrollX
          : placement === "right"
            ? rect.right + GAP + window.scrollX
            : rect.left + rect.width / 2 - tip.width / 2 + window.scrollX,
    };
    setPosition(pos);

    // Highlight the target element
    target.setAttribute("data-tour-active", "true");
    return () => target.removeAttribute("data-tour-active");
  }, [step]);

  return (
    <div
      ref={tooltipRef}
      style={{
        position: "absolute",
        top: position.top,
        left: position.left,
        zIndex: 9999,
      }}
      className="tour-tooltip"
      role="dialog"
      aria-label={step.title}
    >
      <button
        onClick={onDismiss}
        aria-label="Close tour"
        className="tour-tooltip__close"
      >
        ✕
      </button>
      <h4 className="tour-tooltip__title">{step.title}</h4>
      <p className="tour-tooltip__body">{step.body}</p>
      <div className="tour-tooltip__footer">
        <span className="tour-tooltip__progress">
          {stepIndex + 1} / {totalSteps}
        </span>
        <button onClick={onNext} className="tour-tooltip__next">
          {stepIndex === totalSteps - 1 ? "Done" : "Next"}
        </button>
      </div>
    </div>
  );
}
```

### Minimal CSS (adapt to match the app's design system)

```css
/* tour.css */
.tour-tooltip {
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
  padding: 16px;
  min-width: 240px;
  max-width: 340px;
}
.tour-tooltip__close {
  position: absolute;
  top: 8px;
  right: 8px;
  background: none;
  border: none;
  cursor: pointer;
  color: #6b7280;
}
.tour-tooltip__title {
  margin: 0 0 8px;
  font-weight: 600;
  font-size: 14px;
}
.tour-tooltip__body {
  margin: 0 0 12px;
  font-size: 13px;
  color: #374151;
}
.tour-tooltip__footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.tour-tooltip__progress {
  font-size: 12px;
  color: #9ca3af;
}
.tour-tooltip__next {
  background: #f54e00;
  color: #fff;
  border: none;
  border-radius: 6px;
  padding: 6px 14px;
  cursor: pointer;
  font-size: 13px;
}
/* Highlight ring on the targeted element */
[data-tour-active="true"] {
  outline: 2px solid #f54e00;
  outline-offset: 3px;
  border-radius: 4px;
}
```

### Wiring it together

```tsx
// In the page or app root where the tour should run:
import { useTour, TourStep } from "../hooks/useTour";
import { TourTooltip } from "../components/TourTooltip";

// Inline steps are the source of truth in code so the tour renders even when
// PostHog isn't wired (local dev). In production, a flag payload can override these.
const DASHBOARDS_FIRST_CHART_STEPS: TourStep[] = [
  { target: "#new-dashboard-btn", title: "Create a dashboard", body: "Click here to start.", placement: "bottom" },
  { target: ".dashboard-name-input", title: "Name your dashboard", body: "Give it a memorable name.", placement: "right" },
];

export function DashboardPage() {
  const tour = useTour({
    flagKey: "tour-dashboards-first-chart",
    steps: DASHBOARDS_FIRST_CHART_STEPS,
  });

  return (
    <>
      {/* ... page content ... */}
      {tour.active && tour.step && (
        <TourTooltip
          step={tour.step}
          stepIndex={tour.stepIndex}
          totalSteps={tour.totalSteps}
          onNext={tour.advance}
          onDismiss={tour.dismiss}
        />
      )}
    </>
  );
}
```

## Local development

The `useTour` hook is designed to **fail-open when PostHog isn't initialized**. The decision tree on mount:

| PostHog state                          | Flag result   | Behavior                              |
| -------------------------------------- | ------------- | ------------------------------------- |
| Initialized (`posthog.__loaded`)       | `true`        | Show tour. Apply payload steps if present. |
| Initialized                            | `false`       | Hide tour.                            |
| Not initialized (no key, blocked, etc) | n/a           | **Show tour** using inline `staticSteps`. |
| Not initialized + `requireFlag: true`  | n/a           | Hide tour (strict mode).              |

Why: engineers should be able to build and demo a tour without wiring PostHog. The flag, payload, events, and targeting code are all in place — they just don't *gate* rendering during local dev. In production, where PostHog is initialized, the flag is fully respected.

To preview the disabled state locally:

- Set `requireFlag: true` on the hook call, **or**
- Wire PostHog locally and toggle the flag off in the PostHog UI

Note: `posthog.capture(...)` calls inside the hook are no-ops when PostHog isn't initialized, so they're safe to leave in.

## Adding a second tour

Reuse the same hook and component — only the flag key and steps change:

```tsx
const tour = useTour({
  flagKey: "tour-settings-integrations",
  steps: SETTINGS_INTEGRATIONS_STEPS,
});
```

No new components needed. If steps differ enough to need a different layout (e.g., a modal instead of a tooltip), create a second display component (`TourModal`) that accepts the same props shape as `TourTooltip`.

## Targeting patterns

| Goal                    | Flag setup                                                                                                                              |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| All new users           | Roll out 100%, set a person property `onboarding_tour_shown` via `posthog.people.set` after completion to suppress on re-identification |
| Paid plan only          | Filter by `plan = 'paid'` person property                                                                                               |
| After a specific action | Trigger `useTour` only after the user completes the prerequisite; the flag controls the audience, the trigger controls timing           |
| A/B test the tour       | Use a multivariate flag with variants `control` / `tour` and check `posthog.getFeatureFlag(key) === 'tour'`                             |

## Events to analyse

All events emitted by `useTour` above. Query in PostHog:

- Funnel: `tour started` → `tour step viewed (step 0..N)` → `tour completed` — shows drop-off per step
- `tour dismissed` with `at_step` property — shows where users give up
- Filter all by `tour_id` property to keep tours separate

## Checklist before shipping

- [ ] Feature flag created with correct rollout, but not enabled
- [ ] Inline `steps` array passed to `useTour` (so it renders without a PostHog payload)
- [ ] Tour renders locally without PostHog wired up (fail-open verified)
- [ ] Tour renders in production when flag is enabled; hidden when flag is disabled
- [ ] `target` selectors verified in the browser against real DOM nodes
- [ ] `localStorage` key chosen so it doesn't collide with other tours
- [ ] All four events captured in PostHog once wired: `started`, `step viewed`, `completed`, `dismissed`
- [ ] `TourTooltip` / `useTour` live in a shared location, not duplicated per feature
- [ ] User alerted that they should check rollout conditions and enable the flag when they want to see the tour in production
