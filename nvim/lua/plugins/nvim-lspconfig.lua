return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        "williamboman/mason.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        "hrsh7th/nvim-cmp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
        local lspconfig = require("lspconfig")
        local cmp_nvim_lsp = require("cmp_nvim_lsp")
        local keymap = vim.keymap -- for conciseness
        local opts = { noremap = true, silent = true }
        local on_attach = function(_, bufnr)
            opts.buffer = bufnr

            lspconfig.sourcekit.setup({
                on_attach    = on_attach,
                capabilities = caps,
                filetypes    = { "swift", "objc", "c", "cpp", "objective-cpp" },
                cmd          = {
                    "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
                },
                root_dir     = function(fname)
                    local u = require("lspconfig.util")
                    return u.root_pattern("buildServer.json")(fname)
                        or u.root_pattern("*.xcodeproj", "*.xcworkspace")(fname)
                        or u.find_git_ancestor(fname)
                        or u.root_pattern("Package.swift")(fname)
                end,
            })
        end

        local capabilities = cmp_nvim_lsp.default_capabilities()

        local defaultLSPs = {
            "sourcekit",
        }

        for _, lsp in ipairs(defaultLSPs) do
            lspconfig[lsp].setup({
                capabilities = capabilities,
                on_attach = on_attach,
                cmd = lsp == "sourcekit" and { vim.trim(vim.fn.system("xcrun -f sourcekit-lsp")) } or nil,
            })
        end
    end
}
