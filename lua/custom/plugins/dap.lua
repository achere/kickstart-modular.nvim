local function gh(repo) return 'https://github.com/' .. repo end

-- [[ Debug Adapter Protocol ]]
-- `nvim-dap` is the debugger core; `nvim-dap-go` wires up Delve for Go.
-- Related keymaps (<leader>d...) live in `lua/keymaps.lua`.
vim.pack.add {
  gh 'mfussenegger/nvim-dap',
  gh 'leoluz/nvim-dap-go',
}

require('dap-go').setup()

-- vim: ts=2 sts=2 sw=2 et
