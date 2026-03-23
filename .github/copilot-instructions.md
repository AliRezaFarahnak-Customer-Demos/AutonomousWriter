# Architecture Decision: Copilot Coding Agent as Automatic Documenter

## Overview

This repo demonstrates triggering the **Copilot Coding Agent** from a GitHub
Actions workflow to automatically document code changes. On every push to `main`,
the workflow creates an issue assigned to `copilot-swe-agent[bot]`, which then
reads the diff, appends a versioned entry to `docs/CHANGELOG.md`, and opens a PR.

## Authentication: User Token (PAT)

The Copilot Coding Agent assignment requires a **user token with a Copilot
license**. GitHub App installation tokens cannot trigger the agent — the
platform performs a license entitlement check on the caller.

The workflow uses a fine-grained PAT stored as `COPILOT_PAT` with permissions:
metadata (read), actions (read/write), contents (read/write), issues (read/write),
pull requests (read/write).

For production, use a **dedicated service account** with its own Copilot seat
($19/month) to avoid tying the automation to an individual developer.

### Key differences: Management API vs. Assignment API

| Operation | Token support |
|---|---|
| Enable/disable repos (`/orgs/{org}/copilot/coding-agent/permissions`) | GitHub App ✅, PAT ✅ |
| Assign agent to issue (GraphQL `createIssue` with `agentAssignment`) | GitHub App ❌, PAT ✅ |

### API References

- **Copilot Coding Agent Management API** (`2026-03-10`):
  https://docs.github.com/en/rest/copilot/copilot-coding-agent-management?apiVersion=2026-03-10

- **Assigning issues to Copilot via API**:
  https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-a-pr#using-the-rest-api

- **About Copilot Coding Agent**:
  https://docs.github.com/en/copilot/using-github-copilot/coding-agent/about-assigning-tasks-to-copilot

### Technical details

- Copilot bot global node ID: `BOT_kgDOC9w8XQ`
- Required GraphQL header: `GraphQL-Features: issues_copilot_assignment_api_support,coding_agent_model_selection`
- The `copilot-swe-agent[bot]` name must be sent via JSON or GraphQL variables — not `gh api -f` flags, which mangle `[bot]` as array syntax

## Agent Instructions

When assigned an issue titled "📝 Document changes for v…":

1. **Append only** — never delete or rewrite existing changelog entries.
2. Add the new version section at the **bottom** of `docs/CHANGELOG.md`.
3. Use the exact version number from the issue title.
4. Summarize the diff provided in the issue body into human-readable bullets.
5. Keep each bullet concise (one sentence).
6. Use this template:

```markdown
## v{VERSION}

**Date:** {YYYY-MM-DD}
**Commit:** `{SHORT_SHA}`
**Author:** @{AUTHOR}

### Changes

- {change 1}
- {change 2}
```

7. Do **not** modify any file other than `docs/CHANGELOG.md`.
8. Open a pull request with the title `docs: changelog for v{VERSION}`.
