return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "f-person/git-blame.nvim" },
	event = "VeryLazy",
	init = function()
		vim.g.lualine_laststatus = vim.o.laststatus
		if vim.fn.argc(-1) > 0 then
			-- set an empty statusline till lualine loads
			vim.o.statusline = " "
		else
			-- hide the statusline on the starter page
			vim.o.laststatus = 0
		end
	end,
	opts = function()
		local icons = require("config.icons").icons
		local git_blame = require("gitblame")
		local diagnostics = {
			"diagnostics",
			sections = { "error", "warn", "info", "hint" },
			symbols = {
				error = icons.diagnostics.error,
				warn = icons.diagnostics.warn,
				info = icons.diagnostics.info,
				hint = icons.diagnostics.hint,
			},
			update_in_insert = false,
			always_visible = false,
		}

		local function xcodebuild_info()
			local scheme_prefix = ""
			if vim.g.xcodebuild_scheme then
				scheme_prefix = vim.g.xcodebuild_scheme .. " - "
			end

			if vim.g.xcodebuild_platform == "macOS" then
				return scheme_prefix .. " macOS"
			elseif vim.g.xcodebuild_os then
				return scheme_prefix .. " " .. vim.g.xcodebuild_device_name .. " (" .. vim.g.xcodebuild_os .. ")"
			else
				return scheme_prefix .. " " .. vim.g.xcodebuild_device_name
			end
		end

		vim.o.laststatus = vim.g.lualine_laststatus

		return {
			options = {
				theme = "auto",
				globalstatus = true,
				disabled_filetypes = { statusline = { "dashboard", "alpha", "starter" } },
			},
			sections = {
				lualine_a = {
					{ "filename", file_status = true, path = 0, separator = "", padding = { left = 1, right = 0 } },
				},
				lualine_b = { "branch" },
				lualine_c = {
					{
						git_blame.get_current_blame_text,
						cond = git_blame.is_blame_text_available,
					},
				},
				lualine_x = {
					{
						xcodebuild_info,
						color = { fg = "#f9e2af", bg = "#161622" },
					},
					diagnostics,
				},
				lualine_y = {
					{ "progress", separator = " ", padding = { left = 1, right = 1 } },
				},
				lualine_z = {
					{ "location", padding = { left = 0, right = 1 } },
				},
			},
		}
	end,
}
