#!/usr/bin/env bash
# ccNovaTerm — macOS installer
# https://github.com/shuiyu486/ccNovaTerm
set -euo pipefail

DRY_RUN=false
FORCE=false
NO_BACKUP=false
NO_FONT=false
SKIP_DEPS=false

usage() {
  echo "Usage: ./install.sh [--force] [--dry-run] [--no-backup] [--no-font] [--skip-deps]"
  echo "  --force      Skip ccNovaTerm confirmation prompts"
  echo "  --dry-run    Show what would happen without changing files"
  echo "  --no-backup  Do not back up existing config files"
  echo "  --no-font    Skip Nerd Font detection/installation"
  echo "  --skip-deps  Do not install missing dependencies"
}

for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=true ;;
    --force) FORCE=true ;;
    --no-backup) NO_BACKUP=true ;;
    --no-font) NO_FONT=true ;;
    --skip-deps) SKIP_DEPS=true ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      usage
      exit 1
      ;;
  esac
done

# Colors
CYA='\033[36m'; GRN='\033[32m'; YLW='\033[33m'; RED='\033[31m'; GRY='\033[90m'; RST='\033[0m'; BLD='\033[1m'

step()  { echo -e "\n${CYA}>> $*${RST}"; }
ok()    { echo -e "    ${GRN}[OK]${RST} $*"; }
warn()  { echo -e "    ${YLW}[!!]${RST} $*"; }
fail()  { echo -e "    ${RED}[X]${RST} $*"; }
info()  { echo -e "    ${GRY}..${RST} $*"; }

if [ "$(id -u)" -eq 0 ]; then
  fail "Do not run this installer with sudo."
  info "It installs user config files under your home directory."
  info "Run: ./install.sh"
  exit 1
fi

if [ "$(uname -s)" != "Darwin" ]; then
  fail "This installer is macOS only."
  info "Windows users should run: .\\install.ps1"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
HOME_DIR="$HOME"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="$HOME_DIR/ccNovaTerm-backup/$TIMESTAMP"

echo -e "${CYA}${BLD}  ccNovaTerm${RST}"
echo -e "${CYA}  Beautiful Terminal for Claude Code on macOS${RST}"
echo -e "${GRY}  WezTerm + Nushell + Starship + Yazi${RST}"

if $DRY_RUN; then
  echo -e "\n  ${YLW}*** DRY RUN mode - no files will be modified ***${RST}"
fi

# Check config directory exists
if [ ! -f "$CONFIG_DIR/.wezterm.lua" ]; then
  fail "Config directory not found: $CONFIG_DIR"
  info "Make sure you run this script from the cloned repo:"
  info "  git clone https://github.com/shuiyu486/ccNovaTerm.git"
  info "  cd ccNovaTerm && ./install.sh"
  exit 1
fi

# The install plan is confirmed after dependency detection, so the
# prompt can show exactly what will be installed.

# ============================================================
# Detect installed software
# ============================================================
check_cmd() { command -v "$1" &>/dev/null; }
check_wezterm() {
  check_cmd wezterm || \
    [ -d "/Applications/WezTerm.app" ] || \
    [ -d "$HOME_DIR/Applications/WezTerm.app" ]
}

append_word() {
  local words="$1"
  local word="$2"
  case " $words " in
    *" $word "*) printf '%s' "$words" ;;
    *) printf '%s %s' "$words" "$word" ;;
  esac
}

reset_missing_state() {
  missing=0
  missing_brew_casks=""
  missing_brew_formulae=""
  missing_npm_globals=""
  missing_manual_hints=""
}

missing=0
missing_brew_casks=""
missing_brew_formulae=""
missing_npm_globals=""
missing_manual_hints=""
FONT_MISSING=false
YAZI_PLUGIN_SKIPPED=false
YAZI_PLUGIN_FAILED=false
DEPENDENCY_INSTALL_FAILED=false
NUSHELL_MISSING=false
STARSHIP_MISSING=false
YAZI_MISSING=false
NODE_MISSING=false
LOCAL_BIN_DIR="$HOME_DIR/.local/bin"
STARSHIP_BIN_DIR="$LOCAL_BIN_DIR"
NUSHELL_BIN_DIR="$LOCAL_BIN_DIR"
YAZI_BIN_DIR="$LOCAL_BIN_DIR"
NODE_BIN_DIR="$LOCAL_BIN_DIR"
NODE_INSTALL_DIR="$HOME_DIR/.local/node"

ensure_local_bin_path() {
  case ":$PATH:" in
    *":$LOCAL_BIN_DIR:"*) ;;
    *) PATH="$LOCAL_BIN_DIR:$PATH"; export PATH ;;
  esac
}

