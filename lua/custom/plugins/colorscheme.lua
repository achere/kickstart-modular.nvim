local function gh(repo) return 'https://github.com/' .. repo end

-- [[ Colorscheme ]]
-- Theme inspired by Atom. This is loaded from `custom.plugins` (last in the
-- load order), so it overrides kickstart's default `tokyonight` colorscheme.
vim.pack.add { gh 'navarasu/onedark.nvim' }

-- Diff colours, picked on the theme's background (#282c34): old side red, new
-- side green. The line colours replace onedark's palette entries, so they apply
-- in every diff (DiffDelete, DiffAdd). The changed-text and cursor-line groups
-- are used by diffview (`diffview.lua`); the global DiffChange/DiffText stay blue.
local diff = {
  old_line = '#523338', -- deleted lines; changed lines, old side
  old_text = '#7b3b3c', -- changed text, old side
  old_cursor = '#5a3d41', -- cursor line on an old-side diff line
  new_line = '#2d483a', -- added lines; changed lines, new side
  new_text = '#31643f', -- changed text, new side
  new_cursor = '#375143', -- cursor line on a new-side diff line
}
require('onedark').setup {
  colors = { diff_delete = diff.old_line, diff_add = diff.new_line },
  highlights = {
    DiffTextOld = { bg = diff.old_text },
    DiffTextNew = { bg = diff.new_text },
    DiffCursorLineOld = { bg = diff.old_cursor },
    DiffCursorLineNew = { bg = diff.new_cursor },
  },
}
vim.cmd.colorscheme 'onedark'

-- vim: ts=2 sts=2 sw=2 et
