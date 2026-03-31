# New Business Sales skills

## `.posthog-docs/`

A local copy of PostHog's public documentation, synced from the [posthog.com repo](https://github.com/PostHog/posthog.com). This gives skills direct access to docs content for looking up product details, pricing, feature capabilities, and validating URLs - without needing network access to posthog.com.

### Structure

- `contents/` - synced from `posthog.com/contents/` (docs, blog, handbook, etc.)
- `pages/` - synced from `posthog.com/src/pages/` (pricing, BAA generator, etc.)

### Initial setup

First, clone the PostHog website repo somewhere on your machine (if you haven't already):

```
cd ~
git clone https://github.com/PostHog/posthog.com.git
```

Then, from the `new-business-sales/` directory, run the sync:

```
rsync -av --delete ~/posthog.com/contents/ .posthog-docs/contents/ && \
rsync -av --delete ~/posthog.com/src/pages/ .posthog-docs/pages/
```

If you cloned the repo somewhere other than your home directory, replace `~/posthog.com` with wherever it lives (e.g. `~/src/posthog.com`).

### How to refresh

Run the same rsync command above whenever you want to pull in the latest docs. The `--delete` flag keeps the local copy clean by removing anything that's been deleted from the source.

### How skills use it

- **Pricing/feature lookups:** grep or read docs directly (e.g. BAA pricing, non-profit discounts, product capabilities)
- **URL validation:** verify that linked doc paths exist before including them in outreach emails (e.g. confirm `docs/feature-flags/start-here.mdx` exists before linking `posthog.com/docs/feature-flags/start-here`)
- **Accurate product info:** reference the actual docs content rather than relying on potentially outdated info baked into skill files
