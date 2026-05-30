# Starship prompt
$env.STARSHIP_SHELL = "nu"
$env.PROMPT_COMMAND = { || starship prompt --cmd-duration $env.CMD_DURATION_MS }
$env.PROMPT_COMMAND_RIGHT = ""

# Yazi file manager - file type detection
$env.YAZI_FILE_ONE = "__GIT_USR_BIN__\\file.exe"

# Proxy (uncomment and edit if needed)
# load-env { http_proxy: "http://127.0.0.1:7890", https_proxy: "http://127.0.0.1:7890" }