ensure_zshrc_local_bin_path() {
  local zshrc="$HOME_DIR/.zshrc"
  local path_line='export PATH="$HOME/.local/bin:$PATH"'

  if [ -f "$zshrc" ] && { grep -Fq "$path_line" "$zshrc" || grep -Fq "$LOCAL_BIN_DIR" "$zshrc"; }; then
    ok "zsh PATH already includes ~/.local/bin"
    return
  fi

  if $DRY_RUN; then
    info "Would add ~/.local/bin to zsh PATH: $zshrc"
    return
  fi

  mkdir -p "$(dirname "$zshrc")"
  {
    if [ -s "$zshrc" ]; then
      printf '\n'
    fi
    printf '# Added by ccNovaTerm installer\n'
    printf '%s\n' "$path_line"
  } >> "$zshrc"
  ok "Added ~/.local/bin to zsh PATH: $zshrc"
}

ensure_local_bin_path

check_item() {
  local cmd="$1"
  local name="$2"
  local install_hint="$3"
  local install_kind="${4:-manual}"
  local install_package="${5:-}"

  if check_cmd "$cmd"; then
    ok "$name"
  else
    fail "$name -- not found. Install: $install_hint"
    missing=$((missing + 1))
    case "$install_kind" in
      brew-cask) missing_brew_casks="${missing_brew_casks} ${install_package}" ;;
      brew) missing_brew_formulae="${missing_brew_formulae} ${install_package}" ;;
      npm) missing_npm_globals="${missing_npm_globals} ${install_package}" ;;
      manual) missing_manual_hints="${missing_manual_hints}
      ${install_hint}" ;;
    esac
  fi
}

check_starship() {
  check_cmd starship || [ -x "$STARSHIP_BIN_DIR/starship" ]
}

check_nushell() {
  check_cmd nu || [ -x "$NUSHELL_BIN_DIR/nu" ]
}

check_yazi() {
  { check_cmd yazi || [ -x "$YAZI_BIN_DIR/yazi" ]; } && \
    { check_cmd ya || [ -x "$YAZI_BIN_DIR/ya" ]; }
}

check_node() {
  { check_cmd node || [ -x "$NODE_BIN_DIR/node" ]; } && \
    { check_cmd npm || [ -x "$NODE_BIN_DIR/npm" ]; }
}

font_installed() {
  [ -f "$HOME_DIR/Library/Fonts/JetBrainsMonoNerdFont-Regular.ttf" ] || \
    [ -f "$HOME_DIR/Library/Fonts/JetBrains Mono Nerd Font Complete.ttf" ] || \
    [ -f "/Library/Fonts/JetBrainsMonoNerdFont-Regular.ttf" ]
}

detect_font_status() {
  FONT_MISSING=false
  if $NO_FONT; then
    return
  fi

  step "${1:-Checking Nerd Font}"
  if font_installed; then
    ok "JetBrainsMono Nerd Font installed"
  else
    FONT_MISSING=true
    warn "JetBrainsMono Nerd Font not installed"
    info "Install via brew: brew install --cask font-jetbrains-mono-nerd-font"
    info "Or download from: https://www.nerdfonts.com/font-downloads"
  fi
}

detect_software() {
  reset_missing_state
  step "${1:-Checking installed software}"

  if check_wezterm; then
    ok "WezTerm"
  else
    check_item "wezterm" "WezTerm" "brew install --cask wezterm" "brew-cask" "wezterm"
  fi

  if check_nushell; then
    ok "Nushell"
    NUSHELL_MISSING=false
  else
    fail "Nushell -- not found. Install: https://github.com/nushell/nushell/releases"
    missing=$((missing + 1))
    NUSHELL_MISSING=true
  fi
  if check_starship; then
    ok "Starship"
    STARSHIP_MISSING=false
  else
    fail "Starship -- not found. Install: https://starship.rs/install.sh"
    missing=$((missing + 1))
    STARSHIP_MISSING=true
  fi
  if check_yazi; then
    ok "Yazi"
    YAZI_MISSING=false
  else
    fail "Yazi -- not found. Install: https://github.com/sxyazi/yazi/releases"
    missing=$((missing + 1))
    YAZI_MISSING=true
  fi
  if check_node; then
    ok "Node.js/npm"
    NODE_MISSING=false
  else
    fail "Node.js/npm -- not found. Install: https://nodejs.org"
    missing=$((missing + 1))
    NODE_MISSING=true
  fi
  check_item "claude"    "Claude Code" "npm install -g --prefix \"$HOME_DIR/.local\" @anthropic-ai/claude-code" "npm"       "@anthropic-ai/claude-code"
  check_item "git"       "Git"         "xcode-select --install"                  "manual"    ""
}

