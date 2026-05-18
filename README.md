<h1 align="center">ccNovaTerm</h1>
<p align="center">
  <b>Beautiful Terminal for Claude Code</b><br>
  <sub>WezTerm · Nushell · Starship · Yazi — one command, fully equipped.</sub>
</p>

<p align="center">
  <a href="README_CN.md">中文文档</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-Windows%20%7C%20macOS-blue?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License">
  <img src="https://img.shields.io/badge/Claude%20Code-v2.1%2B-orange?style=flat-square" alt="Claude Code">
</p>

<p align="center">
  <img src="docs/hero.png" alt="ccNovaTerm" width="100%">
</p>

---

## Features

- **One-command setup** — `.\install.ps1` (Win) or `./install.sh` (Mac), auto backup, path detection, smart merge
- **Real token tracking** — Parses Claude Code transcript JSONL, deduplicates multi-block API calls, accurate billing
- **Pastel Powerline prompt** — User, directory, Git branch/status, language versions, Docker, clock — full color
- **GPU-accelerated** — WezTerm + Catppuccin Mocha theme + JetBrainsMono Nerd Font
- **Yazi cd-on-exit** — Exit the file manager and land in the browsed directory

## Statusline

<p align="center">
  <img src="docs/statusline.png" alt="Statusline close-up" width="80%">
</p>

| Field | Color | Meaning |
|-------|-------|---------|
| `model` | Cyan | Current model name |
| `effort` | Multi | low→cyan med→green high→yellow-bold xhigh→red-bold MAX→purple-bold |
| `ctx` | Green→Red | Context window usage (yellow at 70%, red at 90%) |
| `in` / `out` | Green / Yellow | Current context input / output tokens |
| `ses` | Blue | Cumulative API tokens for current Claude Code process (deduped) |
| `api` | Red | Cumulative API tokens across the entire transcript (deduped) |

> Claude Code writes 2-6 transcript entries per API call (thinking + text + tool calls) — all with identical `usage`. `ses` / `api` deduplicate consecutively, keeping billing accurate within < 1%.

## Install

### Prerequisites

**Windows:**
```powershell
winget install wez.wezterm Nushell.Nushell Starship.Starship Git.Git
```

**macOS:**
```bash
brew install --cask wezterm
brew install nushell starship yazi git
```

[Yazi](https://github.com/sxyazi/yazi/releases) · [Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases) (JetBrainsMono.zip) · `npm install -g @anthropic-ai/claude-code`

### One-command install

```bash
git clone https://github.com/shuiyu486/ccNovaTerm.git
cd ccNovaTerm

# Windows
.\install.ps1

# macOS
./install.sh
```

<p align="center">
  <img src="docs/install.png" alt="Install process" width="80%">
</p>

| Flag | Effect |
|------|--------|
| `-DryRun` / `--dry-run` | Preview only, no writes |
| `-Force` / `--force` | Skip confirmations |
| `-NoBackup` / `--no-backup` | Skip backing up existing configs |

For status line, install the [cc-statusline plugin](https://github.com/shuiyu486/terr-marketplace) — `/plugin install cc-statusline` then `/cc-statusline:setup`.

## Keybindings

| Shortcut | Action | | Shortcut | Action |
|----------|--------|-|----------|--------|
| `Alt+C` | Copy | | `Alt+V` | Paste |
| `Ctrl+Shift+T` | New tab | | `Ctrl+Shift+W` | Close tab |
| `Alt+D` | Split right | | `Alt+Shift+D` | Split down |
| `Alt+Arrows` | Switch pane | | `Alt+X` | Close pane |
| `Alt+H` | Hide window | | `Right-click` | Smart copy/paste |
| `Shift+Enter` | Newline (Claude Code) | | | |

Nushell: type `y` to launch Yazi, exit to auto-cd. `cc` is aliased to `claude` for quick access.

<details>
<summary><b>Customization — WezTerm / Starship / Proxy</b></summary>

**WezTerm** `~/.wezterm.lua` (Win) or `~/.config/wezterm/wezterm.lua` (Mac) — change `color_scheme`, `font_size`, `initial_cols`

**Starship** `~/.config/starship.toml` — see [presets](https://starship.rs/presets/)

**Proxy** — Windows: `~\AppData\Roaming\nushell\env.nu`, macOS: `~/Library/Application Support/nushell/env.nu` — uncomment the `load-env` line

</details>

## Files

```
After install:
  ~/.wezterm.lua  or  ~/.config/wezterm/wezterm.lua   (Win / Mac)
  nushell config.nu + env.nu                            (OS-dependent path)
  ~/.config/starship.toml                               (Both)

Runtime:
  ccNovaTerm-backup/                                    (Home dir)
```

## Known Issues

| Issue | Fix |
|-------|-----|
| WezTerm won't start | Update NVIDIA GPU drivers |
| Token count inflated | Built-in dedup — no action needed |
| Font fails to install | Close WezTerm before installing |
| Cursor turns white block | ink/DECSCUSR issue, no fix yet |
| Statusline garbled with Chinese | Fixed (raw bytes + UTF-8 decode) |
| ses negative after switching project | Fixed (transcript path + apiTotal check) |
| Multi-window ses conflict | Fixed (per-PID cache isolation) |

## License

[MIT](LICENSE)
