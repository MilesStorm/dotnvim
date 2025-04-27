local M = {
  "lewis6991/hover.nvim",
}

function M.config()
  require("hover").setup {
    init = function()
      require "hover.providers.lsp"
    end,
    preview_opts = {
      border = "single",
    },
  }

  local wk = require "which-key"
  local map = function(keys, func, descr, mode)
    mode = mode or "n"
    wk.add {
      { keys, func, mode = mode, desc = "LSP: " .. descr },
    }
  end

  -- hover aciton
  map("K", require("hover").hover, "Hover info")
end

return M
