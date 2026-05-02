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
  flake.modules.generic.systemConstants = {lib, ...}: {
    options.systemConstants = {
      user = lib.mkOption {
        type = lib.types.str;
        default = "jmfv";
        description = "Primary user account on every host.";
      };
    };
  };
}
