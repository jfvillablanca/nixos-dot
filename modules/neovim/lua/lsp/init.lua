local status_ok, _ = pcall(require, "lspconfig")
if not status_ok then
  return
end

require "mason"
require("handlers").setup()
require "null-ls"
