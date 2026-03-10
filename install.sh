#!/usr/bin/env bash
# ==============================================================================
#  gsu — Git Switch User  installer
#  https://github.com/hetawk/gsu
#
#  One-line install:
#    curl -fsSL https://raw.githubusercontent.com/hetawk/gsu/main/install.sh | bash
#
#  Options (set as env vars before piping):
#    GSU_INSTALL_DIR   Default: ~/.local/bin
#    GSU_NO_SHELL_HOOK Set to 1 to skip adding PATH/alias to shell rc
#    GSU_NO_COMPLETIONS Set to 1 to skip installing shell completions
# ==============================================================================

set -uo pipefail

GSU_REPO="hetawk/gsu"
GSU_RAW_BASE="https://raw.githubusercontent.com/${GSU_REPO}/main"
GSU_INSTALL_DIR="${GSU_INSTALL_DIR:-$HOME/.local/bin}"
GSU_CONFIG_DIR="${GSU_CONFIG_DIR:-$HOME/.config/gsu}"
GSU_COMP_DIR_ZSH="${GSU_COMP_DIR_ZSH:-$HOME/.local/share/zsh/site-functions}"
GSU_COMP_DIR_BASH="${GSU_COMP_DIR_BASH:-$HOME/.bash_completion.d}"
GSU_COMP_DIR_FISH="${GSU_COMP_DIR_FISH:-$HOME/.config/fish/completions}"

# ── Colors ────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  BLUE='\033[0;34m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; DIM=''; NC=''
fi

ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
err()  { echo -e "${RED}  ✗${NC} $*" >&2; }
warn() { echo -e "${YELLOW}  !${NC} $*"; }
info() { echo -e "${BLUE}  →${NC} $*"; }
die()  { err "$*"; exit 1; }

# ── Detect HTTP fetcher ───────────────────────────────────────────────────────
if command -v curl &>/dev/null; then
  fetch() { curl -fsSL "$1" -o "$2"; }
  fetch_stdout() { curl -fsSL "$1"; }
elif command -v wget &>/dev/null; then
  fetch() { wget -qO "$2" "$1"; }
  fetch_stdout() { wget -qO- "$1"; }
else
  die "curl or wget is required to install gsu. Please install one and retry."
fi

# ── Detect current shell ──────────────────────────────────────────────────────
detect_shell() {
  local shell_name
  shell_name=$(basename "${SHELL:-/bin/bash}")
  echo "$shell_name"
}

get_rc_file() {
  local sh; sh=$(detect_shell)
  case "$sh" in
    zsh)  echo "$HOME/.zshrc" ;;
    bash) echo "$HOME/.bashrc" ;;
    fish) echo "$HOME/.config/fish/config.fish" ;;
    *)    echo "$HOME/.profile" ;;
  esac
}

# ── Check if string is already in a file ─────────────────────────────────────
_in_file() {
  grep -qF "$1" "$2" 2>/dev/null
}

