#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_UNDER_TEST="$REPO_ROOT/install.sh"
TEST_ROOT="${TMPDIR:-/tmp}/ccnovaterm-mac-test-$$"
PASSED=0
FAILED=0

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

mkdir -p "$TEST_ROOT"

run_test() {
  local name="$1"
  shift
  echo ""
  echo "=== TEST: $name ==="
  if "$@"; then
    echo "  PASS: $name"
    PASSED=$((PASSED + 1))
  else
    echo "  FAIL: $name"
    FAILED=$((FAILED + 1))
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if ! grep -Fq "$needle" <<<"$haystack"; then
    echo "Expected output to contain: $needle"
    echo "Actual output:"
    echo "$haystack"
    return 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  if grep -Fq "$needle" <<<"$haystack"; then
    echo "Expected output not to contain: $needle"
    echo "Actual output:"
    echo "$haystack"
    return 1
  fi
}

assert_not_exists() {
  local path="$1"
  if [ -e "$path" ]; then
    echo "Expected path not to exist: $path"
    return 1
  fi
}

make_fake_bin() {
  local bin_dir="$1"
  mkdir -p "$bin_dir"
  cat > "$bin_dir/git" <<'EOF'
#!/usr/bin/env bash
echo "git version 2.0"
EOF
  cat > "$bin_dir/uname" <<'EOF'
#!/usr/bin/env bash
echo "${CCNOVATERM_FAKE_UNAME:-Darwin}"
EOF
  chmod +x "$bin_dir/git"
  chmod +x "$bin_dir/uname"
}

make_fake_cmd() {
  local bin_dir="$1"
  local cmd="$2"
  cat > "$bin_dir/$cmd" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$bin_dir/$cmd"
}

make_fake_local_cmd() {
  local home_dir="$1"
  local cmd="$2"
  mkdir -p "$home_dir/.local/bin"
  make_fake_cmd "$home_dir/.local/bin" "$cmd"
}

make_failing_local_ya() {
  local home_dir="$1"
  mkdir -p "$home_dir/.local/bin"
  cat > "$home_dir/.local/bin/ya" <<'EOF'
#!/usr/bin/env bash
echo "simulated ya failure" >&2
exit 1
EOF
  chmod +x "$home_dir/.local/bin/ya"
}

make_recording_local_ya() {
  local home_dir="$1"
  mkdir -p "$home_dir/.local/bin"
  cat > "$home_dir/.local/bin/ya" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$HOME/ya-args"
exit 0
EOF
  chmod +x "$home_dir/.local/bin/ya"
}

run_installer() {
  local home_dir="$1"
  local fake_bin="$2"
  shift 2
  HOME="$home_dir" PATH="$fake_bin:/usr/bin:/bin" OSTYPE="darwin23" bash "$SCRIPT_UNDER_TEST" "$@" 2>&1
}

test_rejects_non_macos() {
  local home_dir="$TEST_ROOT/non-macos-home"
  local fake_bin="$TEST_ROOT/non-macos-bin"
  mkdir -p "$home_dir"
  make_fake_bin "$fake_bin"

  set +e
  local output
  output=$(HOME="$home_dir" PATH="$fake_bin:/usr/bin:/bin" CCNOVATERM_FAKE_UNAME="Linux" bash "$SCRIPT_UNDER_TEST" --dry-run --no-font 2>&1)
  local status=$?
  set -e

  [ "$status" -eq 1 ] || {
    echo "Expected exit code 1, got $status"
    echo "$output"
    return 1
  }
  assert_contains "$output" "macOS only" || return 1
}

test_unknown_option_fails() {
  local home_dir="$TEST_ROOT/unknown-home"
  local fake_bin="$TEST_ROOT/unknown-bin"
  mkdir -p "$home_dir"
  make_fake_bin "$fake_bin"

  set +e
  local output
  output=$(run_installer "$home_dir" "$fake_bin" --not-a-real-option)
  local status=$?
  set -e

  [ "$status" -eq 1 ] || {
    echo "Expected exit code 1, got $status"
    echo "$output"
    return 1
  }
  assert_contains "$output" "Unknown option: --not-a-real-option" || return 1
  assert_contains "$output" "Usage: ./install.sh" || return 1
}

