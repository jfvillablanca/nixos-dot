local config = {
    cmd = { "nixd" },
    settings = {
        nixd = {
            nixpkgs = {
                expr = "import <nixpkgs> { }",
            },
            -- this configuration should be rewritten in a nix file in order for 
            -- the hardcoded configurations to be string interpolated dynamically
            options = {
              nixos = {
                  expr = '(builtins.getFlake "/home/jmfv/nixos-dot").nixosConfigurations."cimmerian".options',
              },
              home_manager = {
                  expr = '(builtins.getFlake "/home/jmfv/nixos-dot").homeConfigurations."cimmerian".options',
              },
            },
        },
    },
}

return config
