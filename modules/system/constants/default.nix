# Constants Aspect — cross-feature shared values exposed in two
# scopes:
#
# 1. `flake.constants.<name>` at the flake-parts level (read via
#    `self.constants.<name>`) for code that needs the value while
#    constructing flake outputs (module identifiers, factory
#    arguments, etc.).
# 2. `config.systemConstants.<name>` inside any module class
#    (nixos, homeManager) that imports the `generic` class module
#    below. `system-default` does this for nixos; the user feature
#    does the same for homeManager.
#
# The two scopes share the same defaults — the systemConstants
# Aspect reads from `self.constants` so a single override flows
# through both.
{
  self,
  lib,
  ...
}: {
  options.flake.constants.user = lib.mkOption {
    type = lib.types.str;
    default = "jmfv";
    description = ''
      Primary user account, available at flake-parts scope as
      `self.constants.user`. Mirrored into module classes via the
      systemConstants Aspect.
    '';
  };

  config.flake.modules.generic.systemConstants = {
    config,
    lib,
    ...
  }: {
    options.systemConstants = {
      user = lib.mkOption {
        type = lib.types.str;
        default = self.constants.user;
        defaultText = lib.literalExpression "self.constants.user";
        description = "Primary user account on every host.";
      };

      repoPath = lib.mkOption {
        type = lib.types.str;
        default = "/home/${config.systemConstants.user}/nixos-dot";
        defaultText = lib.literalExpression ''"/home/''${user}/nixos-dot"'';
        description = ''
          Absolute path to the local nixos-dot checkout for tools that
          need to address the working tree by path (nh's flake target,
          nixd's `getFlake` bootstrap expressions, etc.). Defaults to
          `/home/<user>/nixos-dot`; override per-host if the checkout
          lives elsewhere.
        '';
      };

      git = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "jfvillablanca";
          description = "Git author name baked into commits.";
        };
        email = lib.mkOption {
          type = lib.types.str;
          default = "31008330+jfvillablanca@users.noreply.github.com";
          description = "Git author email baked into commits.";
        };
      };
    };
  };
}