test_help_does_not_expose_with_yazi() {
  local home_dir="$TEST_ROOT/help-home"
  local fake_bin="$TEST_ROOT/help-bin"
  mkdir -p "$home_dir"
  make_fake_bin "$fake_bin"

  local output
  output=$(run_installer "$home_dir" "$fake_bin" --help)

  if grep -Fq -- "--with-yazi" <<<"$output"; then
    echo "Help should not expose --with-yazi"
    echo "$output"
    return 1
  fi
}

test_dry_run_plans_dependencies_without_writes() {
  local home_dir="$TEST_ROOT/dry-run-home"
  local fake_bin="$TEST_ROOT/dry-run-bin"
  mkdir -p "$home_dir"
  make_fake_bin "$fake_bin"

  local output
  output=$(run_installer "$home_dir" "$fake_bin" --dry-run)

  assert_not_contains "$output" "brew install node" || return 1
  assert_not_contains "$output" "brew install nushell" || return 1
  assert_contains "$output" "Would install Nushell from official GitHub release into:" || return 1
  assert_not_contains "$output" "brew install starship" || return 1
  assert_contains "$output" "Would install Starship with official installer into:" || return 1
  assert_not_contains "$output" "brew install yazi" || return 1
  assert_contains "$output" "Would install Yazi from official GitHub release into:" || return 1
  assert_contains "$output" "Would install Node.js from official release into:" || return 1
  assert_contains "$output" "Would install Yazi plugins from package.toml after Yazi is available: ya pkg install --discard" || return 1
  assert_contains "$output" "Would run: npm install -g --prefix" || return 1
  assert_contains "$output" "@anthropic-ai/claude-code" || return 1
  assert_contains "$output" "DRY RUN complete" || return 1
  assert_not_exists "$home_dir/.config" || return 1
  assert_not_exists "$home_dir/Library" || return 1
}

test_skip_deps_force_copies_configs() {
  local home_dir="$TEST_ROOT/skip-deps-home"
  local fake_bin="$TEST_ROOT/skip-deps-bin"
  mkdir -p "$home_dir"
  make_fake_bin "$fake_bin"

  local output
  output=$(run_installer "$home_dir" "$fake_bin" --skip-deps --force --no-font)

  assert_contains "$output" "Config files installed; required software is still missing" || return 1
  [ -f "$home_dir/.config/wezterm/wezterm.lua" ] || return 1
  [ -f "$home_dir/Library/Application Support/nushell/config.nu" ] || return 1
  grep -Fq "def --wrapped claude-dpv4" "$home_dir/Library/Application Support/nushell/config.nu" || return 1
  grep -Fq "CLAUDE_DPV4_ENV_SCRIPT" "$home_dir/Library/Application Support/nushell/config.nu" || return 1
  grep -Fq ".local/bin" "$home_dir/Library/Application Support/nushell/env.nu" || return 1
  [ -f "$home_dir/.config/yazi/package.toml" ] || return 1
}

test_success_summary_has_only_required_next_step() {
  local home_dir="$TEST_ROOT/success-home"
  local fake_bin="$TEST_ROOT/success-bin"
  mkdir -p "$home_dir/Library/Fonts"
  make_fake_bin "$fake_bin"

  local cmd
  for cmd in wezterm nu starship yazi ya node npm claude; do
    make_fake_cmd "$fake_bin" "$cmd"
  done
  touch "$home_dir/Library/Fonts/JetBrainsMonoNerdFont-Regular.ttf"

  local output
  output=$(run_installer "$home_dir" "$fake_bin" --force)

  assert_contains "$output" "Installation complete!" || return 1
  assert_contains "$output" "Next step:" || return 1
  assert_contains "$output" "Restart WezTerm" || return 1
  assert_not_contains "$output" "Verify font:" || return 1
  assert_not_contains "$output" "Configure proxy in:" || return 1
  assert_not_contains "$output" "Configure model/API key if needed" || return 1
  assert_contains "$output" "Optional configuration:" || return 1
}

