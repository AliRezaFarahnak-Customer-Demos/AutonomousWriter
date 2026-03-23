# Copilot Coding Agent as Automatic Documenter

## Overview

On every push to `main`, the workflow creates an issue assigned to
`copilot-swe-agent[bot]`, which documents the changes in `docs/CHANGELOG.md`
and opens a PR. Version format: `1.0.0.<GitHub Actions run_number>`.

## Authentication

Requires `COPILOT_PAT` — a fine-grained PAT from a user with a Copilot license.
GitHub App installation tokens cannot trigger the agent (the platform checks
the caller's Copilot license entitlement, not just API permissions).

For production, use a dedicated service account with its own Copilot seat
($19/month) so the token isn't tied to any individual.

### Copilot bot node ID

`BOT_kgDOC9w8XQ` — constant across all repos.

### Required GraphQL header

`GraphQL-Features: issues_copilot_assignment_api_support,coding_agent_model_selection`

## Agent Instructions

When assigned an issue titled "📝 Document changes for v…":

1. **Append only** — never delete or rewrite existing entries.
2. Add the new section at the **bottom** of `docs/CHANGELOG.md`.
3. Use the version number from the issue title.
4. Summarize the diff into concise bullets.
5. Use this template:

```markdown
## v{VERSION}

**Date:** {YYYY-MM-DD}
**Commit:** `{SHORT_SHA}`
**Author:** @{AUTHOR}

### Changes

- {change 1}
- {change 2}
```

6. Do **not** modify any file other than `docs/CHANGELOG.md`.
7. **Open a pull request** with the title `docs: changelog for v{VERSION}`.
