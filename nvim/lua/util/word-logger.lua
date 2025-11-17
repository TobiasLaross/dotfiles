function LogWord()
	local word = vim.fn.expand("<cword>")
	local filetype = vim.bo.filetype

	local chars = {}
	for index = 1, 4 do
		chars[index] = string.char(math.random(65, 90))
	end
	local prefix = table.concat(chars) .. " TLA91:"
	local stmt

	if filetype == "swift" then
		stmt = string.format('print("%s %s = \\(%s)")', prefix, word, word)
	elseif filetype == "objc" or filetype == "objcpp" then
		stmt = string.format('NSLog(@"%s %s = %%@", %s);', prefix, word, word)
	elseif filetype == "typescript" or filetype == "javascript" then
		stmt = string.format("console.log('%s %s = ', %s);", prefix, word, word)
	elseif filetype == "go" then
		stmt = string.format('fmt.Printf("%s %s = %%v\\n", %s)', prefix, word, word)
	elseif filetype == "sh" or filetype == "zsh" or filetype == "bash" then
		stmt = string.format('echo "%s %s = ${%s}"', prefix, word, word)
	elseif filetype == "python" then
		stmt = string.format('print(f"%s %s = {%s}")', prefix, word, word)
	elseif filetype == "java" then
		stmt = string.format('System.out.println("%s %s = " + %s);', prefix, word, word)
	elseif filetype == "rust" then
		stmt = string.format('println!("%s %s = {:?}", %s);', prefix, word, word)
	else
		print("No log statement defined for filetype: " .. filetype)
		return
	end

	vim.api.nvim_put({ stmt }, "l", true, false)
end
