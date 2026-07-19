# rue -- Dell OptiPlex 3050, headless always-on homelab host. Netboot-
# installed from cimmerian, reached over Tailscale SSH. XFCE + Sunshine so
# Moonlight clients can land in a desktop on demand. Btrfs ephemeral root +
# impermanence like the rest of the fleet; durable state (incl. the
# Tailscale auth key at /persist/secrets) lives on the /persist subvol.
{
  inputs,
  self,
  ...
}: let
  hostName = baseNameOf (toString ./.);
  base16Scheme = "gruvbox-dark-hard";
in {
  flake.modules.nixos.${hostName} = {
    config,
    lib,
    pkgs,
    pkgs-master,
    pkgs-stable-24-05,
    pkgs-stable-25-05,
    ...
  }: let
    inherit (config.systemConstants) user;
  in {
    imports = [
      ./_hardware-configuration.nix
      ./_disko.nix

      self.modules.nixos.user
      self.modules.nixos.system-desktop
      self.modules.nixos.doas
      self.modules.nixos.tailscale
      self.modules.nixos.sunshine
      self.modules.nixos.xfce
      self.modules.nixos.netdata
      self.modules.nixos.wol
      self.modules.nixos.sops
      self.modules.nixos.adguard
    ];

    networking.hostName = hostName;

    # AdGuard is rue's own resolver (started by myNixosModules.adguard below);
    # do not let Tailscale's MagicDNS resolv.conf override it -- see
    # `services.tailscale.extraSetFlags` for the `--accept-dns=false` that
    # keeps tailscaled from managing resolv.conf in the first place.
    networking.nameservers = ["127.0.0.1"];

    # rue is the tailnet nameserver (via AdGuard) and must resolve through its
    # own local AdGuard, not Tailscale's MagicDNS -- accept-dns=true would let
    # tailscaled overwrite resolv.conf with 100.100.100.100, and in `off` mode
    # (adguard-mode CLI, Task 5) the tailnet nameserver is cleared, which would
    # break rue's own resolution. `extraSetFlags` (not `extraUpFlags`): the
    # tailscale module's `tailscaled-set` unit runs after
    # `tailscaled-autoconnect`, so this reliably re-asserts on every boot even
    # though `tailscale up` no-ops once already Running (see
    # modules/services/tailscale/default.nix). This list merges with
    # myNixosModules.tailscale's own `extraSetFlags` (listOf -> concatenated,
    # not overwritten), so it needs no change to the shared tailscale module.
    services.tailscale.extraSetFlags = ["--accept-dns=false"];

    # Password hash comes from sops (encrypted at secrets/rue.yaml, decrypted
    # with the /persist age key). neededForUsers materialises it to
    # /run/secrets-for-users/rue-password before the users activation runs.
    # defaultSopsFile is type `path`; ciphertext is safe to copy into the store.
    sops.defaultSopsFile = ../../../secrets/rue.yaml;
    sops.secrets."rue-password".neededForUsers = true;
    users.users.${user}.hashedPasswordFile = config.sops.secrets."rue-password".path;

    # Make the sops hash the single source of truth: rewrites the existing
    # user's shadow entry from hashedPasswordFile on every activation. Safe now
    # that Task 4 proved the secret decrypts and materialises.
    users.mutableUsers = false;

    # Fresh 2026 install -- set to the release you install from; verify with
    # `nixos-version` on the RAM installer (Task 9). Do NOT copy t14g1's 22.11.
    system.stateVersion = "26.05";

    stylix = {
      enable = true;
      image = null;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/${base16Scheme}.yaml";
      polarity = "dark";
      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Original-Ice";
        size = 24;
      };
      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.jetbrains-mono;
          name = "JetBrainsMono Nerd Font Mono";
        };
        sansSerif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Sans";
        };
        serif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Serif";
        };
      };
    };

    myNixosModules = {
      tailscale = {
        enable = true;
        enableSSH = true;
        # Delivered out-of-band onto the /persist subvol so it survives the
        # first-boot root wipe. Quoted string, NOT a path literal.
        authKeyFile = "/persist/secrets/tailscale-authkey";
        # Always-on box -> also serve as the tailnet exit node. Needs a
        # one-time approval in the Tailscale console after the first rebuild.
        useRoutingFeatures = "both";
        advertiseExitNode = true;
      };
      sunshine.enable = true;
      netdata.enable = true;
      sops.enable = true;
      adguard = {
        enable = true;
        lanInterface = "enp1s0";
        tailnetIp = "100.70.231.87";
        # lanCidr / routerIp / blocklistUrl use defaults
      };
      # Always-on + LAN-wired -> the reliable WoL sender. `ssh rue
      # wake-defenestration` from anywhere on the tailnet powers on the box.
      wol.targets = self.constants.wolTargets;
      xfce = {
        enable = true;
        autoLoginUser = user;
      };
      persistence = {
        enable = true;
        userHomes = [{inherit user;}];
      };
    };

    boot = {
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;

      consoleLogLevel = 3;
      kernelParams = ["quiet" "udev.log_level=3"];
      initrd.verbose = false;

      # Scripted stage-1 so boot.initrd.postDeviceCommands (the btrfs
      # ephemeral-root wipe) works; systemd stage-1 does not support it.
      initrd.systemd.enable = lib.mkForce false;
      initrd.postDeviceCommands = lib.mkAfter ''
        mkdir /btrfs_tmp
        mount /dev/root_vg/root /btrfs_tmp
        if [[ -e /btrfs_tmp/root ]]; then
            mkdir -p /btrfs_tmp/old_roots
            timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
            mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
        fi

        delete_subvolume_recursively() {
            IFS=$'\n'
            for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                delete_subvolume_recursively "/btrfs_tmp/$i"
            done
            btrfs subvolume delete "$1"
        }

        for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
            delete_subvolume_recursively "$i"
        done

        btrfs subvolume create /btrfs_tmp/root
        umount /btrfs_tmp
      '';
    };

    fileSystems."/persist".neededForBoot = true;

    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [wget];

    home-manager = {
      useGlobalPkgs = false;
      useUserPackages = true;
      extraSpecialArgs = {
        inherit inputs pkgs pkgs-master pkgs-stable-24-05 pkgs-stable-25-05;
        inherit user base16Scheme;
        system = "x86_64-linux";
      };
      users.${user}.imports = [
        self.modules.homeManager.user
        ./_home.nix
      ];
    };
  };

  flake.nixosConfigurations.${hostName} = self.lib.mkNixos hostName;

  # rue runs Tailscale SSH (openssh is off), so this is the host key tailscaled
  # presents, captured via `ssh-keyscan rue`. It lives in /var/lib/tailscale
  # (persisted by the tailscale module), so it's stable across reboots.
  flake.hostIdentityKeys.${hostName} = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHqXPLw9J1EiDsVcXs9zfDr5MSIuj2SH+XZaR5vAjnWf";
}
