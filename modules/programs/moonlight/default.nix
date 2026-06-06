# Dendritic wrapper: registers the portable home-manager module that
# lives at packages/homeManager/moonlight/ as
# `flake.modules.homeManager.moonlight`, and auto-enables it for
# any host that imports the wrapper (so consumers configure
# `programs.moonlight.extraSettings` without restating `enable`).
{self, ...}: {
  flake.modules.homeManager.moonlight = {...}: {
    imports = [(self + /packages/homeManager/moonlight)];
    programs.moonlight.enable = true;
  };
}
