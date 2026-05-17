# Dendritic wrapper: registers the portable home-manager module that
# lives at packages/homeManager/moonlight-qt/ as
# `flake.modules.homeManager.moonlight-qt`, and auto-enables it for
# any host that imports the wrapper (so consumers configure
# `programs.moonlight-qt.extraSettings` without restating `enable`).
{self, ...}: {
  flake.modules.homeManager.moonlight-qt = {...}: {
    imports = [(self + /packages/homeManager/moonlight-qt)];
    programs.moonlight-qt.enable = true;
  };
}
