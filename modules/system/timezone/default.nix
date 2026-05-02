{
  flake.modules.nixos.timezone = _: {
    time.timeZone = "Asia/Manila";
    services.chrony = {
      enable = true;
      servers = ["time.cloudflare.com"];
    };
  };
}
