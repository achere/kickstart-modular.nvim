local function gh(repo) return 'https://github.com/' .. repo end

-- [[ LSP Configuration ]]
-- Brief aside: **What is LSP?**
--
-- LSP is an initialism you've probably heard, but might not understand what it is.
--
-- LSP stands for Language Server Protocol. It's a protocol that helps editors
-- and language tooling communicate in a standardized fashion.
--
-- In general, you have a "server" which is some tool built to understand a particular
-- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
-- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
-- processes that communicate with some "client" - in this case, Neovim!
--
-- LSP provides Neovim with features like:
--  - Go to definition
--  - Find references
--  - Autocompletion
--  - Symbol Search
--  - and more!
--
-- Thus, Language Servers are external tools that must be installed separately from
-- Neovim. This is where `mason` and related plugins come into play.
--
-- If you're wondering about lsp vs treesitter, you can check out the wonderfully
-- and elegantly composed help section, `:help lsp-vs-treesitter`

-- Useful status updates for LSP.
vim.pack.add { gh 'j-hui/fidget.nvim' }
require('fidget').setup {}

--  This function gets run when an LSP attaches to a particular buffer.
--    That is to say, every time a new file is opened that is associated with
--    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
--    function will be executed to configure the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
    -- NOTE: Remember that Lua is a real programming language, and as such it is possible
    -- to define small helper and utility functions so you don't have to repeat yourself.
    --
    -- In this case, we create a function that lets us more easily define mappings specific
    -- for LSP related items. It sets the mode, buffer and description for us each time.
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    -- Rename the variable under your cursor.
    --  Most Language Servers support renaming across files, etc.
    map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

    -- Execute a code action, usually your cursor needs to be on top of an error
    -- or a suggestion from your LSP for this to activate.
    map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

    -- WARN: This is not Goto Definition, this is Goto Declaration.
    --  For example, in C this would take you to the header.
    map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

    -- Fuzzy find all the symbols in your current document / workspace.
    map('<leader>so', require('telescope.builtin').lsp_document_symbols, '[S]earch [O]utline (document symbols)')
    map('<leader>sO', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[S]earch [O]utline (workspace symbols)')

    -- Format the current file via the LSP.
    map('<leader>ff', vim.lsp.buf.format, '[F]ormat [F]ile')

    -- The following two autocommands are used to highlight references of the
    -- word under your cursor when your cursor rests there for a little while.
    --    See `:help CursorHold` for information about when this is executed
    --
    -- When you move your cursor, the highlights will be cleared (the second autocommand).
    local client = vim.lsp.get_client_by_id(event.data.client_id)

    -- Prefer treesitter highlighting over LSP semantic tokens. gopls (and others)
    -- flatten string literals into a single token, which hides treesitter's
    -- fine-grained highlights inside strings (e.g. `%d`/`%s` printf specifiers and
    -- `\n` escape sequences). Disabling semantic tokens lets treesitter win.
    -- To keep semantic tokens for other languages, guard on `client.name == 'gopls'`.
    if client and client.server_capabilities.semanticTokensProvider then client.server_capabilities.semanticTokensProvider = nil end

    if client and client:supports_method('textDocument/documentHighlight', event.buf) then
      local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
        end,
      })
    end

    -- The following code creates a keymap to toggle inlay hints in your
    -- code, if the language server you are using supports them
    --
    -- This may be unwanted, since they displace some of your code
    if client and client:supports_method('textDocument/inlayHint', event.buf) then
      map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
    end
  end,
})

