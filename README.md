# Skills collection

A collection of PostHog skills for enhancing AI-assisted workflows.

**🚧 This repo is currently under construction by #team-docs-and-wizard👷**

----

## What are Skills?

Skills are modular packages that extend Claude's capabilities with specialized knowledge, workflows, and tool integrations. They transform Claude from a general-purpose assistant into a specialized agent for specific domains or tasks.

## Available Skills

| Skill | Description |
|-------|-------------|
| [PostHog Survey Creator](skills/posthog-survey-creator/) | Create surveys in PostHog through guided conversation. Includes 22 survey templates (NPS, CSAT, CES, PMF, etc.) and PostHog MCP integration. |

## Installation

### Option 1: Upload the .skill file

1. Navigate to the skill folder (e.g., `skills/posthog-survey-creator/`)
2. Download the `.skill` file
3. In Claude, go to your Project settings
4. Upload the skill file

### Option 2: Manual installation

1. Copy the skill folder to your skills directory
2. The skill will be available in Claude Projects

## Repository Structure

```
claude-skills/
├── README.md                    # This file
├── LICENSE                      # MIT License
└── skills/
    └── posthog-survey-creator/  # Individual skill folder
        ├── README.md            # Skill-specific documentation
        ├── SKILL.md             # Skill instructions (required)
        ├── references/          # Reference materials
        └── *.skill              # Packaged skill file
```

## Contributing

To add a new skill:

1. Create a new folder under `skills/`
2. Include at minimum:
   - `SKILL.md` with YAML frontmatter (`name` and `description`)
   - `README.md` documenting the skill
3. Optionally include:
   - `references/` for documentation Claude should reference
   - `scripts/` for executable code
   - `assets/` for templates and resources
   - A packaged `.skill` file

## License

MIT License - see [LICENSE](LICENSE) for details.
