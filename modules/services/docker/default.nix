# Docker -- one feature, two runtimes. On NixOS the runtime is native
# dockerd (`virtualisation.docker`), which also ships the CLI. On darwin
# there is no native dockerd; two backends are selectable via
# `{myDarwinModules,myHomeModules}.docker.backend` (default "colima"):
#   - "colima": a headless Linux VM (Homebrew brew, since its VM tooling
#     needs macOS virtualization entitlements the nixpkgs build lacks) with
#     the docker CLI from nixpkgs and a login LaunchAgent running colima.
#   - "docker-desktop": the Docker Desktop cask, which bundles its own
#     daemon, CLI, and compose -- so the home-manager half adds nothing but
#     lazydocker. Needs a one-time manual first launch (privileged helper +
#     accept terms). Uses the standard docker socket, so testcontainers work
#     without the colima DOCKER_HOST override.
#
# Hosts opt in by importing:
#   NixOS  -> self.modules.nixos.docker  (rootless by default; flip
#             myNixosModules.docker.rootless = false for WSL/rootful)
#   darwin -> self.modules.darwin.docker + self.modules.homeManager.docker
#             (set both .backend to the same value if not "colima")
# The docker group is provided by the user factory, not here.
{
  flake.modules.nixos.docker = {
    lib,
    config,
    ...
  }: let
    cfg = config.myNixosModules.docker;
  in {
    options.myNixosModules.docker.rootless = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Run docker rootless: the daemon runs as the invoking user and
        `setSocketVariable` points DOCKER_HOST at the per-user socket.
        Set false for rootful docker -- e.g. WSL hosts, where the
        rootless user-daemon model does not fit.
      '';
    };

    config.virtualisation.docker = {
      enable = true;
      rootless = {
        enable = cfg.rootless;
        setSocketVariable = cfg.rootless;
      };
    };
  };

  flake.modules.darwin.docker = {
    lib,
    config,
    ...
  }: let
    cfg = config.myDarwinModules.docker;
  in {
    options.myDarwinModules.docker.backend = lib.mkOption {
      type = lib.types.enum ["colima" "docker-desktop"];
      default = "colima";
      description = ''
        macOS docker runtime. "colima" installs the colima brew (headless
        Linux VM; docker CLI from nixpkgs via the home-manager half).
        "docker-desktop" installs the Docker Desktop cask, which bundles its
        own daemon, CLI, and compose. Set myHomeModules.docker.backend to the
        same value.
      '';
    };

    config = lib.mkMerge [
      (lib.mkIf (cfg.backend == "colima") {homebrew.brews = ["colima"];})
      (lib.mkIf (cfg.backend == "docker-desktop") {homebrew.casks = ["docker-desktop"];})
    ];
  };

  flake.modules.homeManager.docker = {
    config,
    pkgs,
    lib,
    ...
  }: let
    inherit (pkgs.stdenv.hostPlatform) isDarwin;
    cfg = config.myHomeModules.docker;
  in {
    options.myHomeModules.docker.backend = lib.mkOption {
      type = lib.types.enum ["colima" "docker-desktop"];
      default = "colima";
      description = ''
        Match myDarwinModules.docker.backend. "colima" installs the nixpkgs
        docker CLI + compose and a login LaunchAgent running colima.
        "docker-desktop" adds nothing but lazydocker -- Docker Desktop bundles
        the daemon, CLI, and compose itself.
      '';
    };

    config = lib.mkMerge [
      {home.packages = [pkgs.lazydocker];}

      # colima backend, darwin-only: NixOS gets the daemon + CLI from
      # virtualisation.docker (the nixos half above), so none of this applies
      # there. mkIf (not optionalAttrs) defers the condition -- with
      # useGlobalPkgs = false, `pkgs` is config-derived, and forcing isDarwin
      # eagerly recurses. home-manager declares `launchd` on all platforms
      # (activation is darwin-gated internally), so mkIf-false is a safe no-op
      # on Linux.
      (lib.mkIf (isDarwin && cfg.backend == "colima") {
        home.packages = [pkgs.docker-client pkgs.docker-compose];

        # The docker CLI finds the socket via the `colima` docker context,
        # but Docker SDK clients (testcontainers et al.) read DOCKER_HOST
        # directly, so it must be exported.
        home.sessionVariables.DOCKER_HOST = "unix://${config.home.homeDirectory}/.colima/default/docker.sock";

        # Login LaunchAgent brings dockerd (inside the VM) up; KeepAlive
        # restarts it. PATH is pinned because launchd agents start with a
        # bare environment: it needs /opt/homebrew/bin (colima shells out to
        # its lima/qemu tooling) and the nixpkgs docker CLI -- `colima start`
        # does a dependency check for `docker` and fatals without it.
        launchd.agents.colima = {
          enable = true;
          config = {
            ProgramArguments = ["/opt/homebrew/bin/colima" "start" "--foreground"];
            RunAtLoad = true;
            KeepAlive = true;
            EnvironmentVariables.PATH = "${pkgs.docker-client}/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin";
            StandardOutPath = "${config.home.homeDirectory}/Library/Logs/colima.out.log";
            StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/colima.err.log";
          };
        };
      })
    ];
  };
}
