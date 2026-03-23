# AutonomousWriter

> **Demo**: Copilot Coding Agent as an automatic documentation writer.

On every push to `main`, a GitHub Actions workflow creates an issue with the
code diff, assigns it to the Copilot Coding Agent, which then documents the
changes in [`docs/CHANGELOG.md`](docs/CHANGELOG.md) and opens a PR.

## Architecture

```
Developer pushes code to main
    ↓
GitHub Actions workflow triggers
    ↓
1. Stamps HelloDocumentationAgent.ps1 with version 1.0.0.<build#>
2. Commits the version bump
3. Mints a short-lived GitHub App installation token (1 hour, scoped)
4. Creates an issue with the diff context
5. Assigns copilot-swe-agent[bot] via GraphQL API
    ↓
Copilot Coding Agent picks up the issue
    ↓
Reads the diff → updates docs/CHANGELOG.md → opens a PR
```

## Authentication: GitHub App (no PAT)

We use a **GitHub App** with installation access tokens. No personal access
token is involved.

| Secret/Variable | What it is | Where to set it |
|---|---|---|
| `APP_ID` (variable) | GitHub App numeric ID | Repo Settings → Variables |
| `APP_PRIVATE_KEY` (secret) | App's PEM private key | Repo Settings → Secrets |

### Why not a PAT?

- PATs are tied to a **person** — if they leave, the workflow breaks
- PATs grant broad access under a user's identity
- GitHub App tokens are **short-lived** (1 hour), **scoped**, and **not tied to any person**

## Setup Guide

### 1. Create a GitHub App

Go to `https://github.com/organizations/YOUR_ORG/settings/apps/new`:

- **Name**: `autonomous-writer-bot` (or any name)
- **Homepage URL**: your repo URL
- **Webhook**: uncheck Active (not needed)
- **Repository permissions**:
  - Actions: Read and write
  - Contents: Read and write
  - Issues: Read and write
  - Pull requests: Read and write
  - Metadata: Read-only (auto-selected)
- **Organization permissions**:
  - Copilot agent settings: Read and write
  - GitHub Copilot Business: Read and write
  - Members: Read and write
- **Where can this app be installed?**: Only on this account

### 2. Generate a private key

On the App settings page → Private keys → Generate a private key.
A `.pem` file will download.

### 3. Install the App on the repo

App settings → Install App → select your org → select this repository only.

**Important**: When permissions are updated, the org must accept them via
the email GitHub sends. Without acceptance, the app token won't carry
the new permissions.

### 4. Store secrets

```bash
# Set the App ID as a repo variable
gh variable set APP_ID --body "YOUR_APP_ID"

# Set the private key as a repo secret
gh secret set APP_PRIVATE_KEY < path/to/private-key.pem
```

### 5. Enable Copilot Coding Agent

Ensure the coding agent is enabled for the repo:
```bash
gh api -H "X-GitHub-Api-Version: 2026-03-10" \
  /orgs/YOUR_ORG/copilot/coding-agent/permissions
# Should return: {"enabled_repositories":"all"} or "selected" with this repo
```

## Challenges & Solutions

This project explored every possible way to trigger the Copilot Coding Agent
autonomously from a GitHub Actions workflow. Here's what we found:

### Challenge 1: `GITHUB_TOKEN` cannot assign copilot

The built-in `GITHUB_TOKEN` in GitHub Actions cannot assign
`copilot-swe-agent[bot]` to issues. The assignee is rejected as invalid.

### Challenge 2: `-f 'assignees[]=copilot-swe-agent[bot]'` gets mangled

The `gh api -f` flag interprets `[bot]` as array syntax, sending `Copilot`
instead of `copilot-swe-agent[bot]`. **Solution**: use `jq` to build JSON
and pipe via `--input`, or use GraphQL.

### Challenge 3: REST API `POST /issues` with assignees

Creating an issue with `copilot-swe-agent[bot]` in the `assignees` array
returns `422 Validation Failed` even with a GitHub App token.
**Solution**: create the issue first, then assign via a separate API call.

### Challenge 4: REST API `POST /issues/{number}/assignees` returns 403

The add-assignees endpoint returns `403 Forbidden` with a GitHub App token
before the installation accepts updated permissions.
**Solution**: ensure the org accepts the permission change email.

### Challenge 5: REST API `PATCH /issues/{number}` silently accepts but agent rejects

The PATCH endpoint returns `200` when updating assignees, but the Copilot
agent itself rejects the token, saying it doesn't have the necessary
permissions for actions, contents, issues, and pull requests.

### Challenge 6: GraphQL `suggestedActors` doesn't return copilot for app tokens

The `suggestedActors(capabilities: [CAN_BE_ASSIGNED])` query only returns
`copilot-swe-agent` when authenticated as a **user**. App installation tokens
don't see it. **Solution**: hardcode the bot's global node ID (`BOT_kgDOC9w8XQ`).

### Challenge 7: GraphQL mutations return "Copilot is not enabled in this repository"

Both `createIssue` and `addAssigneesToAssignable` with `agentAssignment`
return `FORBIDDEN: Copilot agent is not enabled in this repository` when
called with a GitHub App installation token — even though the Management API
confirms it IS enabled. This is because the mutations check the **caller's
Copilot entitlement**, and GitHub Apps don't have Copilot licenses.

### Challenge 8: gh-aw requires PAT

GitHub Agentic Workflows (gh-aw) requires `COPILOT_GITHUB_TOKEN` which
**must be a PAT** — GitHub Apps cannot be used for Copilot CLI engine auth.

### Current Status

The GraphQL `createIssue` mutation with `agentAssignment` using a GitHub App
installation token is the closest approach. The remaining blocker is that
GitHub's backend validates the caller's Copilot license — a platform limitation
that may be resolved in a future GitHub update.

## API References

- [Installation Access Tokens](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-an-installation-access-token-for-a-github-app)
- [Copilot Coding Agent Management API (2026-03-10)](https://docs.github.com/en/rest/copilot/copilot-coding-agent-management?apiVersion=2026-03-10)
- [Assigning issues to Copilot via API](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-a-pr#using-the-rest-api)
- [GitHub Agentic Workflows (gh-aw)](https://github.com/github/gh-aw)

## Repository Structure

```
AutonomousWriter/
├── HelloDocumentationAgent.ps1       # Trivial script (version auto-stamped)
├── docs/
│   └── CHANGELOG.md                  # Copilot appends versioned entries here
├── .github/
│   ├── workflows/
│   │   └── auto-document.yml         # Workflow: stamp → mint token → assign copilot
│   └── copilot-instructions.md       # Architecture decision + agent rules
├── .gitignore
└── README.md
```

