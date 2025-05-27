-- Lazy.nvim plugin specification
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
        local on_attach = require("util.lsp").on_attach
        local lspconfig = require("lspconfig")
        local caps      = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

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
    end,
}
