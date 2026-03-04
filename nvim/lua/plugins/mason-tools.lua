return {
	"WhoIsSethDaniel/mason-tool-installer.nvim",
	event = "VeryLazy",
	opts = {
		auto_update = true,
		debounce_hours = 24,
		ensure_installed = {
			"black",
			"flake8",
			"luacheck",
			"stylua",
			"hadolint",
			"fixjson",
			"eslint_d",
			"prettierd",
			"swiftformat",
		},
	},
	dependencies = {
		"mason-org/mason.nvim",
	},
}
