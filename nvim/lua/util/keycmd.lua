local feedkeys = vim.api.nvim_feedkeys
local M = {}

function M.paste_no_registry()
	feedkeys('"_dP', "n", true)
end

return M
