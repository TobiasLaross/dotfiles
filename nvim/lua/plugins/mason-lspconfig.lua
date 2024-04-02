local opts = {
	ensure_installed = {
		"efm",
		"bashls",
		"tsserver",
		"pyright",
		"lua_ls",
		"jsonls",
		"kotlin_language_server",
	},
	automatic_installation = true,
}

return {
	"williamboman/mason-lspconfig.nvim",
	opts = opts,
	event = "BufReadPre",
	dependencies = "williamboman/mason.nvim",
}