planned_brew_casks() {
  local casks="$missing_brew_casks"
  if ! $NO_FONT && $FONT_MISSING; then
    casks=$(append_word "$casks" "font-jetbrains-mono-nerd-font")
  fi
  printf '%s' "$casks"
}

planned_brew_formulae() {
  local formulae="$missing_brew_formulae"
  printf '%s' "$formulae"
}

has_installable_dependencies() {
  local casks formulae
  casks=$(planned_brew_casks)
  formulae=$(planned_brew_formulae)
  [ -n "$casks$formulae$missing_npm_globals" ] || $NUSHELL_MISSING || $STARSHIP_MISSING || $YAZI_MISSING || $NODE_MISSING
}

print_missing_install_commands() {
  local brew_casks brew_formulae
  brew_casks=$(planned_brew_casks)
  brew_formulae=$(planned_brew_formulae)

  if [ -n "$brew_casks$brew_formulae" ]; then
    if check_cmd brew; then
      info "Install missing Homebrew packages:"
      if [ -n "$brew_casks" ]; then
        info "  brew install --cask${brew_casks}"
      fi
      if [ -n "$brew_formulae" ]; then
        info "  brew install${brew_formulae}"
      fi
    else
      warn "Homebrew not found. Install Homebrew first: https://brew.sh"
      if [ -n "$brew_casks" ]; then
        info "Then run: brew install --cask${brew_casks}"
      fi
      if [ -n "$brew_formulae" ]; then
        info "Then run: brew install${brew_formulae}"
      fi
    fi
  fi

  if $NODE_MISSING; then
    info "Install Node.js from official release into: $NODE_BIN_DIR"
  fi

  if [ -n "$missing_npm_globals" ]; then
    info "Install missing npm package(s):"
    info "  npm install -g --prefix \"$HOME_DIR/.local\"${missing_npm_globals}"
  fi

  if $NUSHELL_MISSING; then
    info "Install Nushell from official GitHub release into: $NUSHELL_BIN_DIR"
  fi

  if $STARSHIP_MISSING; then
    info "Install Starship with official installer:"
    info "  curl -sS https://starship.rs/install.sh | sh -s -- -y -b \"$STARSHIP_BIN_DIR\""
  fi

  if $YAZI_MISSING; then
    info "Install Yazi from official GitHub release into: $YAZI_BIN_DIR"
  fi

  if [ -n "$missing_manual_hints" ]; then
    info "Other required setup:${missing_manual_hints}"
  fi
}

load_homebrew_path() {
  if check_cmd brew; then
    eval "$(brew shellenv)" 2>/dev/null || true
    return 0
  fi

  local brew_bin
  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$brew_bin" ]; then
      eval "$("$brew_bin" shellenv)"
      return 0
    fi
  done

  return 1
}

refresh_shell_paths() {
  load_homebrew_path || true
  ensure_local_bin_path
  hash -r 2>/dev/null || true
}

node_target_triple() {
  case "$(uname -m)" in
    arm64|aarch64) printf '%s' "darwin-arm64" ;;
    x86_64) printf '%s' "darwin-x64" ;;
    *) return 1 ;;
  esac
}

node_latest_lts_version() {
  curl -fsSL https://nodejs.org/dist/index.json | \
    tr '{' '\n' | \
    awk -F'"' '/"version"/ && /"lts"[[:space:]]*:[[:space:]]*"/ { for (i = 1; i <= NF; i++) if ($i == "version") { print $(i + 2); exit } }'
}

install_node_release() {
  if $DRY_RUN; then
    info "Would install Node.js from official release into: $NODE_BIN_DIR"
    return 0
  fi

  if ! check_cmd curl; then
    fail "curl not found. Install Node.js manually from https://nodejs.org"
    return 1
  fi

  local target version url tmpdir archive extract_dir
  target=$(node_target_triple) || {
    fail "Unsupported macOS architecture for Node.js: $(uname -m)"
    return 1
  }
  version=$(node_latest_lts_version || true)
  if [ -z "$version" ]; then
    fail "Could not find latest Node.js LTS release"
    return 1
  fi

  url="https://nodejs.org/dist/$version/node-$version-$target.tar.gz"
  tmpdir=$(mktemp -d)
  archive="$tmpdir/node.tar.gz"
  if ! curl -fL "$url" -o "$archive"; then
    rm -rf "$tmpdir"
    fail "Failed to download Node.js release: $url"
    return 1
  fi

  if ! tar -xzf "$archive" -C "$tmpdir"; then
    rm -rf "$tmpdir"
    fail "Failed to extract Node.js release"
    return 1
  fi

  extract_dir="$tmpdir/node-$version-$target"
  if [ ! -x "$extract_dir/bin/node" ] || [ ! -x "$extract_dir/bin/npm" ]; then
    rm -rf "$tmpdir"
    fail "Node.js release did not contain node and npm"
    return 1
  fi

  mkdir -p "$NODE_BIN_DIR" "$(dirname "$NODE_INSTALL_DIR")"
  rm -rf "$NODE_INSTALL_DIR"
  mv "$extract_dir" "$NODE_INSTALL_DIR"
  ln -sfn "$NODE_INSTALL_DIR/bin/node" "$NODE_BIN_DIR/node"
  ln -sfn "$NODE_INSTALL_DIR/bin/npm" "$NODE_BIN_DIR/npm"
  if [ -e "$NODE_INSTALL_DIR/bin/npx" ]; then
    ln -sfn "$NODE_INSTALL_DIR/bin/npx" "$NODE_BIN_DIR/npx"
  fi
  if [ -e "$NODE_INSTALL_DIR/bin/corepack" ]; then
    ln -sfn "$NODE_INSTALL_DIR/bin/corepack" "$NODE_BIN_DIR/corepack"
  fi
  rm -rf "$tmpdir"
  refresh_shell_paths
  ok "Installed Node.js $version into: $NODE_INSTALL_DIR"
}

