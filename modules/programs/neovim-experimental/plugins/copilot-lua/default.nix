# copilot.lua — replaces copilot-vim. Auth state lives at
# `$XDG_CONFIG_HOME/github-copilot/` (per-machine, outside our control); the
# plugin loads gracefully without auth and stays silent until `:Copilot auth`
# completes. Honours `NVIM_DISABLE=copilot` env var as a runtime escape hatch
# (Phase 3 portability work; today the plugin always loads if enabled).
#
# Auto-enables `nvim.withNodeJs` since copilot.lua's agent process needs Node.
{lib, ...}: {
  flake.modules.nvim.copilot-lua = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.copilot-lua = {
      enable = lib.mkEnableOption "copilot.lua" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.copilot-lua;
      };
    };

    config = lib.mkIf config.nvim.plugins.copilot-lua.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.copilot-lua.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
          lazy.event = ["InsertEnter"];
        }
      ];
      nvim.withNodeJs = lib.mkForce true;
    };
  };
}
