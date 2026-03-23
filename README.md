# AutonomousWriter

> **Demo**: Copilot Coding Agent as an automatic documentation writer,
> authenticated via a **GitHub App** (no PAT).

On every push to `main`, a GitHub Actions workflow stamps the version,
creates an issue assigned to `copilot-swe-agent[bot]`, and the Copilot
Coding Agent documents the changes in [`docs/CHANGELOG.md`](docs/CHANGELOG.md).

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
└── README.md
```

## How It Works

1. Developer pushes code to `main`
2. Workflow stamps `HelloDocumentationAgent.ps1` with `1.0.0.<build#>`
3. Workflow uses the **GitHub App** to mint a short-lived installation token
4. Creates an issue with the diff, assigns `copilot-swe-agent[bot]`
5. Copilot Coding Agent reads the issue → updates `docs/CHANGELOG.md` → opens a PR

## Authentication

Uses a **GitHub App** — not a PAT. See [`.github/copilot-instructions.md`](.github/copilot-instructions.md) for full details.

| Secret | What it is |
|--------|------------|
| `APP_ID` (variable) | The GitHub App's numeric ID |
| `APP_PRIVATE_KEY` (secret) | The App's PEM private key |

Tokens are **short-lived** (1 hour), **not tied to any person**, and
**scoped** to only the permissions the app needs.

## Prerequisites

1. A **GitHub App** installed on this repo with permissions: `Issues: Read & Write`, `Contents: Read & Write`
2. `APP_ID` set as a repo variable, `APP_PRIVATE_KEY` set as a repo secret
3. Copilot Coding Agent enabled for this repo

## Try It

1. Clone this repo
2. Edit `HelloDocumentationAgent.ps1`
3. Push to `main`
4. Watch Actions tab → issue created → Copilot documents the change → PR opened

