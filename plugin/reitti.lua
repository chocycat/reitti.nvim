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

vim.api.nvim_create_user_command("ReittiAdd", function(opts)
  local path = opts.args ~= "" and opts.args or vim.fn.getcwd()
  require("reitti.core.project").add_project(path)
end, {
  nargs = "?",
  complete = "dir",
})

vim.api.nvim_create_user_command("ReittiRemove", function(opts)
  local path = opts.args ~= "" and opts.args or vim.fn.getcwd()
  local abs_path = require("reitti.utils.path").normalize(path)

  vim.ui.input({
    prompt = string.format("Remove project '%s'? [y/N] ", abs_path),
    default = "",
  }, function(input)
    print("")
    if input and input:lower() == "y" then
      require("reitti.core.project").remove_project(abs_path)
    end
  end)
end, {
  nargs = "?",
  complete = function(arglead, _, _)
    local projects = require("reitti.core.project").visible_projects()
    local paths = vim.tbl_map(function(p)
      return p.path
    end, projects)
    return vim.tbl_filter(function(p)
      return p:find(arglead, 1, true)
    end, paths)
  end,
})

vim.api.nvim_create_user_command("ReittiForget", function(opts)
  local path = opts.args ~= "" and opts.args or vim.fn.getcwd()
  local abs_path = require("reitti.utils.path").normalize(path)

  vim.ui.input({
    prompt = string.format("Permanently forget project '%s'? [y/N] ", abs_path),
    default = "",
  }, function(input)
    print("")
    if input and input:lower() == "y" then
      require("reitti.core.project").forget_project(abs_path)
    end
  end)
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
