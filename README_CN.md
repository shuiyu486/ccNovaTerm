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
| [WezTerm](https://wezfurlong.org/wezterm/) | GPU 加速终端模拟器 |
| [Nushell](https://www.nushell.sh/) | 结构化 Shell |
| [Starship](https://starship.rs/) | 可定制的 Shell 提示符 |
| [Yazi](https://yazi-rs.github.io/) | 终端文件管理器 |
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | AI 编程助手 CLI |
| [Git for Windows](https://git-scm.com/) | 版本控制（Windows 需要 `usr/bin` 中的 `file.exe`） |
| [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads) | 图标和符号支持 |

## 🚀 安装

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

macOS 脚本会自动安装核心终端环境并部署配置，包括 Homebrew、WezTerm、JetBrainsMono Nerd Font、Nushell、Starship、Yazi、Node.js 和 Claude Code。Nushell、Yazi 和 Node.js 会从官方上游 release 安装，Starship 会通过官方预编译安装脚本安装；这些工具都放到 `~/.local/bin`，不再走 Homebrew，从而避开旧系统（例如 macOS 12 Monterey）上的 LLVM/Rust 重型构建。不要使用 `sudo` 运行安装脚本；它会把用户配置安装到 root 环境。若 shell 提示没有执行权限，先运行 `chmod +x install.sh`。

高级用法：

| 命令 | 用途 |
|------|------|
| `./install.sh --dry-run` | 预览会安装哪些依赖、会写入哪些配置，不修改系统 |
| `./install.sh --force` | 跳过 ccNovaTerm 的确认提示，适合自动化环境 |
| `./install.sh --skip-deps` | 不安装依赖，只复制配置文件 |
| `./install.sh --no-font` | 跳过 Nerd Font 检测和安装 |

macOS 常见情况：

| 输出 | 含义 | 处理 |
|------|------|------|
| `This installer is macOS only` | 在非 macOS 环境运行了 `install.sh` | Windows 使用 `install.ps1`，macOS 使用 `install.sh` |
| `sudo: ./install.sh: command not found` 或 `permission denied` | 脚本没有执行权限，或使用了 `sudo` | 运行 `chmod +x install.sh`，然后直接执行 `./install.sh` |
| `[X] WezTerm/Nushell/... -- not found` | 脚本检测到依赖缺失 | 正常情况下继续确认即可，脚本会自动安装缺失依赖 |
| `Nushell -- not found` | Nushell 未安装 | 正常情况下继续确认即可，脚本会从官方 GitHub release 安装到 `~/.local/bin` |
| `Starship -- not found` | Starship 未安装 | 正常情况下继续确认即可，脚本会用官方预编译安装脚本安装到 `~/.local/bin` |
| `Yazi -- not found` | Yazi 未安装 | 正常情况下继续确认即可，脚本会从官方 GitHub release 安装到 `~/.local/bin` |
| `Node.js/npm -- not found` | Node.js 或 npm 未安装 | 正常情况下继续确认即可，脚本会安装最新版 Node.js LTS 到 `~/.local/bin` |
| `Homebrew not found` | 系统没有 Homebrew | 正常情况下脚本会调用官方安装脚本，期间可能要求输入 macOS 密码；也可先手动安装 Homebrew 后重试 |
| `Dependency installation did not complete` | 某个依赖安装失败 | 查看上方具体失败项，修复后重新运行 `./install.sh` |
| `ya command not found` | Yazi 不可用，插件未恢复 | 重新运行 `./install.sh`；若只想手动恢复插件，运行 `YAZI_CONFIG_HOME="$HOME/.config/yazi" ya pkg install` |
| `Config files installed; required software is still missing` | 使用了 `--skip-deps` 只复制配置 | 重新运行 `./install.sh` 完成依赖安装和验证 |

macOS 默认安装脚本会：
1. 检测并安装缺失依赖
2. 用系统路径替换配置模板中的占位符
3. 备份已有配置
4. 将配置文件部署到正确位置
5. 从上游预编译发布包安装 Nushell、Starship、Yazi 和 Node.js 到 `~/.local/bin`
6. 根据 `package.toml` 恢复 Yazi 插件

## 📁 项目结构

```
ccNovaTerm/
├── config/           ← 配置模板
│   ├── .wezterm.lua  ← WezTerm 配置（Catppuccin Mocha 主题）
│   ├── config.nu     ← Nushell 配置（别名、Yazi 集成）
│   ├── env.nu        ← Nushell 环境变量
│   ├── starship.toml ← Starship 提示符（Pastel Powerline）
│   └── yazi/         ← Yazi 配置与插件锁定文件
├── docs/             ← 截图
├── test/             ← 测试脚本
├── install.ps1       ← Windows 安装脚本
├── install.sh        ← macOS 安装脚本
└── CLAUDE.local.md   ← 给 Claude Code 或其他编程助手参考的维护指南
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
| `__NU_PATH__` | Nushell 可执行文件完整路径 |
| `__GIT_USR_BIN__` | Git 安装目录下的 `usr/bin` 路径 |
| `__LOCAL_BIN__` | 用户级二进制目录，例如 macOS 上的 `~/.local/bin` |

## 🛠️ 自定义

所有配置文件都是标准的，可以直接编辑：

- **WezTerm**：编辑 `~/.wezterm.lua` — 字体、颜色、快捷键
- **Nushell**：编辑 `~/AppData/Roaming/nushell/config.nu`（Windows）或 `~/Library/Application Support/nushell/config.nu`（macOS）
- **Starship**：编辑 `~/.config/starship.toml` — 提示符样式和模块
- **环境变量**：编辑 `~/AppData/Roaming/nushell/env.nu`（Windows）或 `~/Library/Application Support/nushell/env.nu`（macOS）
- **Yazi**：编辑 `~/AppData/Roaming/yazi/config/*.toml`（Windows）或 `~/.config/yazi/*.toml`（macOS）；插件依赖记录在 `package.toml`，可用 `ya pkg install` 恢复

修改后，使用 config-sync 的"同步到项目"将更改推回模板。

## 📸 截图

![安装过程](docs/install.png)

![状态栏](docs/statusline.png)

## 📄 许可证

MIT License — 详见 [LICENSE](LICENSE) 文件。
