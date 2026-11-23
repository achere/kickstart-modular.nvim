-- [[ Review ]]
-- Open a diff of a commit range, limited to the current folder. Made for scripts
-- that start nvim in a checkout, for example a code review tool:
--
--   nvim -c 'Review 992afd9..323efec'
--
-- Usage: :Review {base}..{head} [+{line} | -{line}] [-- {path}...]
--
--   {base}..{head}  Two commits: SHAs, branches, tags, or anything else that git
--                   resolves to a commit. The diff shows the changes from {base}
--                   to {head}. With three dots ({base}...{head}), it shows the
--                   changes from the merge base of the two commits to {head}.
--   +{line}         Put the cursor on this line of the new side of the diff: the
--                   file as it is at {head}.
--   -{line}         The same for the old side: the file as it is at {base}. With
--                   three dots, it is the merge base. The signs are those of the
--                   unified diff (`@@ -old +new @@`): use the numbers of a hunk.
--                   Optional, one at most, between the range and `--`. The
--                   window of that side gets focus. It needs exactly one {path}:
--                   with none or several, there is no single file to land in.
--                   Lines start at 1. A line after the end of that side's file
--                   goes to the last line, with no message: a caller can name a
--                   line that exists at only one end of the range. An added file
--                   has no old side, a deleted file has no new side: both give
--                   line 1. Without it, the cursor is where diffview puts it.
--   -- {path}...    Show only the changes under these paths. Paths are relative
--                   to nvim's current folder. Escape a space in a path with a
--                   backslash. Without paths, the current folder is used: from
--                   the repo root, that is the whole range.
--
-- The repo is the one that contains nvim's current folder, not the repo of the
-- current buffer. The diff opens in a new tab; the other tabs stay normal
-- editors. Nothing happens at startup: plain `nvim` is not affected.
--
-- Errors: a usage error (this includes a +{line} or -{line} that is 0, is not
-- alone, or has no single {path}), a folder that is not in a git repo, or a commit
-- that is not in the repo shows a message and opens no diff. nvim does not exit, so the
-- caller cannot see the error in the exit status. In a shallow checkout, {base}
-- must be within the fetched depth. In a partial clone, git tries to fetch a
-- missing commit, and nvim waits until the fetch ends.
--
-- Callers: the text after `-c` is an Ex command line, so pass only validated
-- SHAs. Start nvim in the folder to review (Python: no `cwd=` uses the caller's):
--
--   if not (re.fullmatch(r"[0-9a-f]{7,40}", base) and re.fullmatch(r"[0-9a-f]{7,40}", head)):
--       raise ValueError(f"not a commit SHA: {base!r}..{head!r}")
--   subprocess.run(["nvim", "-c", f"Review {base}..{head}"], check=True)
--
-- To leave one tab and land on a line, add `-c tabonly` after the Review command:
--
--   nvim -c 'Review 992afd9..323efec +20 -- src/main.go' -c tabonly
--
-- The diff plugin is diffview. Only `open_diff` knows it: to use another plugin,
-- change that function. Callers depend on `:Review` only. The landing on a line
-- uses diffview's event emitter and the time of its jump to the first change
-- (see `open_diff`): a plugin update can break it. Then the cursor stays where
-- diffview puts it, with no message.

local usage = 'Usage: :Review base..head [+line|-line] [-- path...]'

-- Show the changes in `range` under `paths`, in the git repo that contains `cwd`.
-- -C makes diffview use that repo and resolve `paths` against `cwd`. Without it,
-- diffview takes the repo of the current buffer, which can be another repo.
--
-- `land` = { side = 'old'|'new', line = n }: when the file is on screen, put the
-- cursor on that line of that side and focus that window. In a 2-way layout,
-- diffview names the old side 'a' and the new side 'b'. The events come from
-- diffview's own emitter, the one behind the `diff_buf_win_enter` hook. The
-- first ones fire inside `open` for placeholder buffers (no symbol), the real
-- file buffers load later, so the listener is added before `open`. It is tied to
-- the new tab and removes itself after the first move or when that tab is gone.
local function open_diff(cwd, range, paths, land)
  local diffview = require 'diffview'
  local tab
  if land then
    local symbol = land.side == 'old' and 'a' or 'b'
    DiffviewGlobal.emitter:on('diff_buf_win_enter', function(_, bufnr, winid, ctx)
      tab = tab or vim.api.nvim_win_get_tabpage(winid) -- fired inside `open`: the new tab
      if not vim.api.nvim_tabpage_is_valid(tab) then return true end
      if vim.api.nvim_win_get_tabpage(winid) ~= tab or ctx.symbol ~= symbol or not ctx.layout_name:match '^diff2' then return end
      -- Scheduled: diffview jumps to the first change after this event, and the
      -- event runs inside nvim_win_call, which restores the window after.
      vim.schedule(function()
        if not (vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == bufnr) then return end
        vim.api.nvim_win_set_cursor(winid, { math.min(land.line, vim.api.nvim_buf_line_count(bufnr)), 0 })
        vim.api.nvim_set_current_win(winid)
      end)
      return true
    end)
  end
  diffview.open(vim.list_extend({ '-C' .. cwd, range, '--' }, paths))
  tab = tab or vim.api.nvim_get_current_tabpage() -- no event inside `open`: the new tab is current
end

-- `^{commit}` makes git look the object up: a well-formed full SHA alone passes
-- `--verify` even when the commit is not in the repo (e.g. a shallow checkout).
local function has_commit(cwd, rev) return vim.system({ 'git', 'rev-parse', '--verify', '--quiet', rev .. '^{commit}' }, { cwd = cwd }):wait().code == 0 end

local function fail(msg) vim.notify('Review: ' .. msg, vim.log.levels.ERROR) end

vim.api.nvim_create_user_command('Review', function(cmd)
  local range = cmd.fargs[1]
  -- Optional `+N` (new side) or `-N` (old side), between the range and `--`.
  local sign, num = (cmd.fargs[2] or ''):match '^([+-])(%d+)$'
  local land = sign and { side = sign == '+' and 'new' or 'old', line = tonumber(num) }
  local sep = cmd.fargs[land and 3 or 2]
  local paths = vim.list_slice(cmd.fargs, land and 4 or 3)
  local base, head = range:match '^(.-)%.%.%.?(.+)$'
  if not base or base == '' or (sep and (sep ~= '--' or #paths == 0)) then return fail(usage) end
  -- One line needs one file to put it in; line numbers start at 1.
  if land and (land.line < 1 or #paths ~= 1) then return fail(usage) end

  local cwd = vim.fn.getcwd()
  if not vim.fs.root(cwd, '.git') then return fail('not in a git repository: ' .. cwd) end
  for _, rev in ipairs { base, head } do
    if not has_commit(cwd, rev) then return fail(('no commit %s here. A shallow checkout may not have it: fetch it first.'):format(rev)) end
  end
  open_diff(cwd, range, #paths > 0 and paths or { '.' }, land)
end, { nargs = '+', desc = 'Show the changes of a commit range under the current folder' })

-- vim: ts=2 sts=2 sw=2 et
