return {
    "tpope/vim-fugitive",
    cmd = { "Git", "Gdiffsplit", "Gread", "Gwrite" }, -- Lazy loading commands
    keys = {
        { "<leader>gs",  "<cmd>Git develop<CR>",         desc = "Open Git Status" },
        { "<leader>gb",  "<cmd>G blame<CR>",             desc = "Open Git Blame" },
        { "<leader>gl",  "<cmd>G log<CR>",               desc = "Open Git log pane" },
        { "<leader>gdl", "<cmd>Gvdiffsplit<CR>",         desc = "Git Diff Split" },
        { "<leader>gdd", "<cmd>Gvdiffsplit develop<CR>", desc = "Git Diff Split against develop" },
        { "<leader>gtl", "<cmd>G difftool<CR>",          desc = "Open Git diff tool" },
        { "<leader>gtd", "<cmd>G difftool develop<CR>",  desc = "Open Git diff tool against develop" },
        { "<leader>gj",  "<cmd>cnext<CR>",               desc = "Find next diff" },
        { "<leader>gk",  "<cmd>cprevious<CR>",           desc = "Find previous diff" },
        -- Add more keybindings as desired
    },
    config = function()
        -- Optional: Additional configuration can go here
    end,
}
