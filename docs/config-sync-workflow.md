# config-sync 维护工作流

## 项目结构（ccNovaTerm）

```
.
├── config/           ← 配置模板（config-sync 管理）
│   ├── .wezterm.lua, config.nu, env.nu, starship.toml
│   └── yazi/         ← yazi.toml, keymap.toml, package.toml
├── docs/             ← 截图 + 参考文档
├── test/             ← test-install.ps1, test-install.sh
├── install.ps1       ← Windows 安装脚本
├── install.sh        ← macOS 安装脚本
└── CLAUDE.local.md   ← 维护指南（不作为 config 模板安装）
```

本项目是 **ccNovaTerm** 和 **config-sync 技能** 的开发和维护工作目录。

根目录 `CLAUDE.local.md` 是公开维护指南，用于帮助用户或编程助手理解本项目如何迭代；它不再放在 `config/` 下，也不作为终端配置同步到用户环境。

## 修改配置后

1. 编辑配置文件 → 说"快速检查"验证（对比远程仓库）
2. 说"同步到项目"推送（临时 clone → 写入 → git commit → git push → 清理）
3. 确认推送成功后，本地项目如有文档/技能变更，git commit + push

`config.nu` 中的 `claude-env` 是通用启动 wrapper；个人 API endpoint、token 和模型只放在用户本机 env 脚本里，并通过 `claude-env --env-script <path>` 或 `CLAUDE_ENV_SCRIPT` 指定，不应通过 config-sync 同步到项目模板。模板中的兼容标记 `CLAUDE_CODE_DISABLE_THINKING=1` 和 `CLAUDE_CODE_ALWAYS_ENABLE_EFFORT=1` 应保留。

## 修改 config-sync 技能后

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

## 添加新的受管文件

1. 将文件放入 `config/` 目录
2. 在 config-sync SKILL.md 中添加文件映射（本地路径、模板路径、占位符规则）
3. 更新 `references/paths.md` 和对应方向的 reference 文件
4. 在兼容性约束文档 `docs/compatibility-constraints.md` 中添加新条目

## 测试安装脚本

- `test/test-install.ps1` 验证 Windows 安装脚本
- `test/test-install.sh` 验证 macOS 安装脚本
- 安装脚本通过占位符替换生成：`__NU_PATH__`、`__GIT_USR_BIN__`、`__LOCAL_BIN__`
- macOS 默认安装策略使用上游预编译发布包和 `~/.local/bin`，避免 Homebrew 在旧系统上编译 LLVM/Rust

## config-sync 的使用

- 同步操作始终以远程仓库（GitHub）为模板基准，不依赖本地项目
- 本地项目（本目录）仅用于编辑技能文件、文档，以及作为 git 工作区
- push 操作通过临时 clone 完成，自动清理
