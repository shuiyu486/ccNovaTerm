﻿local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Auto-detect nushell path per OS (placeholder replaced by installer on Windows)
if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
  config.default_prog = { '__NU_PATH__' }
else
  config.default_prog = { 'nu' }
end
config.font = wezterm.font 'JetBrainsMono Nerd Font'
config.font_size = 11
config.color_scheme = 'Catppuccin Mocha'
config.window_padding = { left = 8, right = 8, top = 4, bottom = 4 }
config.initial_cols = 120
config.initial_rows = 32
config.enable_scroll_bar = true
config.window_decorations = 'RESIZE'
-- Kitty keyboard protocol disabled: interferes with Claude Code and other TUI apps
-- that don't decode Kitty CSI sequences (causes dropped characters like , [ and IME truncation)
config.enable_kitty_keyboard = false

config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 500

config.keys = {
  { key = 'v', mods = 'ALT', action = wezterm.action.PasteFrom 'Clipboard' },
  { key = 'c', mods = 'ALT', action = wezterm.action.CopyTo 'Clipboard' },
  { key = 't', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL|SHIFT', action = wezterm.action.CloseCurrentTab { confirm = true } },
  { key = 'd', mods = 'ALT', action = wezterm.action.SplitPane { direction = 'Right', size = { Percent = 50 } } },
  { key = 'd', mods = 'ALT|SHIFT', action = wezterm.action.SplitPane { direction = 'Down', size = { Percent = 50 } } },
  { key = 'LeftArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Right' },
  { key = 'UpArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Up' },
  { key = 'DownArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Down' },
  { key = 'x', mods = 'ALT', action = wezterm.action.CloseCurrentPane { confirm = true } },
  { key = 'h', mods = 'ALT', action = wezterm.action.Hide },
  { key = 'Enter', mods = 'SHIFT', action = wezterm.action.SendString '\x1b[13;2u' },
}

config.hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(config.hyperlink_rules, { regex = [[\b([A-Za-z]:[^\s<>(){}'"|&;]+)\b]], format = 'file:///$1' })
table.insert(config.hyperlink_rules, { regex = [[\b(/(?:[a-zA-Z0-9._-]+/)+[a-zA-Z0-9._-]+)\b]], format = 'file://$1' })

config.mouse_bindings = {
  { event = { Up = { streak = 1, button = 'Left' } }, mods = 'NONE', action = wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor 'Clipboard' },
  { event = { Up = { streak = 2, button = 'Left' } }, mods = 'NONE', action = wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor 'Clipboard' },
  { event = { Up = { streak = 3, button = 'Left' } }, mods = 'NONE', action = wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor 'Clipboard' },
  { event = { Down = { streak = 1, button = 'Right' } }, mods = 'NONE', action = wezterm.action_callback(function(window, pane)
    if window:get_selection_text_for_pane(pane) ~= '' then
      window:perform_action(wezterm.action.CopyTo 'Clipboard', pane)
      window:perform_action(wezterm.action.ClearSelection, pane)
    else
      window:perform_action(wezterm.action.PasteFrom 'Clipboard', pane)
    end
  end) },
}

return config
