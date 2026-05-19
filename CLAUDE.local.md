## 终端环境

- **终端**：WezTerm（Catppuccin Mocha，JetBrainsMono Nerd Font）
- **Shell**：Nushell | **Prompt**：Starship（Pastel Powerline） | **文件管理器**：Yazi
- **OS**：Windows 10/11

配置文件：`~/.wezterm.lua`、`~/AppData/Roaming/nushell/{env,config}.nu`、`~/.config/starship.toml`

## 项目

ccNovaTerm + config-sync 技能开发工作目录。

## 常用操作

- **修改配置文件后**：说"快速检查"验证 → 说"同步到项目"推送模板 → git commit + push
- **修改 config-sync 技能**：先读取 `docs/config-sync-workflow.md`
- **编辑受管配置文件时**：先读取 `docs/compatibility-constraints.md`
- **测试安装脚本**：`test/test-install.ps1`
- **config-sync 同步**：所有操作以远程仓库为准，本地项目仅用于编辑技能/文档和 git push
