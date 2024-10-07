local has_telescope, telescope = pcall(require, "telescope.builtin")
if not has_telescope then
	vim.notify("Telescope not found! Please install it to use SwitchToRelatedFile.", vim.log.levels.ERROR)
	return
end

local function getTargetFilename()
	local filepath = vim.fn.expand("%:p") -- Get the full path of the current file
	local name = vim.fn.fnamemodify(filepath, ":t:r")
	local ext = vim.fn.fnamemodify(filepath, ":e")

	if ext == "swift" then
		if name:find("View$") then
			return name:gsub("View$", "ViewModel") .. ".swift"
		elseif name:find("ViewModel$") then
			return name:gsub("ViewModel$", "View") .. ".swift"
		end
	elseif ext == "m" then
		return name .. ".h"
	elseif ext == "h" then
		return name .. ".m"
	end

	return nil
end

function SwitchToRelatedFile()
	local target = getTargetFilename()
	if not target then
		vim.notify("No related target file pattern found to switch to.", vim.log.levels.WARN)
		return
	end

	local ag_command = { "ag", "-wsg", target }
	local found_files = vim.fn.systemlist(ag_command)

	if #found_files == 0 then
		vim.notify("No file named " .. target .. " found.", vim.log.levels.INFO)
		return
	end

	-- Open the first found file
	local first_match = found_files[1]
	print("Opening file:", first_match)
	vim.cmd("edit " .. vim.fn.fnameescape(first_match))
end
