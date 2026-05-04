# LSP attach spine. Wires the workflow glue that the lsp-servers spine
# doesn't cover: per-buffer LSP keymaps, custom diagnostic display, hover/
# signatureHelp borders, per-server formatter disable, and format-on-save.
#
# Per-server modules contribute their server name to `formatProviderDisable`
# when they should NOT own formatting (so none-ls handles formatting via
# stylua / alejandra / shfmt / etc. without the LSP server fighting it).
{lib, ...}: {
  flake.modules.nvim.lib-lsp-attach = {config, ...}: {
    options.nvim.lsp = {
      formatProviderDisable = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = ''
          Server names whose `documentFormattingProvider` capability is
          killed on LspAttach. Lets none-ls own formatting end-to-end.
          Per-server modules contribute their own name.
        '';
      };
      formatOnSave = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Register a buffer-local BufWritePre autocmd on attach that calls
          `vim.lsp.buf.format` with a null-ls filter so saving runs the
          configured formatters.
        '';
      };
    };

    config.nvim.spineLua.lsp_attach = let
      formatDisableJson = builtins.toJSON config.nvim.lsp.formatProviderDisable;
    in ''
      -- _spine_lsp_attach.lua: synthesized from `nvim.lsp.{formatProviderDisable,formatOnSave}`.
      -- See modules/programs/neovim-experimental/lib/lsp-attach/default.nix.

      ---@type string[]
      local format_disable = vim.json.decode([==[${formatDisableJson}]==])
      local format_disable_set = {}
      for _, n in ipairs(format_disable) do
        format_disable_set[n] = true
      end

      -- Diagnostic display.
      vim.diagnostic.config({
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.INFO] = "󰌵",
            [vim.diagnostic.severity.HINT] = "",
          },
        },
        virtual_text = { prefix = "" },
        update_in_insert = false,
        underline = true,
        severity_sort = true,
        float = {
          focusable = false,
          style = "minimal",
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        },
      })

      -- Rounded borders for hover + signature help. The K mapping below uses
      -- vim.lsp.buf.hover's `border` arg directly; signatureHelp is wrapped
      -- via a handler proxy because it's triggered automatically.
      ---@type table[]
      local border = {
        { "╭", "FloatBorder" }, { "─", "FloatBorder" }, { "╮", "FloatBorder" }, { "│", "FloatBorder" },
        { "╯", "FloatBorder" }, { "─", "FloatBorder" }, { "╰", "FloatBorder" }, { "│", "FloatBorder" },
      }
      do
        local sig_help = vim.lsp.handlers.signature_help
        vim.lsp.handlers["textDocument/signatureHelp"] = function(err, result, ctx, conf)
          return sig_help(err, result, ctx, vim.tbl_extend("force", conf or {}, { border = border }))
        end
      end

      local format_augroup = vim.api.nvim_create_augroup("NvimLspFormat", { clear = true })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("NvimLspAttach", { clear = true }),
        ---@param args { buf: integer, data: { client_id: integer } }
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then
            return
          end

          -- Per-server formatter disable. nvim.lsp.formatProviderDisable lists
          -- server names that should defer to none-ls for formatting.
          if format_disable_set[client.name] then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end

          ---@param mode string|string[]
          ---@param lhs string
          ---@param rhs string|function
          ---@param desc string
          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
          end

          -- Navigation. K passes border directly; signatureHelp uses the
          -- handler proxy above. gr defers to Trouble.
          map("n", "K", function()
            vim.lsp.buf.hover({ border = border })
          end, "LSP hover")
          map("n", "gd", vim.lsp.buf.definition, "Go to definition")
          map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
          map("n", "gI", vim.lsp.buf.implementation, "Go to implementation")
          map("n", "gr", "<cmd>Trouble lsp_references<cr>", "References (Trouble)")

          -- <leader>l* LSP actions.
          map("n", "<leader>la", function()
            vim.lsp.buf.code_action({
              context = { only = { "source", "refactor", "quickfix" } },
            })
          end, "Code action")
          map("n", "<leader>lf", function()
            vim.lsp.buf.format({ async = true })
          end, "Format buffer")
          map("n", "<leader>lr", vim.lsp.buf.rename, "Rename")
          map("n", "<leader>lh", function()
            local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
            vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
          end, "Toggle inlay hints")
          map("n", "<leader>li", "<cmd>checkhealth vim.lsp<cr>", "LSP health")
          map("n", "<leader>ll", vim.lsp.codelens.run, "Run codelens")
          map("n", "<leader>ld", "<cmd>Telescope diagnostics bufnr=0<cr>", "Buffer diagnostics")
          map("n", "<leader>ls", "<cmd>Telescope lsp_document_symbols<cr>", "Document symbols")
          map("n", "<leader>lS", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", "Workspace symbols")
          map("n", "<leader>lw", "<cmd>Telescope diagnostics<cr>", "Workspace diagnostics")

          ${lib.optionalString config.nvim.lsp.formatOnSave ''
        -- Format-on-save. Only register if the client supports formatting and
        -- the user hasn't disabled it. Filter prefers null-ls so none-ls wins.
        if client:supports_method("textDocument/formatting") then
          vim.api.nvim_clear_autocmds({ group = format_augroup, buffer = bufnr })
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = format_augroup,
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({
                async = false,
                bufnr = bufnr,
                filter = function(c) return c.name == "null-ls" end,
              })
            end,
          })
        end
      ''}
        end,
      })
    '';
  };
}
