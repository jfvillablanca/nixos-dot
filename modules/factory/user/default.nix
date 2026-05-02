# Factory Aspect for users. `flake.factory.user "<name>"` returns
# `{ nixos = <module>; homeManager = <module>; }` — a pair of modules
# that, taken together, set up a system user account plus the
# home-manager defaults for that user. modules/users/<name>/default.nix
# calls the factory and registers the resulting modules under
# `flake.modules.{nixos,homeManager}.<name>`.
{lib, ...}: {
  options.flake.factory = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = {};
  };

  config.flake.factory.user = name: {
    nixos = _: {
      users.users.${name} = {
        isNormalUser = true;
        description = name;
        extraGroups = [
          "networkmanager"
          "wheel"
          "uinput"
          "input"
          "sound"
          "audio"
          "video"
          "docker"
        ];
      };
    };

    homeManager = _: {
      home = {
        username = name;
        homeDirectory = "/home/${name}";
        # Don't touch me :)
        stateVersion = "22.11";
      };
      programs.home-manager.enable = true;
    };
  };
}
