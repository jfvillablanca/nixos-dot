{
  inputs,
  config,
  pkgs,
  lib,
  base16Scheme,
  ...
}: {
  imports =
    [inputs.stylix.homeModules.stylix]
    ++ (with inputs.self.modules.homeManager; [
      bash
      bat
      btop
      claudeCode
      direnv
      docker
      eza
      fd
      fish
      fzf
      gh
      git
      gitui
      kitty
      neovim
      nh
      nom
      ripgrep
      starship
      tmux
      yazi
      zoxide
    ]);

  nixpkgs.config.allowUnfree = true;

  stylix = {
    enable = true;
    enableReleaseChecks = false;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${base16Scheme}.yaml";
    opacity.terminal = 0.9;
  };

  myHomeModules.claudeCode.enable = true;

  # Docker Desktop backend (matches myDarwinModules.docker.backend in
  # ./default.nix): skips the colima CLI/LaunchAgent; Docker Desktop bundles
  # the daemon, CLI, and compose.
  myHomeModules.docker.backend = "docker-desktop";

  home.packages = [pkgs.devenv];

  # Git identity is inherited from the fleet default (personal). To commit under
  # a work identity on this machine, override `systemConstants.git.email` (and
  # `.name`) here, or use git `includeIf` for the work project directories.

  # Override the systemConstants default (Linux-flavoured `/home/...`) for nh's
  # flake-path resolution.
  systemConstants.repoPath = "/Users/${config.systemConstants.user}/nixos-dot";

  # NOTE: Homebrew 6+ refuses formulae from an untrusted tap, so the LizardByte
  # tap must be trusted before `brew bundle` runs. This can't be done in
  # home-manager (it activates AFTER the homebrew step) -- it's a one-time
  # imperative step, documented in the spec: `brew trust lizardbyte/homebrew`
  # (writes ~/.homebrew/trust.json, which then persists across switches).

  # Sunshine stream host. The brew (lizardbyte/homebrew/sunshine) is declared in
  # ./default.nix. macOS keys the Screen Recording permission on the running
  # executable's identity, so the capturing process must BE a stable .app
  # bundle's own executable. A launcher script that exec's the external brew
  # binary does NOT work -- macOS then sees the process as /opt/homebrew/bin/
  # sunshine (and, via the script, bash), neither of which is the granted app.
  # So copy the real Mach-O in as the bundle executable; its dylibs are linked
  # by absolute path, so it runs fine relocated. Refreshed each switch to track
  # brew upgrades. The copy is guarded on the brew being installed already, so a
  # first-ever switch may need a second pass once the homebrew step has run.
  home.activation.sunshineApp = lib.hm.dag.entryAfter ["writeBoundary"] (
    let
      plist = pkgs.writeText "sunshine-Info.plist" ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>CFBundleExecutable</key><string>Sunshine</string>
          <key>CFBundleIdentifier</key><string>dev.lizardbyte.sunshine</string>
          <key>CFBundleName</key><string>Sunshine</string>
          <key>CFBundlePackageType</key><string>APPL</string>
          <key>NSHighResolutionCapable</key><true/>
        </dict>
        </plist>
      '';
    in ''
      app="$HOME/Applications/Sunshine.app"
      run mkdir -p "$app/Contents/MacOS"
      run cp -f ${plist} "$app/Contents/Info.plist"
      if [ -x /opt/homebrew/opt/sunshine/bin/sunshine ]; then
        run cp -f /opt/homebrew/opt/sunshine/bin/sunshine "$app/Contents/MacOS/Sunshine"
      fi
    ''
  );

  launchd.agents.sunshine = {
    enable = true;
    config = {
      ProgramArguments = [
        "${config.home.homeDirectory}/Applications/Sunshine.app/Contents/MacOS/Sunshine"
        "${config.home.homeDirectory}/.config/sunshine/sunshine.conf"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Interactive";
      StandardOutPath = "/tmp/sunshine.out.log";
      StandardErrorPath = "/tmp/sunshine.err.log";
    };
  };
}
