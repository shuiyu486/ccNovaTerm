$env.config.shell_integration.osc133 = false

# cc: claude 的快捷别名
alias cc = claude

# claude-dpv4: 使用本机私有脚本临时切换 Claude Code API/模型。
# 默认 claude/cc 仍使用 ~/.claude/settings.json；此命令启动时复制主配置，
# 只覆盖模型/API 相关 env。可用 CLAUDE_DPV4_ENV_SCRIPT 指定脚本路径。
def --wrapped claude-dpv4 [...args: string] {
  let main_settings = ('~/.claude/settings.json' | path expand)
  let dpv4_env_script = (($env.CLAUDE_DPV4_ENV_SCRIPT? | default '~/.claude/set-cc-dpv4-env.nu') | path expand)

  if not ($dpv4_env_script | path exists) {
    error make { msg: $'找不到 DPV4 环境脚本：($dpv4_env_script)。请创建该脚本，或设置 CLAUDE_DPV4_ENV_SCRIPT 指向你的脚本。' }
  }

  let main = if ($main_settings | path exists) { open $main_settings } else { {} }
  let base_env = ($main.env? | default {})
  let script_literal = ($dpv4_env_script | to nuon)
  let capture_cmd = (
    'with-env { CC_DPV4_QUIET: "true" } { hide-env --ignore-errors ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL ANTHROPIC_DEFAULT_HAIKU_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_HAIKU_MODEL_NAME ANTHROPIC_DEFAULT_SONNET_MODEL_NAME ANTHROPIC_DEFAULT_OPUS_MODEL_NAME; source-env '
    + $script_literal
    + '; { ANTHROPIC_BASE_URL: ($env.ANTHROPIC_BASE_URL? | default null), ANTHROPIC_AUTH_TOKEN: ($env.ANTHROPIC_AUTH_TOKEN? | default null), ANTHROPIC_MODEL: ($env.ANTHROPIC_MODEL? | default null), ANTHROPIC_DEFAULT_HAIKU_MODEL: ($env.ANTHROPIC_DEFAULT_HAIKU_MODEL? | default null), ANTHROPIC_DEFAULT_SONNET_MODEL: ($env.ANTHROPIC_DEFAULT_SONNET_MODEL? | default null), ANTHROPIC_DEFAULT_OPUS_MODEL: ($env.ANTHROPIC_DEFAULT_OPUS_MODEL? | default null), ANTHROPIC_DEFAULT_HAIKU_MODEL_NAME: ($env.ANTHROPIC_DEFAULT_HAIKU_MODEL_NAME? | default null), ANTHROPIC_DEFAULT_SONNET_MODEL_NAME: ($env.ANTHROPIC_DEFAULT_SONNET_MODEL_NAME? | default null), ANTHROPIC_DEFAULT_OPUS_MODEL_NAME: ($env.ANTHROPIC_DEFAULT_OPUS_MODEL_NAME? | default null) } | transpose key value | where value != null | transpose -r -d | to json -r }'
  )
  let captured = (^nu --commands $capture_cmd | complete)

  if $captured.exit_code != 0 {
    error make { msg: '读取 DPV4 环境脚本失败。请确认脚本语法正确，并且不要在静默模式下输出非必要内容。' }
  }

  let output_lines = ($captured.stdout | lines)
  if (($output_lines | length) == 0) {
    error make { msg: 'DPV4 环境脚本没有产生可用的模型/API 配置。' }
  }

  let dpv4_env = ($output_lines | last | from json)
  let dpv4_columns = ($dpv4_env | columns)
  if (($dpv4_columns | length) == 0) {
    error make { msg: 'DPV4 环境脚本没有设置任何模型/API 相关变量。' }
  }
  for required in [ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL] {
    if not ($required in $dpv4_columns) {
      error make { msg: $'DPV4 环境脚本缺少必要变量：($required)。请检查脚本或对应 token 环境变量。' }
    }
  }

  let model = ($dpv4_env.ANTHROPIC_MODEL? | default null)
  let patched = if $model == null {
    $main | upsert env ($base_env | merge $dpv4_env)
  } else {
    $main | upsert model $model | upsert env ($base_env | merge $dpv4_env)
  }

  let generated_settings = (mktemp -t claude-dpv4-settings.XXXXXX.json)
  $patched | save -f $generated_settings
  ^claude --settings $generated_settings ...$args
  rm -f $generated_settings
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
