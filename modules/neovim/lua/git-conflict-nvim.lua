local present, gitconflict = pcall(require, "git-conflict")
if not present then
	return
end

gitconflict.setup({
	-- mappings are indicated in lua/whichkey.lua
	default_mappings = false,
})
