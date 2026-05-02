# CLI tier: system-default + a working network stack. Suits hosts that
# don't run a graphical session but need to reach the network (VMs,
# headless boxes).
{self, ...}: {
  flake.modules.nixos.system-cli = {
    imports = with self.modules.nixos; [
      system-default
      network-manager
    ];
  };
}
