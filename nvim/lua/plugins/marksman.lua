return {
	"alexekdahl/marksman.nvim",
	keys = {
		{
			"<leader>mk",
			function()
				require("marksman").goto_mark(5)
			end,
			desc = "Go to mark 5",
		},
	},
	opts = {
		keymaps = {
			add = "<leader>ma",
			show = "<leader>ms",
			goto_1 = "<leader>mm",
			goto_2 = "<leader>m,",
			goto_3 = "<leader>m.",
			goto_4 = "<leader>mj",
		},
		auto_save = true,
		max_marks = 100,
		search_in_ui = true,
		sort_marks = false,
		silent = true,
		minimal = false,
	},
}
