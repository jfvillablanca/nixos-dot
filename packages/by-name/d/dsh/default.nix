# dsh -- DeepSeek Harness: a plugin-based, model-agnostic AI agent harness
# (Web UI, headless one-shot, ACP and JSON-RPC server modes). Not in nixpkgs
# as of the pinned rev, and upstream ships no Nix expressions, so this is a
# local derivation.
#
# Built from the npm registry rather than a git checkout. Upstream's
# published packages are already-compiled JS, so a source build would mean
# reproducing a 256-manifest pnpm workspace -- patched dependencies,
# `link:vendor/*` overrides, a full `tsc -b` + vite run -- to arrive at
# artifacts upstream CI already produced, and re-hashing all of it on
# every -rc.
#
# ./package.json and ./package-lock.json ARE the version pin. To bump:
#   1. edit the version in both this file and ./package.json
#   2. npm install --package-lock-only --ignore-scripts
#   3. blank npmDepsHash, rebuild, paste the hash nix reports
#
# Upstream is in developer preview and warns of compatibility-breaking
# changes; every release so far has been an -rc.
{
  lib,
  buildNpmPackage,
  nodejs,
  makeWrapper,
  git,
  pnpm,
  ripgrep,
}:
buildNpmPackage {
  pname = "dsh";
  version = "0.1.1-rc.2";

  # Only the manifests are inputs -- editing the comments above must not
  # invalidate the dependency fetch.
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./package.json
      ./package-lock.json
    ];
  };

  npmDepsHash = "sha256-SGZAW+D+vUejT7m9IaGSB1Dq44RJSaCZgc7q7phOzng=";

  # The stub manifest exists only to pull the dependency closure: it has no
  # build script, and nothing of its own worth packing.
  dontNpmBuild = true;

  nativeBuildInputs = [makeWrapper];

  # npmInstallHook would install the stub (which has no bin); wrap the real
  # entrypoint instead. `pnpm` is not optional -- `dsh plugin` shells out to
  # it and hard-errors when it is missing from PATH.
  #
  # `--expose-internals` is load-bearing, not a debugging aid. dsh's HMR
  # service needs Node's internal ESM loader. Without the flag it falls back
  # to node-addon-require-builtin, which finds that loader by pattern-matching
  # arm64 machine code inside the node binary; the scan fits upstream's
  # official Node builds but not the one nixpkgs compiles, so it fails with
  # "arm64 getter is not optional-bti-ldr-x0-this-imm-ret" and `dsh web`
  # aborts at boot. The flag selects the direct require() path instead, and
  # must be a real argv entry -- the guard reads process.execArgv, which
  # NODE_OPTIONS does not populate.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib $out/bin
    cp -r node_modules $out/lib/

    makeWrapper ${lib.getExe nodejs} $out/bin/dsh \
      --add-flags --expose-internals \
      --add-flags $out/lib/node_modules/@deepseek-ai/dsh/lib/bin.js \
      --prefix PATH : ${lib.makeBinPath [nodejs pnpm git ripgrep]}

    runHook postInstall
  '';

  meta = {
    description = "Plugin-based, model-agnostic AI agent harness from DeepSeek";
    homepage = "https://github.com/deepseek-ai/deepseek-harness";
    license = lib.licenses.mit;
    mainProgram = "dsh";
    platforms = lib.platforms.unix;
  };
}
