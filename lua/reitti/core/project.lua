local M = {}

local Path = require("reitti.utils.path")

M.projects = {}

local function get_projects_file()
  local data = Path.get_plugin_data_dir()
  return Path.join(data, "projects.json")
end

local function load_projects()
  local file_path = get_projects_file()
  if not Path.exists(file_path) then
    return {}
  end

  local file = io.open(file_path, "r")
  if not file then
    return {}
  end

  local content = file:read("*all")
  file:close()

  local ok, projects = pcall(vim.json.decode, content)
  if not ok then
    vim.notify("Failed to load projects database", vim.log.levels.WARN)
    return {}
  end

  return projects
end

M.projects = load_projects()

function M.add_project(path)
  local abs_path = Path.normalize(path)
  if not M.projects[abs_path] then
    M.projects[abs_path] = {
      path = abs_path,
      name = Path.basename(abs_path),
      last_opened = os.time(),
    }

    M.save_projects()
  end
end

-- marks a project as 'ignored' so it doesn't get added back
function M.remove_project(path)
  local abs_path = Path.normalize(path)
  if M.projects[abs_path] then
    -- mark it as ignored to prevent it from being discovered again
    M.projects[abs_path].ignored = true

    M.save_projects()
  end
end

-- completely removes a project from the database
function M.forget_project(path)
  local abs_path = Path.normalize(path)
  if M.projects[abs_path] then
    M.projects[abs_path] = nil
    M.save_projects()
  end
end

function M.get_project(path)
  local abs_path = Path.normalize(path)
  return M.projects[abs_path]
end

function M.save_projects()
  local data_dir = Path.get_plugin_data_dir()
  Path.mkdir(data_dir)

  local file_path = get_projects_file()

  -- avoid corrupting the file
  local temp_file = file_path .. ".tmp"
  local file = io.open(temp_file, "w")
  if not file then
    vim.notify("Failed to save projects database", vim.log.levels.ERROR)
    return
  end

  local ok, encoded = pcall(vim.json.encode, M.projects)
  if not ok then
    vim.notify("Failed to encode projects data", vim.log.levels.ERROR)
    file:close()
    os.remove(temp_file)
    return
  end

  file:write(encoded)
  file:close()

  vim.loop.fs_rename(temp_file, file_path)
end

function M.clear_projects()
  M.projects = {}
  M.save_projects()
end

function M.list_projects()
  return vim.tbl_values(M.projects)
end

function M.visible_projects()
  return vim.tbl_filter(function(p)
    return not p.ignored
  end, M.list_projects())
end

return M
