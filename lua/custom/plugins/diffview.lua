local function gh(repo) return 'https://github.com/' .. repo end

-- [[ Diffview ]]
-- Git file history and diff viewer. Maintained fork of sindrets/diffview.nvim
-- (unmaintained); same `diffview` module and `:Diffview*` commands, no plenary.
-- Breaking changes vs upstream: `:h diffview.changelog`.
-- Tracks `main`: its release tags are `vX.Y`, which vim.pack's strict semver
-- parser rejects, so `version = vim.version.range '*'` finds no versions.
vim.pack.add {
  gh 'dlyongemallo/diffview-plus.nvim',
}

-- [[ Diff window highlights ]]
-- Applied per diff window through 'winhighlight' (see the hook below), derived
-- from the colorscheme and rebuilt on ColorScheme.
--
-- Changed lines: diffview colours DiffChange/DiffText blue on both sides. In
-- 2-way layouts, use red on the old side and green on the new side, like added
-- and deleted lines: line bg = the theme's DiffDelete/DiffAdd bg, changed text =
-- DiffTextOld/DiffTextNew. The colorscheme sets those two (`colorscheme.lua`);
-- they are defined here with `default = true` only as a fallback for themes
-- that don't: Removed/Added fg blended 30% into Normal bg.
--
-- Cursor line: on a diff line Neovim draws a CursorLine without fg as an
-- underline and keeps the diff bg (drawline.c, set_line_attr_for_diff). With an
-- fg set, CursorLine is high-priority: its bg covers the diff bg, as on any other
-- line, and there is no underline. Only ctermfg is set, which termguicolors
-- ignores, so syntax colours stay. Scoped to diff windows: a global high-priority
-- CursorLine would hide extmark/LSP highlight backgrounds on the cursor line.
-- A window has one CursorLine colour, so its target follows the cursor (see
-- update_cursorline): DiffCursorLine (the theme's CursorLine) on other lines,
-- DiffCursorLineOld/New on diff lines in 2-way layouts. The cursor line hides
-- the changed-text colour. A blended overlay that keeps it was tried and
-- dropped: Neovim blends the text colour too.

-- Global definition of a group, links followed. Not `link = false`: that follows
-- the current window's 'winhighlight' too (syn_get_final_id uses curwin), and
-- ColorScheme can fire in a diff window, where DiffDelete maps to a grey group.
local function get_hl(name)
  for _ = 1, 100 do
    local hl = vim.api.nvim_get_hl(0, { name = name })
    if not hl.link then return hl end
    name = hl.link
  end
  return {}
end

-- Channel-wise helpers on 0xRRGGBB integers.
local function map_channels(f)
  local out = 0
  for _, shift in ipairs { 65536, 256, 1 } do
    local function ch(c) return math.floor(c / shift) % 256 end
    out = out + math.min(255, math.max(0, math.floor(f(ch) + 0.5))) * shift
  end
  return out
end
local function blend(fg, bg, alpha) return map_channels(function(ch) return ch(fg) * alpha + ch(bg) * (1 - alpha) end) end
-- `c` moved by the step from the Normal bg to the CursorLine bg.
local function cursor_step(c, normal_bg, cursorline_bg)
  return map_channels(function(ch) return ch(c) + ch(cursorline_bg) - ch(normal_bg) end)
end

local function set_diff_hls()
  local set = vim.api.nvim_set_hl
  local normal = get_hl 'Normal'
  local normal_bg = normal.bg or 0x000000
  local red = get_hl('Removed').fg or get_hl('DiagnosticError').fg or 0xff0000
  local green = get_hl('Added').fg or get_hl('DiagnosticOk').fg or 0x00ff00
  set(0, 'DiffTextOld', { bg = blend(red, normal_bg, 0.3), default = true })
  set(0, 'DiffTextNew', { bg = blend(green, normal_bg, 0.3), default = true })

  local function high_priority(hl)
    hl.ctermfg = hl.ctermfg or normal.ctermfg or 'White'
    return hl
  end
  local cursorline = get_hl 'CursorLine'
  local cursorline_bg = cursorline.bg or normal_bg
  set(0, 'DiffCursorLine', high_priority(cursorline))
  local line_bgs = {
    Old = get_hl('DiffDelete').bg or blend(red, normal_bg, 0.15),
    New = get_hl('DiffAdd').bg or blend(green, normal_bg, 0.15),
  }
  for side, line_bg in pairs(line_bgs) do
    set(0, 'DiffChange' .. side, { bg = line_bg })
    -- The colorscheme's colour, else the line colour moved by the CursorLine step.
    local cursor_bg = get_hl('DiffCursorLine' .. side).bg or cursor_step(line_bg, normal_bg, cursorline_bg)
    set(0, 'DiffCursorLine' .. side, high_priority { bg = cursor_bg })
  end
end
set_diff_hls()
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('diff-window-hl', { clear = true }),
  callback = set_diff_hls,
})

