local log_formats = {
	swift = 'print("%s %s = \\(%s)")',
	objc = 'NSLog(@"%s %s = %%@", %s);',
	objcpp = 'NSLog(@"%s %s = %%@", %s);',
	typescript = "console.log('%s %s = ', %s);",
	javascript = "console.log('%s %s = ', %s);",
	go = 'fmt.Printf("%s %s = %%v\\n", %s)',
	sh = 'echo "%s %s = ${%s}"',
	zsh = 'echo "%s %s = ${%s}"',
	bash = 'echo "%s %s = ${%s}"',
	python = 'print(f"%s %s = {%s}")',
	java = 'System.out.println("%s %s = " + %s);',
	rust = 'println!("%s %s = {:?}", %s);',
}

function LogWord()
	local word = vim.fn.expand("<cword>")
	if word == "" then
		return
	end

	local chars = {}
	for index = 1, 4 do
		chars[index] = string.char(math.random(65, 90))
	end
	local prefix = "TLA91 " .. table.concat(chars) .. ":"

	local filetype = vim.bo.filetype
	local format = log_formats[filetype]
	if not format then
		vim.notify("No log format for " .. filetype, vim.log.levels.WARN)
		return
	end

	local stmt = string.format(format, prefix, word, word)

	local cursor = vim.api.nvim_win_get_cursor(0)
	local line_number = cursor[1]
	local current_line = vim.api.nvim_buf_get_lines(0, line_number - 1, line_number, false)[1] or ""
	local indentation = current_line:match("^%s*") or ""

	vim.api.nvim_buf_set_lines(0, line_number, line_number, false, { indentation .. stmt })
	vim.api.nvim_win_set_cursor(0, { line_number + 1, 0 })
end
