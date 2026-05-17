# Constants Aspect — cross-feature shared values exposed as a `generic`
# class module so consumers in any class (nixos, homeManager) read them
# via `config.systemConstants.<name>` instead of pulling values through
# specialArgs.
#
# The `generic` class doesn't auto-load anywhere; whichever class wants
# the constants must `imports = [ self.modules.generic.systemConstants ]`
# explicitly. system-default does this for nixos; the user feature does
# the same for homeManager.
{
  flake.modules.generic.systemConstants = {
    config,
    lib,
    ...
  }: {
    options.systemConstants = {
      user = lib.mkOption {
        type = lib.types.str;
        default = "jmfv";
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
