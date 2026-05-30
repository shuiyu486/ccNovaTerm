#!/usr/bin/env bash
# ccNovaTerm — macOS installer
# https://github.com/shuiyu486/ccNovaTerm
set -euo pipefail

DRY_RUN=false
FORCE=false
NO_BACKUP=false
NO_FONT=false

for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=true ;;
    --force) FORCE=true ;;
    --no-backup) NO_BACKUP=true ;;
    --no-font) NO_FONT=true ;;
    --help) echo "Usage: ./install.sh [--force] [--dry-run] [--no-backup] [--no-font]"; exit 0 ;;
  esac
done

# Colors
CYA='\033[36m'; GRN='\033[32m'; YLW='\033[33m'; RED='\033[31m'; GRY='\033[90m'; RST='\033[0m'; BLD='\033[1m'

step()  { echo -e "\n${CYA}>> $*${RST}"; }
ok()    { echo -e "    ${GRN}[OK]${RST} $*"; }
warn()  { echo -e "    ${YLW}[!!]${RST} $*"; }
fail()  { echo -e "    ${RED}[X]${RST} $*"; }
info()  { echo -e "    ${GRY}..${RST} $*"; }

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

# Confirm
if ! $FORCE && ! $DRY_RUN; then
  echo ""
  echo "This will install terminal config files."
  echo "Existing configs will be backed up to: $BACKUP_DIR"
  echo ""
  read -p "Continue? (Y/n) " confirm
  if [ "$confirm" != "" ] && [ "$confirm" != "Y" ] && [ "$confirm" != "y" ]; then
    echo "Cancelled."
    exit 0
  fi
fi

# ============================================================
# Detect installed software
# ============================================================
step "Checking installed software"

check_cmd() { command -v "$1" &>/dev/null; }

missing=0
check_item() {
  if check_cmd "$1"; then ok "$2"; else fail "$2 -- not found. Install: $3"; missing=$((missing + 1)); fi
}

check_item "wezterm"   "WezTerm"     "brew install --cask wezterm"
check_item "nu"        "Nushell"     "brew install nushell"
check_item "starship"  "Starship"    "brew install starship"
check_item "yazi"      "Yazi"        "brew install yazi"
check_item "claude"    "Claude Code" "npm install -g @anthropic-ai/claude-code"
check_item "git"       "Git"         "xcode-select --install"

if [ "$missing" -gt 0 ] && ! $FORCE && ! $DRY_RUN; then
  echo ""
  warn "$missing software(s) not installed. You can install configs now and install software later."
  read -p "Continue anyway? (y/N) " cont
  if [ "$cont" != "Y" ] && [ "$cont" != "y" ]; then exit 0; fi
fi

# ============================================================
# Detect nu path
# ============================================================
NU_PATH=""
if check_cmd nu; then
  NU_PATH=$(which nu)
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
# Font check
# ============================================================
if ! $NO_FONT; then
  step "Checking Nerd Font"
  if [ -f "$HOME_DIR/Library/Fonts/JetBrainsMonoNerdFont-Regular.ttf" ] || \
     [ -f "$HOME_DIR/Library/Fonts/JetBrains Mono Nerd Font Complete.ttf" ] || \
     [ -f "/Library/Fonts/JetBrainsMonoNerdFont-Regular.ttf" ]; then
    ok "JetBrainsMono Nerd Font installed"
  else
    warn "JetBrainsMono Nerd Font not installed"
    info "Install via brew: brew install --cask font-jetbrains-mono-nerd-font"
    info "Or download from: https://www.nerdfonts.com/font-downloads"
  fi
fi

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

if check_cmd ya; then
  if $DRY_RUN; then
    info "Would install Yazi plugins from package.toml: ya pkg install"
  else
    step "Installing Yazi plugins"
    if YAZI_CONFIG_HOME="$YAZI_DIR" ya pkg install; then
      ok "Yazi plugins installed from package.toml"
    else
      warn "ya pkg install failed. Run it manually after install."
    fi
  fi
else
  warn "ya command not found. After installing Yazi, run: ya pkg install"
fi

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
elif [ "$fail_count" -eq 0 ]; then
  echo -e "  ${GRN}Installation complete!${RST}"
else
  echo -e "  ${YLW}Done with $fail_count warning(s)${RST}"
fi
echo -e "${CYA}============================================${RST}"

if ! $NO_BACKUP && ! $DRY_RUN; then
  echo -e "  ${GRY}Backup: $BACKUP_DIR${RST}"
fi

echo ""
echo -e "${YLW}Next steps:${RST}"
echo "  1. Restart WezTerm"
echo "  2. Verify font: wezterm ls-fonts --list-system | grep JetBrainsMono"
echo "  3. Configure proxy in: $NUSHELL_ENV_DST"
echo "  4. If Yazi plugins were skipped, run: ya pkg install"
echo "  5. Configure model/API key if needed"

if ! check_cmd wezterm; then
  echo ""
  warn "WezTerm not detected. Add to PATH or install via: brew install --cask wezterm"
fi
