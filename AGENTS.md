# Neovim config (kickstart.nvim fork)

Lua config under `lua/` (`keymaps.lua`, `kickstart/plugins/`, `custom/plugins/`).
Upstream is merged in from the `upstream` remote.

## Conventions

- Keymap `desc` mnemonics: the bracketed letter must match the case of the key
  it stands for. `<leader>td` → `[t]oggle inline [d]iagnostics`; `<leader>sO` →
  `[s]earch [O]utline`. Upstream kickstart uses capitals everywhere; do not copy
  that. Applies to which-key group names and mnemonic comments too.

## Formatting

`stylua` formats Lua with `.stylua.toml` (also run on save by conform). Format only
your own files; skip `lua/kickstart/`: it is upstream code, and a reformat conflicts
with the next `upstream` merge.

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
- `:Review base..head [+line|-line] [-- paths]` (`custom/plugins/review.lua`) is the
  entry point for scripts (`nvim -c 'Review a..b'`): it shows the range's changes
  under nvim's cwd. Its header comment is the API reference: update it with any change
  to the command. Callers depend on `:Review`, not diffview; only `open_diff` knows
  the plugin. It passes `-C<cwd>` because diffview otherwise picks the current
  buffer's repo. Commits are checked with `rev-parse --verify <rev>^{commit}`: without
  `^{commit}`, any well-formed full SHA passes even when the commit is missing.
- `+N` / `-N` (unified-diff signs: new / old side, one path only) put the cursor on a
  line of that side's window and focus it; a line past the end clamps silently.
  `open_diff` does it with a one-shot listener on `DiffviewGlobal.emitter`'s
  `diff_buf_win_enter` (the event behind the hook in `diffview.lua`; a plugin
  internal), pinned to the new tab. Two timing facts: it must be added before
  `open`, because the first events fire inside it for placeholder buffers (no
  `symbol`) and the real `a`/`b` buffers load later; and the move is `vim.schedule`d,
  because diffview's own `jump_to_first_change` runs after the event and would
  overwrite it. A plugin update can break this: the cursor then stays on the first
  hunk, with no message. diffview's `--selected-row` was rejected: it moves the new
  side only, and needs a repo-relative `--selected-file`.
- md-render (`custom/plugins/md-render.lua`) renders at the window width through
  `vim.g.md_render_max_width`; it needs md-render >= f371b88. `nvim-pack-lock.json` is
  git-ignored, so each machine needs `vim.pack.update` to get that revision.
