# eslint-language-server. Disabled by default — opt in per-host since most
# repos with eslint use it via none-ls or in-editor cmds, and pulling in the
# server adds startup latency for non-JS work.
{lib, ...}: {
  flake.modules.nvim.lsp-eslint = {pkgs, ...}: {
    nvim.lsp.servers.eslint = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.vscode-langservers-extracted;
      cmd = ["${pkgs.vscode-langservers-extracted}/bin/vscode-eslint-language-server" "--stdio"];
      filetypes = [
        "javascript"
        "javascriptreact"
        "typescript"
        "typescriptreact"
        "vue"
        "svelte"
        "astro"
      ];
      root_markers = [
        ".eslintrc"
        ".eslintrc.json"
        ".eslintrc.js"
        ".eslintrc.cjs"
        "eslint.config.js"
        "eslint.config.mjs"
        "package.json"
        ".git"
      ];
      settings = {
        validate = "on";
        useESLintClass = false;
        experimental.useFlatConfig = false;
        codeAction = {
          disableRuleComment = {
            enable = true;
            location = "separateLine";
          };
          showDocumentation.enable = true;
        };
      };
    };
  };
}
