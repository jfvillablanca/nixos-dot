# Aggregator for the experimental nvim package.
#
# Two responsibilities:
#
# 1. Collector: every nvim-class module declared elsewhere
#    (`flake.modules.nvim.<name>`) is gathered into
#    `flake.modules.nvim.default` via module-system imports, so a single
#    entry point composes the full config.
#
# 2. Build: `flake.packages.x86_64-linux.nvim-experimental` calls
#    `flake.factory.nvim` (declared in ./factory/default.nix) with no
#    host-specific overrides, producing the standalone variant. Per-host
#    variants (`.#nvim-experimental-cimmerian`, `.#nvim-experimental-t14g1`)
#    call the same factory with their slugs from modules/flake/packages.nix.
{
  lib,
  self,
  ...
}: {
  flake.modules.nvim.default.imports =
    lib.attrValues
    (lib.filterAttrs (n: _: n != "default") (self.modules.nvim or {}));

  perSystem = {system, ...}: {
    packages.nvim-experimental = self.factory.nvim {inherit system;};
  };
}
