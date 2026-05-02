# Desktop tier: system-cli + the GUI/audio bits a workstation needs
# (PipeWire, Bluetooth, gvfs for thumbnailing/automounts).
{self, ...}: {
  flake.modules.nixos.system-desktop = {
    imports = with self.modules.nixos; [
      system-cli
      sound
      bluetooth
      virtual-fs
    ];
  };
}
