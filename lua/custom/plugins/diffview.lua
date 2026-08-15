local function gh(repo) return 'https://github.com/' .. repo end

-- [[ Diffview ]]
-- Git file history and diff viewer. `plenary.nvim` is a dependency (also pulled
-- in by telescope); vim.pack dedupes it by name so listing it here is safe.
vim.pack.add {
  gh 'nvim-lua/plenary.nvim',
  gh 'sindrets/diffview.nvim',
}
require('diffview').setup {
  enhanced_diff_hl = true, -- Better diff highlighting
  view = {
    merge_tool = {
      layout = 'diff3_mixed',
    },
  },
}

-- Keymaps for easier access
vim.keymap.set('n', '<leader>vh', ':DiffviewFileHistory %<CR>', { desc = '[V]iew git [H]istory (current file)' })
vim.keymap.set('n', '<leader>vH', ':DiffviewFileHistory<CR>', { desc = '[V]iew git [H]istory (all)' })
vim.keymap.set('n', '<leader>vd', ':DiffviewOpen<CR>', { desc = '[V]iew git [D]iff (current changes)' })
vim.keymap.set('n', '<leader>vc', ':DiffviewClose<CR>', { desc = '[V]iew [C]lose diffview' })

-- vim: ts=2 sts=2 sw=2 et