nushell_target_triple() {
  case "$(uname -m)" in
    arm64|aarch64) printf '%s' "aarch64-apple-darwin" ;;
    x86_64) printf '%s' "x86_64-apple-darwin" ;;
    *) return 1 ;;
  esac
}

nushell_latest_download_url() {
  local target
  target=$(nushell_target_triple) || return 1
  curl -fsSL https://api.github.com/repos/nushell/nushell/releases/latest | \
    sed -nE "s/.*\"browser_download_url\": \"([^\"]*nu-[^\"]*-${target}\\.tar\\.gz)\".*/\\1/p" | \
    head -n 1
}

yazi_target_triple() {
  case "$(uname -m)" in
    arm64|aarch64) printf '%s' "aarch64-apple-darwin" ;;
    x86_64) printf '%s' "x86_64-apple-darwin" ;;
    *) return 1 ;;
  esac
}

yazi_latest_download_url() {
  local target
  target=$(yazi_target_triple) || return 1
  curl -fsSL https://api.github.com/repos/sxyazi/yazi/releases/latest | \
    sed -nE "s/.*\"browser_download_url\": \"([^\"]*yazi-${target}\\.zip)\".*/\\1/p" | \
    head -n 1
}

install_nushell_release() {
  if $DRY_RUN; then
    info "Would install Nushell from official GitHub release into: $NUSHELL_BIN_DIR"
    return 0
  fi

  if ! check_cmd curl; then
    fail "curl not found. Install Nushell manually from https://github.com/nushell/nushell/releases"
    return 1
  fi

  local target url tmpdir archive nu_bin
  target=$(nushell_target_triple) || {
    fail "Unsupported macOS architecture for Nushell: $(uname -m)"
    return 1
  }
  url=$(nushell_latest_download_url)
  if [ -z "$url" ]; then
    fail "Could not find Nushell release asset for: $target"
    return 1
  fi

  tmpdir=$(mktemp -d)
  archive="$tmpdir/nushell.tar.gz"
  if ! curl -fL "$url" -o "$archive"; then
    rm -rf "$tmpdir"
    fail "Failed to download Nushell release: $url"
    return 1
  fi

  if ! tar -xzf "$archive" -C "$tmpdir"; then
    rm -rf "$tmpdir"
    fail "Failed to extract Nushell release"
    return 1
  fi

  nu_bin=$(find "$tmpdir" -type f -name nu | head -n 1)
  if [ -z "$nu_bin" ]; then
    rm -rf "$tmpdir"
    fail "Nushell release did not contain nu binary"
    return 1
  fi

  mkdir -p "$NUSHELL_BIN_DIR"
  cp "$nu_bin" "$NUSHELL_BIN_DIR/nu"
  chmod +x "$NUSHELL_BIN_DIR/nu"
  rm -rf "$tmpdir"
  ok "Installed Nushell into: $NUSHELL_BIN_DIR"
}

