local present, octo = pcall(require, "octo")
if not present then
    return
end

octo.setup({
    -- use local files on right side of reviews
    use_local_fs = true,
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
    timeline_indent = 2,
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
    mappings = {
        issue = {
            close_issue = { lhs = "gOic", desc = "close issue" },
            reopen_issue = { lhs = "gOio", desc = "reopen issue" },
            list_issues = { lhs = "gOil", desc = "list open issues on same repo" },
            -- reload = { lhs = "<C-r>", desc = "reload issue" },
            -- open_in_browser = { lhs = "<C-b>", desc = "open issue in browser" },
            copy_url = { lhs = "<C-y>", desc = "copy url to system clipboard" },
            add_assignee = { lhs = "gOaa", desc = "add assignee" },
            remove_assignee = { lhs = "gOad", desc = "remove assignee" },
            create_label = { lhs = "gOlc", desc = "create label" },
            add_label = { lhs = "gOla", desc = "add label" },
            remove_label = { lhs = "gOld", desc = "remove label" },
            goto_issue = { lhs = "gOgi", desc = "navigate to a local repo issue" },
            add_comment = { lhs = "gOca", desc = "add comment" },
            delete_comment = { lhs = "gOcd", desc = "delete comment" },
            next_comment = { lhs = "]c", desc = "go to next comment" },
            prev_comment = { lhs = "[c", desc = "go to previous comment" },
            react_hooray = { lhs = "gOrp", desc = "add/remove 🎉 reaction" },
            react_heart = { lhs = "gOrh", desc = "add/remove ❤️ reaction" },
            react_eyes = { lhs = "gOre", desc = "add/remove 👀 reaction" },
            react_thumbs_up = { lhs = "gOr+", desc = "add/remove 👍 reaction" },
            react_thumbs_down = { lhs = "gOr-", desc = "add/remove 👎 reaction" },
            react_rocket = { lhs = "gOrr", desc = "add/remove 🚀 reaction" },
            react_laugh = { lhs = "gOrl", desc = "add/remove 😄 reaction" },
            react_confused = { lhs = "gOrc", desc = "add/remove 😕 reaction" },
        },
        pull_request = {
            checkout_pr = { lhs = "gOpo", desc = "checkout PR" },
            merge_pr = { lhs = "gOpm", desc = "merge commit PR" },
            squash_and_merge_pr = { lhs = "gOpsm", desc = "squash and merge PR" },
            rebase_and_merge_pr = { lhs = "gOprm", desc = "rebase and merge PR" },
            list_commits = { lhs = "gOpc", desc = "list PR commits" },
            list_changed_files = { lhs = "gOpf", desc = "list PR changed files" },
            show_pr_diff = { lhs = "gOpd", desc = "show PR diff" },
            add_reviewer = { lhs = "gOva", desc = "add reviewer" },
            remove_reviewer = { lhs = "gOvd", desc = "remove reviewer request" },
            close_issue = { lhs = "gOic", desc = "close PR" },
            reopen_issue = { lhs = "gOio", desc = "reopen PR" },
            list_issues = { lhs = "gOil", desc = "list open issues on same repo" },
            reload = { lhs = "<C-r>", desc = "reload PR" },
            open_in_browser = { lhs = "<C-b>", desc = "open PR in browser" },
            copy_url = { lhs = "<C-y>", desc = "copy url to system clipboard" },
            goto_file = { lhs = "gf", desc = "go to file" },
            add_assignee = { lhs = "gOaa", desc = "add assignee" },
            remove_assignee = { lhs = "gOad", desc = "remove assignee" },
            create_label = { lhs = "gOlc", desc = "create label" },
            add_label = { lhs = "gOla", desc = "add label" },
            remove_label = { lhs = "gOld", desc = "remove label" },
            goto_issue = { lhs = "gOgi", desc = "navigate to a local repo issue" },
            add_comment = { lhs = "gOca", desc = "add comment" },
            delete_comment = { lhs = "gOcd", desc = "delete comment" },
            next_comment = { lhs = "]c", desc = "go to next comment" },
            prev_comment = { lhs = "[c", desc = "go to previous comment" },
            react_hooray = { lhs = "gOrp", desc = "add/remove 🎉 reaction" },
            react_heart = { lhs = "gOrh", desc = "add/remove ❤️ reaction" },
            react_eyes = { lhs = "gOre", desc = "add/remove 👀 reaction" },
            react_thumbs_up = { lhs = "gOr+", desc = "add/remove 👍 reaction" },
            react_thumbs_down = { lhs = "gOr-", desc = "add/remove 👎 reaction" },
            react_rocket = { lhs = "gOrr", desc = "add/remove 🚀 reaction" },
            react_laugh = { lhs = "gOrl", desc = "add/remove 😄 reaction" },
            react_confused = { lhs = "gOrc", desc = "add/remove 😕 reaction" },
            review_start = { lhs = "gOvs", desc = "start a review for the current PR" },
            review_resume = { lhs = "gOvr", desc = "resume a pending review for the current PR" },
        },
        review_thread = {
            goto_issue = { lhs = "gOgi", desc = "navigate to a local repo issue" },
            add_comment = { lhs = "gOac", desc = "add comment" },
            add_suggestion = { lhs = "gOas", desc = "add suggestion" },
            delete_comment = { lhs = "gOcd", desc = "delete comment" },
            next_comment = { lhs = "]c", desc = "go to next comment" },
            prev_comment = { lhs = "[c", desc = "go to previous comment" },
            select_next_entry = { lhs = "]q", desc = "move to previous changed file" },
            select_prev_entry = { lhs = "[q", desc = "move to next changed file" },
            select_first_entry = { lhs = "[Q", desc = "move to first changed file" },
            select_last_entry = { lhs = "]Q", desc = "move to last changed file" },
            close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
            react_hooray = { lhs = "gOrp", desc = "add/remove 🎉 reaction" },
            react_heart = { lhs = "gOrh", desc = "add/remove ❤️ reaction" },
            react_eyes = { lhs = "gOre", desc = "add/remove 👀 reaction" },
            react_thumbs_up = { lhs = "gOr+", desc = "add/remove 👍 reaction" },
            react_thumbs_down = { lhs = "gOr-", desc = "add/remove 👎 reaction" },
            react_rocket = { lhs = "gOrr", desc = "add/remove 🚀 reaction" },
            react_laugh = { lhs = "gOrl", desc = "add/remove 😄 reaction" },
            react_confused = { lhs = "gOrc", desc = "add/remove 😕 reaction" },
        },
        submit_win = {
            approve_review = { lhs = "<C-o>", desc = "approve review" },
            comment_review = { lhs = "<C-m>", desc = "comment review" },
            request_changes = { lhs = "<C-r>", desc = "request changes review" },
            close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
        },
        review_diff = {
            submit_review = { lhs = "gOvs", desc = "submit review" },
            discard_review = { lhs = "gOvd", desc = "discard review" },
            add_review_comment = { lhs = "gOac", desc = "add a new review comment" },
            add_review_suggestion = { lhs = "gOas", desc = "add a new review suggestion" },
            focus_files = { lhs = "gOe", desc = "move focus to changed file panel" },
            toggle_files = { lhs = "gOb", desc = "hide/show changed files panel" },
            next_thread = { lhs = "]t", desc = "move to next thread" },
            prev_thread = { lhs = "[t", desc = "move to previous thread" },
            select_next_entry = { lhs = "]q", desc = "move to previous changed file" },
            select_prev_entry = { lhs = "[q", desc = "move to next changed file" },
            select_first_entry = { lhs = "[Q", desc = "move to first changed file" },
            select_last_entry = { lhs = "]Q", desc = "move to last changed file" },
            close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
            toggle_viewed = { lhs = "gO<space>", desc = "toggle viewer viewed state" },
            goto_file = { lhs = "gOf", desc = "go to file" },
        },
        file_panel = {
            submit_review = { lhs = "gOvs", desc = "submit review" },
            discard_review = { lhs = "gOvd", desc = "discard review" },
            next_entry = { lhs = "<Down>", desc = "move to next changed file" },
            prev_entry = { lhs = "<Up>", desc = "move to previous changed file" },
            select_entry = { lhs = "<cr>", desc = "show selected changed file diffs" },
            refresh_files = { lhs = "R", desc = "refresh changed files panel" },
            focus_files = { lhs = "gOe", desc = "move focus to changed file panel" },
            toggle_files = { lhs = "gOb", desc = "hide/show changed files panel" },
            select_next_entry = { lhs = "]q", desc = "move to previous changed file" },
            select_prev_entry = { lhs = "[q", desc = "move to next changed file" },
            select_first_entry = { lhs = "[Q", desc = "move to first changed file" },
            select_last_entry = { lhs = "]Q", desc = "move to last changed file" },
            close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
            toggle_viewed = { lhs = "gO<space>", desc = "toggle viewer viewed state" },
        },
    },
})
