return {
	"folke/snacks.nvim",
	event = "VeryLazy",
	opts = {
		explorer = {},
		gitbrowse = {
			-- Prepend alias rewrite before the standard patterns so that SSH host
			-- aliases (e.g. github-personal → github.com) resolve to valid URLs.
			remote_patterns = {
				{ "github%-personal",                    "github.com" },
				{ "^(https?://.*)%.git$",                "%1" },
				{ "^git@(.+):(.+)%.git$",                "https://%1/%2" },
				{ "^git@(.+):(.+)$",                     "https://%1/%2" },
				{ "^git@(.+)/(.+)$",                     "https://%1/%2" },
				{ "^org%-%d+@(.+):(.+)%.git$",           "https://%1/%2" },
				{ "^ssh://git@(.*)$",                    "https://%1" },
				{ "^ssh://([^:/]+)(:%d+)/(.*)$",         "https://%1/%3" },
				{ "^ssh://([^/]+)/(.*)$",                "https://%1/%2" },
				{ "ssh%.dev%.azure%.com/v3/(.*)/(.*)$",  "dev.azure.com/%1/_git/%2" },
				{ "^https://%w*@(.*)",                   "https://%1" },
				{ "^git@(.*)",                           "https://%1" },
				{ ":%d+",                                "" },
				{ "%.git$",                              "" },
			},
		},
		notifier = {},
	},
}
