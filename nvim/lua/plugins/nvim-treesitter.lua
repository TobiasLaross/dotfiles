return {
	"nvim-treesitter/nvim-treesitter",
	branch = "master",
	lazy = false,
	build = ":TSUpdate",
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
		{ "OXY2DEV/markview.nvim", lazy = false },
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("nvim-treesitter.configs").setup({
			ensure_installed = {
				"c",
				"lua",
				"vim",
				"vimdoc",
				"query",
				"swift",
				"python",
				"java",
				"typescript",
				"javascript",
				"markdown",
				"markdown_inline",
			},
			auto_install = true,
			highlight = { enable = true },
			indent = { enable = true },
			autopairs = { enable = false },
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<leader>ns",
					node_incremental = "<leader>ni",
					node_decremental = "<leader>nd",
				},
			},
			textobjects = {
				select = {
					enable = true,
					lookahead = true,
					keymaps = {
						["aa"] = "@parameter.outer",
						["ia"] = "@parameter.inner",
						["af"] = "@function.outer",
						["if"] = "@function.inner",
						["ac"] = "@class.outer",
					},
				},
			},
			move = {
				enable = true,
				set_jumps = true, -- whether to set jumps in the jumplist
				goto_next_start = { -- Below bindings does not work
					-- ["<leader>j"] = { query = "@function.inner", desc = "Next method/function def start" },
					-- ["]m"] = { query = "@scope.inner", desc = "Next scope def start" },
				},
				goto_previous_start = {
					-- ["]M"] = { query = "@function.inner", desc = "Previous method/function def start" },
				},
			},
		})
		local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")

		-- vim way: ; goes to the direction you were moving.
		vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move)
		vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_opposite)

		-- Optionally, make builtin f, F, t, T also repeatable with ; and ,
		vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f)
		vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F)
		vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t)
		vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T)
	end,
}
