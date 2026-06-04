# ccNovaTerm Maintenance Guide

This file is a public reference for people who want to maintain or extend ccNovaTerm with Claude Code or another coding assistant. Keep it generic: do not add personal secrets, machine-specific absolute paths, or one-off local notes.

## Project Purpose

ccNovaTerm packages a Claude Code terminal environment:

- WezTerm for the terminal UI
- Nushell as the default shell
- Starship for the prompt
- Yazi for terminal file management
- Installer scripts for Windows and macOS

The repository contains reusable config templates plus installer logic. Local user configuration is generated from the templates during install.

## Platform Notes

Windows uses `install.ps1`.

- Nushell config target: `~/AppData/Roaming/nushell/`
- Yazi config target: `~/AppData/Roaming/yazi/config/`
- The Git for Windows `usr/bin` directory provides `file.exe`, used by Yazi previews.
- Run Windows installer tests with `test/test-install.ps1`.

macOS uses `install.sh`.

- Nushell config target: `~/Library/Application Support/nushell/`
- Yazi config target: `~/.config/yazi/`
- User binaries are installed to `~/.local/bin`.
- The installer writes `~/.local/bin` into `~/.zshrc` so tools such as `yazi`, `ya`, `nu`, `node`, and `claude` are available from new zsh sessions.
- Do not install Nushell, Starship, Yazi, or Node.js through Homebrew formulae by default. On older macOS releases, Homebrew may compile LLVM/Rust. Use upstream prebuilt releases or official installers instead.

## Important Constraints

Read `docs/compatibility-constraints.md` before editing files under `config/`.

- `.wezterm.lua` uses `__NU_PATH__`; installers replace it with the detected Nushell executable path.
- `env.nu` uses `__GIT_USR_BIN__` and `__LOCAL_BIN__`; installers replace them with platform paths.
- Keep proxy or API-key examples disabled in templates. Users can enable them locally after install.
- Yazi plugin dependencies belong in `config/yazi/package.toml`. The macOS installer restores them with `ya pkg install --discard`.
- `install.sh` must not require `sudo`; it installs user-level files and should never target root's home directory.
- `install.sh --skip-deps` should copy configs without downloading dependencies, but the default path should be one-command install.

## Common Workflows

Before changing behavior:

1. Check state with `git status -sb`.
2. Read the relevant files and docs first.
3. Keep edits scoped to the requested behavior.
4. Add or update tests when installer behavior changes.
5. Run the verification commands below before committing.

When editing terminal configs:

1. Read `docs/compatibility-constraints.md`.
2. Edit templates under `config/`.
3. Keep placeholders intact unless the installer and tests are updated at the same time.
4. If Yazi keybindings require plugins, update `config/yazi/package.toml`.

When editing install scripts:

1. Update the matching test script in `test/`.
2. Keep Windows and macOS behavior documented in both READMEs when user-facing behavior changes.
3. Prefer official prebuilt binaries on macOS to avoid long source builds.

## Verification

Use the checks that match the changed files:

```bash
bash -n install.sh
bash test/test-install.sh
git diff --check
```

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File test/test-install.ps1
```

For macOS installer changes, also run a local smoke test when possible:

```bash
./install.sh --dry-run
./install.sh --skip-deps --force --no-font
```

For GitHub publishing from macOS, make sure GitHub CLI is authenticated:

```bash
gh auth status
gh auth setup-git
git push origin main
```

## Documentation Map

- `README.md` and `README_CN.md`: user-facing install and usage docs.
- `docs/config-sync-workflow.md`: workflow for maintaining config-sync related behavior.
- `docs/compatibility-constraints.md`: placeholder and compatibility rules for managed config files.
- `test/`: installer regression tests.

## Commit Style

Use short, behavior-focused commit messages, for example:

- `Improve macOS one-click installer`
- `Document ccNovaTerm maintenance workflow`
- `Fix Yazi plugin restore on macOS`
