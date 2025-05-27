return {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    event        = { "BufReadPre", "BufNewFile" },

    opts         = {
        ensure_installed = {
            "bashls",
            "efm",
            "clangd",
            "dockerls",
            "lua_ls",
            "pyright",
            "rust_analyzer",
            "ts_ls",
        },

        handlers = {
            -- default handler
            function(server_name)
                require("lspconfig")[server_name].setup({
                    on_attach    = require("util.lsp").on_attach,
                    capabilities = require("cmp_nvim_lsp")
                        .default_capabilities(vim.lsp.protocol.make_client_capabilities()),
                })
            end,

            ["lua_ls"] = function()
                local lspconfig = require("lspconfig")
                lspconfig.lua_ls.setup({
                    on_attach    = require("util.lsp").on_attach,
                    capabilities = require("cmp_nvim_lsp")
                        .default_capabilities(vim.lsp.protocol.make_client_capabilities()),
                    settings     = {
                        Lua = {
                            diagnostics = { globals = { "vim" } },
                            workspace   = {
                                library = {
                                    [vim.fn.expand("$VIMRUNTIME/lua")]   = true,
                                    [vim.fn.stdpath("config") .. "/lua"] = true,
                                },
                            },
                        },
                    },
                })
            end,

            ["kotlin_language_server"] = function()
                require("lspconfig").kotlin_language_server.setup({
                    on_attach    = require("util.lsp").on_attach,
                    capabilities = require("cmp_nvim_lsp")
                        .default_capabilities(vim.lsp.protocol.make_client_capabilities()),
                })
            end,

            ["pyright"] = function()
                require("lspconfig").pyright.setup({
                    on_attach    = require("util.lsp").on_attach,
                    capabilities = require("cmp_nvim_lsp")
                        .default_capabilities(vim.lsp.protocol.make_client_capabilities()),
                    settings     = {
                        pyright = {
                            disableOrganizeImports = false,
                            analysis = {
                                useLibraryCodeForTypes = true,
                                autoSearchPaths        = true,
                                diagnosticMode         = "workspace",
                                autoImportCompletions  = true,
                            },
                        },
                    },
                })
            end,

            ["ts_ls"] = function()
                require("lspconfig").ts_ls.setup({
                    on_attach    = require("util.lsp").on_attach,
                    capabilities = require("cmp_nvim_lsp")
                        .default_capabilities(vim.lsp.protocol.make_client_capabilities()),
                    filetypes    = { "typescript", "javascript" },
                    root_dir     = require("lspconfig.util")
                        .root_pattern("package.json", "tsconfig.json"),
                })
            end,

            ["bashls"] = function()
                require("lspconfig").bashls.setup({
                    on_attach    = require("util.lsp").on_attach,
                    capabilities = require("cmp_nvim_lsp")
                        .default_capabilities(vim.lsp.protocol.make_client_capabilities()),
                    filetypes    = { "sh", "bash", "zsh" },
                })
            end,

            ["efm"] = function()
                require("lspconfig").efm.setup({
                    on_attach    = require("util.lsp").on_attach,
                    capabilities = require("cmp_nvim_lsp")
                        .default_capabilities(vim.lsp.protocol.make_client_capabilities()),

                    -- restrict efm to just these filetypes
                    filetypes    = { "python", "json", "objc", "kotlin", "java" },

                    init_options = {
                        documentFormatting      = true,
                        documentRangeFormatting = true,
                        hover                   = true,
                        documentSymbol          = true,
                        codeAction              = true,
                        completion              = true,
                    },
                    settings     = {
                        languages = {
                            python = {
                                require("efmls-configs.linters.flake8"),
                                require("efmls-configs.formatters.black"),
                            },
                            json = { require("efmls-configs.formatters.fixjson") },
                            objc = { require("efmls-configs.formatters.uncrustify") },
                        },
                    },
                })
            end,

            ["rust_analyzer"] = function()
                require("lspconfig").rust_analyzer.setup({
                    on_attach    = require("util.lsp").on_attach,
                    capabilities = require("cmp_nvim_lsp")
                        .default_capabilities(vim.lsp.protocol.make_client_capabilities()),
                    settings     = {
                        ["rust-analyzer"] = {
                            cargo       = { allFeatures = true },
                            checkOnSave = { command = "clippy" },
                        },
                    },
                })
            end,
        },
    },
}
