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
		local bufnr = args.buf
		if not vim.api.nvim_buf_is_loaded(bufnr) then
			return
		end
		if not vim.bo[bufnr].modifiable or vim.bo[bufnr].readonly then
			return
		end
		if not vim.bo[bufnr].modified then
			return
		end

		vim.defer_fn(function()
			if vim.api.nvim_get_mode().mode ~= "n" then
				return
			end

			local ok, conform = pcall(require, "conform")
			if not ok then
				return
			end

			conform.format({
				bufnr = bufnr,
				lsp_fallback = true,
				async = true,
				timeout_ms = 2500,
			}, function(err)
				if err then
					return
				end
				if not vim.api.nvim_buf_is_loaded(bufnr) then
					return
				end
				if vim.api.nvim_get_mode().mode == "i" then
					return
				end
				if vim.bo[bufnr].modifiable and vim.bo[bufnr].modified then
					vim.cmd("update")
				end
			end)
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
