{lib, ...}: {
  flake.modules.nvim.lsp-bashls = {pkgs, ...}: {
    nvim.lsp.servers.bashls = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.bash-language-server;
      cmd = ["${lib.getExe pkgs.bash-language-server}" "start"];
      filetypes = ["sh" "bash"];
      root_markers = [".bashrc" ".git"];
    };
  };
}