-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--  See `:help lsp-config` for information about keys and how to configure
---@type table<string, vim.lsp.Config>
local servers = {
  -- clangd = {},
  gopls = {
    settings = {
      gopls = {
        analyses = {
          unusedparams = true, -- Warn about unused function parameters
          unusedwrite = true, -- Warn about unused writes to a variable
          useany = true, -- Warn about usage of `interface{}` (discouraged in idiomatic Go)
          shadow = true, -- Warn about variable shadowing
          nilness = true, -- Warn about potential nil dereferences
          nonewvars = true, -- Warn when using `:=` but the variable already exists
          unusedvariable = true, -- Warn about unused variables
        },
        staticcheck = true, -- Enable additional checks from staticcheck
        gofumpt = true, -- Use `gofumpt` for better formatting
        codelenses = {
          gc_details = true, -- Show GC optimization details
          regenerate_cgo = true, -- Regenerate cgo definitions
          tidy = true, -- Run `go mod tidy` via code lens
          upgrade_dependency = true, -- Upgrade dependencies with a single action
          test = true, -- Adds `run test` and `debug test` buttons above functions
        },
        hints = {
          assignVariableTypes = true, -- Show types in variable assignments
          compositeLiteralFields = true, -- Show struct field names in literals
          compositeLiteralTypes = true, -- Show type names in literals
          constantValues = true, -- Show values of constants
          functionTypeParameters = true, -- Show function type parameters
          parameterNames = true, -- Show parameter names at call sites
          rangeVariableTypes = true, -- Show range variable types
        },
      },
    },
  },
  basedpyright = {}, -- Python type checker / language server
  ruff = {}, -- Python linter + formatter (runs as an LSP)
  -- rust_analyzer = {},
  --
  -- TypeScript / JavaScript (React + Vite). `vtsls` wraps tsserver with better
  -- performance and monorepo handling than the plain `ts_ls`; it drives .ts/.tsx/.js/.jsx.
  vtsls = {},
  -- ESLint via its language server: diagnostics + code actions. Formatting is handled
  -- by Prettier (see conform.lua); use `:EslintFixAll` or `gra` for lint fixes.
  eslint = {},

  -- YAML: schema-driven completion, hover docs and validation. SchemaStore covers
  -- the well-known files (GitHub Actions, compose, ...); the `kubernetes` keyword
  -- below is yaml-language-server's bundled k8s schema, scoped to manifest dirs so
  -- it doesn't get applied to unrelated YAML.
  yamlls = {
    settings = {
      yaml = {
        -- Without this, every manifest whose keys aren't alphabetised gets a
        -- "wrong ordering of key" diagnostic.
        keyOrdering = false,
        schemaStore = { enable = true, url = 'https://www.schemastore.org/api/json/catalog.json' },
        -- NOTE the direction: key = schema (URL or built-in keyword), value = globs.
        schemas = {
          kubernetes = {
            'k8s/**/*.yaml',
            'kube/**/*.yaml',
            'kubernetes/**/*.yaml',
            'manifests/**/*.yaml',
            'deploy/**/*.yaml',
            '*.k8s.yaml',
          },
        },
        -- Formatting stays off: conform.lua formats on save for every filetype and
        -- falls back to the LSP, so enabling this would silently reformat every YAML
        -- file on `:w`. To opt in, set this to true or add a `yaml` row to
        -- `formatters_by_ft` in conform.lua.
        format = { enable = false },
      },
    },
  },

  stylua = {}, -- Used to format Lua code

  -- Special Lua Config, as recommended by neovim help docs
  lua_ls = {
    on_init = function(client)
      client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
      end

      client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
        runtime = {
          version = 'LuaJIT',
          path = { 'lua/?.lua', 'lua/?/init.lua' },
        },
        workspace = {
          checkThirdParty = false,
          -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
          --  See https://github.com/neovim/nvim-lspconfig/issues/3189
          library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
            '${3rd}/luv/library',
            '${3rd}/busted/library',
          }),
        },
      })
    end,
    ---@type lspconfig.settings.lua_ls
    settings = {
      Lua = {
        format = { enable = false }, -- Disable formatting (formatting is done by stylua)
      },
    },
  },
}

vim.pack.add {
  gh 'neovim/nvim-lspconfig',
  gh 'mason-org/mason.nvim',
  gh 'mason-org/mason-lspconfig.nvim',
  gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
}

-- Automatically install LSPs and related tools to stdpath for Neovim
require('mason').setup {}

-- Ensure the servers and tools above are installed
--
-- To check the current status of installed tools and/or manually install
-- other tools, you can run
--    :Mason
--
-- You can press `g?` for help in this menu.
local ensure_installed = vim.tbl_keys(servers or {})
vim.list_extend(ensure_installed, {
  -- You can add other tools here that you want Mason to install
  'gofumpt',
  'golines',
  'gomodifytags',
  'gotests',
  'prettierd', -- Fast (daemon) formatter for JS/TS/JSX/TSX/JSON/CSS/HTML
  'prettier', -- Prettier fallback used when prettierd is unavailable
})

require('mason-tool-installer').setup { ensure_installed = ensure_installed }

for name, server in pairs(servers) do
  vim.lsp.config(name, server)
  vim.lsp.enable(name)
end

-- vim: ts=2 sts=2 sw=2 et
