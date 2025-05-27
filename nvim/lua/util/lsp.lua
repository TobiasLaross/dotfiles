local M = {}

M.on_attach = function(client, bufnr)
    local function opts(desc)
        return { noremap = true, silent = true, buffer = bufnr, desc = desc }
    end

    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts("Go to declaration"))
    vim.keymap.set("n", "gt", "<cmd>Lspsaga goto_type_definition<CR>", opts("Go to type definition"))
    vim.keymap.set("n", "gk", "<cmd>Lspsaga hover_doc<CR>", opts("Show hover documentation"))
    vim.keymap.set("n", "gn", "<cmd>Lspsaga diagnostic_jump_next<CR>", opts("Jump to next diagnostic"))
    vim.keymap.set("n", "gf", "<cmd>Lspsaga finder tyd+ref+imp+def<CR>", opts("Find type/impl/ref/def"))
    vim.keymap.set("n", "gr", require('telescope.builtin').lsp_references, opts("Find references"))
    vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, opts("Rename symbol"))
    vim.keymap.set("n", "<leader>k", vim.diagnostic.open_float, opts("Show diagnostic popup"))
    vim.keymap.set("n", "<leader>a", "<cmd>Lspsaga code_action<CR>", opts("Code action"))

    vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
        vim.lsp.buf.format()
    end, { desc = "Format buffer with LSP" })
end

return M

