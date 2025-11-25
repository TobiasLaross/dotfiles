return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"folke/neodev.nvim",
		"mason-org/mason.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		"hrsh7th/nvim-cmp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-nvim-lsp",
	},
	config = function()
		require("neodev").setup()
		local cmpNvimLsp = require("cmp_nvim_lsp")
		local capabilities = cmpNvimLsp.default_capabilities()

		local on_attach = function(_, _) end

		vim.lsp.config.lua_ls = {
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
					config = vim.lsp.config.lua_ls,
					root_dir = vim.fs.root(event.buf, { ".git" }),
				})
			end,
		})
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
					cmd = {
						"/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
					},
					capabilities = capabilities,
					on_attach = on_attach,
					root_dir = vim.fs.root(
						event.buf,
						{ ".xcode-build-server", "*.xcodeproj", "*.xcworkspace", ".git", "Package.swift" }
					),
				})
			end,
		})
	end,
}
