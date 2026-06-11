# Persistence Aspect: abstract "persist this directory" surface
# that feature modules write to without depending on a specific
# impermanence-style backend. The backend (currently
# nix-community/impermanence) is imported here and only here, so
# swapping to another (e.g. `preservation`) is a one-file change.
#
# Feature modules opt in by writing to:
#   - `myNixosModules.persistence.directories` / `files` /
#     `parentTmpfiles` at the system layer
#   - `myHomeModules.persistence.directories` / `files` at the
#     home-manager layer
#
# Hosts that want persistence flip `myNixosModules.persistence.enable
# = true` (and the matching home option) plus supply `userHomes` for
# the bootstrap tmpfiles + chown that home-manager's persistence
# relies on.
{
  inputs,
  lib,
  ...
}: let
  entryType = lib.types.either lib.types.str (lib.types.submodule {
    options = {
      directory = lib.mkOption {type = lib.types.str;};
      mode = lib.mkOption {
        type = lib.types.str;
        default = "0755";
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = "root";
      };
      group = lib.mkOption {
        type = lib.types.str;
        default = "root";
      };
    };
  });

  normalize = e:
    if builtins.isString e
    then {
      directory = e;
      mode = "0755";
      user = "root";
      group = "root";
    }
    else
      {
        mode = "0755";
        user = "root";
        group = "root";
      }
      // e;

  # Every prefix of the path, longest last. `/a/b/c` → [`/a` `/a/b` `/a/b/c`].
  parentsOf = path: let
    parts = lib.filter (s: s != "") (lib.splitString "/" path);
    n = lib.length parts;
  in
    lib.genList (i: "/" + lib.concatStringsSep "/" (lib.take (i + 1) parts)) n;

  # Walks each entry, emits a tmpfiles `d` rule for the persisted copy
  # and every parent path under `root`. Order is the entry's insertion
  # order with parents inlined the first time each is seen, which keeps the
  # rules list deterministic across rebuilds without imposing a lex
  # sort. Modes/owners explicitly listed in `directories` or
  # `extraEntries` win; otherwise parents fall back to `0755 root root`.
  deriveTmpfilesRules = {
    root,
    directories,
    extraEntries ? [],
  }: let
    all = (map normalize directories) ++ (map normalize extraEntries);
    byPath = lib.listToAttrs (map (e: {
        name = e.directory;
        value = e;
      })
      all);
    entryFor = path:
      byPath.${
        path
      }
      or {
        directory = path;
        mode = "0755";
        user = "root";
        group = "root";
      };
    ruleFor = path: let
      e = entryFor path;
    in "d ${root}${path} ${e.mode} ${e.user} ${e.group} -";
    # Fold over entries, emitting parents in insertion order; dedupe via
    # an accumulated set of paths already seen.
    step = acc: e: let
      paths = parentsOf e.directory;
      newPaths = lib.filter (p: !(acc.seen ? ${p})) paths;
      newSeen =
        acc.seen
        // lib.listToAttrs (map (p: {
            name = p;
            value = true;
          })
          newPaths);
    in {
      rules = acc.rules ++ map ruleFor newPaths;
      seen = newSeen;
    };
    folded =
      lib.foldl step {
        rules = [];
        seen = {};
      }
      all;
    rootRule = "d ${root} 0755 root root -";
  in
    [rootRule] ++ folded.rules;
