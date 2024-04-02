return {
    "nvim-telescope/telescope.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
    config = function()
        local telescope = require("telescope")
        local actions = require("telescope.actions")
        local opts = {
            defaults = {
                prompt_prefix = "> ",
                selection_caret = "> ",
                entry_prefix = "  ",
                multi_icon = "<>",
                previewer = true,
                layout_strategy = "vertical",
                layout_config = {
                    mirror = false,
                    width = 0.95,
                    height = 0.85,
                    prompt_position = "top",
                    horizontal = {
                        preview_width = function(_, cols, _)
                            if cols > 200 then
                                return math.floor(cols * 0.4)
                            else
                                return math.floor(cols * 0.6)
                            end
                        end,
                    },
                    vertical = {
                        width = 0.9,
                        height = 0.95,
                        preview_height = 0.7,
                    },
                    flex = {
                        horizontal = {
                            preview_width = 0.75,
                        },
                    },
                },
                selection_strategy = "reset",
                sorting_strategy = "ascending",
                scroll_strategy = "cycle",
                color_devicons = true,
                mappings = {
                    i = {
                        ["<Tab>"] = actions.move_selection_next,
                        ["<S-Tab>"] = actions.move_selection_previous,
                    },
                    n = {
                        ["<Tab>"] = actions.move_selection_next,
                        ["<S-Tab>"] = actions.move_selection_previous,
                    },
                },
            },
            pickers = {
                find_files = {
                    find_command = { "rg", "--files", "--hidden", "-g", "!.git" },
                },
                lsp_implementations = {
                    find_command = { "rg", "--files", "--hidden", "-g", "!.git" },
                    layout_strategy = "vertical",
                    layout_config = {
                        prompt_position = "top",
                    },
                    sorting_strategy = "ascending",
                    ignore_filename = false,
                },
                live_grep = {
                    path_display = { "truncate" },
                    find_command = { "rg", "--files", "--hidden", "-g", "!.git" },
                    layout_strategy = "vertical",
                },
                grep_string = {
                    path_display = { shorten = 5 },
                    find_command = { "rg", "--files", "--hidden", "-g", "!.git" },
                    layout_strategy = "vertical",
                },
            },
        }
        telescope.setup(opts)
    end,
}
