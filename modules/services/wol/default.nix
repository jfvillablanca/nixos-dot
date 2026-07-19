# Wake-on-LAN sender. Each named target (name -> MAC) becomes a `wake-<name>`
# command that broadcasts a magic packet via wakeonlan. On an always-on,
# LAN-wired host that's reachable over the tailnet, `ssh <host> wake-<name>`
# is effectively a remote power button. MACs aren't secret (they're broadcast
# on the LAN), so targets live in plain config (e.g. self.constants.wolTargets).
{
  flake.modules.nixos.wol = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.myNixosModules.wol;
  in {
    options.myNixosModules.wol.targets = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = lib.literalExpression ''{ defenestration = "30:56:0F:72:CC:EC"; }'';
      description = ''
        Named Wake-on-LAN targets (name -> MAC). Each generates a
        `wake-<name>` command that broadcasts a magic packet. A non-empty
        set enables the feature.
      '';
    };

    config = lib.mkIf (cfg.targets != {}) {
      environment.systemPackages =
        lib.mapAttrsToList (
          name: mac:
            pkgs.writeShellApplication {
              name = "wake-${name}";
              runtimeInputs = [pkgs.wakeonlan];
              text = ''exec wakeonlan ${mac} "$@"'';
            }
        )
        cfg.targets;
    };
  };
}
