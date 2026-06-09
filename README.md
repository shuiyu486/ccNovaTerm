# ccNovaTerm

> **C**laude **C**ode + **Nova** **Term**inal — One command, fully equipped terminal for Claude Code

[![English](https://img.shields.io/badge/lang-English-blue.svg)](./README.md)
[![中文](https://img.shields.io/badge/lang-中文-red.svg)](./README_CN.md)

An automated setup that bundles [WezTerm](https://wezfurlong.org/wezterm/) + [Nushell](https://www.nushell.sh/) + [Starship](https://starship.rs/) + [Yazi](https://yazi-rs.github.io/) into the perfect terminal experience for Claude Code.

![ccNovaTerm](docs/hero.png)

## ✨ Features

- 🚀 **One-command setup** — Single command, full configuration
- 🎨 **Catppuccin Mocha** — Unified theme across WezTerm and Starship
- 🔤 **Nerd Font** — JetBrainsMono Nerd Font, ready to use
- 🐚 **Nushell** — Modern structured shell, with `cc` alias for instant Claude Code access
- 🧩 **Claude Code launchers** — `claude-env` can temporarily switch API/model with any local env script while keeping global defaults intact
- 📁 **Yazi** — Terminal file manager, seamlessly integrated
- 🔄 **config-sync** — Claude Code skill for bidirectional config sync

## 📋 Prerequisites

| Tool | Description |
|------|-------------|
| [WezTerm](https://wezfurlong.org/wezterm/) | GPU-accelerated terminal emulator |
| [Nushell](https://www.nushell.sh/) | Structured shell |
| [Starship](https://starship.rs/) | Customizable shell prompt |
| [Yazi](https://yazi-rs.github.io/) | Terminal file manager |
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | AI coding assistant CLI |
| [Git for Windows](https://git-scm.com/) | Version control (Windows needs `file.exe` from `usr/bin`) |
| [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads) | Icon and symbol support |

## 🚀 Install

### Windows

```powershell
git clone https://github.com/shuiyu486/ccNovaTerm.git
cd ccNovaTerm
.\install.ps1
```

### macOS

```bash
git clone https://github.com/shuiyu486/ccNovaTerm.git
cd ccNovaTerm
./install.sh
```

The macOS installer automatically installs the core terminal stack and deploys configs, including Homebrew, WezTerm, JetBrainsMono Nerd Font, Nushell, Starship, Yazi, Node.js, and Claude Code. Nushell, Yazi, and Node.js are installed from official upstream release archives, and Starship is installed with the official prebuilt installer; these tools go into `~/.local/bin` instead of Homebrew, which avoids heavy LLVM/Rust builds on older systems such as macOS 12 Monterey. Do not run the installer with `sudo`; it installs user config files and should target your own home directory. If the shell reports a permission error, run `chmod +x install.sh` first.

Advanced options:

| Command | Purpose |
|---------|---------|
| `./install.sh --dry-run` | Preview dependencies and config files without modifying the system |
| `./install.sh --force` | Skip ccNovaTerm confirmation prompts for automation |
| `./install.sh --skip-deps` | Copy config files without installing dependencies |
| `./install.sh --no-font` | Skip Nerd Font detection and installation |

Common macOS cases:

| Output | Meaning | Fix |
|--------|---------|-----|
| `This installer is macOS only` | `install.sh` was run on a non-macOS host | Use `install.ps1` on Windows, or run `install.sh` from macOS |
| `sudo: ./install.sh: command not found` or `permission denied` | The script is not executable, or it was run with `sudo` | Run `chmod +x install.sh`, then run `./install.sh` directly |
| `[X] WezTerm/Nushell/... -- not found` | The installer detected missing dependencies | Continue when prompted; the script will install missing dependencies automatically |
| `Nushell -- not found` | Nushell is missing | Continue when prompted; the script installs Nushell from the official GitHub release into `~/.local/bin` |
| `Starship -- not found` | Starship is missing | Continue when prompted; the script installs Starship from the official prebuilt installer into `~/.local/bin` |
| `Yazi -- not found` | Yazi is missing | Continue when prompted; the script installs Yazi from the official GitHub release into `~/.local/bin` |
| `Node.js/npm -- not found` | Node.js or npm is missing | Continue when prompted; the script installs the latest Node.js LTS release into `~/.local/bin` |
| `Homebrew not found` | Homebrew is not installed | The script normally runs the official Homebrew installer, which may ask for your macOS password; you can also install Homebrew manually and rerun |
| `Dependency installation did not complete` | A dependency install failed | Check the failed package above, fix it, then rerun `./install.sh` |
| `ya command not found` | Yazi is unavailable, so plugins were not restored | Rerun `./install.sh`; for manual plugin restore, run `YAZI_CONFIG_HOME="$HOME/.config/yazi" ya pkg install` |
| `Config files installed; required software is still missing` | `--skip-deps` was used to copy configs only | Rerun `./install.sh` to install and verify dependencies |

The default macOS installer will:
1. Detect and install missing dependencies
2. Replace placeholders in config templates with actual system paths
3. Back up any existing configs
4. Deploy config files to the correct locations
5. Install Nushell, Starship, Yazi, and Node.js into `~/.local/bin` from prebuilt upstream releases
6. Restore Yazi plugins from `package.toml`

## ⌨️ Custom Shortcuts

These shortcuts are enabled after installing the bundled WezTerm and Yazi configs.

### WezTerm

| Shortcut | Action |
|----------|--------|
| `Alt+C` / `Alt+V` | Copy / paste with the system clipboard |
| `Ctrl+Shift+T` / `Ctrl+Shift+W` | New tab / close current tab |
| `Alt+1` … `Alt+9` | Switch to tab 1–9 |
| `Alt+D` / `Alt+Shift+D` | Split the current pane right / down |
| `Alt+←/→/↑/↓` | Move focus between panes |
| `Alt+X` | Close the current pane, with confirmation |
| `Alt+H` | Hide the WezTerm window |
| `Shift+Enter` | Pass Shift+Enter through to TUI apps, useful for multi-line input in Claude Code |
| `Ctrl+Q` | Clear the current Claude Code input, including multi-line drafts |
| `Ctrl+Z` | Restore/yank the last cleared Claude Code input |

Mouse shortcuts:

| Action | Behavior |
|--------|----------|
| Left click / selection | Open links, or copy completed selections to the clipboard |
| Right click | Paste when nothing is selected; copy and clear when text is selected |

### Yazi

| Shortcut | Action |
|----------|--------|
| `Enter` | Maximize or restore the preview pane |
| `l` or `→` | Enter directories or open files; use this because `Enter` toggles the preview pane |

## 🧩 Claude Code multi-config launcher

The default commands are unchanged and continue to use your global `~/.claude/settings.json`:

```nu
claude
# or
cc
```

To temporarily use another API/model in a specific WezTerm window or pane, create any private local Nushell env script. The filename is yours to choose:

```nu
# Example: ~/.claude/claude-openrouter-env.nu
$env.ANTHROPIC_BASE_URL = "https://your-provider.example/anthropic"
$env.ANTHROPIC_AUTH_TOKEN = $env.YOUR_PROVIDER_API_KEY
$env.ANTHROPIC_MODEL = "your-model"
$env.ANTHROPIC_DEFAULT_HAIKU_MODEL = "your-fast-model"
$env.ANTHROPIC_DEFAULT_SONNET_MODEL = "your-model"
$env.ANTHROPIC_DEFAULT_OPUS_MODEL = "your-model"
```

Then start the alternate session with an explicit script path:

```nu
claude-env --env-script ~/.claude/claude-openrouter-env.nu
```

Or set the script once for the current Nushell window/pane and launch with the generic command:

```nu
$env.CLAUDE_ENV_SCRIPT = '~/.claude/claude-openrouter-env.nu'
claude-env
```

If neither `--env-script` nor `CLAUDE_ENV_SCRIPT` is set, `claude-env` defaults to `~/.claude/claude-env.nu`.

`claude-env` reads your main settings, keeps plugins, marketplaces, permissions, statusLine, and other fields, and only overlays the model/API-related environment variables from the script into a temporary settings file for this launch. The script must set `ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN`, and `ANTHROPIC_MODEL` so the launcher never falls back to the default token from your main settings. Do not commit real tokens to the repository. If your script prints status output, guard it with `CLAUDE_ENV_QUIET` so the launcher can read it silently.


## 📁 Project Structure

```
ccNovaTerm/
├── config/           ← Config templates
│   ├── .wezterm.lua  ← WezTerm config (Catppuccin Mocha theme)
│   ├── config.nu     ← Nushell config (aliases, Claude Code launchers, Yazi integration)
│   ├── env.nu        ← Nushell environment variables
│   ├── starship.toml ← Starship prompt (Pastel Powerline)
│   └── yazi/         ← Yazi config and plugin lockfile
├── docs/             ← Screenshots
├── test/             ← Test scripts
├── install.ps1       ← Windows installer
├── install.sh        ← macOS installer
└── CLAUDE.local.md   ← Maintenance guide for Claude Code or other coding assistants
```

## 🔄 config-sync Skill

ccNovaTerm includes a [Claude Code skill](https://docs.anthropic.com/en/docs/claude-code/skills) for bidirectional config sync between your local environment and project templates.

### Install

```bash
/plugin install config-sync
```

### Usage

Just tell Claude Code:

| Command | Action |
|---------|--------|
| "Sync to local" | Project templates → local configs |
| "Sync to project" | Local configs → project templates |
| "Compare" | Show diffs between local and templates |
| "Quick check" | Verify config compatibility |

### Placeholders

Templates use placeholders that are auto-replaced with actual system paths during install:

| Placeholder | Replaced with |
|-------------|--------------|
| `__NU_PATH__` | Full path to Nushell executable |
| `__GIT_USR_BIN__` | `usr/bin` path under Git install directory |
| `__LOCAL_BIN__` | User-level binary directory, such as `~/.local/bin` on macOS |

## 🛠️ Customization

All config files are standard and can be edited directly:

- **WezTerm**: Edit `~/.wezterm.lua` — font, colors, keybindings
- **Nushell**: Edit `~/AppData/Roaming/nushell/config.nu` (Windows) or `~/Library/Application Support/nushell/config.nu` (macOS)
- **Starship**: Edit `~/.config/starship.toml` — prompt style and modules
- **Environment**: Edit `~/AppData/Roaming/nushell/env.nu` (Windows) or `~/Library/Application Support/nushell/env.nu` (macOS)
- **Yazi**: Edit `~/AppData/Roaming/yazi/config/*.toml` (Windows) or `~/.config/yazi/*.toml` (macOS); plugin dependencies are locked in `package.toml` and restored with `ya pkg install`

After changes, use config-sync's "Sync to project" to push them back to templates.

## 📸 Screenshots

![Install process](docs/install.png)

![Statusline](docs/statusline.png)

## 📄 License

MIT License — See [LICENSE](LICENSE) for details.
