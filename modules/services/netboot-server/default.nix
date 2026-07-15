# One-shot netboot server for provisioning new bare-metal hosts without USB
# media. Enable on cimmerian for an install window, then disable (Task 10).
# Serves a RAM NixOS installer (sshd + authorized keys) so nixos-anywhere
# can take over. UEFI PXE clients fetch ipxe.efi over TFTP via proxyDHCP
# (coexists with the LAN's real DHCP); iPXE then chains to HTTP for the big
# kernel/initrd. Lazy `let` bindings mean zero cost when disabled.
{
  inputs,
  self,
  ...
}: {
  flake.modules.nixos.netboot-server = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.myNixosModules.netbootServer;

    installer = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({modulesPath, ...}: {
          imports = ["${modulesPath}/installer/netboot/netboot-minimal.nix"];
          networking.useDHCP = lib.mkForce true;
          services.openssh.enable = true;
          users.users.root.openssh.authorizedKeys.keys = cfg.authorizedKeys;
        })
      ];
    };
    build = installer.config.system.build;

    # netboot.ipxe references bzImage + initrd by relative name.
    netbootRoot = pkgs.runCommand "netboot-root" {} ''
      mkdir -p $out
      ln -s ${build.kernel}/bzImage $out/bzImage
      ln -s ${build.netbootRamdisk}/initrd $out/initrd
      ln -s ${build.netbootIpxeScript}/netboot.ipxe $out/netboot.ipxe
    '';

    ipxeEfi = pkgs.ipxe.override {
      embedScript = pkgs.writeText "boot.ipxe" ''
        #!ipxe
        dhcp
        chain http://${cfg.serveHost}:${toString cfg.httpPort}/netboot.ipxe
      '';
    };

    tftpRoot = pkgs.runCommand "tftp-root" {} ''
      mkdir -p $out
      ln -s ${ipxeEfi}/ipxe.efi $out/ipxe.efi
    '';
  in {
    options.myNixosModules.netbootServer = {
      enable =
        lib.mkEnableOption "one-shot netboot install server"
        // {default = false;};

      serveHost = lib.mkOption {
        type = lib.types.str;
        description = ''
          LAN IP (or router-resolvable hostname) of THIS server, baked into
          the iPXE script so the target chains to the HTTP root. Must be
          reachable from the target's boot network -- NOT a tailnet name;
          the target isn't on the tailnet during netboot.
        '';
      };

      httpPort = lib.mkOption {
        type = lib.types.port;
        default = 8080;
      };

      dhcpSubnet = lib.mkOption {
        type = lib.types.str;
        description = ''
          Subnet for dnsmasq proxyDHCP, e.g. "192.168.1.0". proxyDHCP
          coexists with the LAN's real DHCP, answering only boot options.
        '';
      };

      authorizedKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = builtins.attrValues self.publicKeys;
        defaultText = lib.literalExpression "builtins.attrValues self.publicKeys";
        description = ''
          SSH pubkeys authorized as root in the RAM installer. Defaults to
          every key in the fleet registry so nixos-anywhere connects with
          whatever key the operator's machine presents.
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      services.caddy = {
        enable = true;
        virtualHosts.":${toString cfg.httpPort}".extraConfig = ''
          root * ${netbootRoot}
          file_server browse
        '';
      };

      services.dnsmasq = {
        enable = true;
        settings = {
          port = 0;
          log-dhcp = true;
          dhcp-range = ["${cfg.dhcpSubnet},proxy"];
          dhcp-match = [
            "set:efi64,option:client-arch,7"
            "set:efi64,option:client-arch,9"
          ];
          pxe-service = ["tag:efi64,x86-64_EFI,iPXE,ipxe.efi"];
          enable-tftp = true;
          tftp-root = "${tftpRoot}";
        };
      };

      networking.firewall = {
        allowedTCPPorts = [cfg.httpPort];
        allowedUDPPorts = [67 69];
      };
    };
  };
}
