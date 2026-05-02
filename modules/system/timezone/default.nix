{
  flake.modules.nixos.timezone = {...}: {
    time.timeZone = "Asia/Manila";
    services.chrony = {
      enable = true;
      servers = ["time.cloudflare.com"];
    };
  };
}
