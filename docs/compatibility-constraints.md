# ccNovaTerm 兼容性约束

以下配置文件受版本管理。编辑本地文件时遵循占位符规则，否则同步冲突。

## .wezterm.lua → `~/.wezterm.lua`

- `default_prog` 用跨平台检测块：`if wezterm.target_triple == 'x86_64-pc-windows-msvc'` 时值为 `'__NU_PATH__'`，否则 `'nu'`
- **修改 default_prog**：改占位符不改变结构；改结构则模板和本地同步改
- 其他项（font、color_scheme、keys、hyperlink_rules、mouse_bindings）自由修改

## env.nu → `~/AppData/Roaming/nushell/env.nu`

- `$env.YAZI_FILE_ONE` 用 `__GIT_USR_BIN__` 占位符前缀
- **修改 YAZI_FILE_ONE**：保持 `__GIT_USR_BIN__` 前缀，只改后续路径
- **代理行（load-env）**：本地可激活，模板必须注释。自动保护，无需手动处理

## config.nu → `~/AppData/Roaming/nushell/config.nu`

- 直接拷贝，无占位符。包含 `alias cc = claude` 和 Yazi wrapper
- 修改后记得同步到模板

## starship.toml → `~/.config/starship.toml`

- 直接拷贝，无占位符。含 Nerd Font PUA 字符（`` `` `󰈙`）
- **关键**：写入必须 UTF-8 无 BOM（`[System.IO.File]::WriteAllText`），禁用 PS 默认 GBK
- 损坏症状：Nerd Font 字符变 `顐` `禲` `癩` 等 CJK 字符

## CLAUDE.local.md → `<项目根>/CLAUDE.local.md`

- 直接拷贝，无占位符。本文件自身也受版本管理
- 内容应通用化：不使用绝对路径，使用 `~` 表示 home 目录
- 修改后同步到 `config/CLAUDE.local.md`，其他人 clone 项目后可 `pull` 获得

## Yazi → `~/AppData/Roaming/yazi/config/*.toml` 或 `~/.config/yazi/*.toml`

- 模板位于 `config/yazi/`：`yazi.toml`、`keymap.toml`、`package.toml`
- `keymap.toml` 可引用插件命令；对应插件依赖必须同时记录在 `package.toml`
- 其它电脑部署后运行 `ya pkg install`，按 `package.toml` 锁定版本恢复插件
- `Enter` 当前绑定为 `plugin toggle-pane max-preview`，会覆盖 Yazi 默认打开/进入；使用 `l` 或 `→` 进入目录/打开文件
