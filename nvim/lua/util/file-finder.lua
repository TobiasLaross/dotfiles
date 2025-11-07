local function getTargetFilename()
	local filepath = vim.fn.expand("%:p")
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
	elseif ext == "ts" or ext == "js" or ext == "tsx" or ext == "jsx" then
		local localPath = vim.fn.fnamemodify(filepath, ":.")
		local withoutExt = localPath:gsub("%.%w+$", "")

		local hasSrc = vim.fn.isdirectory("src") == 1
		local hasServer = vim.fn.isdirectory("server") == 1

		if localPath:match("^test/") then
			if hasSrc then
				return withoutExt:gsub("^test/", "src/") .. "." .. ext
			elseif hasServer then
				return withoutExt:gsub("^test/", "server/") .. "." .. ext
			end
		elseif localPath:match("^src/") then
			return withoutExt:gsub("^src/", "test/") .. "." .. ext
		elseif localPath:match("^server/") then
			return withoutExt:gsub("^server/", "test/") .. "." .. ext
		end
	end

	return nil
end

function SwitchToRelatedFile()
	local target = getTargetFilename()
	if not target then
		vim.notify("No related target file pattern found to switch to.", vim.log.levels.WARN)
		return
	end

	local searchCommand = { "ag", "-wsg", target }
	local results = vim.fn.systemlist(searchCommand)

	if #results == 0 then
		print("No file named " .. target .. " found.")
		return
	end

	local match = results[1]
	vim.cmd("edit " .. vim.fn.fnameescape(match))
end
