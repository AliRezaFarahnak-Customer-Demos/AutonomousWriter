# AutonomousWriter

> **Demo**: Copilot Coding Agent as an automatic documentation writer.

Every time a developer pushes code to `main`, a GitHub Actions workflow:

1. **Stamps** the PowerShell script with version `1.0.0.<build#>`
2. **Commits** the version bump
3. **Creates an issue** assigned to `copilot` with the diff context
4. **Copilot Coding Agent** picks up the issue, reads the diff, and appends a
   versioned changelog entry to [`docs/CHANGELOG.md`](docs/CHANGELOG.md)
5. The agent opens a **pull request** with the documentation update

## Repository Structure

```
AutonomousWriter/
├── HelloDocumentationAgent.ps1       # Trivial script (version auto-stamped by CI)
├── docs/
│   └── CHANGELOG.md                  # Copilot appends versioned entries here
├── .github/
│   ├── workflows/
│   │   └── auto-document.yml         # CI: stamp version → create issue for copilot
│   └── copilot-instructions.md       # Rules the coding agent follows
└── README.md                         # You are here
```

## How It Works

### The Workflow (`auto-document.yml`)

| Step | What happens |
|------|-------------|
| Checkout | Fetches the repo with 2 commits of history for diffing |
| Stamp version | Replaces `$Version` in the PS1 with `1.0.0.<run_number>` |
| Commit version bump | Pushes the stamped version (with `[skip ci]` to avoid loops) |
| Collect diff | Extracts the code diff (excluding docs/config) for context |
| Create issue | Opens an issue titled `📝 Document changes for v1.0.0.X` assigned to `copilot` |

### The Coding Agent

When the issue is assigned, Copilot Coding Agent:
- Reads the instructions in `.github/copilot-instructions.md`
- Parses the diff from the issue body
- Appends a new section to `docs/CHANGELOG.md`
- Opens a PR titled `docs: changelog for v1.0.0.X`

## Prerequisites

- **GitHub Copilot** plan with Coding Agent enabled
- Coding Agent must be enabled for this repository (org setting → `selected` or `all`)
- The `documentation` and `copilot-agent` labels should exist in the repo

## Try It

1. Clone this repo
2. Make any change to `HelloDocumentationAgent.ps1`
3. Push to `main`
4. Watch the Actions tab → an issue gets created → Copilot documents the change

## Version Scheme

```
1.0.0.<GitHub Actions run_number>
```

The build number increments automatically with each workflow run, tying every
changelog entry to a specific CI build.
