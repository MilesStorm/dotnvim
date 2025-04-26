local M = {
  "echasnovski/mini.nvim",
}

function M.config()
  -- Better Around/Inside textobjects
  --
  -- Examples:
  --  - va)  - [V]isually select [A]round [)]paren
  --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
  --  - ci'  - [C]hange [I]nside [']quote
  require("mini.ai").setup { n_lines = 500 }

  -- Add/delete/replace surroundings (brackets, quotes, etc.)
  --
  -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
  -- - sd'   - [S]urround [D]elete [']quotes
  -- - sr)'  - [S]urround [R]eplace [)] [']
  require("mini.surround").setup()

  -- simple and easy statusline.
  local statusline = require "mini.statusline"
  statusline.setup { use_icons = vim.g.have_nerd_font }

  statusline.section_location = function()
    return "%2l:%-2v"
  end
end

return M
