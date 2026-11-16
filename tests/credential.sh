#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

export GIT_CONFIG_GLOBAL="$TMP_DIR/gitconfig"
export GIT_CONFIG_NOSYSTEM=1
export GSU_CONFIG_DIR="$TMP_DIR/config"
mkdir -p "$GSU_CONFIG_DIR" "$TMP_DIR/bin"
cp "$SCRIPT_DIR/gsu" "$TMP_DIR/bin/gsu"
chmod +x "$TMP_DIR/bin/gsu"
cat > "$TMP_DIR/bin/gh" <<'GH'
#!/usr/bin/env bash
echo "No GitHub CLI account is authenticated." >&2
exit 1
GH
chmod +x "$TMP_DIR/bin/gh"
cat > "$TMP_DIR/fallback-helper" <<'HELPER'
#!/usr/bin/env bash
if [[ "${1:-}" == "get" ]]; then
  printf 'username=fallback-user\npassword=fallback-token\n\n'
fi
HELPER
chmod +x "$TMP_DIR/fallback-helper"
export PATH="$TMP_DIR/bin:$PATH"

cat > "$GSU_CONFIG_DIR/users.conf" <<'USERS'
alice|Alice Example|alice@example.com|work=github-work-token,personal=github-personal-token|personal=gitlab-token||personal=azure-token
USERS
chmod 600 "$GSU_CONFIG_DIR/users.conf"
printf 'alice\n' > "$GSU_CONFIG_DIR/current"

git config --global credential.helper "$TMP_DIR/fallback-helper"
git config --global --add credential.https://github.com.helper ""
git config --global --add credential.https://github.com.helper "$TMP_DIR/fallback-helper"
bash "$SCRIPT_DIR/gsu" credential install github >/dev/null

helpers=()
while IFS= read -r helper; do
  helpers+=("$helper")
done < <(git config --get-all credential.https://github.com.helper)
[[ "${#helpers[@]}" -eq 3 ]]
[[ -z "${helpers[0]}" ]]
[[ "${helpers[1]}" == "!gsu credential" ]]
[[ "${helpers[2]}" == *"fallback-helper" ]]

github_output="$(printf 'protocol=https\nhost=github.com\n\n' | git credential fill)"
[[ "$github_output" == *"username=x-access-token"* ]]
[[ "$github_output" == *"password=github-personal-token"* ]]
[[ "$github_output" != *"github-work-token"* ]]

printf '%s\n' 'bob|Bob Example|bob@example.com|work=bob-token|||' >> "$GSU_CONFIG_DIR/users.conf"
printf 'bob\n' > "$GSU_CONFIG_DIR/current"
bob_output="$(printf 'protocol=https\nhost=github.com\n\n' | bash "$SCRIPT_DIR/gsu" credential get)"
[[ "$bob_output" == *"password=bob-token"* ]]

printf 'not-configured\n' > "$GSU_CONFIG_DIR/current"
fallback_output="$(printf 'protocol=https\nhost=github.com\n\n' | git credential fill)"
[[ "$fallback_output" == *"password=fallback-token"* ]]

if ! use_output="$(bash "$SCRIPT_DIR/gsu" use alice 2>&1)"; then
  printf '%s\n' "$use_output" >&2
  echo "gsu use should succeed when a saved token can authenticate Git." >&2
  exit 1
fi
[[ "$(<"$GSU_CONFIG_DIR/current")" == "alice" ]]

gitlab_output="$(printf 'protocol=https\nhost=gitlab.com\n\n' | bash "$SCRIPT_DIR/gsu" credential get)"
[[ "$gitlab_output" == *"username=oauth2"* ]]
[[ "$gitlab_output" == *"password=gitlab-token"* ]]

gitlab_output="$(printf 'protocol=https\nhost=gitlab.com\n\n' | git credential fill)"
[[ "$gitlab_output" == *"username=oauth2"* ]]
[[ "$gitlab_output" == *"password=gitlab-token"* ]]

bash "$SCRIPT_DIR/gsu" token alice gitlab personal=gitlab-updated-token >/dev/null
gitlab_output="$(printf 'protocol=https\nhost=gitlab.com\n\n' | git credential fill)"
[[ "$gitlab_output" == *"password=gitlab-updated-token"* ]]

azure_output="$(printf 'protocol=https\nhost=dev.azure.com\n\n' | bash "$SCRIPT_DIR/gsu" credential get)"
[[ "$azure_output" == *"password=azure-token"* ]]

unsupported_output="$(printf 'protocol=https\nhost=example.com\n\n' | bash "$SCRIPT_DIR/gsu" credential get)"
[[ -z "$unsupported_output" ]]

http_output="$(printf 'protocol=http\nhost=github.com\n\n' | bash "$SCRIPT_DIR/gsu" credential get)"
[[ -z "$http_output" ]]

crlf_output="$(printf 'protocol=https\r\nhost=github.com\r\n\r\n' | bash "$SCRIPT_DIR/gsu" credential get)"
[[ "$crlf_output" == *"password=github-personal-token"* ]]

printf '✓ Credential helper tests passed\n'