install_yazi_release() {
  if $DRY_RUN; then
    info "Would install Yazi from official GitHub release into: $YAZI_BIN_DIR"
    return 0
  fi

  if ! check_cmd curl; then
    fail "curl not found. Install Yazi manually from https://github.com/sxyazi/yazi/releases"
    return 1
  fi

  if ! check_cmd unzip; then
    fail "unzip not found. Install Yazi manually from https://github.com/sxyazi/yazi/releases"
    return 1
  fi

  local target url tmpdir archive yazi_bin ya_bin
  target=$(yazi_target_triple) || {
    fail "Unsupported macOS architecture for Yazi: $(uname -m)"
    return 1
  }
  url=$(yazi_latest_download_url)
  if [ -z "$url" ]; then
    fail "Could not find Yazi release asset for: $target"
    return 1
  fi

  tmpdir=$(mktemp -d)
  archive="$tmpdir/yazi.zip"
  if ! curl -fL "$url" -o "$archive"; then
    rm -rf "$tmpdir"
    fail "Failed to download Yazi release: $url"
    return 1
  fi

  if ! unzip -q "$archive" -d "$tmpdir"; then
    rm -rf "$tmpdir"
    fail "Failed to extract Yazi release"
    return 1
  fi

  yazi_bin=$(find "$tmpdir" -type f -name yazi | head -n 1)
  ya_bin=$(find "$tmpdir" -type f -name ya | head -n 1)
  if [ -z "$yazi_bin" ] || [ -z "$ya_bin" ]; then
    rm -rf "$tmpdir"
    fail "Yazi release did not contain yazi and ya binaries"
    return 1
  fi

  mkdir -p "$YAZI_BIN_DIR"
  cp "$yazi_bin" "$YAZI_BIN_DIR/yazi"
  cp "$ya_bin" "$YAZI_BIN_DIR/ya"
  chmod +x "$YAZI_BIN_DIR/yazi" "$YAZI_BIN_DIR/ya"
  rm -rf "$tmpdir"
  ok "Installed Yazi into: $YAZI_BIN_DIR"
}

ensure_homebrew() {
  if load_homebrew_path; then
    return 0
  fi

  if $DRY_RUN; then
    info "Would install Homebrew from https://brew.sh"
    return 0
  fi

  if ! check_cmd curl; then
    fail "curl not found. Install Homebrew manually from https://brew.sh"
    return 1
  fi

  info "Installing Homebrew from https://brew.sh"
  info "Homebrew may ask for your macOS password during its own setup."
  if $FORCE; then
    if NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
      load_homebrew_path
      return $?
    fi
  else
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
      load_homebrew_path
      return $?
    fi
  fi

  fail "Homebrew installation failed"
  return 1
}

install_missing_dependencies() {
  if $SKIP_DEPS; then
    return 0
  fi

  if ! has_installable_dependencies; then
    return 0
  fi

  local brew_casks brew_formulae
  brew_casks=$(planned_brew_casks)
  brew_formulae=$(planned_brew_formulae)
  DEPENDENCY_INSTALL_FAILED=false

  step "Installing missing dependencies"

  if [ -n "$brew_casks$brew_formulae" ]; then
    if ! ensure_homebrew; then
      return 1
    fi

    if [ -n "$brew_casks" ]; then
      if $DRY_RUN; then
        info "Would run: brew install --cask${brew_casks}"
      else
        local cask
        for cask in $brew_casks; do
          if brew install --cask "$cask"; then
            ok "Installed cask: $cask"
          else
            DEPENDENCY_INSTALL_FAILED=true
            fail "Failed to install cask: $cask"
          fi
          refresh_shell_paths
        done
      fi
    fi

    if [ -n "$brew_formulae" ]; then
      if $DRY_RUN; then
        info "Would run: brew install${brew_formulae}"
      else
        local formula
        for formula in $brew_formulae; do
          if brew install "$formula"; then
            ok "Installed formula: $formula"
          else
            DEPENDENCY_INSTALL_FAILED=true
            fail "Failed to install formula: $formula"
          fi
          refresh_shell_paths
        done
      fi
    fi
  fi

  if $NODE_MISSING; then
    if ! install_node_release; then
      DEPENDENCY_INSTALL_FAILED=true
    fi
  fi

  if [ -n "$missing_npm_globals" ]; then
    if $DRY_RUN; then
      info "Would run: npm install -g --prefix \"$HOME_DIR/.local\"${missing_npm_globals}"
    else
      refresh_shell_paths
      if check_cmd npm; then
        local npm_pkg
        for npm_pkg in $missing_npm_globals; do
          if npm install -g --prefix "$HOME_DIR/.local" "$npm_pkg"; then
            ok "Installed npm package: $npm_pkg"
          else
            DEPENDENCY_INSTALL_FAILED=true
            fail "Failed to install npm package: $npm_pkg"
          fi
          refresh_shell_paths
        done
      else
        DEPENDENCY_INSTALL_FAILED=true
        fail "npm not found after dependency installation"
      fi
    fi
  fi

  if $NUSHELL_MISSING; then
    if ! install_nushell_release; then
      DEPENDENCY_INSTALL_FAILED=true
    fi
  fi

  if $STARSHIP_MISSING; then
    if $DRY_RUN; then
      info "Would install Starship with official installer into: $STARSHIP_BIN_DIR"
      info "Would run: curl -sS https://starship.rs/install.sh | sh -s -- -y -b \"$STARSHIP_BIN_DIR\""
    else
      mkdir -p "$STARSHIP_BIN_DIR"
      if ! check_cmd curl; then
        DEPENDENCY_INSTALL_FAILED=true
        fail "curl not found. Install Starship manually from https://starship.rs"
      elif curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$STARSHIP_BIN_DIR"; then
        ok "Installed Starship into: $STARSHIP_BIN_DIR"
      else
        DEPENDENCY_INSTALL_FAILED=true
        fail "Failed to install Starship with official installer"
      fi
    fi
  fi

  if $YAZI_MISSING; then
    if ! install_yazi_release; then
      DEPENDENCY_INSTALL_FAILED=true
    fi
  fi

  if $DEPENDENCY_INSTALL_FAILED; then
    return 1
  fi
}