in {
  flake.modules.nixos.persistence = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.myNixosModules.persistence;
    pathOf = e:
      if builtins.isString e
      then e
      else e.directory;
  in {
    imports = [inputs.impermanence.nixosModules.impermanence];

    options.myNixosModules.persistence = {
      enable =
        lib.mkEnableOption "system persistence aggregator"
        // {default = false;};

      root = lib.mkOption {
        type = lib.types.str;
        default = "/persist/system";
        description = ''
          Mount point under which system state is persisted. The
          backend (impermanence today) bind-mounts entries from this
          location onto their live targets.
        '';
      };

      directories = lib.mkOption {
        type = lib.types.listOf entryType;
        default = [];
        description = ''
          Directories to persist across boots. Drives both the backend's
          bind-mount list and the `systemd.tmpfiles.rules` that
          materialise the persisted copies with the requested mode.
          Entries may be plain path strings (default 0755 root root) or
          `{ directory; mode; user; group; }` attrsets.
        '';
      };

      files = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Files to persist across boots.";
      };

      parentTmpfiles = lib.mkOption {
        type = lib.types.listOf entryType;
        default = [];
        description = ''
          Tmpfiles-only entries (no bind-mount). Use to override the
          mode/owner of a parent of a persisted path; e.g. /root needs
          0700 even when only /root/.ssh is bind-mounted.
        '';
      };

      userHomes = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            user = lib.mkOption {type = lib.types.str;};
            group = lib.mkOption {
              type = lib.types.str;
              default = "users";
            };
            mode = lib.mkOption {
              type = lib.types.str;
              default = "0770";
            };
            root = lib.mkOption {
              type = lib.types.str;
              default = "/persist/home";
            };
          };
        });
        default = [];
        description = ''
          Per-user persisted home roots. Emits the tmpfiles + chown
          oneshot service that gives home-manager's `home.persistence`
          a writable target.
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      # Universals needed for an ephemeral root to behave: journald
      # logs, nix's mutable state, systemd coredumps, machine-id.
      # Feature modules contribute their own paths via the same option;
      # the lists merge.
      myNixosModules.persistence = {
        directories = [
          "/var/log"
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
        ];
        files = [
          "/etc/machine-id"
        ];
      };

      environment.persistence.${cfg.root} = {
        hideMounts = true;
        directories = map pathOf cfg.directories;
        inherit (cfg) files;
      };

      systemd.tmpfiles.rules =
        (deriveTmpfilesRules {
          inherit (cfg) root directories;
          extraEntries = cfg.parentTmpfiles;
        })
        ++ (lib.concatMap (h: [
            "d ${h.root} 0755 root root -"
            "d ${h.root}/${h.user} ${h.mode} ${h.user} ${h.group} -"
          ])
          cfg.userHomes);

      systemd.services = lib.mkIf (cfg.userHomes != []) (
        if lib.length cfg.userHomes == 1
        then let
          h = builtins.head cfg.userHomes;
        in {
          "set-persisted-home-ownership" = {
            description = "Set ownership of ${h.root} to user";
            after = ["network.target"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.coreutils}/bin/chown -R ${h.user}:${h.group} ${h.root}/${h.user}";
              RemainAfterExit = true;
            };
          };
        }
        else {
          "set-persisted-home-ownership" = {
            description = "Set ownership of persisted user homes";
            after = ["network.target"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
              ExecStart =
                pkgs.writeShellScript "set-persisted-home-ownership" (lib.concatMapStringsSep "\n" (h: "${pkgs.coreutils}/bin/chown -R ${h.user}:${h.group} ${h.root}/${h.user}")
                  cfg.userHomes);
              RemainAfterExit = true;
            };
          };
        }
      );
    };
  };

  flake.modules.homeManager.persistence = {
    config,
    lib,
    options,
    ...
  }: let
    cfg = config.myHomeModules.persistence;
  in {
    # impermanence's HM module is auto-imported by its NixOS module since
    # 2026-01 (the standalone HM flake output was deprecated), so no manual
    # import here.
    options.myHomeModules.persistence = {
      enable =
        lib.mkEnableOption "home persistence"
        // {default = false;};

      root = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Mount point under which user state is persisted, e.g.
          `/persist/home/<user>`. Required when `enable = true`.
        '';
      };

      directories = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
      };

      files = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
      };
    };

    # `home.persistence` is only declared where impermanence's NixOS module
    # injects its HM module (via home-manager.sharedModules) -- i.e. NixOS, not
    # darwin (re-importing it manually trips impermanence's assertion). Emit the
    # config only when the option exists; gating on `options` (declarations) not
    # `pkgs` avoids the config<->pkgs infinite recursion. The options above stay
    # declared everywhere so feature modules can still contribute directories.
    config = lib.optionalAttrs (options.home ? persistence) (lib.mkIf cfg.enable {
      # impermanence 2026-01 uses real bind mounts (not bindfs), so the
      # former `allowOther` knob was removed.
      home.persistence.${cfg.root} = {
        inherit (cfg) directories files;
      };
    });
  };
}
