local status_ok, conform = pcall(require, "conform")
if not status_ok then
    return
end

conform.setup({
  formatters_by_ft = {
    lua = { "stylua" },

    nix = { "nixpkgs_fmt" },

    sh = { "shfmt" },

    javascript = { "rustywind", "prettier" },
    typescript = { "rustywind", "prettier" },
    javascriptreact = { "rustywind", "prettier" },
    typescriptreact = { "rustywind", "prettier" },
    vue = { "prettier" },
    css = { "stylelint", "prettier" },
    sass = { "prettier" },
    scss = { "prettier" },
    less = { "prettier" },
    html = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    yaml = { "prettier" },
    svelte = { "prettier" },
    markdown = { "prettier" },
    graphql = { "prettier" },
    handlebars = { "prettier" },

    rust = { "rustfmt" },

    python = { "isort", { "autopep8", "black" } },

    c = { "clang_format" },

    go = { { "gofmt", "gofumpt" }, },

    -- Run on all filetypes.
    ["*"] = { "codespell" },

    -- Run on filetypes with no configured formatters
    ["_"] = { "trim_whitespace" },
  },
  -- format_on_save = {
  --   lsp_fallback = true,
  --   timeout_ms = 500,
  -- },
  -- format_after_save = {
  --   lsp_fallback = true,
  -- },
  log_level = vim.log.levels.ERROR,
  notify_on_error = true,
})
