# xpra — persistent X over SSH with video-style compression.
{
  flake.modules.homeManager.xpra = {pkgs, ...}: {
    config = {
      home.packages = [pkgs.xpra];
    };
  };
}
