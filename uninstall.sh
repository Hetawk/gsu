#!/usr/bin/env bash
# ==============================================================================
#  gsu — Git Switch User  uninstaller
#  https://github.com/hetawk/gsu
#
#  Usage:
#    curl -fsSL https://raw.githubusercontent.com/hetawk/gsu/main/uninstall.sh | bash
#    — or —
#    ./uninstall.sh
#
#  Options:
#    --purge   Also remove ~/.config/gsu/ (all users and config)
# ==============================================================================

set -uo pipefail

GSU_INSTALL_DIR="${GSU_INSTALL_DIR:-$HOME/.local/bin}"
GSU_CONFIG_DIR="${GSU_CONFIG_DIR:-$HOME/.config/gsu}"
PURGE=0

# Parse args
for arg in "$@"; do
  [[ "$arg" == "--purge" ]] && PURGE=1
done

# ── Colors ────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NC=''
fi

ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  !${NC} $*"; }
info() { echo -e "${BLUE}  →${NC} $*"; }
die()  { echo -e "${RED}  ✗${NC} $*" >&2; exit 1; }

echo
echo -e "${BOLD}  Uninstalling gsu — Git Switch User${NC}"
echo "  ──────────────────────────────────────"
echo

# 1. Remove binary
GSU_BIN="$GSU_INSTALL_DIR/gsu"
if [[ -f "$GSU_BIN" ]]; then
  rm -f "$GSU_BIN"
  ok "Removed binary: $GSU_BIN"
else
  warn "Binary not found at $GSU_BIN"
  # Try which
  local_bin=$(command -v gsu 2>/dev/null || echo "")
  if [[ -n "$local_bin" && "$local_bin" != "$GSU_BIN" ]]; then
    rm -f "$local_bin"
    ok "Removed binary: $local_bin"
  fi
fi

# 2. Remove shell completions
comp_zsh_omz="$HOME/.oh-my-zsh/completions/_gsu"
comp_zsh_local="$HOME/.local/share/zsh/site-functions/_gsu"
comp_zsh_dir="$HOME/.zsh/completions/_gsu"
comp_bash="$HOME/.bash_completion.d/gsu"
comp_fish="$HOME/.config/fish/completions/gsu.fish"

for comp in "$comp_zsh_omz" "$comp_zsh_local" "$comp_zsh_dir" "$comp_bash" "$comp_fish"; do
  if [[ -f "$comp" ]]; then
    rm -f "$comp"
    ok "Removed completion: $comp"
  fi
done

# 3. Config directory
if [[ "$PURGE" -eq 1 ]]; then
  if [[ -d "$GSU_CONFIG_DIR" ]]; then
    rm -rf "$GSU_CONFIG_DIR"
    ok "Removed config directory: $GSU_CONFIG_DIR"
  fi
else
  if [[ -d "$GSU_CONFIG_DIR" ]]; then
    warn "Config directory kept: $GSU_CONFIG_DIR"
    info "Run with --purge to also remove your user config and tokens."
  fi
fi

# 4. Shell RC cleanup note
echo
warn "Shell RC files (e.g. ~/.zshrc, ~/.bashrc) were NOT modified."
info "If you added gsu lines to your shell config, remove them manually:"
echo
echo "  Lines to look for and remove:"
echo "    export PATH=\"\$HOME/.local/bin:\$PATH\"  # (if only added for gsu)"
echo "    alias gsl='gsu list'"
echo "    alias gss='gsu show'"
echo "    source ~/.bash_completion.d/gsu"
echo "    fpath=(...zsh/site-functions...)"
echo

echo -e "  ${GREEN}${BOLD}gsu uninstalled.${NC}"
echo
