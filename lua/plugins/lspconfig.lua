local M = {
  "neovim/nvim-lspconfig",
  dependencies = {
    { "williamboman/mason.nvim", opts = {} },
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    { "j-hui/fidget.nvim", opts = {} },
    "saghen/blink.cmp",
  },
}

function M.config()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
    callback = function(event)
      local wk = require "which-key"
      local map = function(keys, func, desc, mode)
        mode = mode or "n"
        wk.add {
          { keys, func, mode = mode, desc = "LSP: " .. desc },
        }
      end

      -- rename symbol under cursor
      map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")

      -- code action
      map("<leader>la", vim.lsp.buf.code_action, "[L]sp code [a]ction", { "n", "x" })

      -- find referencme
      map("<leader>lr", require("telescope.builtin").lsp_reference, "[L]sp find [r]efference")

      -- jump to implementation
      map("gi", require("telescope.builtin").lsp_implementations, "[G]oto [i]mplementation")

      -- jump to the definition of the word under cursor
      map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [d]efinition")

      -- WARN: this is not goto definition this is goto declaration
      -- in C this would be the header
      map("gD", require("telescope.builtin").declaration, "[G]oto [D]decleration")

      -- fuzzy find all the symbols in the document
      map("<leader>lf", require("telescope.builtin").lsp_document_symbols, "[L]sp [F]uzzy find symbols")

      -- fuzzy find symbold in workspace
      map(
        "<leader>lF",
        require("telescope.builtin").lsp_dynamic_workspace_symbols,
        "[L]sp [F]uzzy find symbols in workspace"
      )

      -- jump to the type of the word under cursor
      -- useful when unsure about the type of a variable
      -- the definition of its *type*, not where it was *defined*
      map("<leader>lt", require("telescope.builtin").lsp_type_definition, "[L]sp [t]ype definition")

      -- resolves dif between nvim 0.10 and 0.11
      local function client_supports_method(client, method, bufnr)
        if vim.fn.has "nvim-0.11" == 1 then
          return client:supports_method(method, bufnr)
        else
          return client.supports_method(method, { bufnr = bufnr })
        end
      end

      -- The following two autocommands are used to highlight references of the
      -- word under your cursor when your cursor rests there for a little while.
      -- see `:help CursorHold` for information about whne this is executed
      --
      -- When cursor is moved, highlights will be cleared (second autocmd)
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if
        client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf)
      then
        local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })

        vim.api.nvim_create_autocmd("LspDetach", {
          group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
          callback = function(event2)
            vim.lsp.buf.cler_references()
            vim.api.nvim_clear_autocmds { group = "kickstart-lsp-highlight", buffer = event2.buf }
          end,
        })
      end

      -- the following code creates a keymap to toggle inlay hints in your code,
      -- if the language server you are using supports them
      if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
        map("<leader>oh", function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
        end, "[T]oggle Inlay [H]ints")
      end
    end,
  })

  -- diagnstic Config
  vim.diagnostic.config {
    severity_sort = true,
    float = { border = "rounded", source = "if_many" },
    underline = { serverity = vim.diagnostic.severity.ERROR },
    signs = vim.g.have_nerd_font and {
      text = {
        [vim.diagnostic.severity.ERROR] = "󰅚 ",
        [vim.diagnostic.severity.WARN] = "󰀪 ",
        [vim.diagnostic.severity.INFO] = "󰋽 ",
        [vim.diagnostic.severity.HINT] = "󰌶 ",
      },
    } or {},
    virtual_text = {
      source = "if_many",
      spacing = 2,
      format = function(diagnostic)
        local diagnostic_message = {
          [vim.diagnostic.severity.ERROR] = diagnostic.message,
          [vim.diagnostic.severity.WARN] = diagnostic.message,
          [vim.diagnostic.severity.INFO] = diagnostic.message,
          [vim.diagnostic.severity.HINT] = diagnostic.message,
        }
        return diagnostic_message[diagnostic.serverity]
      end,
    },
  }

  -- LSP servers and clients are able to communicate to each other what features they support.
  -- By default, Neovim doesn't support everything that is in the LSP spec.
  -- When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
  -- So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
  local capabilities = require("blink.cmp").get_lsp_capabilities()

  -- Enable the following language servers
  -- these are just the automatically installed ones
  --
  -- Here any aditional override config can be added as such:
  --  - cmd (table): Override the default command used to start the server
  --  - filetypes (table): Override the default list of associated filetypes for the server
  --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
  --  - settings (table): Override the default settings passed when initializing the server.
  --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
  local servers = {
    clangd = {},
    pyright = {},
    rust_analyzer = {},
    lua_ls = {
      -- cmd = { ... }
      -- filetypes = { ... }
      -- capabilities = {},
      settings = {
        Lua = {
          completion = {
            callSnippet = "Replace",
          },
          diagnostics = { disable = { "missing-fields" } },
        },
      },
    },
  }

  -- Ensure the servers and tools above are installed
  --
  -- to check the current stus of installed tools and/or manually install other tools, run :Mason
  --
  -- here mason can install other tools so they are available in neovim
  local ensure_installed = vim.tbl_keys(servers or {})
  vim.list_extend(ensure_installed, {
    "stylua", -- used to format Lua code
  })
  require("mason-tool-installer").setup { ensure_installed = ensure_installed }

  require("mason-lspconfig").setup {
    ensure_installed = {}, -- explicitly set to empty since we use tool-installer
    automatic_installation = false,
    handlers = {
      function(server_name)
        local server = servers[server_name] or {}
        -- This handles overriding only values explicitly pased
        -- by the server configuration above. Useful when disabling
        -- certain features of an LSP (for example, turning off formatting for ts_ls)
        server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
        require("lspconfig")[server_name].setup(server)
      end,
    },
  }
end

return M
