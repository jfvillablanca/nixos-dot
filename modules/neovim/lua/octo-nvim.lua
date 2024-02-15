local present, octo = pcall(require, "octo")
if not present then
    return
end

octo.setup({
    -- use local files on right side of reviews
    use_local_fs = false,
    -- shows a list of builtin actions when no action is provided
    enable_builtin = false,
    -- order to try remotes
    default_remote = { "upstream", "origin" },
    -- default merge method which should be used when calling `Octo pr merge`, could be `commit`, `rebase` or `squash`
    default_merge_method = "commit",
    -- SSH aliases. e.g. `ssh_aliases = {["github.com-work"] = "github.com"}`
    ssh_aliases = {},
    -- or "telescope" | "fzf-lua"
    picker = "telescope",
    picker_config = {
        -- only used by "fzf-lua" picker for now
        use_emojis = false,
        -- mappings for the pickers
        mappings = {
            open_in_browser = { lhs = "<C-b>", desc = "open issue in browser" },
            copy_url = { lhs = "<C-y>", desc = "copy url to system clipboard" },
            checkout_pr = { lhs = "<C-o>", desc = "checkout pull request" },
            merge_pr = { lhs = "<C-r>", desc = "merge pull request" },
        },
    },
    -- comment marker
    comment_icon = "▎",
    -- outdated indicator
    outdated_icon = "󰅒 ",
    -- resolved indicator
    resolved_icon = " ",
    -- marker for user reactions
    reaction_viewer_hint_icon = " ",
    -- user icon
    user_icon = " ",
    -- timeline marker
    timeline_marker = " ",
    -- timeline indentation
    timeline_indent = "2",
    -- bubble delimiter
    right_bubble_delimiter = "",
    -- bubble delimiter
    left_bubble_delimiter = "",
    -- GitHub Enterprise host
    github_hostname = "",
    -- number or lines around commented lines
    snippet_context_lines = 4,
    -- extra environment variables to pass on to GitHub CLI, can be a table or function returning a table
    gh_env = {},
    -- timeout for requests between the remote server
    timeout = 5000,
    -- use projects v2 for the `Octo card ...` command by default.
    -- Both legacy and v2 commands are available under `Octo cardlegacy ...` and `Octo cardv2 ...` respectively.
    default_to_projects_v2 = false,
    -- show "modified" marks on the sign column
    ui = {
        use_signcolumn = true,
    },
    issues = {
        -- criteria to sort results of `Octo issue list`
        order_by = {
            -- either COMMENTS, CREATED_AT or UPDATED_AT
            -- (https://docs.github.com/en/graphql/reference/enums#issueorderfield)
            field = "CREATED_AT",
            -- either DESC or ASC (https://docs.github.com/en/graphql/reference/enums#orderdirection)
            direction = "DESC",
        },
    },
    pull_requests = {
        -- criteria to sort the results of `Octo pr list`
        order_by = {
            -- either COMMENTS, CREATED_AT or UPDATED_AT
            -- (https://docs.github.com/en/graphql/reference/enums#issueorderfield)
            field = "CREATED_AT",
            -- either DESC or ASC (https://docs.github.com/en/graphql/reference/enums#orderdirection)
            direction = "DESC",
        },
        -- always give prompt to select base remote repo when creating PRs
        always_select_remote_on_create = false,
    },
    file_panel = {
        -- changed files panel rows
        size = 10,
        -- use web-devicons in file panel (if false, nvim-web-devicons does not need to be installed)
        use_icons = true,
    },
    -- used for highlight groups (see Colors section below)
    colors = {
        white = "#ffffff",
        grey = "#2A354C",
        black = "#000000",
        red = "#fdb8c0",
        dark_red = "#da3633",
        green = "#acf2bd",
        dark_green = "#238636",
        yellow = "#d3c846",
        dark_yellow = "#735c0f",
        blue = "#58A6FF",
        dark_blue = "#0366d6",
        purple = "#6f42c1",
    },
})
