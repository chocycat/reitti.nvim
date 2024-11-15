local M = {}
local Path = require("reitti.utils.path")

function M.is_git_repo(path)
  return Path.exists(Path.join(path, ".git"))
end

return M
