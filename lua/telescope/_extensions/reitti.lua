local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error("reitti.nvim requires nvim-telescope/telescope.nvim.")
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")

local function make_display(entry)
  local Path = require("reitti.utils.path")

  print("Display entry:", vim.inspect(entry))

  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 20 },
      { remaining = true },
    },
  })

  return displayer({
    entry.name,
    { Path.shorten(entry.path), "Comment" },
  })
end

local function projects(opts)
  opts = opts or {}

  local Project = require("reitti.core.project")

  local results = vim.tbl_values(Project.projects)

  table.sort(results, function(a, b)
    return a.name:lower() < b.name:lower()
  end)

  pickers
    .new(opts, {
      prompt_title = "Projects",
      finder = finders.new_table({
        results = results,
        entry_maker = function(entry)
          print("Processing entry:", vim.inspect(entry))

          return {
            value = entry,
            display = make_display,
            name = entry.name,
            path = entry.path,
            ordinal = entry.name .. " " .. entry.path,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          require("reitti").switch_project(selection.value.path)
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
