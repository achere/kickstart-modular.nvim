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
