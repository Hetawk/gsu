# gsu — Git Switch User

> Switch between multiple Git identities instantly.  
> Works on macOS, Linux, and any system with Bash 3.2+.

---

## Features

- **One command to switch**: `gsu hetawk` — switch and clear cached credentials
- **Multi-service tokens**: GitHub, GitLab, Bitbucket, Azure DevOps
- **Per-repo identity**: `gsu local work` overrides global config for one repo
- **Tab completion**: Zsh, Bash, and Fish supported
- **Self-updating**: `gsu update` pulls the latest version from GitHub
- **Auto-migration**: detects and imports your existing `git-users.conf`
- **Portable**: single-file script, no dependencies beyond `bash` and `git`

---

## Install

### Platform support

- macOS: supported (zsh/bash)
- Linux: supported (bash/zsh/fish)
- Windows: supported via WSL or Git Bash

`gsu` is a Bash CLI, so the recommended universal installer is the raw `install.sh` script.

Package managers (Homebrew/Scoop/winget) are planned. Until then, use curl/wget or `make install`.

### One-line (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/hetawk/gsu/main/install.sh | bash
```

Or with `wget`:

```bash
wget -qO- https://raw.githubusercontent.com/hetawk/gsu/main/install.sh | bash
```

Windows (PowerShell + Git Bash):

```powershell
bash -lc "curl -fsSL https://raw.githubusercontent.com/hetawk/gsu/main/install.sh | bash"
```

Windows (WSL):

```bash
curl -fsSL https://raw.githubusercontent.com/hetawk/gsu/main/install.sh | bash
```

After install, reload your shell:

```bash
source ~/.zshrc    # zsh
source ~/.bashrc   # bash
```

### Manual install

```bash
# Download the binary
curl -fsSL https://raw.githubusercontent.com/hetawk/gsu/main/gsu \
  -o ~/.local/bin/gsu
chmod +x ~/.local/bin/gsu

# Make sure ~/.local/bin is in your PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
```

### From source (git clone)

```bash
git clone https://github.com/hetawk/gsu.git
cd gsu
make install               # installs to ~/.local/bin
make completions           # installs shell completions
```

---

## Quick Start

```bash
gsu list                   # see all configured users
gsu hetawk                 # switch to the 'hetawk' identity
gsu add                    # interactively add a new user
gsu help                   # full command reference
```

---

## Usage

### Switch identities

```bash
gsu hetawk                 # switch by key (shorthand)
gsu use hetawk             # same — explicit form
```

Switching:

1. Sets `git config --global user.name` and `user.email`
2. Clears cached credentials (GitHub, GitLab, Bitbucket, Azure)

### User management

```bash
gsu list                             # list all users
gsu show [key]                       # show current user, or details for <key>
gsu add                              # interactive add
gsu add ekd "Enoch Dongbo" me@email.com  # non-interactive add
gsu edit hetawk                      # change name or email
gsu remove hetawk                    # remove a user
```

### Token management

Tokens are optional. They're stored locally and can be used as reference or applied to your credential helper.

```bash
gsu token hetawk github              # set GitHub token (interactive)
gsu token hetawk github ghp_xxx      # set directly
gsu tokens hetawk                    # view/manage all tokens
gsu token-remove hetawk github work  # remove the 'work' label token
```

**Named tokens** — one user, multiple tokens:

```bash
# Label format:  label=token
gsu token hetawk github personal=ghp_token1
gsu token hetawk github work=ghp_token2
```

### Per-repo identity

Override the global identity for a specific project:

```bash
cd ~/projects/work-project
gsu local work                  # use 'work' user in this repo only
gsu local-clear                 # remove override, fall back to global
```

This sets `git config --local user.name/email` in `.git/config`.

### Import / Export

```bash
gsu export                          # print to stdout (tokens masked)
gsu export ~/gsu-backup.conf        # save to file
gsu import ~/gsu-backup.conf        # import users from file
```

> **Note:** exported files have token values masked (`****`). They are safe to commit or share. Re-add real tokens after import with `gsu token`.

### Self-update

```bash
gsu update                          # download latest version from GitHub
gsu version                         # show current version
gsu -v                              # short version flag
gsu --version                       # long version flag
```

### Shell completions

```bash
# Install completions for your shell:
gsu completions zsh  > ~/.local/share/zsh/site-functions/_gsu
gsu completions bash > ~/.bash_completion.d/gsu
gsu completions fish > ~/.config/fish/completions/gsu.fish
```

---

## Configuration

Config is stored in `~/.config/gsu/`:

```
~/.config/gsu/
├── users.conf      ← user profiles and tokens
└── current         ← active user key
```

### `users.conf` format

```
# KEY|NAME|EMAIL|GITHUB_TOKENS|GITLAB_TOKENS|BITBUCKET_TOKENS|AZURE_TOKENS
hetawk|Enoch Kwateh Dongbo|enoch@gmail.com|personal=ghp_xxx|||
work|Work Identity|me@work.com|personal=ghp_yyy,ci=ghp_zzz|||
```

> ⚠️ **Security:** tokens are stored in plain text.  
> Protect the file: `chmod 600 ~/.config/gsu/users.conf`  
> For production environments, prefer your system's credential manager (GCM, osxkeychain).

### Environment variables

| Variable          | Default         | Description                          |
| ----------------- | --------------- | ------------------------------------ |
| `GSU_CONFIG_DIR`  | `~/.config/gsu` | Config directory                     |
| `GSU_INSTALL_DIR` | `~/.local/bin`  | Binary install location              |
| `NO_COLOR`        | `0`             | Set to `1` to disable colored output |

---

## Migrating from the old system

If you used `git-switch-user` / `git-setup` previously, your data lives in:

```
~/.config/git-users.conf
~/.config/git-current-user
```

**gsu auto-detects and migrates these on first run.** Nothing to do manually.

---

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/hetawk/gsu/main/uninstall.sh | bash

# Also remove config and token data:
curl -fsSL https://raw.githubusercontent.com/hetawk/gsu/main/uninstall.sh | bash -s -- --purge
```

---

## Development

```bash
git clone https://github.com/hetawk/gsu.git
cd gsu
make install    # install locally for testing
make lint       # shellcheck (install via your OS package manager)
make test       # smoke tests
```

---

## License

MIT — see [LICENSE](LICENSE).
