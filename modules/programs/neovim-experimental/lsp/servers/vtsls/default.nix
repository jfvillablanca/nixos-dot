# vtsls — TypeScript / JavaScript language server. The plugin nvim-vtsls
# (separate file under ../../plugins/nvim-vtsls/) wires the editor-side glue;
# this module configures the LSP server.
{lib, ...}: {
  flake.modules.nvim.lsp-vtsls = {pkgs, ...}: {
    nvim.lsp.servers.vtsls = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.vtsls;
      cmd = ["${lib.getExe pkgs.vtsls}" "--stdio"];
      filetypes = [
        "javascript"
        "javascriptreact"
        "javascript.jsx"
        "typescript"
        "typescriptreact"
        "typescript.tsx"
      ];
      root_markers = ["package.json" "tsconfig.json" ".git"];
      settings = {
        vtsls = {
          autoUseWorkspaceTsdk = true;
          experimental.completion.enableServerSideFuzzyMatch = true;
        };
        typescript = {
          tsserver.pluginPaths = ["./node_modules"];
          inlayHints = {
            parameterNames.enabled = "literals";
            parameterTypes.enabled = true;
            variableTypes.enabled = true;
            propertyDeclarationTypes.enabled = true;
            functionLikeReturnTypes.enabled = true;
            enumMemberValues.enabled = true;
          };
        };
      };
    };

    # Defer formatting to none-ls (prettier / stylelint via the formatters spine).
    nvim.lsp.formatProviderDisable = ["vtsls"];
  };
}
