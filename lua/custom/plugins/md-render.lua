local function gh(repo) return 'https://github.com/' .. repo end

-- [[ md-render.nvim ]]
-- Terminal Markdown previewer: renders into a floating window / tab / split /
-- pager, leaving the editing buffer untouched (unlike render-markdown.nvim,
-- which conceals text in-buffer).
vim.pack.add {
  gh 'delphinus/md-render.nvim',
}

vim.keymap.set('n', '<leader>mt', '<Plug>(md-render-toggle)', { desc = '[M]arkdown [T]oggle (in place)' })
vim.keymap.set('n', '<leader>ms', ':MdRender split<CR>', { desc = '[M]arkdown [S]plit (horizontal)' })
vim.keymap.set('n', '<leader>mv', ':vert MdRender split<CR>', { desc = '[M]arkdown split ([V]ertical)' })

-- Render buffers pad blank lines with spaces (box-drawing width), so native
-- `{`/`}` paragraph motion -- which only stops on truly empty lines -- skips
-- straight to the end of the buffer. Search for whitespace-only lines instead,
-- falling back to buffer start/end when there's no further match, same as
-- native `{`/`}` do at the first/last paragraph.
-- The plugin sets `filetype` under `eventignore = "all"` (to stop `:edit`
-- from clobbering rendered content), so `FileType` never fires here; watch
-- `b:md_render` on buffer entry instead, as the plugin's own docs suggest.
local function para_jump(flags)
  for _ = 1, vim.v.count1 do
    if vim.fn.search([[^\s*$]], flags) == 0 then
      local last = vim.api.nvim_buf_line_count(0)
      vim.api.nvim_win_set_cursor(0, { flags:find 'b' and 1 or last, 0 })
      break
    end
  end
end

vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter' }, {
  callback = function(args)
    if not vim.b[args.buf].md_render or vim.b[args.buf].md_render_kbd_applied then return end
    vim.b[args.buf].md_render_kbd_applied = true
    local opts = { buffer = args.buf, silent = true }
    vim.keymap.set('n', '}', function() para_jump 'W' end, opts)
    vim.keymap.set('n', '{', function() para_jump 'bW' end, opts)
  end,
})

-- vim: ts=2 sts=2 sw=2 et
