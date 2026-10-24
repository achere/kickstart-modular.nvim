local function gh(repo) return 'https://github.com/' .. repo end

-- [[ Fuzzy Finder (files, lsp, etc) ]]
--
-- Telescope is a fuzzy finder that comes with a lot of different things that
-- it can fuzzy find! It's more than just a "file finder", it can search
-- many different aspects of Neovim, your workspace, LSP, and more!
--
-- There are lots of other alternative pickers (like snacks.picker, or fzf-lua)
-- so feel free to experiment and see what you like!
--
-- The easiest way to use Telescope, is to start by doing something like:
--  :Telescope help_tags
--
-- After running this command, a window will open up and you're able to
-- type in the prompt window. You'll see a list of `help_tags` options and
-- a corresponding preview of the help.
--
-- Two important keymaps to use while in Telescope are:
--  - Insert mode: <c-/>
--  - Normal mode: ?
--
-- This opens a window that shows you all of the keymaps for the current
-- Telescope picker. This is really useful to discover what Telescope can
-- do as well as how to actually do it!

---@type (string|vim.pack.Spec)[]
local telescope_plugins = {
  gh 'nvim-lua/plenary.nvim',
  gh 'nvim-telescope/telescope.nvim',
  gh 'nvim-telescope/telescope-ui-select.nvim',
}
if vim.fn.executable 'make' == 1 then table.insert(telescope_plugins, gh 'nvim-telescope/telescope-fzf-native.nvim') end

-- NOTE: You can install multiple plugins at once
vim.pack.add(telescope_plugins)

-- See `:help telescope` and `:help telescope.setup()`
require('telescope').setup {
  -- You can put your default mappings / updates / etc. in here
  --  All the info you're looking for is in `:help telescope.setup()`
  --
  -- defaults = {
  --   mappings = {
  --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
  --   },
  -- },
  -- pickers = {}
  defaults = {
    vimgrep_arguments = {
      'rg',
      '--color=never',
      '--no-heading',
      '--with-filename',
      '--line-number',
      '--column',
      '--smart-case',
      -- Respects .gitignore by default (no --no-ignore flag)
    },
  },
  extensions = {
    ['ui-select'] = { require('telescope.themes').get_dropdown() },
  },
}

-- Enable Telescope extensions if they are installed
pcall(require('telescope').load_extension, 'fzf')
pcall(require('telescope').load_extension, 'ui-select')

-- See `:help telescope.builtin`
local builtin = require 'telescope.builtin'
-- find_files / live_grep with toggles that update the open picker in place:
--   <M-h> hidden files, <M-i> gitignored files,
--   <M-f> asks for ripgrep globs (space separated, `!` excludes) in the command line;
--   the results update while typing, <Esc> restores the previous globs
local function search(kind)
  local conf = require('telescope.config').values
  local finders = require 'telescope.finders'
  local make_entry = require 'telescope.make_entry'
  local state = { hidden = false, ignored = false, glob = nil }

  local function add_globs(cmd, globs)
    for g in vim.gsplit(globs or '', '%s+', { trimempty = true }) do
      table.insert(cmd, '--glob=' .. g)
    end
    return cmd
  end

  local function flags()
    local args = { '--glob=!.git/' }
    if state.hidden then table.insert(args, '--hidden') end
    if state.ignored then table.insert(args, '--no-ignore') end
    return args
  end

  local function title()
    local function flag(on) return on and '[x]' or '[ ]' end
    local head = ('%s  <M-h> %s hidden  <M-i> %s ignored'):format(kind == 'files' and 'Find Files' or 'Live Grep', flag(state.hidden), flag(state.ignored))
    return head .. '  <M-f> glob: ' .. (state.glob or '-')
  end

  local function files_finder()
    local cmd = add_globs(vim.list_extend({ 'rg', '--files' }, flags()), state.glob)
    return finders.new_oneshot_job(cmd, { entry_maker = make_entry.gen_from_file {} })
  end

  local function grep_finder()
    return finders.new_job(function(prompt)
      if prompt == '' then return nil end
      local cmd = vim.list_extend(vim.list_extend({}, conf.vimgrep_arguments), flags())
      return vim.list_extend(add_globs(cmd, state.glob), { '-e', prompt })
    end, make_entry.gen_from_vimgrep {}, nil, vim.uv.cwd())
  end

  require('telescope.pickers')
    .new({}, {
      prompt_title = title(),
      finder = kind == 'files' and files_finder() or grep_finder(),
      previewer = kind == 'files' and conf.file_previewer {} or conf.grep_previewer {},
      sorter = kind == 'files' and conf.file_sorter {} or require('telescope.sorters').highlighter_only {},
      attach_mappings = function(buf, map)
        local function refresh()
          local picker = require('telescope.actions.state').get_current_picker(buf)
          picker.prompt_border:change_title(title())
          picker:refresh(kind == 'files' and files_finder() or nil, { reset_prompt = false })
        end
        local function toggle(key)
          return function()
            state[key] = not state[key]
            refresh()
          end
        end
        map({ 'i', 'n' }, '<M-h>', toggle 'hidden')
        map({ 'i', 'n' }, '<M-i>', toggle 'ignored')
        map({ 'i', 'n' }, '<M-f>', function()
          local previous = state.glob
          local function apply(glob)
            state.glob = glob ~= '' and glob or nil
            refresh()
            vim.defer_fn(function() vim.cmd.redraw() end, 120) -- the cmdline blocks normal redraws
          end
          local au = vim.api.nvim_create_autocmd('CmdlineChanged', {
            callback = function() apply(vim.fn.getcmdline()) end,
          })
          vim.ui.input({ prompt = 'Glob(s): ', default = previous or '' }, function(glob)
            vim.api.nvim_del_autocmd(au)
            apply(glob or previous or '')
          end)
        end)
        return true
      end,
    })
    :find()
