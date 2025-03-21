return {
	"lewis6991/gitsigns.nvim",
	opts = {
		signs = {
			add = { text = "│" },
			change = { text = "│" },
			delete = { text = "_" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
			untracked = { text = "┆" },
		},
		signcolumn = false,
		numhl = true,
		linehl = false,
		word_diff = false,
		watch_gitdir = {
			follow_files = true,
		},
		attach_to_untracked = false,
		current_line_blame = false,
		current_line_blame_opts = {
			virt_text = true,
			virt_text_pos = "eol",
			delay = 700,
			ignore_whitespace = false,
		},
		current_line_blame_formatter = "<author> • <date>",
		sign_priority = 6,
		update_debounce = 100,
		status_formatter = nil,
		max_file_length = 6000,
		preview_config = {
			border = "single",
			style = "minimal",
			relative = "cursor",
			row = 0,
			col = 1,
		},
		yadm = {
			enable = false,
		},
		on_attach = function(bufnr)
			local gs = package.loaded.gitsigns
			local function map(mode, l, r, opts)
				opts = opts or {}
				opts.buffer = bufnr
				vim.keymap.set(mode, l, r, opts)
			end

			-- Navigation
			map("n", "L", function()
				if vim.wo.diff then
					return "L"
				end
				vim.schedule(function()
					gs.next_hunk()
				end)
				return "<Ignore>"
			end, { expr = true })

			map("n", "H", function()
				if vim.wo.diff then
					return "H"
				end
				vim.schedule(function()
					gs.prev_hunk()
				end)
				return "<Ignore>"
			end, { expr = true })

			map("n", "<leader>gh", gs.preview_hunk)
			map("n", "<leader>gu", gs.reset_hunk)
			map("n", "<leader>ga", gs.stage_hunk)
			map("n", "<leader>gf", gs.stage_buffer)
		end,
	},
}
