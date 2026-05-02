# Universal baseline applied to every host: nix daemon settings,
# i18n, timezone, system fonts. Hosts that want anything beyond this
# pick a higher tier (system-cli, system-desktop) or add features
# directly.
{self, ...}: {
  flake.modules.nixos.system-default = {
    imports = [
      self.modules.generic.systemConstants
    ] ++ (with self.modules.nixos; [
      nix
      internationalization
      timezone
      fonts
    ]);
  };
}
