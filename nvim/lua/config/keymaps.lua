local cmd = require("util.keycmd")

-- Text
vim.keymap.set("n", "<leader>p", "o<Esc>p", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>s", ":wa!<CR>", { desc = "Save all" })
vim.keymap.set("v", "p", cmd.paste_no_registry, { noremap = true, silent = true })

-- vim.keymap.set("n", "<leader>sq", ":wqa<CR>", { desc = "Save all and quit" })
vim.keymap.set("n", "<leader>sq", function()
	-- Close all terminal jobs gracefully
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.bo[buf].buftype == "terminal" then
			vim.fn.jobstop(vim.b[buf].terminal_job_id or 0) -- Stop the job
			vim.api.nvim_buf_delete(buf, { force = true }) -- Force delete the buffer
		end
	end
	vim.cmd("wqa") -- Save all and quit
end, { desc = "Save all and quit, killing terminals" })

-- Panes
vim.keymap.set("n", "<leader>vs", ":vsplit<CR>", { desc = "Split Vertically" })
vim.keymap.set("n", "<leader>hs", ":split<CR>", { desc = "Split Horizontally" })

-- Snacks
vim.keymap.set("n", "<leader>e", "<cmd>lua Snacks.explorer()<cr>", { desc = "Toggle snacks explorer" })
vim.keymap.set("n", "<leader>go", function()
	local file = vim.api.nvim_buf_get_name(0)
	local line = vim.fn.line(".")
	local out = vim.fn.system({ "git", "blame", "-L", line .. "," .. line, "--porcelain", file })
	local hash = out:match("^(%x+)")
	-- all-zero hash means the line is not yet committed
	if hash and #hash == 40 and hash ~= string.rep("0", 40) then
		Snacks.gitbrowse({ what = "commit", commit = hash })
	else
		Snacks.gitbrowse({ what = "file" })
	end
end, { desc = "Open blame commit in browser" })
vim.keymap.set("n", "<leader>gf", function() Snacks.gitbrowse({ what = "file" }) end, { desc = "Open file in browser" })

-- NvimTree
-- vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle nvim tree" })
vim.keymap.set("n", "<leader>ntl", "<cmd>NvimTreeResize +5<cr>", { desc = "Increase size of nvim tree" })
vim.keymap.set("n", "<leader>nth", "<cmd>NvimTreeResize -5<cr>", { desc = "Decrease size of nvim tree" })

-- Zen
vim.keymap.set("n", "<leader>z", function()
	vim.o.numberwidth = vim.o.numberwidth == 4 and 20 or 4
	vim.o.foldcolumn = vim.o.numberwidth == 4 and "0" or "9"
	vim.o.signcolumn = vim.o.numberwidth == 4 and "no" or "yes:9"
end, { noremap = true, silent = true })

-- Oil
vim.keymap.set(
	"n",
	"<leader>-",
	"<cmd>lua require('oil').toggle_float()<CR>",
	{ noremap = true, silent = true, desc = "Toggle Oil float" }
)

-- Navigate between splits
vim.keymap.set("n", "<C-J>", "<C-W><C-J>")
vim.keymap.set("n", "<C-H>", "<C-W><C-H>")
vim.keymap.set("n", "<C-K>", "<C-W><C-K>")
vim.keymap.set("n", "<C-L>", "<C-W><C-L>")

-- Remove search highlight using esc
vim.keymap.set("n", "<esc>", ":noh<CR><esc>", { silent = true, noremap = true })

-- Telescope
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Show Help tags" })
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep in cwd" })
vim.keymap.set("n", "<leader>fw", "<cmd>Telescope grep_string<cr>", { desc = "Find string (word under cursor)" })
vim.keymap.set("n", "<leader>fp", function()
	require("telescope.builtin").live_grep({ default_text = "TLA91.*" })
end, { desc = "Grep for TLA91.*" })
vim.keymap.set("n", "<leader>fr", "<cmd>Telescope resume<cr>", { desc = "Live grep resume" })
vim.keymap.set("n", "<leader>fl", "<cmd>Telescope lsp_references<cr>")
vim.keymap.set("n", "<leader>fd", "<cmd>Telescope diagnostics<cr>")
vim.keymap.set("n", "<leader>fq", "<cmd>Telescope quickfix<cr>", { desc = "Show QuickFix List" })
vim.keymap.set("n", "<leader>fc", "<cmd>Telescope git_status<cr>")
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>")
vim.keymap.set("n", "<leader>fo", "<cmd>Telescope oldfiles<cr>")
vim.keymap.set("n", "<leader>fj", "<cmd>Telescope jumplist<cr>")

-- Util
vim.keymap.set("n", "<leader>fs", "<cmd>lua SwitchToRelatedFile()<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>lw", "<cmd>lua LogWord()<CR>", { noremap = true, silent = true })
vim.keymap.set("v", "<leader>lw", "<cmd>lua LogWord()<CR>", { noremap = true, silent = true })

-- Open URL or file under cursor (replaces netrw's gx)
vim.keymap.set("n", "gx", function()
	local target = nil

	-- Check for markdown link [text](url_or_path)
	local line = vim.api.nvim_get_current_line()
	local col = vim.fn.col(".")
	for link in line:gmatch("%[.-%]%((.-)%)") do
		local start, finish = line:find("%[.-%]%(" .. vim.pesc(link) .. "%)")
		if start and col >= start and col <= finish then
			target = link
			break
		end
	end

	-- Fall back to WORD under cursor
	if not target then
		target = vim.fn.expand("<cWORD>")
		-- Strip surrounding punctuation (markdown, parens, quotes)
		target = target:gsub("^[%[%(\"'<]+", ""):gsub("[%]%)\"'>,.;:!?]+$", "")
	end

	if not target or target == "" then return end

	-- URLs: open in browser
	if target:match("^https?://") or target:match("^file://") then
		vim.ui.open(target)
		return
	end

	-- File paths: open in Neovim (resolve relative to buffer directory)
	local path = target:gsub("#.*$", "") -- strip #fragment
	local buf_dir = vim.fn.expand("%:p:h")
	local resolved = vim.fn.fnamemodify(buf_dir .. "/" .. path, ":p")
	if vim.fn.filereadable(resolved) == 1 then
		vim.cmd("edit " .. vim.fn.fnameescape(resolved))
	else
		vim.notify("File not found: " .. resolved, vim.log.levels.WARN)
	end
end, { desc = "Open link or file under cursor" })

-- LSP
vim.keymap.set("n", "<leader>lr", "<cmd>LspRestart<cr>")

-- Debug
vim.keymap.set("n", "<C-S-k>", "<cmd>lua require('dapui').eval()<CR>", { silent = true, noremap = true })
