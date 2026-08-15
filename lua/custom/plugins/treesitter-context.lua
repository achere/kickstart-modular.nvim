local function gh(repo) return 'https://github.com/' .. repo end

-- [[ Treesitter context ]]
-- Show the sticky context (e.g. the current function signature) at the top of
-- the window. `nvim-treesitter` itself is installed by
-- `kickstart.plugins.treesitter`, which loads before this file.
vim.pack.add { gh 'nvim-treesitter/nvim-treesitter-context' }
require('treesitter-context').setup {
  enable = true,
  max_lines = 4, -- How many lines the window should span
  min_window_height = 0,
  line_numbers = true,
  multiline_threshold = 20,
  trim_scope = 'outer',
  mode = 'cursor',
  separator = nil,
}

-- vim: ts=2 sts=2 sw=2 et
