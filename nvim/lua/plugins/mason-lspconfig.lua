return {
	"mason-org/mason-lspconfig.nvim",
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
	},
	dependencies = {
		{ "mason-org/mason.nvim", opts = {} },
		"neovim/nvim-lspconfig",
	},
}
