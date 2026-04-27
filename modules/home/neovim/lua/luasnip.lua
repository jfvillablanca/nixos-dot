local present, ls = pcall(require, "luasnip")
if not present then
	return
end

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

-- luasnip.add_snippets("lua", {

-- })
