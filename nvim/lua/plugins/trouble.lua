return {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},

    -- Lazy load Trouble.nvim when the command or key mappings are triggered
    cmd = { "TroubleToggle", "Trouble" },

    keys = function()
        return {
            -- Toggle diagnostics
            {
                "<leader>tx",
                "<cmd>TroubleToggle diagnostics<cr>",
                desc = "Diagnostics (Trouble)",
            },
            -- Toggle buffer-specific diagnostics
            {
                "<leader>tX",
                "<cmd>TroubleToggle document_diagnostics<cr>",
                desc = "Buffer Diagnostics (Trouble)",
            },
            -- Toggle workspace symbols
            {
                "<leader>ts",
                "<cmd>TroubleToggle lsp_workspace_symbols<cr>",
                desc = "Symbols (Trouble)",
            },
            -- Toggle LSP definitions, references, etc.
            {
                "<leader>tl",
                "<cmd>TroubleToggle lsp_definitions<cr>",
                desc = "LSP Definitions / References (Trouble)",
            },
            -- Toggle location list
            {
                "<leader>tL",
                "<cmd>TroubleToggle loclist<cr>",
                desc = "Location List (Trouble)",
            },
            -- Toggle quickfix list
            {
                "<leader>tQ",
                "<cmd>TroubleToggle quickfix<cr>",
                desc = "Quickfix List (Trouble)",
            },
        }
    end,

    config = function(_, opts)
        require("trouble").setup(opts)
    end,
}
