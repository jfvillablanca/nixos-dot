final: prev:
{
  vimPlugins = prev.vimPlugins // {
    typescript-nvim = prev.vimUtils.buildVimPlugin {
      pname = "typescript.nvim";
      version = "2023-01-03";
      src = prev.fetchFromGitHub {
        owner = "jose-elias-alvarez";
        repo = "typescript.nvim";
        rev = "f66d4472606cb24615dfb7dbc6557e779d177624";
        sha256 = "1hm87jpscv250x8hv3vacw0sdhkwa81x21cxyvc6nf2vsbj5hx9w";
      };
      meta.homepage = "https://github.com/jose-elias-alvarez/typescript.nvim/";
    };
  };
}
