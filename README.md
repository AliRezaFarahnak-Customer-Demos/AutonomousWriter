# AutonomousWriter

Automatic changelog generation powered by the **Copilot Coding Agent**.

Every time a developer pushes code to `main`, the Copilot Coding Agent
reads the diff, writes a versioned changelog entry in
[`docs/CHANGELOG.md`](docs/CHANGELOG.md), and opens a pull request — with
zero human intervention.

## How It Works

```
Developer pushes code
    ↓
GitHub Actions stamps the version → commits [skip ci]
    ↓
Creates a GitHub Issue with the diff via GraphQL
    ↓
Copilot Coding Agent is assigned automatically
    ↓
Agent reads the diff → appends to docs/CHANGELOG.md → opens a PR
```

The workflow uses the GraphQL `createIssue` mutation with `agentAssignment`
to create an issue and assign `copilot-swe-agent[bot]` in a single API call.
The agent follows the instructions in
[`.github/copilot-instructions.md`](.github/copilot-instructions.md) to produce
consistent, versioned documentation.

## Setup

### Prerequisites

- GitHub org with **Copilot Business** or **Enterprise**
- Copilot Coding Agent **enabled** for the repository
- A user (or service account) with a **Copilot license**

### 1. Enable Copilot Coding Agent

```bash
gh api -H "X-GitHub-Api-Version: 2026-03-10" \
  /orgs/YOUR_ORG/copilot/coding-agent/permissions
# Expected: {"enabled_repositories":"all"}
```

### 2. Create a fine-grained PAT

At https://github.com/settings/personal-access-tokens/new, create a token with:

| Permission | Access |
|---|---|
| Metadata | Read-only |
| Actions | Read and write |
| Contents | Read and write |
| Issues | Read and write |
| Pull requests | Read and write |

### 3. Store as a repo secret

```bash
gh secret set COPILOT_PAT --body "github_pat_XXXX"
```

### 4. Push and watch

```bash
git add -A && git commit -m "my change" && git push
```

The Actions tab will show the workflow running, an issue will be created, and
the Copilot Coding Agent will open a PR updating the changelog.

## Authentication

The Copilot Coding Agent assignment requires a **user token with a Copilot
license**. This is the only secret needed:

| Secret | Purpose |
|---|---|
| `COPILOT_PAT` | Fine-grained PAT — used to create the issue and assign the Copilot agent via GraphQL |

### Why a user token?

GitHub's Copilot Coding Agent performs a **license entitlement check** when
assigned to an issue. The platform validates that the caller has an active
Copilot subscription. This means:

- `GITHUB_TOKEN` (built into Actions) → cannot assign the agent
- GitHub App installation tokens → cannot assign the agent (apps don't hold Copilot licenses)
- User tokens (PAT or OAuth) → work, because they carry the user's Copilot entitlement

The **Copilot Coding Agent Management API** (for enabling/disabling repos)
does support GitHub App tokens — but **managing settings** and **triggering
the agent** are two separate operations with different auth requirements.

### Production recommendation: service account

For production and team use, create a dedicated **service account**:

1. Create a GitHub account with a shared team email (e.g., `docs-bot@contoso.com`)
2. Add it to the org and assign a **Copilot Business seat** ($19/month)
3. Grant it **write access** to the repos
4. Create a fine-grained PAT from that account
5. Store it as an org-level secret (`COPILOT_PAT`)

This pattern is widely used across organizations for CI/CD and bot automation.
The token is not tied to any individual developer, survives employee turnover,
and provides a clear audit trail.

## Technical Details

### GraphQL API

The workflow uses the `createIssue` GraphQL mutation with `agentAssignment`:

```graphql
mutation($title: String!, $body: String!, $repoId: ID!, $botId: ID!) {
  createIssue(input: {
    repositoryId: $repoId,
    title: $title,
    body: $body,
    assigneeIds: [$botId],
    agentAssignment: {
      targetRepositoryId: $repoId,
      baseRef: "main",
      customInstructions: "Only modify docs/CHANGELOG.md...",
      customAgent: "",
      model: ""
    }
  }) {
    issue { number title }
  }
}
```

Required header:
```
GraphQL-Features: issues_copilot_assignment_api_support,coding_agent_model_selection
```

Copilot bot global node ID: `BOT_kgDOC9w8XQ`

### Management API vs. Assignment API

| Operation | API | App token? | User token? |
|---|---|---|---|
| Enable/disable repos | `PUT /orgs/{org}/copilot/coding-agent/permissions` | ✅ | ✅ |
| Trigger agent (assign to issue) | GraphQL `createIssue` with `agentAssignment` | ❌ | ✅ |

## References

- [Copilot Coding Agent Management API](https://docs.github.com/en/rest/copilot/copilot-coding-agent-management?apiVersion=2026-03-10)
- [Assigning issues to Copilot via API](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-a-pr#using-the-rest-api)
- [About Copilot Coding Agent](https://docs.github.com/en/copilot/using-github-copilot/coding-agent/about-assigning-tasks-to-copilot)
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

