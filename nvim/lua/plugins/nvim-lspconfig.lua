return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        "mason-org/mason.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        "hrsh7th/nvim-cmp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
        local cmpNvimLsp = require("cmp_nvim_lsp")
        local capabilities = cmpNvimLsp.default_capabilities()

        local on_attach = function(_, _) end

        vim.lsp.config.sourcekit = {
            on_attach = on_attach,
            capabilities = capabilities,
            cmd = {
                "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
            },
        }

        vim.api.nvim_create_autocmd("FileType", {
            pattern = { "swift", "objc", "c", "cpp", "objective-cpp" },
            callback = function(event)
                vim.lsp.start({
                    name = "sourcekit",
                    config = vim.lsp.config.sourcekit,
                    root_dir = vim.fs.root(event.buf,
                        { "buildServer.json", "*.xcodeproj", "*.xcworkspace", ".git", "Package.swift" }),
                })
            end,
        })
    end,
}