confirm_install_plan() {
  if $FORCE || $DRY_RUN; then
    return
  fi

  echo ""
  echo "This will:"
  if $SKIP_DEPS; then
    echo "  - Skip dependency installation"
  elif has_installable_dependencies; then
    echo "  - Install missing dependencies with Homebrew/npm/upstream binaries"
    print_missing_install_commands
  else
    echo "  - Use already installed dependencies"
  fi
  echo "  - Install terminal config files"
  if ! $NO_BACKUP; then
    echo "  - Back up existing configs to: $BACKUP_DIR"
  fi
  echo "  - Install Yazi and restore plugins from package.toml"
  echo ""
  read -p "Continue? (Y/n) " confirm
  if [ "$confirm" != "" ] && [ "$confirm" != "Y" ] && [ "$confirm" != "y" ]; then
    echo "Cancelled."
    exit 0
  fi
}

handle_remaining_missing_dependencies() {
  if [ "$missing" -eq 0 ]; then
    return
  fi

  if $DRY_RUN; then
    return
  fi

  echo ""
  warn "$missing required software(s) not installed. Config files can be copied, but ccNovaTerm will not be usable yet."
  print_missing_install_commands

  if ! $SKIP_DEPS; then
    echo ""
    fail "Dependency installation did not complete. Fix the failed install step above, then rerun: ./install.sh"
    exit 1
  fi

  if $FORCE; then
    return
  fi

  echo ""
  read -p "Continue installing config files anyway? (y/N) " cont
  if [ "$cont" != "Y" ] && [ "$cont" != "y" ]; then
    echo "Cancelled."
    exit 0
  fi
}

detect_software "Checking installed software"
detect_font_status "Checking Nerd Font"
INSTALL_DEPS_NEEDED=false
if ! $SKIP_DEPS && has_installable_dependencies; then
  INSTALL_DEPS_NEEDED=true
fi

confirm_install_plan

if ! $SKIP_DEPS; then
  if ! install_missing_dependencies; then
    DEPENDENCY_INSTALL_FAILED=true
  fi
fi

if $INSTALL_DEPS_NEEDED && ! $DRY_RUN; then
  refresh_shell_paths
  detect_software "Verifying installed software"
  detect_font_status "Verifying Nerd Font"
fi

handle_remaining_missing_dependencies

# ============================================================
# Detect nu path
# ============================================================
NU_PATH=""
if check_cmd nu; then
  NU_PATH=$(which nu)
fi
if [ -z "$NU_PATH" ] && [ -x "$NUSHELL_BIN_DIR/nu" ]; then
  NU_PATH="$NUSHELL_BIN_DIR/nu"
fi
if [ -z "$NU_PATH" ] && [ -f "/opt/homebrew/bin/nu" ]; then
  NU_PATH="/opt/homebrew/bin/nu"
elif [ -z "$NU_PATH" ] && [ -f "/usr/local/bin/nu" ]; then
  NU_PATH="/usr/local/bin/nu"
fi
if [ -z "$NU_PATH" ]; then
  NU_PATH="nu"
fi
info "Nushell path: $NU_PATH"

# ============================================================
# Target paths (macOS)
# ============================================================
WEZTERM_DST="$HOME_DIR/.config/wezterm/wezterm.lua"
NUSHELL_DIR="$HOME_DIR/Library/Application Support/nushell"
NUSHELL_CONFIG_DST="$NUSHELL_DIR/config.nu"
NUSHELL_ENV_DST="$NUSHELL_DIR/env.nu"
STARSHIP_DST="$HOME_DIR/.config/starship.toml"
YAZI_DIR="$HOME_DIR/.config/yazi"
YAZI_CONFIG_DST="$YAZI_DIR/yazi.toml"
YAZI_KEYMAP_DST="$YAZI_DIR/keymap.toml"
YAZI_PACKAGE_DST="$YAZI_DIR/package.toml"

