# confidence

Route prompts to whichever AI model is most confident it can solve them.

`confidence` sends your prompt to both **Claude Code** and **Codex CLI** in parallel, asks each to self-assess their confidence (0-100), then executes with the winner.

```
$ confidence "refactor auth.py to use async/await"

  Claude  88/100  (moderate)
  Reasoning: Strong match for refactoring tasks...
  Approach:  Convert synchronous handlers to async/await...

  Codex   72/100  (moderate)
  Reasoning: Can handle the refactor but may miss edge cases...
  Approach:  Identify blocking calls and convert to async...

✓ Winner: claude (88/100)

▸ Executing with Claude...
```

## How it works

1. **Confidence phase** — Both models receive a meta-prompt asking them to honestly rate their confidence on your task. They return structured JSON with a score, reasoning, approach, strengths, risks, and complexity estimate. This runs in parallel.
2. **Routing** — The model with the higher confidence score wins. Ties go to Claude.
3. **Execution** — Your original prompt is sent to the winner for actual execution.

All UI output goes to stderr. The model's response goes to stdout, so `confidence` is pipe-friendly.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — authenticated (`claude` CLI)
- [Codex CLI](https://github.com/openai/codex) — authenticated (`codex` CLI)
- [jq](https://jqlang.github.io/jq/) — JSON processing

## Installation

### Quick install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/cj-vana/confidence/main/install.sh | bash
```

### Manual install

```bash
git clone https://github.com/cj-vana/confidence.git
cd confidence
./install.sh
```

### Direct download

```bash
curl -fsSL https://raw.githubusercontent.com/cj-vana/confidence/main/confidence -o /usr/local/bin/confidence
chmod +x /usr/local/bin/confidence
```

### Uninstall

```bash
rm "$(which confidence)"
```

## Usage

```
confidence [options] <prompt>
echo "prompt" | confidence [options]
```

### Options

| Flag | Description |
|------|-------------|
| `-h, --help` | Show help |
| `-v, --verbose` | Show strengths and risks detail |
| `-n, --dry-run` | Show confidence scores but don't execute |
| `-s, --scores` | Show confidence scores before executing |
| `--force <claude\|codex>` | Skip confidence check, use this model directly |
| `--claude-model <model>` | Override Claude model (default: opus) |
| `--codex-model <model>` | Override Codex model (default: o3) |
| `--timeout <seconds>` | Execution timeout (default: 300) |
| `-C, --cd <dir>` | Working directory for execution |
| `--yolo` | Run Codex without sandbox restrictions |

### Examples

```bash
# Basic usage — let the models decide
confidence "add input validation to the signup form"

# See the reasoning before executing
confidence --verbose "migrate the database schema to support multi-tenancy"

# Score only, don't execute
confidence --dry-run "rewrite the test suite in pytest"

# Pipe a prompt
echo "explain the authentication flow in this codebase" | confidence

# Force a specific model
confidence --force claude "review this PR for security issues"
confidence --force codex "scaffold a new Express API"

# Use in a script — stdout is just the model's output
result=$(confidence "what is the capital of France")

# Dry run outputs machine-readable JSON to stdout
confidence --dry-run "complex task" | jq '.winner'

# Override models
confidence --claude-model sonnet --codex-model o4-mini "quick lint fix"

# Run Codex without sandbox
confidence --yolo "set up the entire project from scratch"
```

### Confidence scale

| Score | Meaning |
|-------|---------|
| 96-100 | Near-certain — exactly what the model is built for |
| 81-95 | Very confident — strong match |
| 61-80 | Confident — likely good result with minor gaps |
| 41-60 | Decent chance — notable uncertainty |
| 21-40 | Might succeed — significant gaps expected |
| 0-20 | Very unlikely to succeed |

## How routing tends to shake out

From testing, general patterns emerge:

- **Codex** tends to win on straightforward scripting, automation, file scaffolding, and "just do it" tasks
- **Claude** tends to win on reasoning-heavy architecture questions, nuanced refactoring, and tasks requiring deep context
- **Ties** are common on tasks both models handle well — Claude gets the tiebreaker

These aren't rules. The whole point is letting the models decide per-task.

## License

MIT
