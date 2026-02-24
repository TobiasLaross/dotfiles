vim.opt.number = true
vim.opt.relativenumber = false

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.wrap = false

vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

vim.opt.clipboard = "unnamedplus"

vim.opt.scrolloff = 20

vim.opt.virtualedit = "block"
vim.opt.inccommand = "split"

vim.opt.ignorecase = true

vim.opt.termguicolors = true
vim.opt.colorcolumn = "140"

vim.opt.spelllang = "en_us"
vim.opt.spell = true

vim.g.mapleader = " "
vim.g.gitblame_display_virtual_text = 0
vim.g.gitblame_message_template = "<author> • <date>"
vim.g.gitblame_date_format = "%d/%m-%y" --"%r"

-- Workaround for switching between nvim and xcode to reload files
vim.opt.autoread = true
vim.opt.swapfile = false

-- Auto save and trigger auto-format in the background
vim.api.nvim_create_autocmd("InsertLeave", {
	callback = function(args)
		local bufferNumber = args.buf
		if not vim.api.nvim_buf_is_valid(bufferNumber) or not vim.api.nvim_buf_is_loaded(bufferNumber) then
			return
		end
		if vim.bo[bufferNumber].buftype ~= "" then
			return
		end
		local fileType = vim.bo[bufferNumber].filetype
		if type(fileType) ~= "string" or fileType == "" then
			return
		end
		if not vim.bo[bufferNumber].modifiable or vim.bo[bufferNumber].readonly then
			return
		end
		if not vim.bo[bufferNumber].modified then
			return
		end

		vim.defer_fn(function()
			if not vim.api.nvim_buf_is_valid(bufferNumber) or not vim.api.nvim_buf_is_loaded(bufferNumber) then
				return
			end
			if vim.api.nvim_get_mode().mode ~= "n" then
				return
			end
			if vim.bo[bufferNumber].buftype ~= "" then
				return
			end
			local deferredFileType = vim.bo[bufferNumber].filetype
			if type(deferredFileType) ~= "string" or deferredFileType == "" then
				return
			end

			local okConform, conform = pcall(require, "conform")
			if not okConform or type(conform.format) ~= "function" then
				return
			end

			local okFormat = pcall(conform.format, {
				bufnr = bufferNumber,
				lsp_fallback = true,
				async = true,
				timeout_ms = 2500,
			}, function(formatError)
				if formatError then
					return
				end
				if not vim.api.nvim_buf_is_valid(bufferNumber) or not vim.api.nvim_buf_is_loaded(bufferNumber) then
					return
				end
				if vim.api.nvim_get_mode().mode == "i" then
					return
				end
				if vim.bo[bufferNumber].modifiable and vim.bo[bufferNumber].modified then
					vim.cmd("update")
				end
			end)

			if not okFormat then
				return
			end
		end, 2500)
	end,
})

-- refresh files if changed outside
vim.fn.timer_start(2000, function()
	vim.cmd("silent! checktime")
end, { ["repeat"] = -1 })

vim.api.nvim_create_autocmd("User", {
	pattern = { "XcodebuildBuildFinished", "XcodebuildTestsFinished" },
	callback = function(event)
		if event.data.cancelled then
			return
		end

		if event.data.success then
			require("trouble").close()
		elseif not event.data.failedCount or event.data.failedCount > 0 then
			if next(vim.fn.getqflist()) then
				require("trouble").open("quickfix")
			else
				require("trouble").close()
			end

			require("trouble").refresh()
		end
	end,
})
