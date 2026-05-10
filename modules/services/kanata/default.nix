# kanata — keyboard remapper.
{inputs, ...}: {
  flake-file.inputs.kanata.follows = "nixpkgs";

  flake.modules.nixos.kanata = {pkgs, ...}: {
    services.kanata = {
      enable = true;
      package = inputs.kanata.legacyPackages.${pkgs.stdenv.hostPlatform.system}.kanata;
      keyboards = {
        thinkpad-t14 = {
          devices = ["/dev/input/by-path/platform-i8042-serio-0-event-kbd"];
          extraDefCfg = "process-unmapped-keys yes";
          config = builtins.readFile ./kbd/thinkpad-t14.kbd;
        };
      };
    };
  };
}
