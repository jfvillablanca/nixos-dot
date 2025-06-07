local status_ok, handlers = pcall(require, "lsp.handlers")
if not status_ok then
    return
end

local servers = {
    "bashls",
    "ccls",
    "cssls",
    "eslint",
    "html",
    "jsonls",
    -- "tsserver",         -- managed by pmizio/typescript-tools.nvim
    "tailwindcss",
    "prismals",
    "nil_ls",
    "nixd",
    "lua_ls",
    "gopls",
    -- "rust_analyzer",    -- managed by mrcjkb/rustaceanvim
    "purescriptls",
    -- "hls",
    "pylsp",
    -- "volar",            -- uses local node_modules installation Typescript (there is no global Typescript installation in this machine)
    "texlab"
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