end

vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[s]earch [h]elp' })
vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[s]earch [k]eymaps' })
vim.keymap.set('n', '<leader>sf', function() search 'files' end, { desc = '[s]earch [f]iles' })
vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[s]earch [s]elect Telescope' })
vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[s]earch current [w]ord' })
vim.keymap.set('n', '<leader>sg', function() search 'grep' end, { desc = '[s]earch by [g]rep' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[s]earch [d]iagnostics' })
vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[s]earch [r]esume' })
vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[s]earch Recent Files ("." for repeat)' })
vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[s]earch [c]ommands' })
vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

-- Add Telescope-based LSP pickers when an LSP attaches to a buffer.
-- If you later switch picker plugins, this is where to update these mappings.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
  callback = function(event)
    local buf = event.buf

    -- Find references for the word under your cursor.
    vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[g]oto [r]eferences' })

    -- Jump to the implementation of the word under your cursor.
    -- Useful when your language has ways of declaring types without an actual implementation.
    vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[g]oto [i]mplementation' })

    -- Jump to the definition of the word under your cursor.
    -- This is where a variable was first declared, or where a function is defined, etc.
    -- To jump back, press <C-t>.
    vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[g]oto [d]efinition' })

    -- Fuzzy find all the symbols in your current document.
    -- Symbols are things like variables, functions, types, etc.
    vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })

    -- Fuzzy find all the symbols in your current workspace.
    -- Similar to document symbols, except searches over your entire project.
    vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })

    -- Jump to the type of the word under your cursor.
    -- Useful when you're not sure what type a variable is and you want to see
    -- the definition of its *type*, not where it was *defined*.
    vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[g]oto [t]ype Definition' })
  end,
})

-- Override default behavior and theme when searching
vim.keymap.set('n', '<leader>/', function()
  -- You can pass additional configuration to Telescope to change the theme, layout, etc.
  builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer' })

-- It's also possible to pass additional configuration options.
--  See `:help telescope.builtin.live_grep()` for information about particular keys
vim.keymap.set(
  'n',
  '<leader>s/',
  function()
    builtin.live_grep {
      grep_open_files = true,
      prompt_title = 'Live Grep in Open Files',
    }
  end,
  { desc = '[s]earch [/] in Open Files' }
)

-- Shortcut for searching your Neovim configuration files
vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config', follow = true } end, { desc = '[s]earch [n]eovim files' })

-- vim: ts=2 sts=2 sw=2 et
