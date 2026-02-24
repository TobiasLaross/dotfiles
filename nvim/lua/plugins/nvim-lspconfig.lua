return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"folke/neodev.nvim",
		"mason-org/mason.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		"saghen/blink.cmp",
	},
	config = function()
		require("neodev").setup()

		local capabilities = require("blink.cmp").get_lsp_capabilities()
		local on_attach = function(_, _) end

		vim.lsp.config.lua_ls = {
			cmd = { "lua-language-server" },
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				Lua = {
					diagnostics = { globals = { "vim" } },
					workspace = { library = vim.api.nvim_get_runtime_file("", true) },
				},
			},
		}

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "lua",
			callback = function(event)
				vim.lsp.start({
					name = "lua_ls",
					cmd = vim.lsp.config.lua_ls.cmd,
					capabilities = vim.lsp.config.lua_ls.capabilities,
					on_attach = vim.lsp.config.lua_ls.on_attach,
					settings = vim.lsp.config.lua_ls.settings,
					root_dir = vim.fs.root(event.buf, { ".git" }),
				})
			end,
		})

		vim.lsp.config.sourcekit = {
			cmd = {
				"/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
			},
			capabilities = capabilities,
			on_attach = on_attach,
		}

		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "swift", "objc", "c", "cpp", "objective-cpp" },
			callback = function(event)
				vim.lsp.start({
					name = "sourcekit",
					cmd = vim.lsp.config.sourcekit.cmd,
					capabilities = vim.lsp.config.sourcekit.capabilities,
					on_attach = vim.lsp.config.sourcekit.on_attach,
					root_dir = vim.fs.root(event.buf, {
						".xcode-build-server",
						"*.xcodeproj",
						"*.xcworkspace",
						".git",
						"Package.swift",
					}),
				})
			end,
		})
	end,
}
