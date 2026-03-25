#!/usr/bin/env bash
set -euo pipefail

# ── confidence installer ─────────────────────────────────────────────

BOLD='\033[1m' DIM='\033[2m' GREEN='\033[32m' RED='\033[31m' YELLOW='\033[33m' CYAN='\033[36m' RESET='\033[0m'
info()  { echo -e "${CYAN}${BOLD}▸${RESET} $*"; }
ok()    { echo -e "${GREEN}${BOLD}✓${RESET} $*"; }
warn()  { echo -e "${YELLOW}${BOLD}⚠${RESET} $*"; }
err()   { echo -e "${RED}${BOLD}✗${RESET} $*"; }

INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="confidence"

# allow override: INSTALL_DIR=/custom/path ./install.sh
[[ -n "${1:-}" ]] && INSTALL_DIR="$1"

echo -e "${BOLD}confidence${RESET} installer"
echo ""

# ── check prerequisites ─────────────────────────────────────────────
missing=()
for cmd in claude codex jq; do
    if command -v "$cmd" &>/dev/null; then
        ok "$cmd found at $(which "$cmd")"
    else
        missing+=("$cmd")
        err "$cmd not found"
    fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
    echo ""
    warn "Missing dependencies: ${missing[*]}"
    echo -e "${DIM}Install them before using confidence:${RESET}"
    for cmd in "${missing[@]}"; do
        case "$cmd" in
            claude) echo "  Claude Code: npm install -g @anthropic-ai/claude-code" ;;
            codex)  echo "  Codex CLI:   npm install -g @openai/codex" ;;
            jq)     echo "  jq:          brew install jq  (or apt-get install jq)" ;;
        esac
    done
    echo ""
    echo -e "${DIM}Continuing with install anyway...${RESET}"
    echo ""
fi

# ── find the script ─────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="${SCRIPT_DIR}/${SCRIPT_NAME}"

if [[ ! -f "$SOURCE" ]]; then
    # running via curl pipe — download it
    info "Downloading confidence..."
    TMPFILE="$(mktemp)"
    curl -fsSL "https://raw.githubusercontent.com/cj-vana/confidence/main/confidence" -o "$TMPFILE"
    SOURCE="$TMPFILE"
fi

# ── install ──────────────────────────────────────────────────────────
info "Installing to ${INSTALL_DIR}/${SCRIPT_NAME}..."

if [[ -w "$INSTALL_DIR" ]]; then
    cp "$SOURCE" "${INSTALL_DIR}/${SCRIPT_NAME}"
    chmod +x "${INSTALL_DIR}/${SCRIPT_NAME}"
else
    warn "Need sudo to write to ${INSTALL_DIR}"
    sudo cp "$SOURCE" "${INSTALL_DIR}/${SCRIPT_NAME}"
    sudo chmod +x "${INSTALL_DIR}/${SCRIPT_NAME}"
fi

# clean up temp file if we downloaded
[[ -n "${TMPFILE:-}" ]] && rm -f "$TMPFILE"

echo ""
ok "Installed ${BOLD}confidence${RESET} to ${INSTALL_DIR}/${SCRIPT_NAME}"

# verify it's on PATH
if command -v confidence &>/dev/null; then
    ok "confidence is on your PATH"
else
    warn "${INSTALL_DIR} is not on your PATH"
    echo -e "  Add it: ${DIM}export PATH=\"${INSTALL_DIR}:\$PATH\"${RESET}"
fi

echo ""
echo -e "${DIM}Usage: confidence \"your prompt here\"${RESET}"
echo -e "${DIM}       confidence --help${RESET}"
