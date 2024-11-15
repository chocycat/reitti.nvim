local M = {}

local config = require("reitti.config")
local Project = require("reitti.core.project")
local Discovery = require("reitti.core.discovery")
local Session = require("reitti.core.session")
local Workspace = require("reitti.utils.workspace")

function M.setup(opts)
  config.setup(opts)

  -- Telescope
  pcall(require("telescope").load_extension, "reitti")

  -- auto-commands
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      local current_project = Project.get_project(vim.fn.getcwd())
      if current_project then
        Session.save_session(current_project.path)
      end
      Project.save_projects()
    end,
  })
end

function M.switch_project(path)
  local project = Project.get_project(path)
  if not project then
    Project.add_project(path)
    project = Project.get_project(path)
  end

  -- save current session
  local current_project = Project.get_project(vim.fn.getcwd())
  if current_project then
    Session.save_session(current_project.path)
  end

  -- change to new project
  Workspace.clear_buffers()
  Workspace.change_directory(project.path)
  Session.restore_session(project.path)

  project.last_opened = os.time()
  Project.save_projects()
end

function M.discover_projects(path)
  local projects = Discovery.discover_projects(path)
  for _, project_path in ipairs(projects) do
    Project.add_project(project_path)
  end

  Project.save_projects()
end

return M
