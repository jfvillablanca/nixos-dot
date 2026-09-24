-- obsidian.nvim -- notes in an Obsidian vault, without declaring where the
-- vault is. The vault is discovered at runtime by walking up from the current
-- buffer for the `.obsidian/` marker directory, so nothing here or in any
-- host's config names a path: the same config works for any vault, on any
-- machine, under any username.
--
-- Why setup() is deferred instead of being called at the top level:
-- obsidian.Workspace.setup() raises "At least one workspace is required!" when
-- no workspace resolves, and this repo writes plugin configs eagerly into
-- init.lua -- so an unconditional setup() would throw on every nvim startup
-- outside a vault. Deferring is safe because the plugin's own
-- plugin/obsidian.lua does nothing at load but register the `:Obsidian`
-- command, and guards each of its entry points on the global `Obsidian` being
-- set (it reports "Did not setup obsidian.nvim" until then).

local initialised = false

-- Walk up for the vault marker. An unnamed buffer -- the scratch buffer nvim
-- starts with -- has no path to walk from, so fall back to the cwd; that is
-- what makes a bare `nvim` launched inside a vault activate.
local function vault_root()
    local name = vim.api.nvim_buf_get_name(0)
    local from = name ~= "" and name or vim.uv.cwd()
    if not from then
        return nil
    end
    return vim.fs.root(from, ".obsidian")
end

vim.api.nvim_create_autocmd({ "VimEnter", "BufReadPost", "BufNewFile" }, {
    group = vim.api.nvim_create_augroup("obsidian-lazy-setup", { clear = true }),
    desc = "Initialise obsidian.nvim the first time a buffer is inside a vault",
    callback = function()
        if initialised then
            return
        end

        local root = vault_root()
        if not root then
            return
        end

        initialised = true

        -- The picker is left unset so it resolves lazily on first use (telescope
        -- is the one installed in this config), and the completion defaults are
        -- already what we want.
        --
        -- ui is off because its syntax features require 'conceallevel' to be 1 or
        -- 2 and warn on every note otherwise, while options.lua deliberately sets
        -- conceallevel = 0 "so that `` is visible in markdown files". Concealment
        -- is most of what that layer does, so enabling it here would mean paying
        -- for machinery this config has switched off -- and taking a warning for
        -- it. To get the prettified rendering instead, set ui.enable = true and
        -- raise conceallevel for vault buffers (obsidian.nvim marks them with
        -- vim.b.obsidian_buffer).
        --
        -- legacy_commands is off because it defaults on and then warns that it
        -- will: upstream emits "set `opts.legacy_commands` to false to get rid of
        -- this warning" on every setup. Nothing here predates the `Obsidian <sub>`
        -- form, so there is no reason to carry commands that go away in 4.0.
        require("obsidian").setup({
            workspaces = { { name = vim.fs.basename(root), path = root } },
            legacy_commands = false,
            ui = { enable = false },
        })
    end,
})
