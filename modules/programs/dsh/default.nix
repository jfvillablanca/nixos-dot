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
# The derivation lives in packages/by-name/d/dsh and knows nothing about
# secrets; credential policy is this module's job. mkDarwin installs no
# overlays (unlike mkNixos), so `pkgs.dsh` does not resolve on darwin hosts;
# callPackage explicitly, matching modules/hosts/sienna/_home.nix.
{
  lib,
  self,
  ...
}: let
  dsh = self + /packages/by-name/d/dsh;
in {
  flake.modules.homeManager.dsh = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.myHomeModules.dsh;
    base = pkgs.callPackage dsh {};

    # dsh resolves credentials with the process environment ranked above every
    # file layer, so exporting the key is enough -- no settings.yaml, no
    # .credentials.yaml. It also refuses to persist an env-supplied key back to
    # disk, and strips /KEY|PASSWORD|SECRET|TOKEN/i before spawning its tool
    # subprocesses, so the value stays inside this one process.
    #
    # Does not clobber an existing DEEPSEEK_API_KEY: the caller's export is the
    # deliberate override and should win. Missing or unreadable file is not an
    # error here -- dsh raises its own MISSING_CREDENTIAL, which says far more
    # than a failure inside a wrapper would.
    preload = ''
      if [ -z "''${DEEPSEEK_API_KEY:-}" ] && [ -r ${lib.escapeShellArg cfg.apiKeyFile} ]; then
        DEEPSEEK_API_KEY="$(cat ${lib.escapeShellArg cfg.apiKeyFile})"
        export DEEPSEEK_API_KEY
      fi
    '';

    wrapped = pkgs.symlinkJoin {
      name = "dsh-with-credentials";
      paths = [base];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/dsh --run ${lib.escapeShellArg preload}
      '';
      inherit (base) meta;
    };
  in {
    options.myHomeModules.dsh.apiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/run/secrets/deepseek-api-key";
      description = ''
        Path to a file holding a DeepSeek API key, read at launch and exported
        as DEEPSEEK_API_KEY for the dsh process alone.

        A string, not a path: a Nix path literal would copy the secret into the
        world-readable store. Same convention as sops.age.keyFile.
      '';
    };

    config.home.packages = [
      (
        if cfg.apiKeyFile == null
        then base
        else wrapped
      )
    ];
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
