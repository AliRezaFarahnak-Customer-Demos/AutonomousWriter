# AutonomousWriter

> **Demo**: Copilot Coding Agent as an automatic documentation writer.

On every push to `main`, a GitHub Actions workflow creates an issue with the
code diff, assigns it to the Copilot Coding Agent via GraphQL, which then
documents the changes in [`docs/CHANGELOG.md`](docs/CHANGELOG.md) and opens a PR.

**Fully autonomous** — no human intervention after setup.

## Architecture

```
Developer pushes code to main
    ↓
GitHub Actions workflow triggers
    ↓
1. Stamps HelloDocumentationAgent.ps1 with version 1.0.0.<build#>
2. Commits the version bump [skip ci]
3. Uses COPILOT_PAT to create an issue with the diff via GraphQL
4. Assigns copilot-swe-agent[bot] with agentAssignment in the same call
    ↓
Copilot Coding Agent picks up the issue autonomously
    ↓
Reads the diff → appends to docs/CHANGELOG.md → opens a PR
```

## Authentication

| Secret | What it is | Why |
|---|---|---|
| `COPILOT_PAT` | Fine-grained PAT from a user with Copilot license | Required — the Copilot agent assignment API needs a user token with Copilot entitlement. GitHub App installation tokens cannot trigger the agent (see [Challenges](#challenges--what-we-learned)). |

### Why a PAT and not a GitHub App?

We extensively tested GitHub App installation tokens. They can:
- ✅ Create issues
- ✅ Manage Copilot agent settings (enable/disable repos)
- ❌ **Cannot** assign `copilot-swe-agent[bot]` — the GraphQL mutation checks the caller's **Copilot license**, and GitHub Apps don't have one

**Production recommendation**: Create a dedicated machine user (service account),
assign it a Copilot Business seat ($19/month), and use its PAT. This way the
token isn't tied to any individual developer.

## Setup Guide

### 1. Enable Copilot Coding Agent for the repo

```bash
# Check current status
gh api -H "X-GitHub-Api-Version: 2026-03-10" \
  /orgs/YOUR_ORG/copilot/coding-agent/permissions
# Should return: {"enabled_repositories":"all"}
```

### 2. Create a fine-grained PAT

Go to https://github.com/settings/personal-access-tokens/new

Permissions needed:
- **Metadata**: Read-only
- **Actions**: Read and write
- **Contents**: Read and write
- **Issues**: Read and write
- **Pull requests**: Read and write

### 3. Store as repo secret

```bash
gh secret set COPILOT_PAT --body "github_pat_XXXX"
```

### 4. Push code and watch it work

```bash
# Edit something
echo "# test" >> HelloDocumentationAgent.ps1
git add -A && git commit -m "test change" && git push
# Watch: Actions tab → issue created → Copilot documents → PR opened
```

## Challenges & What We Learned

This project systematically explored every possible way to trigger the Copilot
Coding Agent autonomously from a GitHub Actions workflow without a PAT.

### What we tried (and why it failed)

| Approach | Result | Error |
|---|---|---|
| `GITHUB_TOKEN` + REST assignees | ❌ 422 | `copilot` not a valid assignee |
| `gh api -f 'assignees[]=copilot-swe-agent[bot]'` | ❌ 422 | `[bot]` mangled as array syntax → sent `Copilot` |
| GitHub App + REST `POST /issues` | ❌ 422 | Can't assign copilot in creation |
| GitHub App + REST `POST /issues/{n}/assignees` | ❌ 403 | Forbidden (pre-permission acceptance) |
| GitHub App + REST `PATCH /issues/{n}` | ⚠️ 200 but agent rejects | "Token doesn't have necessary permissions" |
| GitHub App + GraphQL `suggestedActors` | ❌ Empty | Bot not visible to app tokens |
| GitHub App + GraphQL `createIssue` + `agentAssignment` | ❌ FORBIDDEN | "Copilot is not enabled in this repository" |
| GitHub App + GraphQL `addAssigneesToAssignable` | ❌ FORBIDDEN | Same as above |
| Hardcoded bot ID (`BOT_kgDOC9w8XQ`) | ❌ FORBIDDEN | Same — checks caller's Copilot license |
| gh-aw (Agentic Workflows) | ❌ Needs PAT | `COPILOT_GITHUB_TOKEN` must be a PAT |

### What works

| Approach | Result |
|---|---|
| **User PAT + GraphQL `createIssue` with `agentAssignment`** | ✅ Issue created, Copilot assigned, PR opened |

### Root cause

The Copilot Coding Agent assignment is not just an API permission — it's a
**license entitlement check**. GitHub's backend validates that the **caller**
has an active Copilot subscription. GitHub App installation tokens don't carry
license entitlements, so they always fail with "Copilot is not enabled."

### Key technical details

- Copilot bot global node ID: `BOT_kgDOC9w8XQ` (constant across all repos)
- Required API header: `GraphQL-Features: issues_copilot_assignment_api_support,coding_agent_model_selection`
- The Management API (`/orgs/{org}/copilot/coding-agent/permissions`) works with GitHub App tokens — but it only manages settings, not agent assignment
- The `copilot-swe-agent[bot]` name must be sent via JSON (not `-f` flags) to avoid `[bot]` being parsed as array syntax

## API References

- [Copilot Coding Agent Management API (2026-03-10)](https://docs.github.com/en/rest/copilot/copilot-coding-agent-management?apiVersion=2026-03-10)
- [Assigning issues to Copilot via API](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-a-pr#using-the-rest-api)
- [Installation Access Tokens](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-an-installation-access-token-for-a-github-app)

## Repository Structure

```
AutonomousWriter/
├── HelloDocumentationAgent.ps1       # Trivial script (version auto-stamped)
├── docs/
│   └── CHANGELOG.md                  # Copilot appends versioned entries here
├── .github/
│   ├── workflows/
│   │   └── auto-document.yml         # Workflow: stamp → create issue → assign copilot
│   └── copilot-instructions.md       # Architecture decision + agent rules
├── .gitignore
└── README.md
```

