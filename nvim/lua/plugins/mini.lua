return {
	"echasnovski/mini.nvim",
	event = "VeryLazy",
	version = false,
	config = function()
		-- to toggle comments just hit `gc`
		require("mini.comment").setup({
			options = {
				custom_commentstring = function()
					local ft = vim.api.nvim_buf_get_option(0, "ft")
					if ft == "swift" then
						return "// %s"
					elseif ft == "python" then
						return "# %s"
					elseif ft == "lua" then
						return "-- %s"
					elseif ft == "objc" then
						return "// %s"
					elseif ft == "typescript" or ft == "javascript" then
						return "// %s"
					end
				end,
			},
			mappings = {
				comment_line = "<leader>c",
			},
		})

		-- this is very useful, by hitting `sj` you can split arguments into new lines (ctrl+m in Xcode)
		require("mini.splitjoin").setup({
			mappings = {
				toggle = "sj",
				split = "",
				join = "",
			},
		})

		-- recently, I stopped using it but it adds automatically closing brackets, quotes, etc.
		require("mini.pairs").setup({
			modes = { insert = true, command = false, terminal = false },
			mappings = { ["`"] = false },
		})

		-- to easily move code around
		require("mini.move").setup({
			mappings = {
				left = "<A-h>",
				right = "<A-l>",
				down = "<C-j>",
				up = "<C-k>",
				line_left = "<A-h>",
				line_right = "<A-l>",
				line_down = "<C-j>",
				line_up = "<C-k>",
			},
		})
	end,
}
