local icons = require("config.icons").icons
return {
	"mason-org/mason.nvim",
	cmd = "Mason",
	event = "BufReadPre",
	opts = {
		ensure_installed = {
			"bashls",
			"clangd",
			"cssls",
			"dockerls",
			"html",
			"pyright",
			"rust_analyzer",
			"vtsls",
			"lua_ls",
		},
		automatic_enable = true,
		automatic_installation = true,
		ui = {
			icons = {
				package_installed = icons.symbols.check,
				package_pending = icons.symbols.arrow_right,
				package_uninstalled = icons.symbols.cross,
			},
		},
	},
}
