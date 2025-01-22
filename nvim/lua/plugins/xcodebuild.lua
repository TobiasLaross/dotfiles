local progress_handle

return {
    "wojciech-kulik/xcodebuild.nvim",
    dependencies = {
        "nvim-telescope/telescope.nvim",
        "MunifTanjim/nui.nvim",
        "nvim-tree/nvim-tree.lua",   -- (optional) to manage project files
        "stevearc/oil.nvim",         -- (optional) to manage project files
        "nvim-treesitter/nvim-treesitter", -- (optional) for Quick tests support (required Swift parser)
    },
    config = function()
        require("xcodebuild").setup({
            show_build_progress_bar = true, -- shows [ ...    ] progress bar during build, based on the last duration
            logs = {
                notify = function(message, severity)
                    local fidget = require("fidget")
                    if progress_handle then
                        progress_handle.message = message
                        if not message:find("Loading") then
                            progress_handle:finish()
                            progress_handle = nil
                            if vim.trim(message) ~= "" then
                                fidget.notify(message, severity)
                            end
                        end
                    else
                        fidget.notify(message, severity)
                    end
                end,
                notify_progress = function(message)
                    local progress = require("fidget.progress")

                    if progress_handle then
                        progress_handle.title = ""
                        progress_handle.message = message
                    else
                        progress_handle = progress.handle.create({
                            message = message,
                            lsp_client = { name = "xcodebuild.nvim" },
                        })
                    end
                end,
                auto_open_on_success_tests = false, -- open logs when tests succeeded
                auto_open_on_failed_tests = false, -- open logs when tests failed
                auto_open_on_success_build = false, -- open logs when build succeeded
                auto_open_on_failed_build = false, -- open logs when build failed
                auto_close_on_app_launch = false, -- close logs when app is launched
                auto_close_on_success_build = false, -- close logs when build succeeded (only if auto_open_on_success_build=false)
                auto_focus = true,
            },
            code_coverage = {
                enabled = true,
            },
            integrations = {
                xcode_build_server = {
                    enabled = true, -- run "xcode-build-server config" when scheme changes
                },
                pymobiledevice = {
                    enabled = true,
                },
                xcodebuild_offline = {
                    enabled = false, -- improves build time (requires configuration, see `:h xcodebuild.xcodebuild-offline`)
                },
            },
            commands = {
                extra_build_args = { "-parallelizeTargets" }, -- extra arguments for `xcodebuild build`
                extra_test_args = { "-parallelizeTargets" }, -- extra arguments for `xcodebuild test`
            },
        })

        vim.keymap.set("n", "<leader>xl", "<cmd>XcodebuildToggleLogs<cr>", { desc = "Toggle Xcodebuild Logs" })
        vim.keymap.set("n", "<leader>xb", "<cmd>XcodebuildBuild<cr>", { desc = "Build Project" })
        vim.keymap.set("n", "<leader>xx", "<cmd>XcodebuildBuildRun<cr>", { desc = "Build & Run Project" })
        vim.keymap.set("n", "<leader>xo", "<cmd>XcodebuildOpenInXcode<cr>", { desc = "Open Project in Xcode" })
        vim.keymap.set("n", "<leader>xr", "<cmd>XcodebuildRun<cr>", { desc = "Build & Run Project" })
        vim.keymap.set("n", "<leader>xt", "<cmd>XcodebuildTest<cr>", { desc = "Run Tests" })
        vim.keymap.set("n", "<leader>xT", "<cmd>XcodebuildTestClass<cr>", { desc = "Run This Test Class" })
        vim.keymap.set("n", "<leader>X", "<cmd>XcodebuildPicker<cr>", { desc = "Show All Xcodebuild Actions" })
        vim.keymap.set(
            "n",
            "<leader>xm",
            "<cmd>XcodebuildProjectManager<cr>",
            { desc = "Show Project Manager Actions" }
        )
        vim.keymap.set("n", "<leader>xa", "<cmd>XcodebuildCodeActions<cr>", { desc = "Show Code Actions" })
        vim.keymap.set("n", "<leader>xf", "<cmd>XcodebuildQuickfixLine<cr>", { desc = "Quickfix Line" })
        vim.keymap.set("n", "<leader>xd", "<cmd>XcodebuildSelectDevice<cr>", { desc = "Select Device" })
        vim.keymap.set("n", "<leader>xp", "<cmd>XcodebuildSelectTestPlan<cr>", { desc = "Select Test Plan" })
        vim.keymap.set("n", "<leader>xc", "<cmd>XcodebuildCancel<cr>", { desc = "Cancel Build" })
        vim.keymap.set("n", "<leader>xC", "<cmd>XcodebuildToggleCodeCoverage<cr>", { desc = "Toggle Code Coverage" })
    end,
}
