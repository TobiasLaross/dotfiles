return {
	"RRethy/vim-illuminate",
	event = "bufread",
	opts = {
		delay = 100,
		min_count_to_highlight = 2,
		large_file_cutoff = 2000,
		large_file_overrides = {
			providers = {
				"lsp",
				"treesitter",
				"regex",
			},
		},
	},
	config = function(_, opts)
		require("illuminate").configure(opts)
	end,
}
