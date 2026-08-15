local function gh(repo) return 'https://github.com/' .. repo end

-- [[ Undotree ]]
-- Visualize the undo history as a tree. Toggle with `:UndotreeToggle`.
vim.pack.add { gh 'mbbill/undotree' }

-- vim: ts=2 sts=2 sw=2 et
