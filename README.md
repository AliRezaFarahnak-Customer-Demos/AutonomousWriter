# AutonomousWriter

Automatic changelog generation powered by the **Copilot Coding Agent**. Every code change pushed to `main` is autonomously documented in `docs/CHANGELOG.md` via a pull request — no human writes the changelog.

---

## Architecture

The system is a closed loop of four components that run end-to-end without human intervention:

```
┌──────────────┐      ┌───────────────────┐      ┌─────────────────────┐      ┌──────────────────┐
│  Developer   │ push │  GitHub Actions    │ issue│  Copilot Coding     │  PR  │  docs/CHANGELOG  │
│  pushes to   │─────▶│  Workflow          │─────▶│  Agent (bot)        │─────▶│  .md updated     │
│  main        │      │  auto-document.yml │      │  copilot-swe-agent  │      │  via pull request│
└──────────────┘      └───────────────────┘      └─────────────────────┘      └──────────────────┘
```

### Step-by-step flow

#### 1. Developer pushes code to `main`

Any commit to the `main` branch triggers the workflow — as long as the changed files are **not** in the ignore list (`docs/`, `.github/copilot-instructions.md`, `README.md`). This prevents the agent's own documentation PRs from re-triggering the loop.

#### 2. GitHub Actions workflow runs (`.github/workflows/auto-document.yml`)

The workflow:

1. **Checks out the repo** with `fetch-depth: 2` so it can diff the latest commit against its parent.
2. **Generates a diff** of the push (`git diff HEAD~1 HEAD`), excluding `docs/` and `.github/`, capped at 3,000 characters.
3. **Computes a version** string: `1.0.0.<run_number>` (the GitHub Actions build number auto-increments).
4. **Looks up the repository's GraphQL node ID** via the GitHub API.
5. **Creates a GitHub Issue** with:
   - Title: `📝 Document changes for v1.0.0.<run_number>`
   - Body: the version, commit SHA, author, and the diff
   - Assignee: the Copilot coding agent bot (`BOT_kgDOC9w8XQ`)
   - An `agentAssignment` block that tells the bot to target `main`, only modify `docs/CHANGELOG.md`, and open a pull request.

This step uses the **GitHub GraphQL API** with the feature flags `issues_copilot_assignment_api_support` and `coding_agent_model_selection`, authenticated via a fine-grained PAT (`COPILOT_PAT`).

#### 3. Copilot Coding Agent picks up the issue

GitHub's backend detects the agent assignment and dispatches the issue to `copilot-swe-agent[bot]`. The agent:

1. **Reads the issue body** to get the diff and version number.
2. **Reads `.github/copilot-instructions.md`** for formatting rules (append-only, use the changelog template, etc.).
3. **Appends a new entry** at the bottom of `docs/CHANGELOG.md` using this template:

   ```markdown
   ## v{VERSION}

   **Date:** {YYYY-MM-DD}
   **Commit:** `{SHORT_SHA}`
   **Author:** @{AUTHOR}

   ### Changes

   - {summarized change 1}
   - {summarized change 2}
   ```

4. **Opens a pull request** (e.g., `docs: changelog for v1.0.0.18`) from a feature branch back into `main`.

#### 4. Human reviews and merges the PR

The PR only touches `docs/CHANGELOG.md`. Because `docs/` is in `paths-ignore`, merging it does **not** re-trigger the workflow — the loop terminates cleanly.

---

## Key design decisions

| Decision                                                                      | Why                                                                                                                 |
| ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| **`paths-ignore` on `docs/`, `README.md`, `.github/copilot-instructions.md`** | Prevents infinite loops — the agent's own PRs don't re-trigger the workflow.                                        |
| **`fetch-depth: 2`**                                                          | Allows `git diff HEAD~1 HEAD` to compare the push against its parent commit.                                        |
| **Diff capped at 3,000 chars**                                                | Keeps the issue body within GitHub's limits and gives the agent a focused summary.                                  |
| **GraphQL `agentAssignment` mutation**                                        | The only way to programmatically assign the Copilot Coding Agent to an issue. REST API assignment is not supported. |
| **Bot node ID `BOT_kgDOC9w8XQ`**                                              | The global constant for the `copilot-swe-agent[bot]` across all GitHub repos.                                       |
| **Append-only changelog**                                                     | The agent never rewrites history — it only adds new entries at the bottom.                                          |

---

## Repository structure

```
├── .github/
│   ├── copilot-instructions.md   # Rules the agent follows (template, append-only, etc.)
│   └── workflows/
│       └── auto-document.yml     # The GitHub Actions workflow that triggers everything
├── docs/
│   └── CHANGELOG.md              # The auto-generated changelog (agent writes here)
├── HelloDocumentationAgent.ps1   # Sample script — any change here triggers documentation
└── README.md                     # This file
```

---

## Authentication

The workflow authenticates with a **fine-grained Personal Access Token** stored as the `COPILOT_PAT` repository secret.

**Required permissions:**

- `metadata` — read
- `actions` — read/write
- `contents` — read/write
- `issues` — read/write
- `pull-requests` — read/write

**Critical requirement:** The PAT must belong to a user with an active **GitHub Copilot license**. The agent assignment API checks the caller's Copilot entitlement — GitHub App installation tokens do not work.

---

## Setup

```bash
# 1. Enable Copilot Coding Agent for the repo (org settings → Copilot → Policies)

# 2. Create a fine-grained PAT with the permissions listed above

# 3. Store it as a repository secret
gh secret set COPILOT_PAT --body "github_pat_XXXX"

# 4. Push any code change to main and watch the Agents tab
```

---

## Production note

For teams, use a **dedicated service account** with its own Copilot seat ($19/month) instead of a personal PAT. This ensures the automation isn't tied to any individual and won't break if someone leaves the org.
