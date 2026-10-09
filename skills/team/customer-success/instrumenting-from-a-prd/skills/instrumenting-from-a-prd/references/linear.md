# Linear

## Connect

- Claude Code: `claude mcp add --transport http linear https://mcp.linear.app/mcp`
- Read-only access: use `https://mcp.linear.app/mcp/readonly` instead. The skill then prints every write for the user to paste.
- Claude app: turn on the Linear connector.

Linear's tool names change between versions. List the Linear tools that are available, and use the ones that read projects, documents, issues, comments and attachments, and that create issues and comments.

## Find the PRD

| The user gives | Read |
|---|---|
| A project URL | The project description, its documents, its issues and milestones |
| A document URL | That document, then its project |
| An issue URL | That issue, its sub-issues, then its project |

Teams keep a PRD in different places: the project description, a project document, or an issue description. If a project has several documents, use the one whose title says PRD, spec, brief or requirements. If two or more fit, ask which one.

Treat each issue in the project as a story. Record its identifier, for example `ENG-412`, because the plan and the code path both use it.

## Trace a story to code (engineers)

1. Read the issue's attachments. When the Linear GitHub integration is on, Linear attaches each pull request whose branch name or title contains the issue ID.
2. If attachments are not available, search git for the ID: `git log --all -i --grep '<ID>' --format='%h %s'` and `git branch -a | grep -i '<ID>'`.
3. If the `gh` CLI is available, also run `gh pr list --state all --search '<ID>'`.
4. If nothing matches, ask the engineer which files implement the story.

## Write back (after approval)

- **Analytics issue:** create one issue in the PRD's project and team. Title: "Analytics: <project name>". Body: the Analytics plan. Add an existing label such as "analytics" if the team has one. Do not create labels.
- **PM questions:** post them as one comment on the Analytics issue, and mention the PM. If the PRD names no PM, mention the project lead.
- **Do not edit** the PRD document or the project description. The PM owns them, and an agent edit to a PM's document is hard to review.
- Show the exact issue body and comment before each write, and wait for a yes.
