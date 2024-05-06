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
    if target then
        local pwd = vim.fn.expand("%:p:h")             -- Get the current directory
        local parent = vim.fn.fnamemodify(pwd, ":h")   -- Get the parent directory
        local grandparent = vim.fn.fnamemodify(parent, ":h") -- Get the parent of the parent directory

        -- Construct a list of possible related files
        local files = vim.fn.systemlist({
            "rg",
            "--files",
            "--ignore",
            "--hidden",
            "--follow",
            "--glob",
            "!{.git,node_modules,venv}/*",
            "--maxdepth",
            "3", -- Limit search depth to 3 levels
            vim.fn.fnameescape(pwd),
            vim.fn.fnameescape(parent),
            vim.fn.fnameescape(grandparent),
        })

        -- Iterate over the list of files to find the exact match for the target filename
        for _, file in ipairs(files) do
            if vim.fn.fnamemodify(file, ":t") == target and vim.fn.filereadable(file) == 1 then
                vim.cmd("edit " .. vim.fn.fnameescape(file))
                return
            end
        end

        print("No file named " .. target .. " found.")
    else
        print("No related target file found to switch to.")
    end
end
