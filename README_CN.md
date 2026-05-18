<h1 align="center">ccNovaTerm</h1>
<p align="center">
  <b>Claude Code 的美化终端</b><br>
  <sub>WezTerm · Nushell · Starship · Yazi — 一键部署，全副武装</sub>
</p>

<p align="center">
  <a href="README.md">English</a>
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

## 核心特性

- **一键部署** — `install.ps1`（Windows）或 `install.sh`（macOS），自动备份、路径检测
- **Pastel Powerline 提示符** — 用户、目录、Git 分支/状态、语言版本、Docker、时间，全彩色展示
- **GPU 加速终端** — WezTerm + Catppuccin Mocha 主题 + JetBrainsMono Nerd Font
- **Yazi cd-on-exit** — 退出文件管理器自动 cd 到浏览目录

## Statusline

安装 [cc-statusline 插件](https://github.com/shuiyu486/terr-marketplace) 获取功能丰富的状态栏：真实 token 统计、effort 等级、上下文用量、会话 API 消耗——全部去重，计费精确。

```shell
/plugin install cc-statusline
/cc-statusline:setup
```

<p align="center">
  <img src="docs/statusline.png" alt="Statusline close-up" width="80%">
</p>

## 安装

### 前置软件

**Windows：**
```powershell
winget install wez.wezterm Nushell.Nushell Starship.Starship Git.Git
```

**macOS：**
```bash
brew install --cask wezterm
brew install nushell starship yazi git
```

[Yazi](https://github.com/sxyazi/yazi/releases) · [Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases)（JetBrainsMono.zip） · `npm install -g @anthropic-ai/claude-code`

### 一键安装

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

| 参数 | 作用 |
|------|------|
| `-DryRun` / `--dry-run` | 预览，不写入 |
| `-Force` / `--force` | 跳过确认 |
| `-NoBackup` / `--no-backup` | 不备份现有配置 |

状态栏已独立为 [cc-statusline 插件](https://github.com/shuiyu486/terr-marketplace) — `/plugin install cc-statusline` 然后 `/cc-statusline:setup`。

## 快捷键

| 快捷键 | 功能 | | 快捷键 | 功能 |
|--------|------|-|--------|------|
| `Alt+C` | 复制 | | `Alt+V` | 粘贴 |
| `Ctrl+Shift+T` | 新建标签 | | `Ctrl+Shift+W` | 关闭标签 |
| `Alt+D` | 右侧分屏 | | `Alt+Shift+D` | 下方分屏 |
| `Alt+←↑↓→` | 切换分屏 | | `Alt+X` | 关闭分屏 |
| `Alt+H` | 隐藏窗口 | | `右键` | 复制/粘贴 |
| `Shift+Enter` | 换行 (Claude Code) | | | |

Nushell：键入 `y` 启动 Yazi，退出自动 cd。`cc` 是 `claude` 的快捷别名。

<details>
<summary><b>自定义 WezTerm / Starship / 代理</b></summary>

**WezTerm** — Windows: `~\.wezterm.lua`，macOS: `~/.config/wezterm/wezterm.lua` — 改 `color_scheme`、`font_size`、`initial_cols`

**Starship** `~\.config\starship.toml` — 参考[预设](https://starship.rs/presets/)

**代理** — Windows: `~\AppData\Roaming\nushell\env.nu`，macOS: `~/Library/Application Support/nushell/env.nu` — 取消注释 `load-env` 行

</details>

## 文件清单

```
安装后:
  ~/.wezterm.lua  或  ~/.config/wezterm/wezterm.lua  （Win / Mac）
  nushell config.nu + env.nu                         （系统相关路径）
  ~/.config/starship.toml                            （双平台）

运行时:
  ccNovaTerm-backup/                                      （用户目录）
```

## 已知问题

| 问题 | 解决 |
|------|------|
| WezTerm 启动不了 | 升级 NVIDIA 驱动 |
| 字体装不上 | 关闭 WezTerm 再装 |
| 光标变白块 | ink/DECSCUSR，暂无解 |

## License

[MIT](LICENSE)
