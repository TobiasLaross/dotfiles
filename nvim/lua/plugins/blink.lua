return {
	"saghen/blink.cmp",
	event = "InsertEnter",
	dependencies = {
		"L3MON4D3/LuaSnip",
		"rafamadriz/friendly-snippets",
	},
	version = "*",
	config = function()
		local luasnip = require("luasnip")

		require("luasnip.loaders.from_vscode").lazy_load()

		require("blink.cmp").setup({
			keymap = {
				["<C-k>"] = { "select_prev", "fallback" },
				["<C-j>"] = { "select_next", "fallback" },
				["<C-Space>"] = { "show", "show_documentation", "fallback" },
				["<C-e>"] = { "hide", "fallback" },
				["<Tab>"] = { "accept", "fallback" },
				["<C-b>"] = {
					function()
						if luasnip.jumpable(-1) then
							luasnip.jump(-1)
							return true
						end
						return false
					end,
					"fallback",
				},
				["<C-f>"] = {
					function()
						if luasnip.jumpable(1) then
							luasnip.jump(1)
							return true
						end
						return false
					end,
					"fallback",
				},
			},

			sources = {
				default = { "lsp", "path", "buffer", "snippets" },
			},

			snippets = {
				preset = "luasnip",
			},

			appearance = {
				use_nvim_cmp_as_default = false,
			},

			completion = {
				keyword = { range = "full" },
				accept = { auto_brackets = { enabled = false } },
				list = {
					selection = {
						preselect = true,
						auto_insert = false,
					},
				},
				documentation = { auto_show = true, auto_show_delay_ms = 500 },
			},
		})
	end,
}
