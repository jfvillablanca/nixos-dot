{lib, ...}: {
  flake.modules.nvim.lsp-jsonls = {pkgs, ...}: {
    nvim.lsp.servers.jsonls = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.vscode-langservers-extracted;
      cmd = ["${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server" "--stdio"];
      filetypes = ["json" "jsonc"];
      root_markers = [".git"];
      init_options.provideFormatter = true;
    };
  };
}
