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
		vim.lsp.config("*", { capabilities = capabilities })

		local sourcekit_bin = vim.fn.exepath("sourcekit-lsp")
		if sourcekit_bin == "" then
			sourcekit_bin =
				"/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp"
		end

		vim.lsp.config.sourcekit = {
			cmd = { sourcekit_bin },
			capabilities = capabilities,
		}

		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "swift", "objc", "c", "cpp", "objective-cpp" },
			callback = function(event)
				vim.lsp.start({
					name = "sourcekit",
					cmd = vim.lsp.config.sourcekit.cmd,
					capabilities = vim.lsp.config.sourcekit.capabilities,
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
