{
  inputs,
  config,
  pkgs,
  base16Scheme,
  ...
}: {
  imports =
    [inputs.stylix.homeModules.stylix]
    ++ (with inputs.self.modules.homeManager; [
      aerospace
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
      moonlight
      neovim
      nh
      nom
      ripgrep
      sol
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

  programs.moonlight.extraSettings = {
    General = {
      width = 3840;
      height = 2160;
      fps = 60;
      bitrate = 80000;
      videocfg = 2;
    };
  };

  myHomeModules.claudeCode.enable = true;

  # kitty has no native window restoration; the aerospace login restore
  # re-opens its missing windows so they can be placed back onto workspaces.
  # (Chrome is intentionally excluded: it only ever restores a single profile
  # picker, so respawning it just yields a stray window, not the lost ones.)
  myHomeModules.aerospace.respawnApps = ["net.kovidgoyal.kitty"];

  # Sol activates the running kitty (and jumps to its workspace); this script
  # item spawns a fresh instance on the current workspace instead -- the rofi
  # "open a new window" behaviour. `open -na` needs no PATH, resolves the app
  # via LaunchServices.
  myHomeModules.sol.newWindowApps.Kitty = {
    icon = "🐱";
    command = "open -na kitty";
  };

  home.packages = [
    pkgs.devenv
    (pkgs.callPackage (inputs.self + /packages/by-name/v/vf) {})
  ];

  # Override the systemConstants default (Linux-flavoured `/home/...`)
  # for nh's flake-path resolution. Could be lifted into a darwin-aware
  # default in modules/system/constants when the second darwin host lands.
  systemConstants.repoPath = "/Users/${config.systemConstants.user}/nixos-dot";

  # Sunshine stream host: DISABLED on sienna (enabled on work-ct). Kept
  # commented as the validated reference config -- it was proven end-to-end on
  # sienna. To re-enable streaming from sienna: uncomment the tap + `brews` in
  # ./default.nix and this block, add `lib` back to the module args above, and
  # run `brew trust lizardbyte/homebrew` once (Homebrew 6 tap-trust; can't be
  # declarative because home-manager activates after `brew bundle`).
  /*
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
  */
}
