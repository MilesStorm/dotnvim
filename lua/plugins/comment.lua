local M = {
  "numToStr/Comment.nvim",
  opts = {},
}

function M.config()
  require("Comment").setup()
end

return M
