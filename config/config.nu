$env.config.shell_integration.osc133 = false

# cc: claude 的快捷别名
alias cc = claude

# Yazi wrapper - cd on exit
def --env y [...args] {
  let tmp = (mktemp -d -t yazi-cwd.XXXXXX)
  let yazi_cmd = (which yazi | get path.0)
  ^$yazi_cmd --cwd-file $tmp ...$args
  let cwd = (open $tmp)
  if $cwd != $env.PWD { cd $cwd }
  rm -f $tmp
}
