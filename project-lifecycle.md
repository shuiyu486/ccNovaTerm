# ccNovaTerm — Project project-lifecycle.md

## 项目定位

ccNovaTerm 是一套为 Claude Code 优化的跨平台终端配置包。用户克隆仓库后执行一条命令即可完成 WezTerm + Nushell + Starship + Yazi 全套配置。面向 Windows 和 macOS 用户。

## 仓库结构

```
ccNovaTerm/
├── README.md              # 英文文档（GitHub 默认展示）
├── README_CN.md           # 中文文档（README.md 顶部链接跳转）
├── LICENSE                # MIT
├── install.ps1            # Windows 安装脚本 (PowerShell 5.1)
├── install.sh             # macOS 安装脚本 (Bash)
├── config/                # 配置模板（跨平台共用）
│   ├── .wezterm.lua       # WezTerm 终端配置
│   ├── config.nu          # Nushell Shell 配置
│   ├── env.nu             # Nushell 环境变量
│   ├── starship.toml      # Starship 提示符
│   └── CLAUDE.local.md    # Claude Code 项目指令
├── docs/                  # README 图片
│   ├── hero.png           # 全终端截图 (1200×650)
│   ├── install.png        # 安装过程截图 (800×400)
│   └── statusline.png     # 状态栏特写 (800×60)
└── test/
    └── test-install.ps1   # Windows 集成测试套件
```

## 架构决策

### 配置模板 + 占位符 → 安装时替换

配置模板使用 `__PLACEHOLDER__` 标记，安装脚本在写入目标路径前替换：

| 占位符 | 替换为 | 影响文件 |
|--------|--------|---------|
| `__NU_PATH__` | `nu.exe` 完整路径（Windows 双反斜杠） | `.wezterm.lua` |
| `__GIT_USR_BIN__` | Git `usr/bin` 目录路径 | `env.nu` |

模板不能用实际路径，因为每台机器的安装位置不同。

### 状态栏已独立

