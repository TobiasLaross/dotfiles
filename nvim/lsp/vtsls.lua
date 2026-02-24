return {
	filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },

	on_attach = function(_, bufnr)
		vim.keymap.set("n", "gD", function()
			vim.lsp.buf.definition()
		end, { buffer = bufnr, desc = "Go to Source Definition" })
	end,
}
