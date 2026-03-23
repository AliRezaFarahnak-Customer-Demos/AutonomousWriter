---
name: Auto-Document Changes
description: On every push, stamp the version and document code changes in docs/CHANGELOG.md
on:
  push:
    branches: [main]
    paths-ignore:
      - "docs/**"
      - "README.md"
  workflow_dispatch:

permissions:
  contents: read
  pull-requests: read

engine: copilot

safe-outputs:
  create-pull-request:
    title-prefix: "docs: "
    labels: [documentation]
    draft: false

tools:
  github:
    toolsets: [default]
  edit:
  bash:
    - "cat HelloDocumentationAgent.ps1"
    - "cat docs/CHANGELOG.md"
    - "git log --oneline -5"
    - "git diff HEAD~1 HEAD -- . ':!docs/'"
    - "grep -n 'Version' HelloDocumentationAgent.ps1"

timeout-minutes: 15
---

# Auto-Document Changes

You are a documentation agent for the AutonomousWriter repository.

## Your Task

1. Run `git diff HEAD~1 HEAD -- . ':!docs/'` to see what changed in the latest commit.
2. Run `grep -n 'Version' HelloDocumentationAgent.ps1` to get the current version number.
3. Read `docs/CHANGELOG.md` to see existing entries.
4. Append a new section at the **bottom** of `docs/CHANGELOG.md` with this format:

```markdown
## v{VERSION}

**Date:** {today's date YYYY-MM-DD}
**Commit:** `{short SHA from git log}`
**Author:** @{commit author}

### Changes

- {one-line summary of each meaningful change from the diff}
```

5. Do NOT delete or modify existing changelog entries — **append only**.
6. Do NOT modify any file other than `docs/CHANGELOG.md`.
7. Create a pull request with title `docs: changelog for v{VERSION}`.
8. If the diff is empty or only touches docs, exit without creating a PR.
