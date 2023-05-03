final: prev:
{
  nodePackages_latest = prev.nodePackages_latest // {
    "emmet-ls" = prev.buildNpmPackage rec {
      pname = "emmet-ls";
      version = "0.3.1";
      src = prev.fetchFromGitHub {
        owner = "aca";
        repo = pname;
        rev = "282cbdd3d8fb86a326f70261b655fe7d9b0f1f1b";
        hash = "sha256-TmsJpVLF9FZf/6uOM9LZBKC6S3bMPjA3QMiRMPaY9Dg=";
      };
      npmDepsHash = "sha256-azK0KGPo1r3jJA87E1QNnj54KMxCmBnh6wcagwSU6Fo=";
      # npmPackFlags = [ "--ignore-scripts" ];
      # npmFlags = [ "--legacy-peer-deps" ];
      # makeCacheWritable = true;
    };
  };
}
