return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "wojciech-kulik/xcodebuild.nvim",
        "theHamsta/nvim-dap-virtual-text",
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
        "williamboman/mason.nvim",
    },
    config = function()
        local dap = require("dap")
        local xcodebuild = require("xcodebuild.dap")
        local codelldbPath = os.getenv("HOME") .. "/Developer/codelldb-aarch64-darwin/extension/adapter/codelldb"

        xcodebuild.setup(codelldbPath)
        require("dap").configurations.swift[1].postRunCommands = {
            "breakpoint delete cpp_exception",
        }

        dap.listeners.after.event_initialized["remove_cpp_exception"] = function(session)
            session:request("evaluate", {
                expression = "breakpoint delete cpp_exception",
                context = "repl",
            })
        end

        require("nvim-dap-virtual-text").setup({
            display_callback = function(variable)
                if #variable.value > 15 then
                    return " " .. string.sub(variable.value, 1, 15) .. "... "
                end

                return " " .. variable.value
            end,
        })

        local define = vim.fn.sign_define
        define("DapBreakpoint", { text = "", texthl = "DiagnosticError", linehl = "", numhl = "" })
        define("DapBreakpointRejected", { text = "", texthl = "DiagnosticError", linehl = "", numhl = "" })
        define("DapStopped", { text = "", texthl = "DiagnosticOk", linehl = "", numhl = "" })
        define("DapLogPoint", { text = "", texthl = "DiagnosticInfo", linehl = "", numhl = "" })
        define("DapLogPoint", { text = "", texthl = "DiagnosticInfo", linehl = "", numhl = "" })

        -- integration with xcodebuild.nvim
        vim.keymap.set("n", "<leader>dd", xcodebuild.build_and_debug, { desc = "Build & Debug" })
        vim.keymap.set("n", "<leader>dr", xcodebuild.debug_without_build, { desc = "Debug Without Building" })
        vim.keymap.set("n", "<leader>dt", xcodebuild.debug_tests, { desc = "Debug Tests" })
        vim.keymap.set("n", "<leader>dT", xcodebuild.debug_class_tests, { desc = "Debug Class Tests" })

        vim.keymap.set("n", "<leader>dc", dap.continue)
        vim.keymap.set("n", "<leader>ds", dap.step_over)
        vim.keymap.set("n", "<leader>di", dap.step_into)
        vim.keymap.set("n", "<leader>do", dap.step_out)
        vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint)

        vim.keymap.set("n", "<leader>dk", function()
            require("dapui").eval(nil, { enter = true })
        end)
        vim.keymap.set("n", "<leader>dx", xcodebuild.terminate_session, { desc = "Terminate Debugger" })
        vim.keymap.set("n", "<leader>dm", function()
            dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
        end)
    end,
}
