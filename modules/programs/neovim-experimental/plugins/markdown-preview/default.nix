# markdown-preview-nvim — browser-based markdown preview. Gated behind
# `nvim.tools.markdown-preview.enable` (default off): adds withNodeJs and a
# Node modules build to the closure. A future minimal/full split surfaces
# these gates as separate `flake.packages.x86_64-linux.nvim-experimental-{...}`.
{lib, ...}: {
  flake.modules.nvim.markdown-preview = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.markdown-preview = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.markdown-preview-nvim;
      };
    };

    config = lib.mkIf config.nvim.tools.markdown-preview.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.markdown-preview.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
          lazy.cmd = ["MarkdownPreview" "MarkdownPreviewToggle"];
        }
      ];
      nvim.withNodeJs = lib.mkForce true;
    };
  };
}
