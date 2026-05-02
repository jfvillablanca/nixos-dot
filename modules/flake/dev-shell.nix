# Dev shell + flake templates.
{
  self,
  pkgs,
  system,
  ...
}: {
  flake.devShells.${system}.default = pkgs.mkShell {
    packages = with pkgs; [
      stylua
      selene
      lua-language-server

      alejandra
      statix
      deadnix
      nil
      nixd
    ];
    formatter = pkgs.alejandra;
  };

  flake.templates = let
    basic = {
      path = self + /templates/basic;
      description = "A basic flake with devenv.";
    };
  in {
    inherit basic;
    default = basic;
  };
}
