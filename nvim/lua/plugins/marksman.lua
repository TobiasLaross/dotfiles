return {
	"alexekdahl/marksman.nvim",
	keys = {
		{
			"<leader>ma",
			function()
				require("marksman").add_mark()
			end,
			desc = "Add mark",
		},
		{
			"<leader>ms",
			function()
				require("marksman").show_marks()
			end,
			desc = "Show marks",
		},
		{
			"<leader>mm",
			function()
				require("marksman").goto_mark(1)
			end,
			desc = "Go to mark 1",
		},
		{
			"<leader>m,",
			function()
				require("marksman").goto_mark(2)
			end,
			desc = "Go to mark 2",
		},
		{
			"<leader>m.",
			function()
				require("marksman").goto_mark(3)
			end,
			desc = "Go to mark 3",
		},
		{
			"<leader>mj",
			function()
				require("marksman").goto_mark(4)
			end,
			desc = "Go to mark 4",
		},
		{
			"<leader>mk",
			function()
				require("marksman").goto_mark(5)
			end,
			desc = "Go to mark 5",
		},
		{
			"<leader>mi",
			function()
				require("marksman").goto_next()
			end,
			desc = "Next mark",
		},
		{
			"<leader>mo",
			function()
				require("marksman").goto_previous()
			end,
			desc = "Previous mark",
		},
	},
	opts = {
		auto_save = true,
		max_marks = 100,
		search_in_ui = true,
		sort_marks = false,
		disable_default_keys = true,
		silent = true,
		minimal = true,
	},
}
