# ccNovaTerm 兼容性约束

以下配置文件受版本管理。编辑本地文件时遵循占位符规则，否则同步冲突。

## .wezterm.lua → `~/.wezterm.lua`

- `default_prog` 使用 `__NU_PATH__` 占位符，安装器会替换为检测到的 Nushell 绝对路径
- **修改 default_prog**：保持 `__NU_PATH__` 语义；如果改变结构，必须同步更新 Windows/macOS 安装脚本和测试
- 其他项（font、color_scheme、keys、hyperlink_rules、mouse_bindings）自由修改

## env.nu → `~/AppData/Roaming/nushell/env.nu` 或 `~/Library/Application Support/nushell/env.nu`

- `$env.PATH` 用 `__LOCAL_BIN__` 占位符前缀，macOS 安装器会替换为 `~/.local/bin`
- `$env.YAZI_FILE_ONE` 用 `__GIT_USR_BIN__` 占位符前缀
- **修改 PATH 或 YAZI_FILE_ONE**：保持占位符前缀，只改后续逻辑；若占位符变化，必须同步更新安装脚本、README 和测试
- **代理行（load-env）**：本地可激活，模板必须注释。自动保护，无需手动处理

## config.nu → `~/AppData/Roaming/nushell/config.nu`

- 直接拷贝，无占位符。包含 `alias cc = claude`、`claude-env` 通用启动命令、兼容旧命名的 `claude-dpv4` 和 Yazi wrapper
- `claude-env` 只提供通用 wrapper；真实 API endpoint、token 和模型写在用户本机的 env 脚本中，不提交到模板；脚本路径可通过 `claude-env --env-script <path>` 或 `CLAUDE_ENV_SCRIPT` 指定，未指定时默认读取 `~/.claude/claude-env.nu`；脚本必须设置 `ANTHROPIC_BASE_URL`、`ANTHROPIC_AUTH_TOKEN` 和 `ANTHROPIC_MODEL`
- 修改后记得同步到模板

## starship.toml → `~/.config/starship.toml`

- 直接拷贝，无占位符。含 Nerd Font PUA 字符（`` `` `󰈙`）
- **关键**：写入必须 UTF-8 无 BOM（`[System.IO.File]::WriteAllText`），禁用 PS 默认 GBK
- 损坏症状：Nerd Font 字符变 `顐` `禲` `癩` 等 CJK 字符

## CLAUDE.local.md → `<项目根>/CLAUDE.local.md`

- 这是公开维护指南，不是终端配置模板，不放入 `config/`
- 内容应通用化：不写个人密钥、本机绝对路径或只适用于单台机器的临时记忆
- 修改后直接提交根目录文件即可

## Yazi → `~/AppData/Roaming/yazi/config/*.toml` 或 `~/.config/yazi/*.toml`

- 模板位于 `config/yazi/`：`yazi.toml`、`keymap.toml`、`package.toml`
- `keymap.toml` 可引用插件命令；对应插件依赖必须同时记录在 `package.toml`
- 其它电脑部署后运行 `ya pkg install`，按 `package.toml` 锁定版本恢复插件；macOS 安装器会自动执行 `ya pkg install --discard`
- `Enter` 当前绑定为 `plugin toggle-pane max-preview`，会覆盖 Yazi 默认打开/进入；使用 `l` 或 `→` 进入目录/打开文件

## macOS zsh PATH → `~/.zshrc`

- macOS 安装器会把 `export PATH="$HOME/.local/bin:$PATH"` 追加到 `~/.zshrc`
- 修改该行为时必须同步更新 `test/test-install.sh`，避免 Yazi、Nushell、Node.js 等已安装但 zsh 找不到