# ============================================================
# Backup
# ============================================================
if ! $NO_BACKUP && ! $DRY_RUN; then
  step "Backing up existing configs -> $BACKUP_DIR"
  has_backup=false
  backup_file() {
    if [ -f "$1" ]; then
      $has_backup || mkdir -p "$BACKUP_DIR"
      cp "$1" "$BACKUP_DIR/$(basename "$1")"
      ok "Backed up: $(basename "$1")"
      has_backup=true
    fi
  }
  backup_file "$WEZTERM_DST"
  backup_file "$NUSHELL_CONFIG_DST"
  backup_file "$NUSHELL_ENV_DST"
  backup_file "$STARSHIP_DST"
  backup_file "$YAZI_CONFIG_DST"
  backup_file "$YAZI_KEYMAP_DST"
  backup_file "$YAZI_PACKAGE_DST"
  backup_file "$HOME_DIR/.zshrc"
  if ! $has_backup; then
    info "No existing configs to backup"
  fi
elif $DRY_RUN; then
  step "(DRY RUN) Would backup to: $BACKUP_DIR"
fi

# ============================================================
# Install
# ============================================================
step "Installing config files"

if $DRY_RUN; then info "(DRY RUN -- no files written below)"; fi

install_count=0
fail_count=0

# Helper: copy a config file with placeholder replacement
copy_config() {
  local src="$CONFIG_DIR/$1"
  local dst="$2"

  if [ ! -f "$src" ]; then
    fail "$1: source not found"
    fail_count=$((fail_count + 1))
    return
  fi

  if $DRY_RUN; then
    info "Would write: $dst"
    return
  fi

  mkdir -p "$(dirname "$dst")"

  # Read content and replace placeholders
  local content
  content=$(cat "$src")

  # Replace __NU_PATH__ with detected nu path (for wezterm.lua)
  if echo "$1" | grep -q "wezterm"; then
    content="${content//__NU_PATH__/$NU_PATH}"
  fi

  # Replace __GIT_USR_BIN__ with git usr/bin path (for env.nu)
  if echo "$1" | grep -q "env.nu"; then
    local git_bin
    git_bin=$(dirname "$(which git)" 2>/dev/null || echo "/usr")
    # On macOS, file is at /usr/bin/file or /opt/homebrew/opt/coreutils/libexec/gnubin/file
    local file_dir=""
    local file_path=""
    if [ -f "/opt/homebrew/opt/coreutils/libexec/gnubin/file" ]; then
      file_dir="/opt/homebrew/opt/coreutils/libexec/gnubin"
      file_path="$file_dir/file"
    elif [ -f "/usr/local/opt/coreutils/libexec/gnubin/file" ]; then
      file_dir="/usr/local/opt/coreutils/libexec/gnubin"
      file_path="$file_dir/file"
    elif [ -f "/usr/bin/file" ]; then
      file_dir="/usr/bin"
      file_path="/usr/bin/file"
    else
      file_dir="$git_bin"
      file_path="$file_dir/file"
    fi
    content="${content//__GIT_USR_BIN__\\\\file.exe/$file_path}"
    content="${content//__GIT_USR_BIN__/$file_dir}"
    content="${content//__LOCAL_BIN__/$STARSHIP_BIN_DIR}"
  fi

  printf '%s\n' "$content" > "$dst"
  ok "$1 -> $dst"
  install_count=$((install_count + 1))
}

# Copy configs
copy_config ".wezterm.lua"        "$WEZTERM_DST"
copy_config "config.nu"            "$NUSHELL_CONFIG_DST"
copy_config "env.nu"               "$NUSHELL_ENV_DST"
copy_config "starship.toml"        "$STARSHIP_DST"
copy_config "yazi/yazi.toml"       "$YAZI_CONFIG_DST"
copy_config "yazi/keymap.toml"     "$YAZI_KEYMAP_DST"
copy_config "yazi/package.toml"    "$YAZI_PACKAGE_DST"
ensure_zshrc_local_bin_path

install_yazi_plugins() {
  if $DRY_RUN; then
    info "Would install Yazi plugins from package.toml after Yazi is available: ya pkg install --discard"
    return
  fi

  refresh_shell_paths

  local ya_cmd=""
  if check_cmd ya; then
    ya_cmd=$(command -v ya)
  elif [ -x "$YAZI_BIN_DIR/ya" ]; then
    ya_cmd="$YAZI_BIN_DIR/ya"
  fi

  if [ -z "$ya_cmd" ]; then
    YAZI_PLUGIN_SKIPPED=true
    warn "Yazi plugin install was skipped because ya was not found."
    return
  fi

  step "Installing Yazi plugins"
  if YAZI_CONFIG_HOME="$YAZI_DIR" "$ya_cmd" pkg install --discard; then
    ok "Yazi plugins installed from package.toml"
  else
    YAZI_PLUGIN_FAILED=true
    warn "Yazi plugin install was attempted automatically but failed. Check the error above, then rerun ./install.sh to retry."
  fi
}

