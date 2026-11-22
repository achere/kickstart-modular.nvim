-- [[ Review ]]
-- Open a diff of a commit range, limited to the current folder. Made for scripts
-- that start nvim in a checkout, for example a code review tool:
--
--   nvim -c 'Review 992afd9..323efec'
--
-- Usage: :Review {base}..{head} [-- {path}...]
--
--   {base}..{head}  Two commits: SHAs, branches, tags, or anything else that git
--                   resolves to a commit. The diff shows the changes from {base}
--                   to {head}. With three dots ({base}...{head}), it shows the
--                   changes from the merge base of the two commits to {head}.
--   -- {path}...    Show only the changes under these paths. Paths are relative
--                   to nvim's current folder. Escape a space in a path with a
--                   backslash. Without paths, the current folder is used: from
--                   the repo root, that is the whole range.
--
-- The repo is the one that contains nvim's current folder, not the repo of the
-- current buffer. The diff opens in a new tab; the other tabs stay normal
-- editors. Nothing happens at startup: plain `nvim` is not affected.
--
-- Errors: a usage error, a folder that is not in a git repo, or a commit that is
-- not in the repo shows a message and opens no diff. nvim does not exit, so the
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
-- The diff plugin is diffview. Only `open_diff` knows it: to use another plugin,
-- change that function. Callers depend on `:Review` only.

local usage = 'Usage: :Review base..head [-- path...]'

-- Show the changes in `range` under `paths`, in the git repo that contains `cwd`.
-- -C makes diffview use that repo and resolve `paths` against `cwd`. Without it,
-- diffview takes the repo of the current buffer, which can be another repo.
local function open_diff(cwd, range, paths) require('diffview').open(vim.list_extend({ '-C' .. cwd, range, '--' }, paths)) end

-- `^{commit}` makes git look the object up: a well-formed full SHA alone passes
-- `--verify` even when the commit is not in the repo (e.g. a shallow checkout).
local function has_commit(cwd, rev)
  return vim.system({ 'git', 'rev-parse', '--verify', '--quiet', rev .. '^{commit}' }, { cwd = cwd }):wait().code == 0
end

local function fail(msg) vim.notify('Review: ' .. msg, vim.log.levels.ERROR) end

vim.api.nvim_create_user_command('Review', function(cmd)
  local range, sep = cmd.fargs[1], cmd.fargs[2]
  local paths = vim.list_slice(cmd.fargs, 3)
  local base, head = range:match '^(.-)%.%.%.?(.+)$'
  if not base or base == '' or (sep and (sep ~= '--' or #paths == 0)) then return fail(usage) end

  local cwd = vim.fn.getcwd()
  if not vim.fs.root(cwd, '.git') then return fail('not in a git repository: ' .. cwd) end
  for _, rev in ipairs { base, head } do
    if not has_commit(cwd, rev) then return fail(('no commit %s here. A shallow checkout may not have it: fetch it first.'):format(rev)) end
  end
  open_diff(cwd, range, #paths > 0 and paths or { '.' })
end, { nargs = '+', desc = 'Show the changes of a commit range under the current folder' })

-- vim: ts=2 sts=2 sw=2 et
