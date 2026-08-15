local function gh(repo) return 'https://github.com/' .. repo end

-- [[ gopher.nvim ]]
-- Go tooling: struct tag editing, `iferr`, test generation, etc. Powers the
-- <leader>gi / <leader>gj keymaps in `lua/keymaps.lua`.
-- `plenary.nvim` and `nvim-treesitter` are dependencies; both are already
-- installed by other modules, and vim.pack dedupes by name.
vim.pack.add {
  gh 'nvim-lua/plenary.nvim',
  gh 'olexsmir/gopher.nvim',
}

require('gopher').setup {
  commands = {
    go = 'go',
    gomodifytags = 'gomodifytags',
    gotests = 'gotests',
    impl = 'impl',
    iferr = 'iferr',
    dlv = 'dlv',
  },
  gotests = {
    -- gotests doesn't have a template named "default"; this plugin uses "default"
    -- to select the default template.
    template = 'default',
    -- Path to a directory containing custom test code templates.
    template_dir = nil,
    -- Switch table tests from using a slice to a map (with the test name as key).
    -- Only works with gotests installed from the develop branch.
    named = false,
  },
  gotag = {
    transform = 'snakecase',
  },
}

-- Install gopher's external Go dependencies (impl, iferr, dlv, ...) after the
-- plugin is installed or updated. Mirrors the build handling in `lua/pack.lua`.
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    if ev.data.spec.name == 'gopher.nvim' and (ev.data.kind == 'install' or ev.data.kind == 'update') then
      pcall(vim.cmd, 'silent! GoInstallDeps')
    end
  end,
})

-- vim: ts=2 sts=2 sw=2 et
