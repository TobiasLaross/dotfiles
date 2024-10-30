return {
	"folke/trouble.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {},
	event = { "BufReadPre", "BufNewFile" },

	-- Lazy load Trouble.nvim when the command or key mappings are triggered
	cmd = { "TroubleToggle", "Trouble" },

	keys = function()
		return {
			-- Toggle quickfix
			{
				"<leader>tl",
				"<cmd>Trouble quickfix toggle<cr>",
				desc = "Diagnostics (Trouble)",
			},
			-- Toggle workspace symbols
			{
				"<leader>ts",
				"<cmd>Trouble symbols toggle<cr>",
				desc = "Symbols (Trouble)",
			},
			-- Toggle location list
			{
				"<leader>tL",
				"<cmd>Trouble loclist toggle<cr>",
				desc = "Location List (Trouble)",
			},
		}
	end,

	config = function()
		require("trouble").setup({
			auto_open = false,
			auto_close = true,
			auto_preview = true,
			auto_jump = false,
			mode = "quickfix",
			severity = vim.diagnostic.severity.ERROR,
			cycle_results = true,
		})
	end,
}
