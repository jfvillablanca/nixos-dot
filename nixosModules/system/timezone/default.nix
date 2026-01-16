{ ... }:
{
  time.timeZone = "Asia/Manila";
  services.chrony = {
    enable = false;
    servers = [ "time.cloudflare.com" ];
  };
}
