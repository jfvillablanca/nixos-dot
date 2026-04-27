{...}: {
  # auto-mount 500GB nvme drive
  fileSystems."/media/nvme" = {
    device = "/dev/disk/by-uuid/b6e952f1-e939-4c70-b974-6d3d0bbcbafb";
    fsType = "ext4";
  };
}
