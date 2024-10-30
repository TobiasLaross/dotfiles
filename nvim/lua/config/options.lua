vim.opt.number = true
vim.opt.relativenumber = true

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

-- refresh files if changed outside
vim.fn.timer_start(2000, function()
	vim.cmd("silent! checktime")
end, { ["repeat"] = -1 })

-- Keymap
-- Text
vim.api.nvim_set_keymap("n", "<leader>p", "o<Esc>p", { noremap = true, silent = true })

-- Navigation
vim.keymap.set("n", "<leader>k", "[{", { noremap = true, silent = true }) -- Move up to the previous function
vim.keymap.set("n", "<leader>j", "]}", { noremap = true, silent = true }) -- Move down to the next function

-- Panes
vim.keymap.set("n", "<leader>vs", ":vsplit<CR>", { desc = "Split Vertically" })
vim.keymap.set("n", "<leader>hs", ":split<CR>", { desc = "Split Horizontally" })
vim.keymap.set("n", "<leader>s", ":wa!<CR>", { desc = "Save all" })
-- vim.keymap.set("n", "<leader>s", ":wa!<CR>:TrimXcodeLogFile<CR>", { desc = "Save all and trim xcode log file" })
vim.keymap.set("n", "<leader>sq", ":wqa<CR>", { desc = "Save all and quit" })

-- NvimTree
vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle nvim tree" })
vim.keymap.set("n", "<leader>ntl", "<cmd>NvimTreeResize +5<cr>", { desc = "Increase size of nvim tree" })
vim.keymap.set("n", "<leader>nth", "<cmd>NvimTreeResize -5<cr>", { desc = "Decrease size of nvim tree" })

-- Navigate between splits
vim.keymap.set("n", "<C-J>", "<C-W><C-J>")
vim.keymap.set("n", "<C-H>", "<C-W><C-H>")
vim.keymap.set("n", "<C-K>", "<C-W><C-K>")
vim.keymap.set("n", "<C-L>", "<C-W><C-L>")

-- Remove search highlight using esc
vim.keymap.set("n", "<esc>", ":noh<CR><esc>", { silent = true, noremap = true })

-- Telescope
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep in cwd" })
vim.keymap.set("n", "<leader>fr", "<cmd>Telescope resume<cr>", { desc = "Live grep resume" })
vim.keymap.set("n", "<leader>fl", "<cmd>Telescope lsp_references<cr>")
vim.keymap.set("n", "<leader>fd", "<cmd>Telescope diagnostics<cr>")
vim.keymap.set("n", "<leader>fq", "<cmd>Telescope quickfix<cr>", { desc = "Show QuickFix List" })
vim.keymap.set("n", "<leader>fc", "<cmd>Telescope git_status<cr>")
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>")
vim.keymap.set("n", "<leader>fo", "<cmd>Telescope oldfiles<cr>")
vim.keymap.set("n", "<leader>fj", "<cmd>Telescope jumplist<cr>")
vim.keymap.set("n", "<leader>fs", "<cmd>lua SwitchToRelatedFile()<CR>", { noremap = true, silent = true })

-- Harpoon
-- local harpoon = require("harpoon")
-- harpoon:setup()

-- LSP
vim.keymap.set("n", "<leader>lr", "<cmd>LspRestart<cr>")

-- Debug
vim.keymap.set("n", "<C-S-k>", "<cmd>lua require('dapui').eval()<CR>", { silent = true, noremap = true })

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
