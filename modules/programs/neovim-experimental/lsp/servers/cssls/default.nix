{lib, ...}: {
  flake.modules.nvim.lsp-cssls = {pkgs, ...}: {
    nvim.lsp.servers.cssls = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.vscode-langservers-extracted;
      cmd = ["${pkgs.vscode-langservers-extracted}/bin/vscode-css-language-server" "--stdio"];
      filetypes = ["css" "scss" "less"];
      root_markers = ["package.json" ".git"];
      init_options.provideFormatter = true;
    };
  };
}
