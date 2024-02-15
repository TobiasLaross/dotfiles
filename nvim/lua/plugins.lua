require("options")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    {
        "rebelot/kanagawa.nvim",
        config = function()
            vim.cmd.colorscheme("kanagawa-wave")
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "swift", "typescript", "javascript" },
                auto_install = true,
                highlight = {
                    enable = true,
                },

                incremental_selection = {
                    enable = true,
                    keymaps = {
                        init_selection = "<Leader>ss",
                        node_incremental = "<Leader>si",
                        node_decremental = "<Leader>sd",
                    },
                }
            })
        end,
    },
    {
        "hrsh7th/vim-vsnip",
        event = "InsertEnter",
    },
    {
         "hrsh7th/nvim-cmp",
         event = "InsertEnter",
         dependencies = {
             "hrsh7th/cmp-buffer", -- source for text in buffer
             "hrsh7th/cmp-path", -- source for file system paths
             "L3MON4D3/LuaSnip", -- snippet engine
             "saadparwaiz1/cmp_luasnip", -- for autocompletion
             "rafamadriz/friendly-snippets", -- useful snippets
             "onsails/lspkind.nvim", -- vs-code like pictograms
         },
         config = function()
             local cmp = require("cmp")
             local luasnip = require("luasnip")
             local lspkind = require("lspkind")

             -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
             require("luasnip.loaders.from_vscode").lazy_load()

             cmp.setup({
                 completion = {
                     completeopt = "menu,menuone,preview",
                 },
                 snippet = { -- configure how nvim-cmp interacts with snippet engine
                 expand = function(args)
                     luasnip.lsp_expand(args.body)
                 end,
             },
             mapping = cmp.mapping.preset.insert({
                 ["<C-k>"] = cmp.mapping.select_prev_item(), -- previous suggestion
                 ["<C-j>"] = cmp.mapping.select_next_item(), -- next suggestion
                 ["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
                 ["<C-e>"] = cmp.mapping.abort(), -- close completion window
                 ["<CR>"] = cmp.mapping.confirm({ select = false, behavior = cmp.ConfirmBehavior.Replace }),
                 ["<C-b>"] = cmp.mapping(function(fallback)
                     if luasnip.jumpable(-1) then
                         luasnip.jump(-1)
                     else
                         fallback()
                     end
                 end, { "i", "s" }),
                 ["<C-f>"] = cmp.mapping(function(fallback)
                     if luasnip.jumpable(1) then
                         luasnip.jump(1)
                     else
                         fallback()
                     end
                 end, { "i", "s" }),
             }),
             -- sources for autocompletion
             sources = cmp.config.sources({
                 { name = "nvim_lsp" },
                 { name = "luasnip" }, -- snippets
                 { name = "buffer" }, -- text within current buffer
                 { name = "path" }, -- file system paths
             }),
             -- configure lspkind for vs-code like pictograms in completion menu
             formatting = {
                 format = lspkind.cmp_format({
                     maxwidth = 50,
                     ellipsis_char = "...",
                 }),
             },
         })
     end,
 },
 {
     "antosha417/nvim-lsp-file-operations",
     dependencies = {
         "nvim-lua/plenary.nvim",
         "nvim-tree/nvim-tree.lua",
     },
     config = function()
         require("lsp-file-operations").setup()
     end,
 },
 {
     "neovim/nvim-lspconfig",
     event = { "BufReadPre", "BufNewFile" },
     dependencies = {
         "hrsh7th/cmp-nvim-lsp",
         { "antosha417/nvim-lsp-file-operations", config = true },
     },
     config = function()
         local lspconfig = require("lspconfig")
         local util = require("lspconfig.util")
         local cmp_nvim_lsp = require("cmp_nvim_lsp")
         local capabilities = cmp_nvim_lsp.default_capabilities()
            local opts = { noremap = true, silent = true }
            local on_attach = function(_, bufnr)
                opts.buffer = bufnr

                opts.desc = "Show line diagnostics"
                vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

                opts.desc = "Show documentation for what is under cursor"
                vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
            end

            lspconfig["sourcekit"].setup({
                capabilities = capabilities,
                on_attach = on_attach,
                cmd = {
                    "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
                },
                root_dir = function(filename, _)
                    return util.root_pattern("buildServer.json")(filename)
                    or util.root_pattern("*.xcodeproj", "*.xcworkspace")(filename)
                    or util.find_git_ancestor(filename)
                    or util.root_pattern("Package.swift")(filename)
                end,
            })
        end,
    },
})

