local lsp = require("util.lsp")

local function root(find)
    return vim.fs.dirname(vim.fs.find(find, { upward = true })[1])
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = "swift",
    callback = function()
        vim.lsp.start {
            name = "sourcekit",
            cmd = {
                "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
            },
            root_dir = root({ "Package.swift", "buildServer.json", "*.xcodeproj", "*.xcworkspace" }),
            on_attach = lsp.on_attach,
            capabilities = lsp.get_capabilities(),
        }
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "typescript", "javascript" },
    callback = function()
        vim.lsp.start {
            name = "tsserver",
            cmd = { "typescript-language-server", "--stdio" },
            root_dir = root({ "package.json", "tsconfig.json" }),
            on_attach = lsp.on_attach,
            capabilities = lsp.get_capabilities(),
        }
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "lua" },
    callback = function()
        vim.lsp.start {
            name = "lua_ls",
            cmd = { "lua-language-server" },
            root_dir = root({ ".luarc.json", ".luarc.jsonc", ".git" }),
            settings = {
                Lua = {
                    diagnostics = {
                        globals = { "vim" },
                    },
                    workspace = {
                        library = {
                            [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                            [vim.fn.stdpath("config") .. "/lua"] = true,
                        },
                    },
                },
            },
            on_attach = lsp.on_attach,
            capabilities = lsp.get_capabilities(),
        }
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "kotlin" },
    callback = function()
        vim.lsp.start {
            name = "kotlin_language_server",
            cmd = { "kotlin-language-server" },
            root_dir = root({ "settings.gradle", "build.gradle", "build.gradle.kts" }),
            on_attach = lsp.on_attach,
            capabilities = lsp.get_capabilities(),
        }
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "python" },
    callback = function()
        vim.lsp.start {
            name = "pyright",
            cmd = { "pyright-langserver", "--stdio" },
            root_dir = root({ "pyproject.toml", "setup.py", "requirements.txt", ".git" }),
            settings = {
                pyright = {
                    disableOrganizeImports = false,
                    analysis = {
                        useLibraryCodeForTypes = true,
                        autoSearchPaths = true,
                        diagnosticMode = "workspace",
                        autoImportCompletions = true,
                    },
                },
            },
            on_attach = lsp.on_attach,
            capabilities = lsp.get_capabilities(),
        }
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "sh", "bash", "zsh" },
    callback = function()
        vim.lsp.start {
            name = "bashls",
            cmd = { "bash-language-server", "start" },
            root_dir = root({ ".git", ".bashrc" }),
            on_attach = lsp.on_attach,
            capabilities = lsp.get_capabilities(),
        }
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "rust" },
    callback = function()
        vim.lsp.start {
            name = "rust_analyzer",
            cmd = { "rust-analyzer" },
            root_dir = root({ "Cargo.toml", ".git" }),
            on_attach = lsp.on_attach,
            capabilities = lsp.get_capabilities(),
        }
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "json", "objc", "kotlin", "java", "python" },
    callback = function()
        vim.lsp.start {
            name = "efm",
            cmd = { "efm-langserver" },
            root_dir = root({ ".git" }),
            init_options = {
                documentFormatting = true,
                documentRangeFormatting = true,
                hover = true,
                documentSymbol = true,
                codeAction = true,
                completion = true,
            },
            settings = {
                languages = {
                    python = {
                        require("efmls-configs.linters.flake8"),
                        require("efmls-configs.formatters.black"),
                    },
                    json = {
                        require("efmls-configs.formatters.fixjson"),
                    },
                    objc = {
                        require("efmls-configs.formatters.uncrustify"),
                    },
                },
            },
            on_attach = lsp.on_attach,
            capabilities = lsp.get_capabilities(),
        }
    end,
})
