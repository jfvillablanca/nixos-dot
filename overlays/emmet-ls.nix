self: super:
let
  "emmet-ls" = super.buildNpmPackage rec {
    pname = "emmet-ls";
    version = "0.3.1";
    src = super.fetchFromGitHub {
      owner = "aca";
      repo = pname;
      rev = "d644b4e56235fd760e1af8ee2a6dad5f3e449f1f";
      hash = "sha256-EocgRF0pW/iNLiUxDRa9MoAMFLWeuMmYroXz91HiNos=";
    };
    npmDepsHash = "sha256-azK0KGPo1r3jJA87E1QNnj54KMxCmBnh6wcagwSU6Fo=";
    npmPackFlags = [ "--ignore-scripts" ];
  };
in
{
  nodePackages_latest = super.nodePackages_latest // {
    inherit emmet-ls;
  };
}