# Standalone home-manager configuration for `home-manager switch --flake .#jmfv`.
# Reuses sartre's _home.nix as the host-specific layer and pulls in every
# ported home module via flake.homeModules.
{
  inputs,
  self,
  config,
  pkgs,
  pkgs-stable-24-05,
  system,
  ...
}: {
  flake.homeConfigurations = {
    "jmfv" = inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      extraSpecialArgs = rec {
        inherit inputs pkgs pkgs-stable-24-05 system;
        user = "jmfv";
        base16Scheme = "rose-pine-moon";
      };
      modules =
        [
          {
            home = {
              # username = "${user}";
              # homeDirectory = "/home/${user}";
              username = "jmfv";
              homeDirectory = "/home/jmfv";
              # Don't touch me :)
              stateVersion = "22.11";
            };
            programs.home-manager.enable = true;
          }
          inputs.stylix.homeManagerModules.stylix

          # fonts
          {
            fonts.fontconfig.enable = true;
            home.packages = with pkgs; [
              source-code-pro
              font-awesome
              corefonts
              jetbrains-mono
              nerd-fonts.fira-code
              nerd-fonts.jetbrains-mono
            ];
          }
          (self + /modules/hosts/sartre/_home.nix)
        ]
        ++ builtins.attrValues config.flake.homeModules;
    };
  };
}
