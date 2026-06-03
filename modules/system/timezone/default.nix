let
  timeZone = "Asia/Manila";
in {
  flake.modules.nixos.timezone = _: {
    time.timeZone = timeZone;
    services.chrony = {
      enable = true;
      servers = ["time.cloudflare.com"];
    };
  };

  flake.modules.darwin.timezone = _: {
    time.timeZone = timeZone;
  };
}
