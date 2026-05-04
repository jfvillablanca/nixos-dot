# lua-language-server. Exercises the lsp-servers spine end-to-end:
# - declares cmd / filetypes / settings via the spine option
# - uses `preConfigLua` to populate `workspace.library` at runtime
#   (vim.api.nvim_get_runtime_file can't roundtrip through JSON)
{lib, ...}: {
  flake.modules.nvim.lsp-lua-ls = {pkgs, ...}: {
    nvim.lsp.servers.lua_ls = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.lua-language-server;
      cmd = ["${lib.getExe pkgs.lua-language-server}"];
      filetypes = ["lua"];
      root_markers = [".luarc.json" ".luarc.jsonc" ".git"];
      settings = {
        Lua = {
          runtime.version = "LuaJIT";
          diagnostics.globals = ["vim"];
          telemetry.enable = false;
          workspace = {
            checkThirdParty = false;
            # `library` populated at runtime; see preConfigLua below.
          };
        };
      };
      # Populate workspace.library with neovim's runtime files so the LSP
      # autocompletes vim.api.* etc. Can't be set statically — the value
      # depends on neovim's running rtp.
      preConfigLua = ''
        cfg.settings.Lua.workspace.library = vim.api.nvim_get_runtime_file("", true)
      '';
    };
  };
}
