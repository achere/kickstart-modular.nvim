-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- [[ Custom Commands ]]
-- Preserve copied text in buffer when pasting
vim.keymap.set('x', '<leader>p', '"_dP', { noremap = true })

-- Function to switch to the next buffer
local function next_buffer()
  vim.cmd 'bnext'
end

-- Function to switch to the previous buffer
local function previous_buffer()
  vim.cmd 'bprevious'
end

-- Mapping key combinations to the functions
vim.keymap.set('n', '<C-l>', next_buffer, { noremap = true, silent = true })
vim.keymap.set('n', '<C-h>', previous_buffer, { noremap = true, silent = true })

-- Define a function to perform global replacement with selected text
vim.keymap.set('v', '<leader>d', '"ay:%s/\\M<C-R>a//gc<Left><Left><Left>', { noremap = true, silent = true })

-- Go-specific if err expansion
vim.keymap.set('n', '<leader>gi', function()
  vim.api.nvim_command 'GoIfErr'
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>jf l', true, false, true), 'n', true)
end, { noremap = true, silent = true, desc = '[G]o [i]f err!=nil' })

vim.keymap.set('v', '<leader>gj', function()
  vim.api.nvim_command 'GoTagAdd json'
end, { noremap = true, silent = true, desc = '[G]o Add [J]SON Tag' })

-- Go DAP keymaps
vim.keymap.set('n', '<leader>db', function()
  vim.api.nvim_command 'DapToggleBreakpoint'
end, { noremap = true, desc = 'Toggle [D]ebug [B]reakpoint' })

vim.keymap.set('n', '<leader>dus', function()
  local widgets = require 'dap.ui.widgets'
  local sidebar = widgets.sidebar(widgets.scopes)
  sidebar.open()
end, { noremap = true, desc = 'Open [D]eb[u]gging [S]idebar' })

vim.keymap.set('n', '<leader>dgt', function()
  require('dap-go').debug_test()
end, { noremap = true, desc = '[D]ebug [G]o [T]est' })

vim.keymap.set('n', '<leader>dgl', function()
  require('dap-go').debug_last()
end, { noremap = true, desc = '[D]ebug [G]o [L]ast Test' })

vim.keymap.set('n', '<leader>dso', function()
  vim.api.nvim_command 'DapStepOver'
end, { noremap = true, desc = '[D]ebug [S]tep [O]ver' })

-- vim: ts=2 sts=2 sw=2 et
