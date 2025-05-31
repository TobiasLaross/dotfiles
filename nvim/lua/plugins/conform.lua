local cachedSwiftConfig = nil
local searchedSwift = false

local function find_swift_config()
    if searchedSwift then return cachedSwiftConfig end
    local results = vim.fn.systemlist({ "find", vim.fn.getcwd(), "-maxdepth", "2", "-iname", ".swiftformat", "-not",
        "-path", "*/.*/*" })
    searchedSwift = true
    if vim.v.shell_error ~= 0 then return nil end
    table.sort(results, function(a, b) return a ~= "" and #a < #b end)
    if results[1] then cachedSwiftConfig = vim.trim(results[1]) end
    return cachedSwiftConfig
end

return {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        local conform = require("conform")
        conform.setup({
            formatters_by_ft = {
                swift = { "swiftformat_ext" },
                javascript = { "prettier" },
                typescript = { "prettier" },
                javascriptreact = { 'prettier' },
                typescriptreact = { 'prettier' },
                lua = { 'stylua' },
                python = { 'isort', 'black' },
                html = { 'prettier' },
                json = { 'prettier' },
                yaml = { 'prettier' },
                markdown = { 'prettier' },
            },
            format_on_save = function(bufnr)
                return { timeout_ms = 500, lsp_fallback = true }
            end,
            log_level = vim.log.levels.ERROR,
            formatters = {
                swiftformat_ext = {
                    command = "swiftformat",
                    args = function()
                        return {
                            "--config",
                            find_swift_config() or "~/.config/nvim/.swiftformat",
                            "--stdinpath",
                            "$FILENAME",
                        }
                    end,
                    range_args = function(ctx)
                        return {
                            "--config",
                            find_swift_config() or "~/.config/nvim/.swiftformat",
                            "--linerange",
                            ctx.range.start[1] .. "," .. ctx.range["end"][1],
                        }
                    end,
                    stdin = true,
                    condition = function(ctx)
                        return vim.fs.basename(ctx.filename) ~= "README.md"
                    end,
                },
            },
        })

        vim.keymap.set({ "n", "v" }, "<leader>mp", function()
            conform.format({
                lsp_fallback = true,
                async = false,
                timeout_ms = 500,
            })
        end, { desc = "Format file or range (in visual mode)" })
    end,
}
