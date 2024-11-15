local M = {}

M.defaults = {
  discovery = {
    patterns = {
      "Cargo.toml",
      "package.json",
      "go.mod",
      "Makefile",
      ".git",
    },
    git = {
      enabled = true,
      max_depth = 3,
    },
    auto_discover = {
      enabled = false,
      paths = {},
      max_depth = 3,
    },
  },

  session = {
    enabled = true,
    components = {
      tabs = true,
      buffers = {
        enabled = true,
        save_bufferline = true, -- save bufferline.nvim state
      },
      splits = true,
    },
  },

  hooks = {
    before_switch = nil,
    after_switch = nil,
  },
}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

return M
