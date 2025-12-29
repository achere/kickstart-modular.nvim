-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

return {
  {
    'mbbill/undotree',
  },
  {
    -- Theme inspired by Atom
    'navarasu/onedark.nvim',
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'onedark'
    end,
  },
  {
    'olexsmir/gopher.nvim',
    config = {
      commands = {
        go = 'go',
        gomodifytags = 'gomodifytags',
        gotests = 'gotests',
        impl = 'impl',
        iferr = 'iferr',
        dlv = 'dlv',
      },
      gotests = {
        -- gotests doesn't have template named "default" so this plugin uses "default" to set the default template
        template = 'default',
        -- path to a directory containing custom test code templates
        template_dir = nil,
        -- switch table tests from using slice to map (with test name for the key)
        -- works only with gotests installed from develop branch
        named = false,
      },
      gotag = {
        transform = 'snakecase',
      },
    },
    build = function()
      vim.cmd [[silent! GoInstallDeps]]
    end,
  },
  {
    'mfussenegger/nvim-dap',
  },
  {
    'leoluz/nvim-dap-go',
    ft = 'go',
    dependencies = 'mfussenegger/nvim-dap',
    config = function(_, opts)
      require('dap-go').setup(opts)
    end,
  },
  -- Add sticky context (function signature)
  {
    'nvim-treesitter/nvim-treesitter-context',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
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
    end,
  },
  -- Git file history and diff viewer
  {
    'sindrets/diffview.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
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
    end,
  },
}
