# texlab — LaTeX language server. Replaces vimtex-driven LaTeX support per
# the Phase 1 plan. Disabled by default (LaTeX is host-specific).
{lib, ...}: {
  flake.modules.nvim.lsp-texlab = {pkgs, ...}: {
    nvim.lsp.servers.texlab = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.texlab;
      cmd = ["${lib.getExe pkgs.texlab}"];
      filetypes = ["tex" "plaintex" "bib"];
      root_markers = [
        ".latexmkrc"
        ".texlabroot"
        "texlabroot"
        "Tectonic.toml"
        ".git"
      ];
      settings.texlab = {
        rootDirectory = null;
        build = {
          executable = "latexmk";
          args = ["-pdf" "-interaction=nonstopmode" "-synctex=1" "%f"];
          onSave = false;
          forwardSearchAfter = false;
        };
        forwardSearch = {
          executable = null;
          args = [];
        };
        chktex = {
          onOpenAndSave = false;
          onEdit = false;
        };
        diagnosticsDelay = 300;
        latexFormatter = "latexindent";
        latexindent = {
          modifyLineBreaks = false;
        };
        bibtexFormatter = "texlab";
        formatterLineLength = 80;
      };
    };
  };
}
