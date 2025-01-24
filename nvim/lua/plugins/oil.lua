return {
	{
		"stevearc/oil.nvim",
		---@module 'oil'
		---@type oil.SetupOpts
		opts = function()
			local max_width = math.floor(vim.o.columns * 0.4)
			local max_height = math.floor(vim.o.lines * 0.6)
			return {
				view_options = {
					show_hidden = true,
				},
				float = {
					padding = 2,
					max_width = max_width,
					max_height = max_height,
					border = "rounded",
					win_options = {
						winblend = 0,
					},
				},
			}
		end,
		-- Optional dependencies
		dependencies = { { "echasnovski/mini.icons", opts = {} } },
		-- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
	},
}
