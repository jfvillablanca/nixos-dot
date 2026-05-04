# vscode-langservers-extracted ships html, css, json, eslint LSPs. Each is
# its own per-server module here, sharing the underlying package.
{lib, ...}: {
  flake.modules.nvim.lsp-html = {pkgs, ...}: {
    nvim.lsp.servers.html = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.vscode-langservers-extracted;
      cmd = ["${pkgs.vscode-langservers-extracted}/bin/vscode-html-language-server" "--stdio"];
      filetypes = ["html" "templ"];
      root_markers = ["package.json" ".git"];
      init_options = {
        provideFormatter = true;
        embeddedLanguages.css = true;
        embeddedLanguages.javascript = true;
        configurationSection = ["html" "css" "javascript"];
      };
    };
  };
}
