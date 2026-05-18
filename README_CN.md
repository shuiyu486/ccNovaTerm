# ccNovaTerm

> **C**laude **C**ode + **Nova** **Term**inal — 一键打造 Claude Code 专属终端环境

[![English](https://img.shields.io/badge/lang-English-blue.svg)](./README.md)
[![中文](https://img.shields.io/badge/lang-中文-red.svg)](./README_CN.md)

一个自动化配置工具，将 [WezTerm](https://wezfurlong.org/wezterm/) + [Nushell](https://www.nushell.sh/) + [Starship](https://starship.rs/) + [Yazi](https://yazi-rs.github.io/) 打包为 Claude Code 的完美终端体验。

![ccNovaTerm](docs/hero.png)

## ✨ 特性

- 🚀 **一键安装** — 单条命令完成全部配置
- 🎨 **Catppuccin Mocha** — WezTerm、Starship 全局统一主题
- 🔤 **Nerd Font** — JetBrainsMono Nerd Font 开箱即用
- 🐚 **Nushell** — 现代化结构化 Shell，内置 `cc` 别名直达 Claude Code
- 📁 **Yazi** — 终端文件管理器，无缝集成
- 🔄 **config-sync** — Claude Code 技能，双向同步终端配置

## 📋 前置要求

| 工具 | 说明 |
|------|------|
| [WezTerm](https://wezfurlong.org/weizterm/) | GPU 加速终端模拟器 |
| [Nushell](https://www.nushell.sh/) | 结构化 Shell |
| [Starship](https://starship.rs/) | 可定制的 Shell 提示符 |
| [Yazi](https://yazi-rs.github.io/) | 终端文件管理器 |
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | AI 编程助手 CLI |
| [Git for Windows](https://git-scm.com/) | 版本控制（Windows 需要 `usr/bin` 中的 `file.exe`） |
| [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads) | 图标和符号支持 |

## 🚀 安装

### Windows

```powershell
irm https://raw.githubusercontent.com/shuiyu486/ccNovaTerm/main/install.ps1 | iex
```

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/shuiyu486/ccNovaTerm/main/install.sh | bash
```

安装脚本会：
1. 检测所有前置依赖
2. 用系统路径替换配置模板中的占位符
3. 将配置文件部署到正确位置
4. 备份已有配置

## 📁 项目结构

```
ccNovaTerm/
├── config/           ← 配置模板
│   ├── .wezterm.lua  ← WezTerm 配置（Catppuccin Mocha 主题）
│   ├── config.nu     ← Nushell 配置（别名、Yazi 集成）
│   ├── env.nu        ← Nushell 环境变量
│   ├── starship.toml ← Starship 提示符（Pastel Powerline）
│   └── CLAUDE.local.md ← 项目级 Claude Code 指令
├── docs/             ← 截图
├── test/             ← 测试脚本
├── install.ps1       ← Windows 安装脚本
├── install.sh        ← macOS 安装脚本
└── CLAUDE.local.md   ← 本文件
```

## 🔄 config-sync 技能

ccNovaTerm 包含一个 [Claude Code 技能](https://docs.anthropic.com/en/docs/claude-code/skills)，用于在本地环境和项目模板之间双向同步配置。

### 安装

```bash
/plugin install config-sync
```

### 使用

在 Claude Code 中直接说：

| 命令 | 操作 |
|------|------|
| "同步到本地" | 项目模板 → 本地配置 |
| "同步到项目" | 本地配置 → 项目模板 |
| "对比" | 显示本地与模板的差异 |
| "快速检查" | 验证配置兼容性 |

### 占位符

模板使用占位符，安装时自动替换为实际系统路径：

| 占位符 | 替换为 |
|--------|--------|
| `__NU_PATH__` | Nushell 可执行文件完整路径（Windows）或 `'nu'`（macOS） |
| `__GIT_USR_BIN__` | Git 安装目录下的 `usr/bin` 路径 |

## 🛠️ 自定义

所有配置文件都是标准的，可以直接编辑：

- **WezTerm**：编辑 `~/.wezterm.lua` — 字体、颜色、快捷键
- **Nushell**：编辑 `~/AppData/Roaming/nushell/config.nu`（Windows）或 `~/.config/nushell/config.nu`（macOS）
- **Starship**：编辑 `~/.config/starship.toml` — 提示符样式和模块
- **环境变量**：编辑 `~/AppData/Roaming/nushell/env.nu`（Windows）或 `~/.config/nushell/env.nu`（macOS）

修改后，使用 config-sync 的"同步到项目"将更改推回模板。

## 📸 截图

![安装过程](docs/install.png)

![状态栏](docs/statusline.png)

## 📄 许可证

MIT License — 详见 [LICENSE](LICENSE) 文件。
