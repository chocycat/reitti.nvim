local M = {}

local Path = require("reitti.utils.path")
local Git = require("reitti.utils.git")
local config = require("reitti.config")

function M.is_project_root(path)
  for _, pattern in ipairs(config.options.discovery.patterns) do
    if Path.exists(Path.join(path, pattern)) then
      return true
    end
  end

  if config.options.discovery.git.enabled and Git.is_git_repo(path) then
    return true
  end

  return false
end

function M.discover_projects(root)
  local projects = {}
  local max_depth = config.options.discovery.auto_discover.max_depth or 3

  local function scan_dir(path, depth)
    if depth > max_depth then
      return
    end

    if M.is_project_root(path) then
      table.insert(projects, path)
      return
    end

    for name, type in vim.fs.dir(path) do
      if type == "directory" and name:sub(1, 1) ~= "." then
        scan_dir(Path.join(path, name), depth + 1)
      end
    end
  end

  scan_dir(Path.normalize(root), 1)
  return projects
end

return M
