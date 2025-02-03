return {
    "echasnovski/mini.nvim",
    event = "VeryLazy",
    version = false,
    config = function()
        require("mini.comment").setup({
            options = {
                custom_commentstring = function()
                    local ft = vim.api.nvim_buf_get_option(0, "ft")
                    if ft == "swift" then
                        return "// %s"
                    elseif ft == "python" then
                        return "# %s"
                    elseif ft == "lua" then
                        return "-- %s"
                    elseif ft == "objc" then
                        return "// %s"
                    elseif ft == "typescript" or ft == "javascript" then
                        return "// %s"
                    end
                end,
            },
            mappings = {
                comment_line = "<leader>c",
            },
        })

        require("mini.splitjoin").setup({
            mappings = {
                toggle = "sj",
                split = "",
                join = "",
            },
        })

        -- to easily move code around
        require("mini.move").setup({
            mappings = {
                left = "<A-h>",
                right = "<A-l>",
                down = "J",
                up = "K",
                line_left = "<A-h>",
                line_right = "<A-l>",
                line_down = "J",
                line_up = "K",
            },
        })
        require('mini.trailspace').setup()
    end,
}
