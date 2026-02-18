# PostHog skill format specification

This document defines the structure and conventions for PostHog skills.

## Directory structure

A skill is a directory containing at minimum a `SKILL.md` file:

```
my-skill/
├── SKILL.md              # Required: Skill instructions (agent-consumed)
├── README.md             # Optional: Human-readable documentation
├── references/           # Optional: Reference materials like docs
│   ├── docs.md
│   └── examples.md
├── scripts/              # Optional: Executable scripts
│   └── run.py
├── assets/               # Optional: Templates, configs, static files
└── my-skill.skill        # Optional: Packaged skill file (ZIP)
```

## SKILL.md

The `SKILL.md` file is the core of every skill. It is consumed by AI agents and defines what the skill does and how to use it.

### Frontmatter

Every `SKILL.md` must begin with YAML frontmatter containing at least `name` and `description`:

```yaml
---
name: my-skill
description: >
  A concise description of what this skill does and when to use it.
  This is used by agents to decide whether to activate the skill.
---
```

#### Required fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Unique skill identifier. Use kebab-case (e.g., `posthog-debugger`). |
| `description` | string | What the skill does and when to use it. Should help an agent decide if this skill is relevant. |

#### Optional fields

| Field | Type | Description |
|-------|------|-------------|
| `version` | string | Semantic version (e.g., `1.0.0`). |
| `tags` | string[] | Discovery tags (e.g., `["react", "nextjs", "integration"]`). |
| `author` | string | Skill author or team. |

### Body

The body of `SKILL.md` contains the skill's instructions in Markdown. This is the prompt content that teaches the agent how to execute the skill's workflow.

Best practices for the body:

- **Start with a summary** — one paragraph explaining the skill's purpose and target audience
- **Define critical rules** — non-negotiable behaviors (e.g., "always create as draft")
- **Describe the workflow** — step-by-step flow the agent should follow
- **Include examples** — show expected inputs/outputs where helpful
- **Reference files explicitly** — use relative paths to files in `references/` or `scripts/`

## References directory

The `references/` directory contains supporting materials the agent can read during skill execution:

- Documentation excerpts
- Code examples
- API references
- Configuration templates

Files should be Markdown (`.md`) for best agent consumption. Keep individual files focused — one topic per file.

## Scripts directory

The `scripts/` directory contains executable code the agent can run:

- Python scripts (`.py`) are preferred for portability
- Scripts should be self-contained with minimal dependencies
- Include a shebang line (`#!/usr/bin/env python3`)
- Scripts should handle errors gracefully and output clear messages

## Packaged skill files

A `.skill` file is a ZIP archive of the skill directory. It can be uploaded directly to Claude Projects or distributed as a single file.

## Naming conventions

- **Skill directories:** kebab-case (e.g., `posthog-survey-creator`)
- **Skill names (frontmatter):** match the directory name
- **Reference files:** descriptive kebab-case (e.g., `question-examples.md`)
- **Scripts:** descriptive kebab-case (e.g., `install-skill.py`)

## Skill tiers

Skills in the PostHog skills library are organized into tiers:

| Tier | Path | Description |
|------|------|-------------|
| **System** | `skills/.system/` | Meta-skills that operate on other skills (install, create, diagnose) |
| **PostHog** | `skills/posthog/` | Official PostHog skills, auto-generated from context-mill |
| **Team** | `skills/team/` | Hand-authored skills by the PostHog team |
| **Community** | `skills/community/` | Skills contributed by the community |

### Targeting the right tier

- **Auto-generated skills** go in `skills/posthog/{category}/` — these are managed by CI and should not be edited directly
- **PostHog team skills** go in `skills/team/` — submit via PR, reviewed by #team-docs-and-wizard
- **Community skills** go in `skills/community/` — submit via PR, reviewed by PostHog maintainers
