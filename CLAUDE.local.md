# ccNovaTerm 维护指南

这个文件是公开的项目维护参考，给想用 Claude Code 或其他编程助手继续开发、调整、迭代 ccNovaTerm 的人使用。内容应保持通用：不要写入个人密钥、本机绝对路径，或只适用于某一台机器的临时记忆。

## 项目目标

ccNovaTerm 打包了一套 Claude Code 专用终端环境：

- WezTerm：终端界面
- Nushell：默认 Shell
- Starship：命令行提示符
- Yazi：终端文件管理器
- Windows 和 macOS 安装脚本

仓库里保存的是可复用的配置模板和安装逻辑。用户本机配置由安装器根据模板生成。

## 平台差异

Windows 使用 `install.ps1`。

- Nushell 配置目标目录：`~/AppData/Roaming/nushell/`
- Yazi 配置目标目录：`~/AppData/Roaming/yazi/config/`
- Git for Windows 的 `usr/bin` 目录提供 `file.exe`，用于 Yazi 预览文件类型检测。
- Windows 安装器测试命令：`test/test-install.ps1`

macOS 使用 `install.sh`。

- Nushell 配置目标目录：`~/Library/Application Support/nushell/`
- Yazi 配置目标目录：`~/.config/yazi/`
- 用户级二进制文件安装到 `~/.local/bin`
- 安装器会把 `~/.local/bin` 写入 `~/.zshrc`，让新开的 zsh 会话可以直接找到 `yazi`、`ya`、`nu`、`node`、`claude` 等命令。
- 默认不要通过 Homebrew formula 安装 Nushell、Starship、Yazi、Node.js。旧 macOS 上 Homebrew 可能会编译 LLVM/Rust，应优先使用上游预编译 release 或官方安装器。

## 重要约束

编辑 `config/` 下的文件前，先阅读 `docs/compatibility-constraints.md`。

- `.wezterm.lua` 使用 `__NU_PATH__` 占位符；安装器会替换为检测到的 Nushell 可执行文件路径。
- `env.nu` 使用 `__GIT_USR_BIN__` 和 `__LOCAL_BIN__` 占位符；安装器会替换为对应平台路径。
- 模板里的代理或 API key 示例必须保持禁用状态。用户安装后可在本机按需启用。
- Yazi 插件依赖应记录在 `config/yazi/package.toml`。macOS 安装器会用 `ya pkg install --discard` 恢复插件。
- `install.sh` 不应要求 `sudo`；它只安装用户级文件，不能写入 root 的 home 目录。
- `install.sh --skip-deps` 应只复制配置、不下载依赖；默认路径应保持一键安装体验。

## 常用流程

修改行为前：

1. 用 `git status -sb` 确认工作区状态。
2. 先读相关文件和文档。
3. 只改和当前目标有关的内容。
4. 安装器行为变化时，同步新增或更新测试。
5. 提交前运行下面的验证命令。

编辑终端配置时：

1. 阅读 `docs/compatibility-constraints.md`。
2. 修改 `config/` 下的模板文件。
3. 保持占位符语义不变；如果必须改占位符，同时更新安装器和测试。
4. 如果 Yazi 快捷键依赖插件，同步更新 `config/yazi/package.toml`。

编辑安装脚本时：

1. 更新 `test/` 下对应平台的测试脚本。
2. 如果用户可见行为变化，同步更新 `README.md` 和 `README_CN.md`。
3. macOS 上优先使用官方预编译二进制，避免触发长时间源码编译。

## 验证命令

按改动范围选择验证命令：

```bash
bash -n install.sh
bash test/test-install.sh
git diff --check
```

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File test/test-install.ps1
```

修改 macOS 安装器时，条件允许的话再做本机烟测：

```bash
./install.sh --dry-run
./install.sh --skip-deps --force --no-font
```

在 macOS 上推送 GitHub 前，确认 GitHub CLI 已登录：

```bash
gh auth status
gh auth setup-git
git push origin main
```

## 文档地图

- `README.md` 和 `README_CN.md`：面向用户的安装和使用说明。
- `docs/config-sync-workflow.md`：维护 config-sync 相关行为的工作流。
- `docs/compatibility-constraints.md`：受管配置文件的占位符和兼容性约束。
- `test/`：安装器回归测试。

## 提交风格

提交信息保持简短，描述行为变化，例如：

- `Improve macOS one-click installer`
- `Document ccNovaTerm maintenance workflow`
- `Fix Yazi plugin restore on macOS`