-- winhighlight entries per diff window. `symbol` is the window's side: in diff2
-- layouts 'a' is the old state, 'b' the new one. DiffTextAdd (changed text that
-- only exists on one side, Nvim 0.12) is mapped too: diffview leaves it alone.
local function diff_winhl(layout_name, symbol)
  local map = { CursorLine = 'DiffCursorLine' }
  local side = layout_name:match '^diff2' and ({ a = 'Old', b = 'New' })[symbol]
  if side then
    map.DiffChange = 'DiffChange' .. side
    map.DiffText = 'DiffText' .. side
    map.DiffTextAdd = 'DiffText' .. side
  end
  return map
end

-- Set `map` entries in a 'winhighlight' value: replace existing ones, append the
-- rest, drop duplicate keys (diffview re-adds its own entries on every file load).
local function merge_winhl(winhl, map)
  local entries, seen = {}, {}
  for item in winhl:gmatch '[^,]+' do
    local from = item:match '^([^:]+):'
    if from and not seen[from] then
      seen[from] = true
      entries[#entries + 1] = map[from] and (from .. ':' .. map[from]) or item
    end
  end
  for from, to in pairs(map) do
    if not seen[from] then entries[#entries + 1] = from .. ':' .. to end
  end
  return table.concat(entries, ',')
end

-- Point CursorLine at the colour for the line under the window's cursor:
-- DiffCursorLineOld/New on a diff line, else DiffCursorLine. Only in windows set
-- up by the hook; their DiffChange entry gives the side (none outside diff2).
local function update_cursorline(win)
  local winhl = vim.wo[win].winhighlight
  local current = winhl:match '%f[%w]CursorLine:(DiffCursorLine%a*)'
  if not current then return end
  local target = 'DiffCursorLine'
  local side = winhl:match '%f[%w]DiffChange:DiffChange(%a+)'
  if side then
    local lnum = vim.api.nvim_win_get_cursor(win)[1]
    if vim.api.nvim_win_call(win, function() return vim.fn.diff_hlID(lnum, 1) end) ~= 0 then target = target .. side end
  end
  if target ~= current then
    vim.api.nvim_set_option_value('winhighlight', merge_winhl(winhl, { CursorLine = target }), { win = win, scope = 'local' })
  end
end
local function update_cursorlines(tab)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab or 0)) do
    update_cursorline(win)
  end
end
-- CursorMoved fires only in the current window, but 'cursorbind' moves the other
-- diff window too: update every window of the tab. DiffUpdated: a line can
-- become a diff line (or stop being one) without a cursor move.
vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'DiffUpdated' }, {
  group = vim.api.nvim_create_augroup('diff-cursorline', { clear = true }),
  callback = function(ev)
    if ev.event == 'DiffUpdated' or vim.wo.winhighlight:find('CursorLine:DiffCursorLine', 1, true) then update_cursorlines() end
  end,
})

require('diffview').setup {
  enhanced_diff_hl = true, -- Better diff highlighting
  view = {
    merge_tool = {
      layout = 'diff3_mixed',
    },
  },
  hooks = {
    -- Diffview resets winhighlight when it loads a file, so apply on every
    -- enter. scope = 'local' (:setlocal) keeps it out of windows split off a
    -- diff window that show another buffer (the file panel). The cursor-line
    -- colour is picked after the diff is computed, so schedule it.
    diff_buf_win_enter = function(_, winid, ctx)
      local winhl = merge_winhl(vim.wo[winid].winhighlight, diff_winhl(ctx.layout_name, ctx.symbol))
      vim.api.nvim_set_option_value('winhighlight', winhl, { win = winid, scope = 'local' })
      local tab = vim.api.nvim_win_get_tabpage(winid)
      vim.schedule(function()
        if vim.api.nvim_tabpage_is_valid(tab) then update_cursorlines(tab) end
      end)
    end,
  },
}

-- Keymaps for easier access
vim.keymap.set('n', '<leader>vh', ':DiffviewFileHistory %<CR>', { desc = '[v]iew git [h]istory (current file)' })
vim.keymap.set('n', '<leader>vH', ':DiffviewFileHistory<CR>', { desc = '[v]iew git [H]istory (all)' })
vim.keymap.set('n', '<leader>vd', ':DiffviewOpen<CR>', { desc = '[v]iew git [d]iff (current changes)' })
vim.keymap.set('n', '<leader>vc', ':DiffviewClose<CR>', { desc = '[v]iew [c]lose diffview' })

-- vim: ts=2 sts=2 sw=2 et