install_yazi_plugins

# ============================================================
# Verify
# ============================================================
if ! $DRY_RUN && [ "$install_count" -gt 0 ]; then
  step "Verifying installed files"
  verify() {
    if [ -f "$1" ]; then
      local sz
      sz=$(wc -c < "$1" | tr -d ' ')
      if [ "$sz" -gt 10 ]; then
        ok "$(basename "$1") ($sz bytes)"
      else
        warn "$(basename "$1") is very small ($sz bytes), may be corrupted"
      fi
    fi
  }
  verify "$WEZTERM_DST"
  verify "$NUSHELL_CONFIG_DST"
  verify "$NUSHELL_ENV_DST"
  verify "$STARSHIP_DST"
  verify "$YAZI_CONFIG_DST"
  verify "$YAZI_KEYMAP_DST"
  verify "$YAZI_PACKAGE_DST"
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo -e "${CYA}============================================${RST}"
if $DRY_RUN; then
  echo -e "  ${YLW}DRY RUN complete${RST}"
elif [ "$fail_count" -eq 0 ] && [ "$missing" -eq 0 ]; then
  echo -e "  ${GRN}Installation complete!${RST}"
elif [ "$fail_count" -eq 0 ]; then
  echo -e "  ${YLW}Config files installed; required software is still missing${RST}"
else
  echo -e "  ${YLW}Done with $fail_count warning(s)${RST}"
fi
echo -e "${CYA}============================================${RST}"

if ! $NO_BACKUP && ! $DRY_RUN; then
  echo -e "  ${GRY}Backup: $BACKUP_DIR${RST}"
fi

echo ""
next_step=1

if $DRY_RUN; then
  echo -e "${YLW}Next steps:${RST}"
  if $SKIP_DEPS; then
    echo "  1. Run: ./install.sh --skip-deps"
  else
    echo "  1. Run: ./install.sh"
  fi
  echo "  2. Use ./install.sh --force to skip ccNovaTerm confirmation prompts"
  exit 0
fi

if [ "$missing" -gt 0 ]; then
  echo -e "${YLW}Next steps:${RST}"
  next_brew_casks=$(planned_brew_casks)
  next_brew_formulae=$(planned_brew_formulae)
  echo "  $next_step. Install the missing required software:"
  if [ -n "$next_brew_casks" ]; then
    echo "     brew install --cask${next_brew_casks}"
  fi
  if [ -n "$next_brew_formulae" ]; then
    echo "     brew install${next_brew_formulae}"
  fi
  if $NODE_MISSING; then
    echo "     Install Node.js from official release into: $NODE_BIN_DIR"
  fi
  if [ -n "$missing_npm_globals" ]; then
    echo "     npm install -g --prefix \"$HOME_DIR/.local\"${missing_npm_globals}"
  fi
  if [ -n "$missing_manual_hints" ]; then
    printf '%s\n' "$missing_manual_hints" | while IFS= read -r hint; do
      [ -n "$hint" ] && echo "     $hint"
    done
  fi
  next_step=$((next_step + 1))
  echo "  $next_step. Rerun: ./install.sh"
  next_step=$((next_step + 1))
else
  if [ "$missing" -eq 0 ] && { $YAZI_PLUGIN_SKIPPED || $YAZI_PLUGIN_FAILED; }; then
    echo -e "${YLW}Next steps:${RST}"
  else
    echo -e "${YLW}Next step:${RST}"
  fi
  echo "  $next_step. Restart WezTerm"
  next_step=$((next_step + 1))
  if $YAZI_PLUGIN_FAILED; then
    echo "  $next_step. Rerun ./install.sh to retry Yazi plugin installation"
    next_step=$((next_step + 1))
  elif $YAZI_PLUGIN_SKIPPED; then
    echo "  $next_step. Rerun ./install.sh after Yazi is available to install plugins"
    next_step=$((next_step + 1))
  fi
fi

if [ "$missing" -eq 0 ]; then
  echo ""
  echo -e "${YLW}Optional configuration:${RST}"
  if ! $NO_FONT && $FONT_MISSING; then
    echo "  - Recommended font: brew install --cask font-jetbrains-mono-nerd-font"
  fi
  echo "  - Proxy: only if your network needs one, edit: $NUSHELL_ENV_DST"
  echo "  - Claude Code auth/model/API key: only if Claude Code asks after launch"
fi

if [ "$missing" -eq 0 ] && ! check_wezterm; then
  echo ""
  warn "WezTerm not detected. Add to PATH or install via: brew install --cask wezterm"
fi
