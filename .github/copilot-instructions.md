# Architecture Decision: Copilot Coding Agent as Automatic Documenter

## Overview

This repo demonstrates triggering the **Copilot Coding Agent** from a GitHub
Actions workflow to automatically document code changes. On every push to `main`,
the workflow creates an issue assigned to `copilot-swe-agent[bot]`, which then
reads the diff, appends a versioned entry to `docs/CHANGELOG.md`, and opens a PR.

## Authentication: GitHub App (no PAT)

We use a **GitHub App** with installation access tokens — not a personal access
token. This is the production best practice because:

- **Not tied to any person** — survives employee turnover
- **Short-lived tokens** — auto-generated per workflow run, expire in 1 hour
- **Actions attributed to the app**, not a user
- **Scoped permissions** — only what the app needs

### How it works

1. The GitHub App's `APP_ID` and `APP_PRIVATE_KEY` are stored as repo secrets.
2. The workflow generates a JWT from the private key.
3. It calls `POST /app/installations/{id}/access_tokens` to mint a 1-hour token.
4. That token is used to create an issue and assign `copilot-swe-agent[bot]`.

### API References

- **Installation Access Tokens**:
  https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-an-installation-access-token-for-a-github-app

- **Copilot Coding Agent Management API** (`2026-03-10`):
  https://docs.github.com/en/rest/copilot/copilot-coding-agent-management?apiVersion=2026-03-10

- **Assigning issues to Copilot via REST API**:
  https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-a-pr#using-the-rest-api

### Key API details

**REST API — Create issue and assign to Copilot:**

```bash
gh api --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/OWNER/REPO/issues \
  --input - <<< '{
    "title": "Issue title",
    "body": "Issue description.",
    "assignees": ["copilot-swe-agent[bot]"],
    "agent_assignment": {
      "target_repo": "OWNER/REPO",
      "base_branch": "main",
      "custom_instructions": "",
      "custom_agent": "",
      "model": ""
    }
  }'
```

**GraphQL — Create issue and assign to Copilot:**
Requires header: `GraphQL-Features: issues_copilot_assignment_api_support,coding_agent_model_selection`

1. Query `suggestedActors(capabilities: [CAN_BE_ASSIGNED])` to get the bot ID (`copilot-swe-agent`).
2. Use `createIssue` mutation with `assigneeIds: ["BOT_ID"]` and `agentAssignment` input.

**Copilot Coding Agent Management API endpoints:**

- `GET  /orgs/{org}/copilot/coding-agent/permissions` — check enabled repos
- `PUT  /orgs/{org}/copilot/coding-agent/permissions` — set policy (all/selected/none)
- `GET  /orgs/{org}/copilot/coding-agent/permissions/repositories` — list enabled repos
- `PUT  /orgs/{org}/copilot/coding-agent/permissions/repositories` — replace selected repos
- `PUT  /orgs/{org}/copilot/coding-agent/permissions/repositories/{id}` — enable one repo
- `DELETE /orgs/{org}/copilot/coding-agent/permissions/repositories/{id}` — disable one repo

All require `X-GitHub-Api-Version: 2026-03-10`. Support GitHub App installation
access tokens with `"Copilot agent settings"` org permission.

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
