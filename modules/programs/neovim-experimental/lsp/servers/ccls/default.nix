# ccls — C/C++/ObjC language server. Default off; opt in per host via
# factory extraModules. Original config didn't disable ccls's formatting
# (clang-format-style), so we don't either — none-ls's clang_format and
# ccls's bundled formatting both available, ccls wins on its own buffers.
{lib, ...}: {
  flake.modules.nvim.lsp-ccls = {pkgs, ...}: {
    nvim.lsp.servers.ccls = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.ccls;
      cmd = ["${lib.getExe pkgs.ccls}"];
      filetypes = ["c" "cpp" "objc" "objcpp"];
      root_markers = ["compile_commands.json" ".ccls" ".git"];
      init_options = {
        cache.directory = ".ccls-cache";
        highlight.lsRanges = true;
      };
    };
  };
}
