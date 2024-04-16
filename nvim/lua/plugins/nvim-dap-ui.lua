return {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    lazy = true,
    config = function()
        require("dapui").setup({
            controls = {
                element = "repl",
                enabled = true,
                icons = {
                    disconnect = "",
                    run_last = "",
                    terminate = "⏹︎",
                    pause = "⏸︎",
                    play = "",
                    step_into = "󰆹",
                    step_out = "󰆸",
                    step_over = "",
                    step_back = "",
                },
            },
            floating = {
                border = "single",
                mappings = {
                    close = { "q", "<Esc>" },
                },
            },
            icons = { collapsed = "", expanded = "", current_frame = "" },
            layouts = {
                {
                    elements = {
                        { id = "stacks",      size = 0.30 },
                        { id = "scopes",      size = 0.50 },
                        { id = "breakpoints", size = 0.15 },
                        { id = "watches",     size = 0.05 },
                    },
                    position = "left",
                    size = 60,
                },
                {
                    elements = {
                        { id = "repl", size = 1 },
                        --                        { id = "console", size = 0 },
                    },
                    position = "bottom",
                    size = 20,
                },
            },
        })

        local dap, dapui = require("dap"), require("dapui")
        local group = vim.api.nvim_create_augroup("dapui_config", { clear = true })
        -- hide ~ in DAPUI
        vim.api.nvim_create_autocmd("BufWinEnter", {
            group = group,
            pattern = "DAP*",
            callback = function()
                vim.wo.fillchars = "eob: "
            end,
        })
        vim.api.nvim_create_autocmd("BufWinEnter", {
            group = group,
            pattern = "\\[dap\\-repl\\]",
            callback = function()
                vim.wo.fillchars = "eob: "
            end,
        })

        vim.api.nvim_set_keymap(
            "n",
            "<leader>dh",
            "<cmd>lua require'dapui'.toggle(1)<CR>",
            { noremap = true, silent = true }
        )
        vim.api.nvim_set_keymap(
            "n",
            "<leader>dj",
            "<cmd>lua require'dapui'.toggle(2)<CR>",
            { noremap = true, silent = true }
        )
        dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
        end
        dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
        end
        dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
        end
    end,
}
