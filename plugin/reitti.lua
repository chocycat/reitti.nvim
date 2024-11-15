if vim.g.loaded_reitti then
  return
end

vim.g.loaded_reitti = true

-- user commands
vim.api.nvim_create_user_command("ReittiSwitch", function()
  local has_telescope, telescope = pcall(require, "telescope")
  if not has_telescope then
    vim.notify("reitti.nvim requires nvim-telescope/telescope.nvim.", vim.log.levels.ERROR)
    return
  end

  telescope.extensions.reitti.projects()
end, {})

vim.api.nvim_create_user_command("ReittiDiscover", function(opts)
  local path = opts.args ~= "" and opts.args or vim.fn.getcwd()
  require("reitti").discover_projects(path)
end, { nargs = "?", complete = "dir" })

vim.api.nvim_create_user_command("ReittiForget", function(opts)
  local Project = require("reitti.core.project")
  if opts.args ~= "" then
    Project.remove_project(opts.args)
  else
    Project.remove_project(vim.fn.getcwd())
  end
end, {
  nargs = "?",
  complete = function(arglead, _, _)
    local projects = require("reitti.core.project").list_projects()
    local paths = vim.tbl_map(function(p)
      return p.path
    end, projects)
    return vim.tbl_filter(function(p)
      return p:find(arglead, 1, true)
    end, paths)
  end,
})
