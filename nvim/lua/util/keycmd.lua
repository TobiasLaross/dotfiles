local feedkeys = vim.api.nvim_feedkeys
local M = {}

function M.paste_no_registry()
	feedkeys('"_dP', "n", true)
end

local function run_replace(search)
	vim.ui.input({ prompt = "󰛔 : replace " .. search }, function(replace)
		if not replace then
			return
		end

		vim.ui.input({
			prompt = " Scope: ",
			default = "%",
		}, function(scope)
			scope = (scope == "" or scope == nil) and "%" or scope

			--[[
                    %        whole file
                    .        current line
                    $        last line
                    1,10     explicit line span
                    .,$      from current to end
                --]]

			local command =
				string.format("%ss/%s/%s/g", scope, vim.fn.escape(search, "/\\"), vim.fn.escape(replace, "/\\"))

			vim.cmd(command)
		end)
	end)
end

function M.smart_replace()
	vim.ui.input({ prompt = " : search" }, function(search)
		if not search or search == "" then
			return
		end
		run_replace(search)
	end)
end

function M.smart_replace_word()
	local search = vim.fn.expand("<cword>")
	if search == nil or search == "" then
		return
	end
	run_replace(search)
end

function M.smart_replace_visual()
	local _, startRow, startCol = unpack(vim.fn.getpos("v"))
	local _, endRow, endCol = unpack(vim.fn.getpos("."))

	if startRow ~= endRow then
		return
	end

	local text = vim.api.nvim_buf_get_text(0, startRow - 1, startCol - 1, endRow - 1, endCol, {})
	local selected = table.concat(text, "")

	if selected == "" then
		return
	end

	run_replace(selected)
end

return M
