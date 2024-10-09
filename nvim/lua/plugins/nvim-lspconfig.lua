local on_attach = require("util.lsp").on_attach

local config = function()
	local lspconfig = require("lspconfig")
	local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())
	lspconfig.sourcekit.setup({
		on_attach = on_attach,
		capabilities = capabilities,
		filetypes = {
			"swift",
			"objc",
			"c",
			"cpp",
			"objective-cpp",
		},
		cmd = {
			"/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
			-- "/Library/Developer/Toolchains/swift-DEVELOPMENT-SNAPSHOT-2024-05-15-a.xctoolchain/usr/bin/sourcekit-lsp",
			-- "/Users/tobias/Developer/sourcekit-lsp/.build/release/sourcekit-lsp",
		},
		root_dir = function(filename, _)
			local util = require("lspconfig.util")
			return util.root_pattern("buildServer.json")(filename)
				or util.root_pattern("*.xcodeproj", "*.xcworkspace")(filename)
				or util.find_git_ancestor(filename)
				or util.root_pattern("Package.swift")(filename)
		end,
	})

	require("mason-lspconfig").setup_handlers({
		["lua_ls"] = function()
			lspconfig.lua_ls.setup({
				capabilities = capabilities,
				on_attach = on_attach,
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
			})
		end,
		["kotlin_language_server"] = function()
			lspconfig.kotlin_language_server.setup({
				capabilities = capabilities,
				on_attach = on_attach,
			})
		end,
		["pyright"] = function()
			lspconfig.pyright.setup({
				capabilities = capabilities,
				on_attach = on_attach,
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
			})
		end,
		["ts_ls"] = function()
			lspconfig.ts_ls.setup({
				on_attach = on_attach,
				capabilities = capabilities,
				filetypes = {
					"typescript",
					"javascript",
				},
				root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json"),
			})
		end,
		["bashls"] = function()
			lspconfig.bashls.setup({
				capabilities = capabilities,
				on_attach = on_attach,
				filetypes = { "sh", "bash", "zsh" },
			})
		end,
		["efm"] = function()
			lspconfig.efm.setup({
				filetypes = {
					"lua",
					"python",
					"json",
					"javascript",
					"typescript",
					"objc",
					"kotlin",
					"java",
				},
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
						lua = { require("efmls-configs.linters.luacheck"), require("efmls-configs.formatters.stylua") },
						python = { require("efmls-configs.linters.flake8"), require("efmls-configs.formatters.black") },
						typescript = {
							require("efmls-configs.linters.eslint_d"),
							-- require("efmls-configs.formatters.prettier_d"),
						},
						json = { require("efmls-configs.formatters.fixjson") },
						javascript = {
							require("efmls-configs.linters.eslint_d"),
							require("efmls-configs.formatters.prettier_d"),
						},
						objc = {
							require("efmls-configs.formatters.uncrustify"),
						},
					},
				},
			})
		end,
	})
end

return {
	"neovim/nvim-lspconfig",
	config = config,
	opts = {
		servers = {
			sourcekit = {
				cmd = {
					"/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
					-- "/Library/Developer/Toolchains/swift-DEVELOPMENT-SNAPSHOT-2024-05-15-a.xctoolchain/usr/bin/sourcekit-lsp",
					-- "/Users/tobias/Developer/sourcekit-lsp/.build/release/sourcekit-lsp",
				},
			},
		},
	},
	dependencies = {
		"windwp/nvim-autopairs",
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"creativenull/efmls-configs-nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		"hrsh7th/nvim-cmp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-nvim-lsp",
	},
}
