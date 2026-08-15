local function gh(repo) return 'https://github.com/' .. repo end

-- [[ Colorscheme ]]
-- Theme inspired by Atom. This is loaded from `custom.plugins` (last in the
-- load order), so it overrides kickstart's default `tokyonight` colorscheme.
vim.pack.add { gh 'navarasu/onedark.nvim' }
vim.cmd.colorscheme 'onedark'

-- vim: ts=2 sts=2 sw=2 et
