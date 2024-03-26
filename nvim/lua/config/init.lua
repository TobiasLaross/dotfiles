require("config.options")

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
		lazy = false,
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

vim.api.nvim_create_user_command("TrimXcodeLogFile", function()
	vim.fn.system("tail -n 700 .nvim/xcodebuild/xcodebuild.log > tmplog && mv tmplog .nvim/xcodebuild/xcodebuild.log")
end, {})

require("lazy").setup(plugins, opts)
