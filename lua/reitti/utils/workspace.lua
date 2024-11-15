local M = {}

function M.change_directory(path)
  local escaped_path = vim.fn.fnameescape(path)
  local prev_dir = vim.fn.getcwd()

  vim.cmd("cd " .. escaped_path)

  -- explicitly refresh tree states
  if package.loaded["nvim-tree"] then
    local api = require("nvim-tree.api")

    if api.tree.is_visible() then
      api.tree.change_root(path)
      api.tree.reload()
    end
  end

  -- trigger autocmd
  vim.api.nvim_exec_autocmds("User", {
    pattern = "ReittiDirChanged",
    data = { prev_dir = prev_dir, new_dir = path },
  })
end

function M.clear_buffers()
  local buffers = vim.api.nvim_list_bufs()

  local new_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(new_buf)

  for _, bufnr in ipairs(buffers) do
    if vim.fn.buflisted(bufnr) == 1 then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
  end
end

function M.get_current_directory()
  return vim.fn.getcwd()
end

return M
