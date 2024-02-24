return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter",
	config = function()
		require("copilot").setup({
			panel = {
				enabled = false,
				auto_refresh = true,
			},
			suggestion = {
				enabled = false,
				auto_trigger = false,
			},
		})
	end,
}
