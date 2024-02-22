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

vim.g.mapleader = " "
vim.g.gitblame_display_virtual_text = 0
vim.g.gitblame_message_template = "<author> • <date> • <sha>"
vim.g.gitblame_date_format = "%r"

-- Keymap

vim.keymap.set("n", "<leader>vs", ":vsplit<CR>", { desc = "Split Vertically" })
vim.keymap.set("n", "<leader>hs", ":split<CR>", { desc = "Split Horizontally" })
vim.keymap.set("n", "<leader>s", "<cmd>wa!<CR>", { desc = "Save all" })

-- Navigate between splits
vim.keymap.set("n", "<C-J>", "<C-W><C-J>")
vim.keymap.set("n", "<C-H>", "<C-W><C-H>")
vim.keymap.set("n", "<C-K>", "<C-W><C-K>")
vim.keymap.set("n", "<C-L>", "<C-W><C-L>")

-- Remove search highlight using esc
vim.keymap.set("n", "<esc>", ":noh<CR><esc>", {silent = true, noremap = true})

vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files theme=dropdown previewer=false<cr>", { desc = "Fuzzy find files in cwd" })
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep in cwd" })
