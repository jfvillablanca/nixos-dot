local status_ok, handlers = pcall(require, "lsp.handlers")
if not status_ok then
    return
end

local servers = {
    "bashls",
    "cssls",
    "html",
    "jsonls",
    -- "tsserver",      -- managed by jose-elias-alvarez/typescript.nvim 
    "tailwindcss",
    -- "nil_ls",        -- needs to be explicitly directed to use nix store path
    -- "lua_ls",        -- needs to be explicitly directed to use nix store path
    -- "gopls",
    "rust_analyzer",
    -- "hls",
    "pylsp",
    "emmet_ls",         -- installed non-declaratively (temporarily) via npm install -g emmet-ls (installed in ~/.npm-global)
    "volar",            -- uses local node_modules installation Typescript (there is no global Typescript installation in this machine)
}

local lspconfig_status_ok, lspconfig = pcall(require, "lspconfig")
if not lspconfig_status_ok then
    return
end

local opts = {}

for _, server in pairs(servers) do
    opts = {
        on_attach = handlers.on_attach,
        capabilities = handlers.capabilities,
    }

    local require_ok, conf_opts = pcall(require, "lsp.servers." .. server)
    if require_ok then
        opts = vim.tbl_deep_extend("force", conf_opts, opts)
    end

    lspconfig[server].setup(opts)
end

handlers.setup()
