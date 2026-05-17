# carcosa — QEMU+SPICE WM-stack hot-swap test lab.
# Built and run from cimmerian:
#   nixos-rebuild build-vm --flake .#carcosa
#   ./result/bin/run-carcosa-vm
# Reached from any tailnet peer:
#   remote-viewer spice://cimmerian:5930
{self, ...}: let
  hostName = baseNameOf (toString ./.);
in {
  flake.modules.nixos.${hostName} = {config, ...}: let
    inherit (config.systemConstants) user;
  in {
    imports = [
      self.modules.nixos.user
      self.modules.nixos.system-cli
      self.modules.nixos.doas
      self.modules.nixos.spice-vda
    ];

    networking.hostName = hostName;

    system.stateVersion = "25.05";

    # Stub bootable config so system.build.toplevel evaluates;
    # virtualisation.vmVariant below overrides both when QEMU builds.
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
    boot.loader.grub = {
      enable = true;
      device = "/dev/vda";
    };

    users.users.${user}.initialPassword = "carcosa";

    virtualisation.vmVariant.virtualisation = {
      memorySize = 4096;
      cores = 4;
      graphics = false;
      qemu.options = [
        "-vga qxl"
        "-display none"
        "-spice port=5930,addr=0.0.0.0,disable-ticketing=on"
        "-device virtio-serial-pci"
        "-chardev spicevmc,id=spicechannel0,name=vdagent"
        "-device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0"
      ];
    };

    nixpkgs.config.allowUnfree = true;
  };

  flake.nixosConfigurations.${hostName} = self.lib.mkNixos hostName;
}
