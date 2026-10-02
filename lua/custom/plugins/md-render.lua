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

-- Neovim's builtin `gx` hands the link under the cursor to `vim.ui.open`, which
-- errors on in-document `#heading` links (e.g. a table of contents). The plugin
-- only resolves those on mouse click, so do the same for `gx`: jump to the
-- footnote/heading anchor, and open anything else with `vim.ui.open`.
local function render_gx(buf)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local marks = vim.api.nvim_buf_get_extmarks(buf, -1, { row - 1, 0 }, { row, 0 }, { details = true })
  for _, mark in ipairs(marks) do
    local url, end_col = mark[4].url, mark[4].end_col or (mark[3] + 1)
    if url and col >= mark[3] and col < end_col then
      local anchor = url:match '^#(.+)$'
      if not anchor then return vim.ui.open(url) end
      local session = require('md-render.preview')._sessions[buf]
      local content = session and session.content
      if not content then return end
      local line = (content.footnote_anchors or {})[anchor] or (content.heading_anchors or {})[anchor:lower()]
      if line then
        vim.cmd "normal! m'"
        vim.api.nvim_win_set_cursor(0, { line + 1, 0 })
      else
        vim.notify('md-render: no heading for #' .. anchor, vim.log.levels.WARN)
      end
      return
    end
  end
  vim.notify('md-render: no link under cursor', vim.log.levels.INFO)
end

-- The same failure happens in the raw markdown buffer: `[Usage](#usage)` goes
-- to `vim.ui.open`. Resolve `#heading` links there by scanning for the matching
-- ATX heading (GitHub-style slugs, `-1`/`-2` suffixes for duplicates), and let
-- the original `gx` handle every other link.
local function md_slug(text)
  text = text:gsub('%[(.-)%]%b()', '%1'):gsub('[`*~]', ''):lower()
  return (text:gsub('[^%w%s_%-\128-\255]', ''):gsub('%s', '-'))
end

local function md_heading_line(buf, anchor)
  local seen, fence = {}, nil
  for i, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local f = l:match '^%s*(```+)' or l:match '^%s*(~~~+)'
    if f then
      if not fence then fence = f:sub(1, 3) elseif f:sub(1, 3) == fence then fence = nil end
    elseif not fence then
      local text = l:match '^ ? ? ?#+%s+(.-)%s*$'
      if text then
        local slug = md_slug((text:gsub('%s+#+$', '')))
        local n = seen[slug] or 0
        seen[slug] = n + 1
        if (n == 0 and slug or slug .. '-' .. n) == anchor then return i end
      end
    end
  end
end

local function md_anchor_at_cursor()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local line, init = vim.api.nvim_get_current_line(), 1
  while true do
    local s, e, anchor = line:find('%b[]%(#([^)%s]+)[^)]*%)', init)
    if not s then return end
    if col + 1 >= s and col + 1 <= e then return anchor end
    init = e + 1
  end
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function(args)
    local default = vim.fn.maparg('gx', 'n', false, true)
    vim.keymap.set('n', 'gx', function()
      local anchor = md_anchor_at_cursor()
      if not anchor then
        -- Not an in-document link: hand over to whatever `gx` was before.
        if default.callback then return default.callback() end
        return vim.cmd.normal { 'gx', bang = true }
      end
      anchor = vim.uri_decode(anchor):lower()
      local line = md_heading_line(args.buf, anchor)
      if not line then return vim.notify('No heading for #' .. anchor, vim.log.levels.WARN) end
      vim.cmd "normal! m'"
      vim.api.nvim_win_set_cursor(0, { line, 0 })
    end, { buffer = args.buf, silent = true, desc = 'Open link / jump to #heading' })
  end,
})

vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter' }, {
  callback = function(args)
    if not vim.b[args.buf].md_render or vim.b[args.buf].md_render_kbd_applied then return end
    vim.b[args.buf].md_render_kbd_applied = true
    local opts = { buffer = args.buf, silent = true }
    vim.keymap.set('n', '}', function() para_jump 'W' end, opts)
    vim.keymap.set('n', '{', function() para_jump 'bW' end, opts)
    vim.keymap.set('n', 'gx', function() render_gx(args.buf) end, vim.tbl_extend('force', opts, { desc = 'Open link / jump to #heading' }))
  end,
})

-- vim: ts=2 sts=2 sw=2 et
