local status_ok, _ = pcall(require, "lspconfig")
if not status_ok then
  return
end

require "mason"
handlers.setup() -- refactor
require "null-ls"
