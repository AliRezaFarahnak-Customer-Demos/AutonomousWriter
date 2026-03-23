# AutonomousWriter

> **Demo**: Automatic documentation via [GitHub Agentic Workflows](https://github.com/github/gh-aw).

On every push to `main`, an AI agent reads the diff, and appends a versioned
changelog entry to [`docs/CHANGELOG.md`](docs/CHANGELOG.md), then opens a PR.

No PAT. No secrets. Just `GITHUB_TOKEN`.

## Repository Structure

```
AutonomousWriter/
├── HelloDocumentationAgent.ps1          # Trivial script
├── docs/
│   └── CHANGELOG.md                     # Agent appends entries here
├── .github/
│   └── workflows/
│       ├── auto-document.md             # Workflow spec (what the agent does)
│       └── auto-document.lock.yml       # Compiled Actions YAML (generated)
└── README.md
```

## How It Works

1. You push code to `main`
2. GitHub Actions runs the compiled workflow
3. The Copilot agent runs **inside** the action — reads the diff, reads the changelog
4. Appends a new versioned entry to `docs/CHANGELOG.md`
5. Opens a **pull request** via safe-outputs

## Prerequisites

- [gh-aw CLI](https://github.com/github/gh-aw) installed (`gh extension install github/gh-aw`)
- GitHub Copilot plan with Coding Agent enabled
- Coding Agent enabled for this repo

## Try It

1. Clone this repo
2. Edit `HelloDocumentationAgent.ps1`
3. Push to `main`
4. Watch the Actions tab → agent runs → PR with changelog update

