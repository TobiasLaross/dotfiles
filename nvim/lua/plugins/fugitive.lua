return {
	"tpope/vim-fugitive",
	cmd = { "Git", "Gdiffsplit", "Gread", "Gwrite" }, -- Lazy loading commands
	keys = {
		{ "<leader>gs", "<cmd>Git<CR>", desc = "Open Git Status" },
		{ "<leader>gb", "<cmd>G blame<CR>", desc = "Open Git Blame" },
		{ "<leader>gl", "<cmd>G log<CR>", desc = "Open Git log pane" },
		{ "<leader>gds", "<cmd>Gdiffsplit<CR>", desc = "Git Diff Split" },
		{ "<leader>gdt", "<cmd>G difftool<CR>", desc = "Open Git diff tool" },
		{ "<leader>gj", "<cmd>cnext<CR>", desc = "Find next diff" },
		{ "<leader>gk", "<cmd>cprevious<CR>", desc = "Find previous diff" },
		-- Add more keybindings as desired
	},
	config = function()
		-- Optional: Additional configuration can go here
	end,
}
