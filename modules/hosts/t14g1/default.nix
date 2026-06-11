# t14g1 — ThinkPad T14 Gen 1 laptop, Hyprland-first.
{
  inputs,
  self,
  ...
}: let
  hostName = baseNameOf (toString ./.);
  base16Scheme = "gruvbox-dark-hard";
in {
  flake-file.inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

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
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen1

      ./_hardware-configuration.nix
      ./_disko.nix

      self.modules.nixos.user
      self.modules.nixos.system-desktop
      self.modules.nixos.steam
      self.modules.nixos.laptop-power-management
      self.modules.nixos.doas
      self.modules.nixos.tailscale
      self.modules.nixos.distributed-builds
      self.modules.nixos.kanata
      self.modules.nixos.openssh
      self.modules.nixos.docker
    ];

    networking.hostName = hostName;

    users.users.${user}.initialPassword = "12345";

    # Don't touch me :)
    system.stateVersion = "22.11";

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
      targets = {
        gnome.enable = true;
      };
    };

    myNixosModules = {
      steam.enable = false;
      tailscale.enable = true;
      distributedBuilds.enable = true;
      openssh.enable = true;
      persistence = {
        enable = true;
        userHomes = [{inherit user;}];
      };
    };

    boot = {
      # Use the systemd-boot EFI boot loader.
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;

      # Pin the 6.12 LTS kernel to match the fleet and stay on the kernel
      # this T14 (AMD Gen1, Renoir) already ran on 25.11. amdgpu in 6.18.x
      # has documented critical regressions on Renoir-class APUs, so don't
      # debut 6.18 on the ephemeral-root host. Drop the pin once the
      # 6.18.x / 6.19 amdgpu reverts land.
      # https://community.frame.work/t/attn-critical-bugs-in-amdgpu-driver-included-with-kernel-6-18-x-6-19-x/79221
      kernelPackages = pkgs.linuxPackages_6_12;

      # nixpkgs 26.11 defaults systemd stage-1 initrd on, which does not
      # support `boot.initrd.postDeviceCommands`. Stay on scripted stage-1 so
      # the btrfs ephemeral-root wipe below keeps working. (Alternative:
      # migrate the wipe to a `boot.initrd.systemd.services` unit.)
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

    # Clamshell-friendly: never suspend on lid close so the box stays
    # reachable over SSH with the lid down. Hyprland disables the
    # internal panel via a switch bind (see modules/desktop/hyprland).
    services.logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchDocked = "ignore";
      HandleLidSwitchExternalPower = "ignore";
    };

    # Enable window manager
    services = {
      # GDM 50 cannot launch the Hyprland Wayland session: it waits for the
      # compositor to self-register, Hyprland never does, so login bounces
      # back to the greeter ("Unable to run session" / "Session never
      # registered"). greetd execs the compositor directly and avoids that
      # handoff. cimmerian keeps GDM (it runs X11/i3, which is unaffected).
      # GDM-specific regression: nixpkgs#490431, nixpkgs#484328.
      greetd = {
        enable = true;
        settings.default_session = {
          command = "${lib.getExe pkgs.tuigreet} --time --remember --asterisks --cmd Hyprland";
          user = "greeter";
        };
      };
      xserver = {
        enable = true;
        windowManager = {
          i3.enable = true;
        };
      };
      libinput = {
        enable = true;
        mouse = {
          tapping = true;
        };
        touchpad = {
          naturalScrolling = true;
          tapping = true;
        };
      };
      actkbd = {
        enable = true;
        bindings = [
          {
            keys = [224];
            events = ["key"];
            command = "/run/current-system/sw/bin/brightnessctl set 10%-";
          }
          {
            keys = [225];
            events = ["key"];
            command = "/run/current-system/sw/bin/brightnessctl set +10%";
          }
        ];
      };
    };

    programs = {
      fuse.userAllowOther = true;

      hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      };
    };

    # Polkit (need enabled for sway)
    security.polkit.enable = true;

    # Backlight control (replaces the removed `programs.light`); udev rules
    # let video-group users adjust brightness without root.
    services.udev.packages = [pkgs.brightnessctl];

    users.extraGroups.docker.members = ["username-with-access-to-socket"];

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment = {
      # Disable DPMS and prevent screen from blanking. Guarded
      # because environment.extraInit fires in every shell — over
      # plain ssh DISPLAY is unset, and over ssh -X it points at a
      # forwarded X server that may not implement DPMS.
      extraInit = ''
        if [ -n "$DISPLAY" ]; then
          xset s off -dpms 2>/dev/null || true
        fi
      '';
      systemPackages = with pkgs; [
        wget
        brightnessctl # backlight control (replaces removed `light`)
      ];
    };

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

  flake.publicKeys.${hostName} = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFAAQv0TTQr9OUABswhWE6bQf+YcRkvRQHUigK7JsGUS jmfv.dev@gmail.com";
  flake.publicKeys."${hostName}-root" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPWKj8zIYP0LgZmik2Fu6JfgIvTmmYCndBseqPUOVgrY t14g1 root build key";

  flake.hostIdentityKeys.${hostName} = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC7wcHSp3W0Gwx9LATsW3m2+vbDiST1TYlM8LzgtiCqj root@t14g1";
}
