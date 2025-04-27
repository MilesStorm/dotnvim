local M = {
  "aznhe21/actions-preview.nvim",
}

function M.config()
  require("actions-preview").setup {
    telescope = require("telescope.themes").get_dropdown { winblend = 10 },
  }
end

return M
