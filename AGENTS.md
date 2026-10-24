# Neovim config (kickstart.nvim fork)

Lua config under `lua/` (`keymaps.lua`, `kickstart/plugins/`, `custom/plugins/`).
Upstream is merged in from the `upstream` remote.

## Conventions

- Keymap `desc` mnemonics: the bracketed letter must match the case of the key
  it stands for. `<leader>td` → `[t]oggle inline [d]iagnostics`; `<leader>sO` →
  `[s]earch [O]utline`. Upstream kickstart uses capitals everywhere; do not copy
  that. Applies to which-key group names and mnemonic comments too.
