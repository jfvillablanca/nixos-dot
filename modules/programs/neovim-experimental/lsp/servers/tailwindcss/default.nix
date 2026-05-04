{lib, ...}: {
  flake.modules.nvim.lsp-tailwindcss = {pkgs, ...}: {
    nvim.lsp.servers.tailwindcss = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.tailwindcss-language-server;
      cmd = ["${lib.getExe pkgs.tailwindcss-language-server}" "--stdio"];
      filetypes = [
        "html"
        "css"
        "scss"
        "less"
        "postcss"
        "javascript"
        "javascriptreact"
        "typescript"
        "typescriptreact"
        "vue"
        "svelte"
        "astro"
        "elixir"
        "phoenix"
        "heex"
        "django-html"
        "htmldjango"
      ];
      root_markers = [
        "tailwind.config.js"
        "tailwind.config.ts"
        "postcss.config.js"
        "postcss.config.ts"
        ".git"
      ];
      init_options.userLanguages = {
        eelixir = "html-eex";
        eruby = "erb";
      };
      settings.tailwindCSS = {
        classAttributes = ["class" "className" "classList" "ngClass"];
        lint = {
          cssConflict = "warning";
          invalidApply = "error";
          invalidConfigPath = "error";
          invalidScreen = "error";
          invalidTailwindDirective = "error";
          invalidVariant = "error";
          recommendedVariantOrder = "warning";
        };
        validate = true;
      };
    };
  };
}
