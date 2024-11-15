local M = {}
local uv = vim.loop

function M.normalize(path)
  path = vim.fn.expand(path)

  if not vim.fn.fnamemodify(path, ":p") then
    return path
  end

  return vim.fn.fnamemodify(path, ":p"):gsub("\\", "/"):gsub("/$", "")
end

function M.exists(path)
  return uv.fs_stat(path) ~= nil
end

function M.basename(path)
  return vim.fn.fnamemodify(path, ":t")
end

function M.dirname(path)
  return vim.fn.fnamemodify(path, ":h")
end

function M.join(...)
  return table.concat({ ... }, "/"):gsub("//+", "/")
end

function M.hash_path(path)
  local normalized = path:gsub("[/\\]", "_"):gsub(":", "_")
  return vim.fn.sha256(normalized):sub(1, 16)
end

function M.get_plugin_data_dir()
  return vim.fn.resolve(vim.fn.stdpath("data") .. "/reitti")
end

function M.mkdir(path)
  return vim.fn.mkdir(path, "p")
end

return M
