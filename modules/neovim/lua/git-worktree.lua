local status_ok, worktree = pcall(require, "git-worktree")
if not status_ok then
	return
end

worktree.setup({
    change_directory_command = "cd",     -- default: "cd",
    update_on_change = true,             -- default: true,
    update_on_change_command = "e .",    -- default: "e .",
    clearjumps_on_change = true,         -- default: true,
    autopush = false,                    -- default: false,
})
worktree.on_tree_change(function(op, metadata)
  if op == worktree.Operations.Switch then
    print("Switched from " .. metadata.prev_path .. " to " .. metadata.path)
  end
end)
require("telescope").load_extension("git_worktree")
