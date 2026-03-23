# AutonomousWriter

Automatic changelog generation powered by the Copilot Coding Agent.

Push code to `main` → agent documents the changes in `docs/CHANGELOG.md` → opens a PR.

## How it works

1. Developer pushes to `main`
2. GitHub Actions creates an issue with the diff (version `1.0.0.<build#>`)
3. Copilot Coding Agent reads the diff, appends to the changelog, opens a PR

One secret: `COPILOT_PAT` — a fine-grained PAT from a user with a Copilot license.

## Setup

```bash
# 1. Enable Copilot Coding Agent for the repo (org settings)

# 2. Create a fine-grained PAT with: metadata(read), actions(rw), contents(rw), issues(rw), pull-requests(rw)

# 3. Store it
gh secret set COPILOT_PAT --body "github_pat_XXXX"

# 4. Push any change and watch the Agents tab
```

## Production note

For teams, use a **service account** with its own Copilot seat ($19/month)
instead of a personal PAT. The agent assignment API requires a user identity
with a Copilot license — GitHub App installation tokens cannot trigger it.

