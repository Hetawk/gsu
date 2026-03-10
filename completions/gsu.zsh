#compdef gsu

# gsu — Git Switch User — Zsh completion
# Install: gsu completions zsh > ~/.local/share/zsh/site-functions/_gsu
#          (or to ~/.oh-my-zsh/completions/_gsu for Oh My Zsh)

_gsu() {
  local -a commands users services
  commands=(
    'list:List all configured users'
    'ls:List all configured users (alias)'
    'use:Switch to a user'
    'add:Add a new user'
    'remove:Remove a user'
    'rm:Remove a user (alias)'
    'edit:Edit a user name/email'
    'show:Show current or named user'
    'whoami:Show current user (alias for show)'
    'token:Set or update a token for a service'
    'tokens:View and manage all tokens for a user'
    'token-remove:Remove a specific named token'
    'local:Set per-repo git identity'
    'local-clear:Remove per-repo identity override'
    'export:Export users to file (tokens masked)'
    'import:Import users from .conf file'
    'update:Update gsu to latest version'
    'version:Show current version'
    'completions:Print shell completion script'
    'help:Show help'
  )

  local user_keys
  user_keys=($(gsu _keys 2>/dev/null))
  services=(github gitlab bitbucket azure)

  case $CURRENT in
    2)
      _describe 'gsu command' commands
      _describe 'user key' user_keys
      ;;
    3)
      case ${words[2]} in
        use|show|remove|rm|edit|tokens|token|token-remove|local)
          compadd -a user_keys ;;
        completions)
          compadd bash zsh fish ;;
        export)
          _files ;;
        import)
          _files ;;
      esac
      ;;
    4)
      case ${words[2]} in
        token|token-remove)
          compadd -a services ;;
      esac
      ;;
  esac
}

_gsu "$@"
