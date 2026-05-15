用户长期使用的终端环境：
- **终端**：WezTerm（Catppuccin Mocha 主题，JetBrainsMono Nerd Font）
- **Shell**：Nushell
- **Prompt**：Starship（Pastel Powerline 预设）
- **文件管理器**：Yazi（通过 nushell wrapper 实现退出时 cd）
- **操作系统**：Windows 10/11

配置文件位置：
- WezTerm：`~/.wezterm.lua`
- Nushell：`~/AppData/Roaming/nushell/env.nu` 和 `config.nu`
- Starship：`~/.config/starship.toml`

给建议时应考虑：
- Shell 命令用 nushell 语法（不是 bash/zsh）
- 快捷键体系：Alt+C/V 复制粘贴，Alt+D 分屏，Alt+方向键切换分屏
- 右键复制/粘贴（CMD 风格）

## ccNovaTerm 兼容性约束

以下 6 个文件受 ccNovaTerm 版本管理（本地 ccNovaTerm 项目的 `config/` 目录），编辑本地文件时必须遵守模板规则，否则同步时会冲突。

### .wezterm.lua → `~/.wezterm.lua`
- `default_prog` 使用跨平台检测块（`if wezterm.target_triple == 'x86_64-pc-windows-msvc'`），Windows 分支值为 `'__NU_PATH__'`，macOS 分支值为 `'nu'`
- **修改 default_prog 时**：只改占位符不改变结构，改结构则两边（模板+本地）同步改
- 其他配置项（font、color_scheme、keys、hyperlink_rules、mouse_bindings）自由修改，不影响模板兼容

### env.nu → `~/AppData/Roaming/nushell/env.nu`
- `$env.YAZI_FILE_ONE` 路径使用 `__GIT_USR_BIN__` 占位符（如 `__GIT_USR_BIN__\\file.exe`）
- **修改 YAZI_FILE_ONE 时**：保持 `__GIT_USR_BIN__` 占位符前缀，只改后续路径
- **代理行（load-env）**：本地可激活，模板中必须保持注释状态。此规则自动保护，无需手动处理

### config.nu → `~/AppData/Roaming/nushell/config.nu`
- 直接拷贝，无占位符。包含 `alias cc = claude` 和 Yazi wrapper 函数
- **修改时无特殊约束**，但修改后记得同步到模板

### starship.toml → `~/.config/starship.toml`
- 直接拷贝，无占位符。包含 Nerd Font PUA 字符（如 `` `` `󰈙`）
- **关键**：写入时必须用 UTF-8 无 BOM（`[System.IO.File]::WriteAllText`），绝不能用 PowerShell 默认 GBK 编码
- 编码损坏症状：Nerd Font 字符变成 `顐` `禲` `癩` 等 CJK 字符

### settings.json → `~/.claude/settings.json`
- 模板**只含 `statusLine` 字段**，用户名为 `__USERNAME__` 占位符
- **修改 statusLine 时**：路径中的用户名部分用 `__USERNAME__`
- **本地 settings.json 改其他字段**（model、permissions、env 等）：自由修改，同步时会自动过滤

### statusline.ps1 → `~/.claude/statusline.ps1`
- 直接拷贝，无占位符。**修改时无特殊约束**

### 快速兼容检查
如需验证本地修改是否与模板兼容，使用 `config-sync` 的快速检查模式即可——无需完整对比。
