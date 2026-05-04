{lib, ...}: {
  flake.modules.nvim.cellular-automaton = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.cellular-automaton = {
      enable = lib.mkEnableOption "cellular-automaton-nvim (because why not)" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.cellular-automaton-nvim;
      };
    };

    config = lib.mkIf config.nvim.plugins.cellular-automaton.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.cellular-automaton.package;
          # No setup() — invoke via :CellularAutomaton make_it_rain.
          lazy.cmd = ["CellularAutomaton"];
        }
      ];
    };
  };
}
