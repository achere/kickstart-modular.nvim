# Neovim config (kickstart.nvim fork)

Lua config under `lua/` (`keymaps.lua`, `kickstart/plugins/`, `custom/plugins/`).
Upstream is merged in from the `upstream` remote.

## Conventions

- Keymap `desc` mnemonics: the bracketed letter must match the case of the key
  it stands for. `<leader>td` → `[t]oggle inline [d]iagnostics`; `<leader>sO` →
  `[s]earch [O]utline`. Upstream kickstart uses capitals everywhere; do not copy
  that. Applies to which-key group names and mnemonic comments too.

## Caveats

- `<leader>b` is the `[b]uffer` group (`<leader>bd`, `<leader>br`). Upstream's
  `kickstart/plugins/debug.lua` also maps bare `<leader>b` to toggle breakpoint, but
  that module is commented out in `lua/plugins.lua`, so there is no clash today.
  If you enable it, delete that line: `<leader>db` (in `keymaps.lua`) already toggles
  breakpoints.
- External edits (an agent changing a file open in nvim) are not picked up on their
  own: `autoread` only checks on focus, `:checktime` and shell commands, so the buffer
  and its LSP diagnostics stay stale. `<leader>br` runs `:checktime` on demand. A timer
  was rejected on purpose; unsaved buffers would hit the blocking W12 prompt.
- Diffview is the maintained fork `dlyongemallo/diffview-plus.nvim`, tracking `main`:
  its `vX.Y` tags fail vim.pack's strict semver, so `version = '*'` finds nothing.
  Diff-window colours (red old / green new for changed lines) and the cursor line are
  set per window through `winhighlight` in its `diff_buf_win_enter` hook
  (`custom/plugins/diffview.lua`). The colour values live in
  `custom/plugins/colorscheme.lua` (onedark `setup`). On diff lines Neovim draws an
  fg-less `CursorLine` as an underline, so the cursor-line groups are high-priority
  (ctermfg set) and their bg covers the diff colours. A window has one `CursorLine`,
  so a CursorMoved/DiffUpdated autocmd points it at `DiffCursorLineOld/New` when the
  cursor is on a diff line, else `DiffCursorLine`. A blended overlay (decoration
  provider) that keeps the changed-text colour was tried and dropped: Neovim blends
  the text colour too.
- `nvim_get_hl(0, { link = false })` follows the current window's `winhighlight`
  (`syn_get_final_id` uses curwin). Follow `link` by hand to read the global group.
