$env.config.shell_integration.osc133 = false

# cc: claude 的快捷别名
alias cc = claude

# claude-env: 使用本机私有脚本临时切换 Claude Code API/模型。
# 默认 claude/cc 仍使用 ~/.claude/settings.json；此命令启动时复制主配置，
# 排除 NO_PROXY 后只覆盖模型/API 相关 env。脚本路径可用 --env-script 或 CLAUDE_ENV_SCRIPT 指定。
def --wrapped claude-env [
  --env-script: string # 本次启动使用的环境脚本路径；未指定时读取 CLAUDE_ENV_SCRIPT 或 ~/.claude/claude-env.nu。
  ...args: string
] {
  let main_settings = ('~/.claude/settings.json' | path expand)
  let script_from_flag = ($env_script | default null)
  let script_from_env = ($env.CLAUDE_ENV_SCRIPT? | default null)
  let launcher_env_script = ((
    if $script_from_flag != null {
      $script_from_flag
    } else if $script_from_env != null {
      $script_from_env
    } else {
      '~/.claude/claude-env.nu'
    }
  ) | path expand)

  if not ($launcher_env_script | path exists) {
    error make { msg: $'找不到 Claude 环境脚本：($launcher_env_script)。请创建该脚本，或用 claude-env --env-script <path> / CLAUDE_ENV_SCRIPT 指向你的脚本。' }
  }
  print $'claude-env 使用环境脚本：($launcher_env_script)'

  let main = if ($main_settings | path exists) { open $main_settings } else { {} }
  let base_env = ($main.env? | default {})
  let copied_env = if ('NO_PROXY' in ($base_env | columns)) { $base_env | reject NO_PROXY } else { $base_env }
  let script_literal = ($launcher_env_script | to nuon)
  let capture_cmd = (
    'with-env { CLAUDE_ENV_QUIET: "true" } { hide-env --ignore-errors ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL ANTHROPIC_DEFAULT_HAIKU_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_HAIKU_MODEL_NAME ANTHROPIC_DEFAULT_SONNET_MODEL_NAME ANTHROPIC_DEFAULT_OPUS_MODEL_NAME; source-env '
    + $script_literal
    + '; { ANTHROPIC_BASE_URL: ($env.ANTHROPIC_BASE_URL? | default null), ANTHROPIC_AUTH_TOKEN: ($env.ANTHROPIC_AUTH_TOKEN? | default null), ANTHROPIC_MODEL: ($env.ANTHROPIC_MODEL? | default null), ANTHROPIC_DEFAULT_HAIKU_MODEL: ($env.ANTHROPIC_DEFAULT_HAIKU_MODEL? | default null), ANTHROPIC_DEFAULT_SONNET_MODEL: ($env.ANTHROPIC_DEFAULT_SONNET_MODEL? | default null), ANTHROPIC_DEFAULT_OPUS_MODEL: ($env.ANTHROPIC_DEFAULT_OPUS_MODEL? | default null), ANTHROPIC_DEFAULT_HAIKU_MODEL_NAME: ($env.ANTHROPIC_DEFAULT_HAIKU_MODEL_NAME? | default null), ANTHROPIC_DEFAULT_SONNET_MODEL_NAME: ($env.ANTHROPIC_DEFAULT_SONNET_MODEL_NAME? | default null), ANTHROPIC_DEFAULT_OPUS_MODEL_NAME: ($env.ANTHROPIC_DEFAULT_OPUS_MODEL_NAME? | default null) } | transpose key value | where value != null | transpose -r -d | to json -r }'
  )
  let captured = (^nu --commands $capture_cmd | complete)

  if $captured.exit_code != 0 {
    error make { msg: '读取 Claude 环境脚本失败。请确认脚本语法正确，并且不要在静默模式下输出非必要内容。' }
  }

  let output_lines = ($captured.stdout | lines)
  if (($output_lines | length) == 0) {
    error make { msg: 'Claude 环境脚本没有产生可用的模型/API 配置。' }
  }

  let launcher_env = ($output_lines | last | from json)
  let launcher_columns = ($launcher_env | columns)
  if (($launcher_columns | length) == 0) {
    error make { msg: 'Claude 环境脚本没有设置任何模型/API 相关变量。' }
  }
  for required in [ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL] {
    if not ($required in $launcher_columns) {
      error make { msg: $'Claude 环境脚本缺少必要变量：($required)。请检查脚本或对应 token 环境变量。' }
    }
  }

  let model = ($launcher_env.ANTHROPIC_MODEL? | default null)
  let effective_env = ($launcher_env | merge {
    CLAUDE_CODE_DISABLE_THINKING: "1"
    CLAUDE_CODE_ALWAYS_ENABLE_EFFORT: "1"
  })
  let patched = if $model == null {
    $main | upsert env ($copied_env | merge $effective_env)
  } else {
    $main | upsert model $model | upsert env ($copied_env | merge $effective_env)
  }

  let generated_settings = (mktemp -t claude-env-settings.XXXXXX.json)
  try {
    $patched | save -f $generated_settings
    ^claude --settings $generated_settings ...$args
    rm -f $generated_settings
  } catch {|err|
    rm -f $generated_settings
    error make $err
  }
}

# Yazi wrapper - cd on exit
def --env y [...args] {
  let tmp = (mktemp -d -t yazi-cwd.XXXXXX)
  let yazi_cmd = (which yazi | get path.0)
  ^$yazi_cmd --cwd-file $tmp ...$args
  let cwd = (open $tmp)
  if $cwd != $env.PWD { cd $cwd }
  rm -f $tmp
}
