#!/bin/bash
# Wrapper for Claude Code statusLine on Windows.
# Claude Code does not close stdin pipe after writing JSON data,
# causing PowerShell to block forever on stdin reads.
# This script uses `timeout cat` to relay stdin to a temp file,
# then PowerShell reads the file instead.
JSON_FILE="/tmp/claude-statusline.json"
timeout 0.5 cat > "$JSON_FILE" 2>/dev/null
if [ -s "$JSON_FILE" ]; then
    powershell -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w ~/.claude/statusline.ps1)"
fi
