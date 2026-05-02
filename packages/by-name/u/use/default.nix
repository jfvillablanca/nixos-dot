{
  # pkgs,
  writeShellApplication,
}:
writeShellApplication {
  name = "use";
  text = ''
    if [ "$#" -lt 1 ]; then
      echo "Usage: $0 <package1> [<package2> ...]"
      exit 1
    fi

    packages=()
    for pkg in "$@"; do
      packages+=("nixpkgs#$pkg")
    done

    nix shell "''\$''\{packages[@]}"
  '';
}
