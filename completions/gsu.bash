# gsu — Git Switch User — Bash completion
# Install: gsu completions bash > ~/.bash_completion.d/gsu
#          Then add to ~/.bashrc:  source ~/.bash_completion.d/gsu

_gsu_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"
  local cmd="${COMP_WORDS[1]}"

  local all_cmds="list ls use add remove rm edit show whoami token tokens token-remove local local-clear export import update version completions help"
  local user_keys; user_keys=$(gsu _keys 2>/dev/null | tr '\n' ' ')
  local services="github gitlab bitbucket azure"

  COMPREPLY=()

  # Word 1 (right after 'gsu'): complete commands OR user keys
  if [[ $COMP_CWORD -eq 1 ]]; then
    COMPREPLY=($(compgen -W "$all_cmds $user_keys" -- "$cur"))
    return
  fi

  # Word 2: depends on prior command
  if [[ $COMP_CWORD -eq 2 ]]; then
    case "$cmd" in
      use|show|remove|rm|edit|tokens|token|token-remove|local)
        COMPREPLY=($(compgen -W "$user_keys" -- "$cur")) ;;
      completions)
        COMPREPLY=($(compgen -W "bash zsh fish" -- "$cur")) ;;
      export|import)
        COMPREPLY=($(compgen -f -- "$cur")) ;;
    esac
    return
  fi

  # Word 3: service after token/token-remove <user>
  if [[ $COMP_CWORD -eq 3 ]]; then
    case "$cmd" in
      token|token-remove)
        COMPREPLY=($(compgen -W "$services" -- "$cur")) ;;
    esac
    return
  fi
}

complete -F _gsu_completions gsu
