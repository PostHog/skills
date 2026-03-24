---
name: feature-flags-rust
description: PostHog feature flags for Rust applications
metadata:
  author: PostHog
  version: 1.9.4
---

# PostHog feature flags for Rust

This skill helps you add PostHog feature flags to Rust applications.

## Reference files

- `references/rust.md` - Rust feature flags installation - docs
- `references/adding-feature-flag-code.md` - Adding feature flag code - docs
- `references/best-practices.md` - Feature flag best practices - docs

Consult the documentation for API details and framework-specific patterns.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys. Never hardcode them.
- **Minimal changes**: Add feature flag code alongside existing logic. Don't replace or restructure existing code.
- **Boolean flags first**: Default to boolean flag checks unless the user specifically asks for multivariate flags.
- **Server-side when possible**: Prefer server-side flag evaluation to avoid UI flicker.

## PostHog MCP tools

Check if a PostHog MCP server is connected. If available, look for tools related to feature flag management (creating, listing, updating, deleting flags). Use these tools to manage flags directly in PostHog rather than requiring the user to do it manually in the dashboard.

## Framework guidelines

_No specific framework guidelines._
