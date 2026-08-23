# dsh -- DeepSeek Harness, a second agent harness alongside claude-code.
# Model-agnostic: it ships a native DeepSeek adapter plus a generic
# multi-provider one (openai-completions, openai-responses, azure, anthropic
# -messages, bedrock), and can drive claude-code and codex as subagents.
#
# Runtime state lives in $DSH_HOME (default ~/.dsh): settings.yaml,
# .credentials.yaml, profiles/<name>/. Deliberately left unmanaged -- the
# Web UI writes to all of it, and upstream is still reshaping the schema
# between -rc releases.
#
# The derivation lives in packages/by-name/d/dsh. mkDarwin installs no
# overlays (unlike mkNixos), so `pkgs.dsh` does not resolve on darwin hosts;
# callPackage explicitly, matching modules/hosts/sienna/_home.nix.
{
  lib,
  self,
  ...
}: let
  dsh = self + /packages/by-name/d/dsh;
in {
  flake.modules.homeManager.dsh = {pkgs, ...}: {
    home.packages = [(pkgs.callPackage dsh {})];
  };

  # Exposed for `nix build .#dsh` on sienna. Darwin-only on purpose: CI
  # enumerates every attr in `packages.x86_64-linux` (.github/workflows/
  # build-cache.yml) and this has only ever been built for aarch64-darwin.
  perSystem = {
    pkgs,
    system,
    ...
  }:
    lib.optionalAttrs (system == "aarch64-darwin") {
      packages.dsh = pkgs.callPackage dsh {};
    };
}