# ── Main install ──────────────────────────────────────────────────────────────
main() {
  echo
  echo -e "${BOLD}  Installing gsu — Git Switch User${NC}"
  echo "  ────────────────────────────────────"
  echo

  # 1. Check git is installed
  command -v git &>/dev/null || die "git is required but not found. Install it and retry."
  ok "git found: $(git --version)"

  # 2. Create install directory
  mkdir -p "$GSU_INSTALL_DIR"
  ok "Install directory: $GSU_INSTALL_DIR"

  # 3. Download gsu binary
  info "Downloading gsu binary..."
  local tmp_bin; tmp_bin=$(mktemp)
  fetch "${GSU_RAW_BASE}/gsu" "$tmp_bin" || die "Failed to download gsu binary."
  chmod +x "$tmp_bin"

  # Verify it looks like the right file
  if ! grep -q 'GSU_VERSION=' "$tmp_bin"; then
    rm -f "$tmp_bin"
    die "Downloaded file does not look like a valid gsu binary."
  fi

  mv "$tmp_bin" "${GSU_INSTALL_DIR}/gsu"
  local version; version=$(grep '^GSU_VERSION=' "${GSU_INSTALL_DIR}/gsu" | tr -d '"' | cut -d'=' -f2)
  ok "gsu v${version} installed → ${GSU_INSTALL_DIR}/gsu"

  # 4. Create config directory
  mkdir -p "$GSU_CONFIG_DIR"
  ok "Config directory: $GSU_CONFIG_DIR"

  # 5. Shell integration
  if [[ "${GSU_NO_SHELL_HOOK:-0}" != "1" ]]; then
    local rc_file; rc_file=$(get_rc_file)
    local sh; sh=$(detect_shell)

    echo
    info "Setting up shell integration ($sh → $rc_file)..."

    # PATH
    local path_line='export PATH="$HOME/.local/bin:$PATH"'
    if _in_file "$GSU_INSTALL_DIR" "$rc_file"; then
      ok "$GSU_INSTALL_DIR already in PATH via $rc_file"
    else
      echo "" >> "$rc_file"
      echo "# gsu — Git Switch User" >> "$rc_file"
      echo "$path_line" >> "$rc_file"
      ok "Added PATH entry to $rc_file"
    fi

    # Aliases (skip for fish — fish uses functions)
    if [[ "$sh" != "fish" ]]; then
      local alias_marker="alias gsu="
      if _in_file "$alias_marker" "$rc_file"; then
        ok "gsu aliases already present in $rc_file"
      else
        cat >> "$rc_file" <<'ALIASES'
alias gsl='gsu list'
alias gss='gsu show'
ALIASES
        ok "Added convenience aliases (gsl, gss) to $rc_file"
      fi
    fi

    # Fish: add PATH via fish_user_paths
    if [[ "$sh" == "fish" ]]; then
      local fish_conf="$HOME/.config/fish/config.fish"
      mkdir -p "$(dirname "$fish_conf")"
      local fish_path_line="fish_add_path $GSU_INSTALL_DIR"
      if ! _in_file "$fish_path_line" "$fish_conf" 2>/dev/null; then
        echo "$fish_path_line" >> "$fish_conf"
        ok "Added $GSU_INSTALL_DIR to fish PATH"
      fi
    fi
  fi

  # 6. Install shell completions
  if [[ "${GSU_NO_COMPLETIONS:-0}" != "1" ]]; then
    local sh; sh=$(detect_shell)
    echo
    info "Installing shell completions..."

    case "$sh" in
      zsh)
        # Try Oh My Zsh completions dir first
        local zsh_comp_dir=""
        if [[ -d "$HOME/.oh-my-zsh/completions" ]]; then
          zsh_comp_dir="$HOME/.oh-my-zsh/completions"
        elif [[ -d "$HOME/.zsh/completions" ]]; then
          zsh_comp_dir="$HOME/.zsh/completions"
        else
          zsh_comp_dir="$GSU_COMP_DIR_ZSH"
          mkdir -p "$zsh_comp_dir"
        fi
        "${GSU_INSTALL_DIR}/gsu" completions zsh > "${zsh_comp_dir}/_gsu"
        ok "Zsh completions → ${zsh_comp_dir}/_gsu"

        # Ensure fpath includes the directory
        local rc_file; rc_file=$(get_rc_file)
        if ! _in_file "$zsh_comp_dir" "$rc_file" 2>/dev/null && [[ "$zsh_comp_dir" != "$HOME/.oh-my-zsh/completions" ]]; then
          echo "fpath=(\"$zsh_comp_dir\" \$fpath)" >> "$rc_file"
          echo "autoload -Uz compinit && compinit" >> "$rc_file"
          ok "Added fpath entry to $rc_file"
        fi
        ;;

      bash)
        mkdir -p "$GSU_COMP_DIR_BASH"
        "${GSU_INSTALL_DIR}/gsu" completions bash > "${GSU_COMP_DIR_BASH}/gsu"
        ok "Bash completions → ${GSU_COMP_DIR_BASH}/gsu"

        local rc_file; rc_file=$(get_rc_file)
        local source_line="[ -f \"${GSU_COMP_DIR_BASH}/gsu\" ] && source \"${GSU_COMP_DIR_BASH}/gsu\""
        if ! _in_file "${GSU_COMP_DIR_BASH}/gsu" "$rc_file" 2>/dev/null; then
          echo "$source_line" >> "$rc_file"
          ok "Added completion source to $rc_file"
        fi
        ;;

      fish)
        mkdir -p "$GSU_COMP_DIR_FISH"
        "${GSU_INSTALL_DIR}/gsu" completions fish > "${GSU_COMP_DIR_FISH}/gsu.fish"
        ok "Fish completions → ${GSU_COMP_DIR_FISH}/gsu.fish"
        ;;

      *)
        warn "Unknown shell '$sh'. Skipping completions. Install manually:"
        echo "  gsu completions [bash|zsh|fish]"
        ;;
    esac
  fi

  # 7. Migrate legacy config
  echo
  local old_users="$HOME/.config/git-users.conf"
  if [[ -f "$old_users" ]]; then
    info "Legacy git-users.conf detected."
    info "Run 'gsu' to auto-migrate your existing users on first use."
  fi

  # 8. Done
  echo
  echo -e "  ${GREEN}${BOLD}━━━ gsu installed successfully! ━━━${NC}"
  echo
  echo -e "  ${BOLD}Quick start:${NC}"
  echo "    Reload your shell:  source $(get_rc_file)"
  echo "    List users:         gsu list"
  echo "    Switch user:        gsu <key>"
  echo "    Add a user:         gsu add"
  echo "    Full help:          gsu help"
  echo
  if [[ "${GSU_NO_SHELL_HOOK:-0}" != "1" ]]; then
    warn "Restart your shell or run: source $(get_rc_file)"
  fi
  echo
}

main "$@"
