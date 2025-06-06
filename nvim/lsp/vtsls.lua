return {
    filetypes = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },

    on_attach = function(client, bufnr)
        local vtsls = require('vtsls')
        vim.keymap.set("n", "gD", function()
            vtsls.commands.goto_source_definition()
        end, { buffer = bufnr, desc = "Go to Source Definition" })
    end,
}
