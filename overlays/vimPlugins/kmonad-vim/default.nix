final: prev:
{
  vimPlugins = prev.vimPlugins // {
    kmonad-vim = prev.vimUtils.buildVimPlugin {
      pname = "kmonad-vim";
      version = "2022-03-20";
      src = prev.fetchFromGitHub {
        owner = "kmonad";
        repo = "kmonad-vim";
        rev = "37978445197ab00edeb5b731e9ca90c2b141723f";
        sha256 = "13p3i0b8azkmhafyv8hc4hav1pmgqg52xzvk2a3gp3ppqqx9bwpc";
      };
      meta.homepage = "https://github.com/kmonad/kmonad-vim/";
    };
  };
}
