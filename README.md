<h1 align="center">ccNovaTerm</h1>
<p align="center">
  <b>Beautiful Terminal for Claude Code on Windows</b><br>
  <sub>WezTerm · Nushell · Starship · Yazi — one command, fully equipped.</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-Windows%2010%2F11-blue?style=flat-square&logo=windows" alt="Platform">
  <img src="https://img.shields.io/badge/powershell-5.1%2B-blue?style=flat-square" alt="PowerShell">
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License">
  <img src="https://img.shields.io/badge/Claude%20Code-v2.1%2B-orange?style=flat-square" alt="Claude Code">
</p>

<p align="center">
  <img src="docs/hero.png" alt="ccNovaTerm" width="100%">
</p>

---

## 核心特性

- **一键部署** — `.\install.ps1`，自动备份、路径检测、智能合并
- **真实 Token 统计** — 解析 transcript JSONL，自动去重，精确计费
- **Pastel Powerline** — 用户、目录、Git、语言版本、时间，全彩分段
- **GPU 加速** — WezTerm + Catppuccin Mocha + JetBrainsMono Nerd Font
- **Yazi cd-on-exit** — 退出文件管理器自动 cd

## Statusline

<p align="center">
  <img src="docs/statusline.png" alt="Statusline close-up" width="80%">
</p>

| 字段 | 颜色 | 含义 |
|------|------|------|
| `model` | 青 | 当前模型 |
| `effort` | 多色 | low→青 med→绿 high→黄 xhigh→红 MAX→紫 |
| `ctx` | 绿→黄→红 | 上下文窗口占比（70% 黄，90% 红） |
| `in` / `out` | 绿 / 黄 | 当前上下文输入/输出 token |
| `ses` | 蓝 | 当前进程累计 API 消耗（去重） |
| `api` | 红 | 全程累计 API 消耗（去重） |

> 每次 API 调用产生 2-6 条相同 usage 的 transcript 记录（思考 + 文本 + 工具调用）。`ses` / `api` 自动跳过重复条目，统计误差 < 1%。

## 安装

```powershell
# 1. 前置软件
winget install wez.wezterm Nushell.Nushell Starship.Starship Git.Git

# Yazi: https://github.com/sxyazi/yazi/releases (yazi.exe + ya.exe → PATH)
# Nerd Font: https://github.com/ryanoasis/nerd-fonts/releases (JetBrainsMono.zip)

# 2. 一键安装
git clone https://github.com/shuiyu486/ccNovaTerm.git
cd ccNovaTerm
.\install.ps1
```

<p align="center">
  <img src="docs/install.png" alt="Install process" width="80%">
</p>

| 参数 | 作用 |
|------|------|
| `-DryRun` | 预览，不写入 |
| `-Force` | 跳过确认 |
| `-NoBackup` | 不备份现有配置 |

`settings.json` 自动**合并**：只添加 `statusLine`，不覆盖你已有的 API key、模型设置。

## 快捷键

| 快捷键 | 功能 | | 快捷键 | 功能 |
|--------|------|-|--------|------|
| `Alt+C` | 复制 | | `Alt+V` | 粘贴 |
| `Ctrl+Shift+T` | 新建标签 | | `Ctrl+Shift+W` | 关闭标签 |
| `Alt+D` | 右侧分屏 | | `Alt+Shift+D` | 下方分屏 |
| `Alt+←↑↓→` | 切换分屏 | | `Alt+X` | 关闭分屏 |
| `Alt+H` | 隐藏窗口 | | `右键` | 复制/粘贴 |

Nushell: `y` 启动 Yazi，退出自动 cd。

<details>
<summary><b>自定义 WezTerm / Starship / Statusline / 代理</b></summary>

**WezTerm** `~\.wezterm.lua` — 改 `color_scheme`、`font_size`、`initial_cols`

**Starship** `~\.config\starship.toml` — 参考 [预设](https://starship.rs/presets/)

**Statusline** `~\.claude\statusline.ps1` — 末尾 ANSI 颜色码：`esc "32m"` 绿 `"33m"` 黄 `"31m"` 红

**代理** `~\AppData\Roaming\nushell\env.nu` — 取消注释 `load-env` 行，改端口

</details>

## 已知问题

| 问题 | 解决 |
|------|------|
| WezTerm 启动不了 | 升级 NVIDIA 驱动 |
| Token 虚高 | 已内置去重，无需处理 |
| 字体装不上 | 关闭 WezTerm 再装 |
| 光标变白块 | ink/DECSCUSR，暂无解 |

## License

[MIT](LICENSE)