test_wezterm_uses_absolute_nushell_path() {
  local home_dir="$TEST_ROOT/wezterm-nu-home"
  local fake_bin="$TEST_ROOT/wezterm-nu-bin"
  mkdir -p "$home_dir"
  make_fake_bin "$fake_bin"
  make_fake_local_cmd "$home_dir" "nu"

  local output
  output=$(run_installer "$home_dir" "$fake_bin" --skip-deps --force --no-font)

  assert_contains "$output" "Nushell path: $home_dir/.local/bin/nu" || return 1
  grep -Fq "config.default_prog = { '$home_dir/.local/bin/nu' }" "$home_dir/.config/wezterm/wezterm.lua" || {
    echo "Expected wezterm.lua to use absolute nu path"
    sed -n '1,12p' "$home_dir/.config/wezterm/wezterm.lua"
    return 1
  }
  if grep -Fq "config.default_prog = { 'nu' }" "$home_dir/.config/wezterm/wezterm.lua"; then
    echo "wezterm.lua should not rely on PATH for nu"
    sed -n '1,12p' "$home_dir/.config/wezterm/wezterm.lua"
    return 1
  fi
}

test_zshrc_exports_local_bin_path() {
  local home_dir="$TEST_ROOT/zsh-path-home"
  local fake_bin="$TEST_ROOT/zsh-path-bin"
  mkdir -p "$home_dir"
  make_fake_bin "$fake_bin"

  local output
  output=$(run_installer "$home_dir" "$fake_bin" --skip-deps --force --no-font)

  assert_contains "$output" "Added ~/.local/bin to zsh PATH" || return 1
  grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$home_dir/.zshrc" || {
    echo "Expected .zshrc to export ~/.local/bin"
    [ -f "$home_dir/.zshrc" ] && cat "$home_dir/.zshrc"
    return 1
  }
}

test_yazi_plugin_failure_reports_automatic_attempt() {
  local home_dir="$TEST_ROOT/yazi-plugin-fail-home"
  local fake_bin="$TEST_ROOT/yazi-plugin-fail-bin"
  mkdir -p "$home_dir/Library/Fonts"
  make_fake_bin "$fake_bin"

  local cmd
  for cmd in wezterm nu starship yazi node npm claude; do
    make_fake_cmd "$fake_bin" "$cmd"
  done
  make_failing_local_ya "$home_dir"
  touch "$home_dir/Library/Fonts/JetBrainsMonoNerdFont-Regular.ttf"

  local output
  output=$(run_installer "$home_dir" "$fake_bin" --force)

  assert_contains "$output" "Yazi plugin install was attempted automatically" || return 1
  assert_not_contains "$output" "Install Yazi plugins after Yazi is available" || return 1
}

test_yazi_plugin_install_discards_local_package_changes() {
  local home_dir="$TEST_ROOT/yazi-plugin-discard-home"
  local fake_bin="$TEST_ROOT/yazi-plugin-discard-bin"
  mkdir -p "$home_dir/Library/Fonts"
  make_fake_bin "$fake_bin"

  local cmd
  for cmd in wezterm nu starship yazi node npm claude; do
    make_fake_cmd "$fake_bin" "$cmd"
  done
  make_recording_local_ya "$home_dir"
  touch "$home_dir/Library/Fonts/JetBrainsMonoNerdFont-Regular.ttf"

  local output
  output=$(run_installer "$home_dir" "$fake_bin" --force)

  assert_contains "$output" "Yazi plugins installed from package.toml" || return 1
  grep -Fq "pkg install --discard" "$home_dir/ya-args" || {
    echo "Expected ya pkg install to use --discard"
    cat "$home_dir/ya-args"
    return 1
  }
}

run_test "rejects non-macOS hosts" test_rejects_non_macos
run_test "unknown option fails" test_unknown_option_fails
run_test "help does not expose with-yazi" test_help_does_not_expose_with_yazi
run_test "dry-run plans one-click dependencies without writes" test_dry_run_plans_dependencies_without_writes
run_test "skip-deps force copies configs only" test_skip_deps_force_copies_configs
run_test "success summary has only required next step" test_success_summary_has_only_required_next_step
run_test "wezterm uses absolute nushell path" test_wezterm_uses_absolute_nushell_path
run_test "zshrc exports local bin path" test_zshrc_exports_local_bin_path
run_test "yazi plugin failure reports automatic attempt" test_yazi_plugin_failure_reports_automatic_attempt
run_test "yazi plugin install discards local package changes" test_yazi_plugin_install_discards_local_package_changes

echo ""
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [ "$FAILED" -ne 0 ]; then
  exit 1
fi