状态栏功能已独立为 [cc-statusline 插件](https://github.com/shuiyu486/terr-marketplace)，不再由 ccNovaTerm 管理。用户通过 `/plugin install cc-statusline` + `/cc-statusline:setup` 安装。

### 跨平台路径差异

| 配置 | Windows 目标路径 | macOS 目标路径 |
|------|-----------------|---------------|
| WezTerm | `~/.wezterm.lua` | `~/.config/wezterm/wezterm.lua` |
| Nushell config | `~\AppData\Roaming\nushell\config.nu` | `~/Library/Application Support/nushell/config.nu` |
| Nushell env | `~\AppData\Roaming\nushell\env.nu` | `~/Library/Application Support/nushell/env.nu` |
| Starship | `~/.config/starship.toml` | `~/.config/starship.toml` |

WezTerm 配置通过 `wezterm.target_triple` 检测 OS，Windows 使用完整 nu.exe 路径，macOS 使用 `nu`（依赖 PATH）。

### install.ps1 → macOS 用户自动重定向

`install.ps1` 顶部检测 `$IsMacOS` 或 `sw_vers` 命令，如果是 macOS 则打印提示并退出，引导用户使用 `./install.sh`。PowerShell Core 用户仍可手动使用 `install.ps1`。

### 备份目录命名约定

- Windows：`~\ccNovaTerm-backup\yyyyMMdd_HHmmss\`
- macOS：`~/ccNovaTerm-backup/yyyyMMdd_HHmmss/`

### 状态栏缓存文件（已独立为 cc-statusline 插件）

缓存机制已迁移到 cc-statusline 插件中，使用 `cc-statusline-cache/ses-{PID}.txt`。

### Token 去重核心逻辑

Claude Code 每次 API 调用在 transcript JSONL 中产生 2-6 行 `type: "message"` + `role: "assistant"` 条目——思考块、文本块、工具调用块——它们的 `usage` 完全相同。逐行求和会使计数虚高 3-4 倍。

修复：扫描 `"usage"` 字段中的 `input_tokens + output_tokens + cache_creation_input_tokens + cache_read_input_tokens`，跳过与前一条已计数条目四个值全部相同的条目。

## 开发流程

### 修改配置模板

1. 编辑 `config/` 下的模板文件
2. 运行测试确认模板语法正确
3. 如果新增占位符，同步更新两个安装脚本的替换逻辑
4. 先 `-DryRun` 测试，再实装到一个临时目录验证

### 修改安装脚本

- `install.ps1`：必须兼容 PowerShell 5.1（无 `??`、`?.`、三元运算符、`-AsHashtable`）
- `install.sh`：必须兼容 Bash 3.2+（macOS 默认版本，无 `[[ ]]`、关联数组）
- 脚本新增 flag 要同时更新两个平台的参数表
- README 的参数表也需同步更新

### 修改状态栏

状态栏已独立为 cc-statusline 插件。修改流程：
1. 编辑 `~/.claude/plugins/marketplaces/terr-marketplace/plugins/cc-statusline/src/` 下的 TypeScript 源码
2. `npm run build` 编译
3. 用实际 transcript 测试 token 计数准确性
4. 检查 ANSI 颜色输出在 WezTerm 中显示正常

### 更新 README 图片

```powershell
# Windows 安装截图
$tmpHome = Join-Path $env:TEMP "nova-demo"; New-Item -ItemType Directory $tmpHome -Force | Out-Null
$env:USERPROFILE = $tmpHome
.\install.ps1 -Force -NoFont
# 截图 → docs/install.png
```

hero.png 需要展示完整终端环境（Starship 提示符 + claude 运行 + statusline），statusline.png 只需截底部两行。

## 测试

### Windows

```powershell
.\test\test-install.ps1
```

10 个测试用例覆盖：全新安装、备份、合并已有 settings、-DryRun 零写入、空文件处理、缺失 config/ 目录、特殊字符路径、配置文件语法冒烟测试。

工作方式：创建 temp 目录 → 重写 `$env:USERPROFILE` → 执行 `install.ps1 -Force` → 验证写入结果。

### macOS

目前 macOS 没有自动化测试套件。验证步骤：
1. 在干净 Mac 或 VM 上 `./install.sh --dry-run`
2. 确认路径检测正确
3. `./install.sh --force` 实际安装
4. 手动验证 WezTerm 启动、Nushell 加载、Starship 显示、statusline 输出

## 发布清单

1. [ ] 所有改动通过测试
2. [ ] README.md 和 README_CN.md 内容同步
3. [ ] 两个安装脚本版本号/日期更新
4. [ ] git diff 检查无硬编码用户名、API key、密码
5. [ ] 提交信息格式：`类型: 简述`（如 `feat: add X`, `fix: Y bug`）
6. [ ] `git push origin main`

## 兼容性约束

| 约束 | 原因 |
|------|------|
| PowerShell 5.1 | Windows 10/11 默认版本 |
| Bash 3.2 | macOS 默认版本 |
| WezTerm 2024+ | `config_builder()` API |
| Nushell 0.100+ | `def --env` 语法 |
| Claude Code v2.1+ | `transcript_path` 字段 |

## 未来规划

- [ ] macOS 自动化测试套件
- [ ] Linux 支持
- [ ] `irm ... | iex` 一键安装（不需 git clone）
- [ ] 配置更新命令（已安装用户增量更新）
- [ ] 主题切换器
- [ ] WezTerm 多标签自动命名

## 维护备忘

- 状态栏缓存格式变更（如 5→7→9 行）时，`$cl.Count -ge N` 校验会清掉旧缓存自动重建
- 缓存文件按 PID 隔离（`ses-{PID}.txt`），切换项目或新开窗口不会互相干扰
- 状态栏已独立为 cc-statusline 插件，不再由 ccNovaTerm 管理
- WezTerm 的 `window_decorations = 'RESIZE'` 是刻意为之——`INTEGRATED_BUTTONS` 会导致中文 IME 失效
- 鼠标绑定用 `Up` 事件而非 `Down`——避免拖拽选区异常
- `config.nu` 中 yazi 参数顺序 `--cwd-file $tmp ...$args` 不可颠倒
