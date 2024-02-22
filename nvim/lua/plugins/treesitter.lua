return {
    "nvim-treesitter/nvim-treesitter",
    config = function()
        require("nvim-treesitter.configs").setup({
            ensure_installed = {
                "c",
                "lua",
                "vim",
                "vimdoc",
                "query",
                "swift",
                "typescript",
                "javascript",
                "markdown",
                "markdown_inline",
            },
            auto_install = true,
            highlight = {
                enable = true,
            },
            autopairs = {
                enable = true,
            },

            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "<Leader>ss",
                    node_incremental = "<Leader>si",
                    node_decremental = "<Leader>sd",
                },
            },
        })
    end,
}
