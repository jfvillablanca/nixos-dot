# Docker -- one feature, two runtimes. On NixOS the runtime is native
# dockerd (`virtualisation.docker`), which also ships the CLI. On darwin
# there is no native dockerd, so Colima runs a headless Linux VM and the
# CLI comes from nixpkgs; Colima itself comes from Homebrew (its VM
# tooling needs macOS virtualization entitlements the nixpkgs build
# lacks). The CLI is co-located with whichever runtime backs it.
#
# Hosts opt in by importing:
#   NixOS  -> self.modules.nixos.docker  (rootless by default; flip
#             myNixosModules.docker.rootless = false for WSL/rootful)
#   darwin -> self.modules.darwin.docker (the colima brew)
#             + self.modules.homeManager.docker (CLI + agent + env)
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

  flake.modules.darwin.docker.homebrew.brews = ["colima"];

  flake.modules.homeManager.docker = {
    config,
    pkgs,
    lib,
    ...
  }: let
    inherit (pkgs.stdenv.hostPlatform) isDarwin;
  in {
    config = lib.mkMerge [
      {home.packages = [pkgs.lazydocker];}

      # darwin-only: NixOS gets the daemon + CLI from virtualisation.docker
      # (the nixos half above), so none of this applies there. mkIf (not
      # optionalAttrs) defers the condition -- with useGlobalPkgs = false,
      # `pkgs` is config-derived, and forcing isDarwin eagerly recurses.
      # home-manager declares `launchd` on all platforms (activation is
      # darwin-gated internally), so mkIf-false is a safe no-op on Linux.
      (lib.mkIf isDarwin {
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
