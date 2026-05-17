require("config.options")
require("config.keymaps")

-- Ensure node (managed by nvm) is on PATH for plugin subprocesses (mason, treesitter CLI, etc.),
-- regardless of how nvim was launched.
do
	local nvm_default_alias = vim.fn.expand("~/.nvm/alias/default")
	if vim.fn.filereadable(nvm_default_alias) == 1 then
		local alias_target = vim.fn.readfile(nvm_default_alias)[1] or ""
		local matches = vim.fn.glob("~/.nvm/versions/node/v" .. alias_target .. "*/bin", false, true)
		local node_bin = matches[1]
		if node_bin and vim.fn.isdirectory(node_bin) == 1 and not vim.env.PATH:find(node_bin, 1, true) then
			vim.env.PATH = node_bin .. ":" .. vim.env.PATH
		end
	end
end

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

local plugins = "plugins"

local opts = {
	defaults = {
		lazy = true,
	},
	--    checker = { enabled = true },
	dev = {
		path = "~/",
	},
	rtp = {
		disabled_plugins = {
			"gzip",
			"matchit",
			"matchparen",
			"netrw",
			"netrwPlugin",
			"tarPlugin",
			"tohtml",
			"tutor",
			"zipPlugin",
		},
	},
	change_detection = {
		notify = false,
	},
}

require("lazy").setup(plugins, opts)
