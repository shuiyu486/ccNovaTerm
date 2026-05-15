## 终端环境

- **终端**：WezTerm（Catppuccin Mocha 主题，JetBrainsMono Nerd Font）
- **Shell**：Nushell | **Prompt**：Starship（Pastel Powerline） | **文件管理器**：Yazi
- **OS**：Windows 10/11

配置文件：`~/.wezterm.lua`、`~/AppData/Roaming/nushell/{env,config}.nu`、`~/.config/starship.toml`

## 项目结构（ccNovaTerm）

```
.
├── config/           ← 7 个配置模板（config-sync 管理）
│   ├── .wezterm.lua, config.nu, env.nu, starship.toml
│   ├── statusline.ps1, settings.json, CLAUDE.local.md
├── docs/             ← 截图（hero.png, install.png, statusline.png）
├── test/             ← test-install.ps1
├── install.ps1       ← Windows 安装脚本
├── install.sh        ← macOS 安装脚本
└── CLAUDE.local.md   ← 本文件（受 config-sync 管理）
```

## 维护工作流

本项目是 **ccNovaTerm** 和 **config-sync 技能** 的开发和维护工作目录。常用操作：

**修改配置后**：
1. 编辑配置文件 → 说"快速检查"验证兼容性
2. 说"同步到项目"推送到 `config/` 模板
3. git commit + push 到远程仓库

**修改 config-sync 技能后**：
config-sync 技能源码位于 `~/.claude/plugins/marketplaces/terr-marketplace/plugins/config-sync/`（同时是 terr-marketplace 的 git 仓库）。修改流程：
1. 编辑技能文件（SKILL.md、references/*.md、scripts/*.ps1）
2. 运行验证确保无误：
   - `claude plugin validate ~/.claude/plugins/marketplaces/terr-marketplace` 检查插件结构
   - 说"快速检查"验证本地配置文件与模板兼容
3. 更新 `plugins/config-sync/.claude-plugin/plugin.json` 中的 `version` 字段
4. 同步更新 `.claude-plugin/marketplace.json` 中 config-sync 条目的 `version`
5. 提交并推送：
   ```
   cd ~/.claude/plugins/marketplaces/terr-marketplace
   git add plugins/config-sync/ .claude-plugin/marketplace.json
   git commit -m "sync: config-sync v<version> — <变更说明>"
   git pull --rebase && git push
   ```
   - 若 push 被 rejected（远程有新提交），先 `git pull --rebase` 再 push
6. 用户端执行 `/plugin install config-sync` 即可更新

**添加新的受管文件**：
1. 将文件放入 `config/` 目录
2. 在 config-sync SKILL.md 中添加文件映射（本地路径、模板路径、占位符规则）
3. 更新 `references/paths.md` 和对应方向的 reference 文件
4. 在本文件的兼容性约束章节添加新条目

**测试安装脚本**：
- `test/test-install.ps1` 验证本地配置是否正确
- 安装脚本通过占位符替换生成：`__NU_PATH__`、`__GIT_USR_BIN__`、`__USERNAME__`

**config-sync 的使用**：
- 本目录已在 config-sync 的自动发现路径中（`$PWD.Path` 优先匹配）
- 所有同步操作默认使用本地 `ccNovaTerm/` 作为模板源，无需远程获取

## ccNovaTerm 兼容性约束

以下 7 个文件受版本管理。编辑本地文件时遵循占位符规则，否则同步冲突。

### .wezterm.lua → `~/.wezterm.lua`
- `default_prog` 用跨平台检测块：`if wezterm.target_triple == 'x86_64-pc-windows-msvc'` 时值为 `'__NU_PATH__'`，否则 `'nu'`
- **修改 default_prog**：改占位符不改变结构；改结构则模板和本地同步改
- 其他项（font、color_scheme、keys、hyperlink_rules、mouse_bindings）自由修改

### env.nu → `~/AppData/Roaming/nushell/env.nu`
- `$env.YAZI_FILE_ONE` 用 `__GIT_USR_BIN__` 占位符前缀
- **修改 YAZI_FILE_ONE**：保持 `__GIT_USR_BIN__` 前缀，只改后续路径
- **代理行（load-env）**：本地可激活，模板必须注释。自动保护，无需手动处理

### config.nu → `~/AppData/Roaming/nushell/config.nu`
- 直接拷贝，无占位符。包含 `alias cc = claude` 和 Yazi wrapper
- 修改后记得同步到模板

### starship.toml → `~/.config/starship.toml`
- 直接拷贝，无占位符。含 Nerd Font PUA 字符（`` `` `󰈙`）
- **关键**：写入必须 UTF-8 无 BOM（`[System.IO.File]::WriteAllText`），禁用 PS 默认 GBK
- 损坏症状：Nerd Font 字符变 `顐` `禲` `癩` 等 CJK 字符

### settings.json → `~/.claude/settings.json`
- 模板只含 `statusLine` 字段，用户名用 `__USERNAME__` 占位符
- **修改 statusLine**：路径中用户名部分用 `__USERNAME__`
- 本地改其他字段（model、permissions、env）自由，同步自动过滤

### statusline.ps1 → `~/.claude/statusline.ps1`
- 直接拷贝，无占位符

### CLAUDE.local.md → `<项目根>/CLAUDE.local.md`
- 直接拷贝，无占位符。本文件自身也受版本管理
- 内容应通用化：不使用绝对路径，使用 `~` 表示 home 目录
- 修改后同步到 `config/CLAUDE.local.md`，其他人 clone 项目后可 `pull` 获得
