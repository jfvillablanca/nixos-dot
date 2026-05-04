# pylsp — python-lsp-server. Default off; opt in per host via factory
# extraModules when the host does regular Python work. Disables formatting
# (defer to none-ls black + isort).
{lib, ...}: {
  flake.modules.nvim.lsp-pylsp = {pkgs, ...}: {
    nvim.lsp.servers.pylsp = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.python3Packages.python-lsp-server;
      cmd = ["${pkgs.python3Packages.python-lsp-server}/bin/pylsp"];
      filetypes = ["python"];
      root_markers = ["pyproject.toml" "setup.py" "setup.cfg" "requirements.txt" "Pipfile" ".git"];
      settings.pylsp.plugins = {
        # The pylsp-bundled formatter set conflicts with none-ls's black +
        # isort. Disable here so pylsp focuses on diagnostics + completion.
        autopep8.enabled = false;
        yapf.enabled = false;
        black.enabled = false;
        # Linters: pyflakes for fast errors; flake8/pylint left default-off
        # so projects that want them turn them on per-host.
        pyflakes.enabled = true;
        pycodestyle.enabled = false;
      };
    };

    nvim.lsp.formatProviderDisable = ["pylsp"];
  };
}
