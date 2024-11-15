local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error("reitti.nvim requires nvim-telescope/telescope.nvim.")
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function projects(opts)
  opts = opts or {}

  local Project = require("reitti.core.project")

  pickers
    .new(opts, {
      prompt_title = "Projects",
      finder = finders.new_table({
        results = vim.tbl_values(Project.projects),
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.name,
            ordinal = entry.name,
            path = entry.path,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          require("reitti").switch_project(selection.path)
        end)
        return true
      end,
    })
    :find()
end

return telescope.register_extension({
  exports = {
    projects = projects,
  },
})
