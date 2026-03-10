# gsu — Git Switch User — Fish completion
# Install: gsu completions fish > ~/.config/fish/completions/gsu.fish

function __gsu_users
    gsu _keys 2>/dev/null
end

function __gsu_no_subcommand
    set -l cmds list ls use add remove rm edit show whoami token tokens token-remove local local-clear export import update version completions help
    not __fish_seen_subcommand_from $cmds
end

# Disable file completions globally for gsu
complete -c gsu -f

# Direct user switch (when no subcommand seen)
complete -c gsu -n "__gsu_no_subcommand" -a "(__gsu_users)" -d "Switch to user"

# Subcommands
complete -c gsu -n "__gsu_no_subcommand" -a "list"         -d "List all users"
complete -c gsu -n "__gsu_no_subcommand" -a "ls"           -d "List all users"
complete -c gsu -n "__gsu_no_subcommand" -a "use"          -d "Switch to a user"
complete -c gsu -n "__gsu_no_subcommand" -a "add"          -d "Add a new user"
complete -c gsu -n "__gsu_no_subcommand" -a "remove"       -d "Remove a user"
complete -c gsu -n "__gsu_no_subcommand" -a "rm"           -d "Remove a user"
complete -c gsu -n "__gsu_no_subcommand" -a "edit"         -d "Edit user name/email"
complete -c gsu -n "__gsu_no_subcommand" -a "show"         -d "Show current/named user"
complete -c gsu -n "__gsu_no_subcommand" -a "whoami"       -d "Show current user"
complete -c gsu -n "__gsu_no_subcommand" -a "token"        -d "Set/update a token"
complete -c gsu -n "__gsu_no_subcommand" -a "tokens"       -d "Manage all tokens"
complete -c gsu -n "__gsu_no_subcommand" -a "token-remove" -d "Remove a token"
complete -c gsu -n "__gsu_no_subcommand" -a "local"        -d "Per-repo identity"
complete -c gsu -n "__gsu_no_subcommand" -a "local-clear"  -d "Clear per-repo identity"
complete -c gsu -n "__gsu_no_subcommand" -a "export"       -d "Export users (masked)"
complete -c gsu -n "__gsu_no_subcommand" -a "import"       -d "Import users from file"
complete -c gsu -n "__gsu_no_subcommand" -a "update"       -d "Update gsu"
complete -c gsu -n "__gsu_no_subcommand" -a "version"      -d "Show version"
complete -c gsu -n "__gsu_no_subcommand" -a "completions"  -d "Print completion script"
complete -c gsu -n "__gsu_no_subcommand" -a "help"         -d "Show help"

# User argument for subcommands that take a user key
for _gsu_cmd in use show remove rm edit tokens token token-remove local
    complete -c gsu -n "__fish_seen_subcommand_from $_gsu_cmd; and test (count (commandline -opc)) -eq 2" \
        -a "(__gsu_users)"
end

# Service argument for token/token-remove after user key
for _gsu_cmd in token token-remove
    complete -c gsu -n "__fish_seen_subcommand_from $_gsu_cmd; and test (count (commandline -opc)) -eq 3" \
        -a "github gitlab bitbucket azure"
end

# Shell argument for completions
complete -c gsu -n "__fish_seen_subcommand_from completions; and test (count (commandline -opc)) -eq 2" \
    -a "bash zsh fish"
