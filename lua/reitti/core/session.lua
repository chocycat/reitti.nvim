local M = {}

local config = require("reitti.config")
local Path = require("reitti.utils.path")

local function get_buffer_info(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  local info = {
    bufnr = bufnr,
    name = vim.api.nvim_buf_get_name(bufnr),
    filetype = vim.api.nvim_buf_get_option(bufnr, "filetype"),
  }

  -- get bufferline.nvim specific info
  if package.loaded["bufferline"] and config.options.session.components.buffers.save_bufferline then
    local bufferline_state = require("bufferline.state")
    if bufferline_state and bufferline_state.get_buffer_data then
      local buffer_data = bufferline_state.get_buffer_data(bufnr)
      if buffer_data then
        info.bufferline = {
          pinned = buffer_data.pinned or false,
          group = buffer_data.group,
          ordinal = buffer_data.ordinal,
        }
      end
    end
  end

  return info
end

local function get_session_dir()
  local basedir = Path.get_plugin_data_dir()
  local session_dir = basedir .. "/sessions"

  -- ensure it exists
  vim.fn.mkdir(session_dir, "p")

  return session_dir
end

local function get_session_file(path)
  return get_session_dir() .. "/" .. Path.hash_path(path) .. ".json"
end

function M.save_session(path)
  if not config.options.session.enabled then
    return
  end

  local session = {
    version = 1,
    tabs = {},
    buffers = {},
    tree = {},
    splits = {},
  }

  -- tabs
  if config.options.session.components.tabs then
    for i = 1, vim.fn.tabpagenr("$") do
      session.tabs[i] = {
        buffers = vim.fn.tabpagebuflist(i),
        current = vim.fn.tabpagewinnr(i),
      }
    end
  end

  -- buffers
  if config.options.session.components.buffers.enabled then
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(bufnr) and vim.fn.buflisted(bufnr) == 1 then
        local info = {
          bufnr = bufnr,
          name = vim.api.nvim_buf_get_name(bufnr),
          filetype = vim.api.nvim_buf_get_option(bufnr, "filetype"),
        }

        if info.name and info.name ~= "" then
          if config.options.session.components.buffers.save_bufferline and package.loaded["bufferline"] then
            local bufferline_state = require("bufferline.state")
            if bufferline_state and bufferline_state.get_buffer_data then
              local buffer_data = bufferline_state.get_buffer_data(bufnr)
              if buffer_data then
                info.bufferline = {
                  pinned = buffer_data.pinned or false,
                  group = buffer_data.group,
                  ordinal = buffer_data.ordinal,
                }
              end
            end
          end

          session.buffers[tostring(bufnr)] = info
        end
      end
    end
  end

  -- window splits
  if config.options.session.components.splits then
    session.splits = vim.fn.winlayout()
  end

  -- save to disk
  local session_file = get_session_file(path)

  -- ensure parent dirs exist
  vim.fn.mkdir(vim.fn.fnamemodify(session_file, ":h"), "p")

  -- avoid destroying old project file
  local temp_file = session_file .. ".tmp"
  local file = io.open(temp_file, "w")
  if file then
    file:write(vim.fn.json_encode(session))
    file:close()

    vim.loop.fs_rename(temp_file, session_file)
  end
end

function M.restore_session(path)
  local session_file = get_session_file(path)
  if not Path.exists(session_file) then
    return
  end

  local file = io.open(session_file, "r")
  if not file then
    return
  end

  local content = file:read("*all")
  file:close()

  local ok, session = pcall(vim.fn.json_decode, content)
  if not ok then
    vim.notify("Couldn't decode session file for project: " .. path, vim.log.levels.ERROR)
    return
  end

  if not session.version or session.version ~= 1 then
    vim.notify("Session file version mismatch", vim.log.levels.ERROR)
  end

  -- buffers
  if session.buffers and config.options.session.components.buffers.enabled then
    local first_buffer_set = false
    for _, buf_info in pairs(session.buffers) do
      if buf_info.name and buf_info.name ~= "" and vim.fn.filereadable(buf_info.name) == 1 then
        vim.cmd("badd " .. vim.fn.fnameescape(buf_info.name))
        local bufnr = vim.fn.bufnr(buf_info.name)

        if not first_buffer_set then
          vim.api.nvim_set_current_buf(bufnr)
          first_buffer_set = true
        end

        if
          buf_info.bufferline
          and config.options.session.components.buffers.save_bufferline
          and package.loaded["bufferline"]
        then
          local bufferline = require("bufferline")
          if bufferline.pin_buffer and buf_info.bufferline.pinned then
            bufferline.pin_buffer(bufnr)
          end
        end
      end
    end
  end

  -- tabs
  if session.tabs and config.options.session.components.tabs then
    for i, tab in ipairs(session.tabs) do
      if i > 1 then
        vim.cmd("tabnew")
      end

      local valid_bufnr
      for _, bufnr in ipairs(tab.buffers) do
        local buf_info = session.buffers[tostring(bufnr)]
        if buf_info and buf_info.name and vim.fn.filereadable(buf_info.name) == 1 then
          valid_bufnr = vim.fn.bufnr(buf_info.name)
          break
        end
      end

      if valid_bufnr then
        vim.cmd("buffer " .. valid_bufnr)
      else
        vim.cmd("enew")
      end
    end
  else
    local first_valid_buffer
    for _, buf_info in pairs(session.buffers) do
      if buf_info.name and buf_info.name ~= "" and vim.fn.filereadable(buf_info.name) == 1 then
        first_valid_buffer = vim.fn.bufnr(buf_info.name)
        break
      end
    end

    if first_valid_buffer then
      vim.cmd("buffer " .. first_valid_buffer)
    end
  end
end

return M
