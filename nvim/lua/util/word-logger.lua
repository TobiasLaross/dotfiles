function LogWord()
    local word = vim.fn.expand("<cword>")
    local filetype = vim.bo.filetype
    local log_statement = ""

    if filetype == "swift" then
        log_statement = string.format("print(\"TLA91: %s = \\(%s)\")", word, word)
    elseif filetype == "objc" or filetype == "objcpp" then
        log_statement = string.format("NSLog(@\"TLA91: %s = %%@\", %s);", word, word)
    elseif filetype == "typescript" or filetype == "javascript" then
        log_statement = string.format("console.log(`TLA91: %s = ${%s}`);", word, word)
    elseif filetype == "go" then
        log_statement = string.format("fmt.Printf(\"TLA91: %s = %%v\\n\", %s)", word, word)
    elseif filetype == "sh" or filetype == "zsh" or filetype == "bash" then
        log_statement = string.format("echo \"TLA91: %s = ${%s}\"", word, word)
    elseif filetype == "python" then
        log_statement = string.format("print(f\"TLA91: %s = {%s}\")", word, word)
    elseif filetype == "java" then
        log_statement = string.format("System.out.println(\"TLA91: %s = \" + %s);", word, word)
    else
        print("No log statement defined for filetype: " .. filetype)
        return
    end

    vim.api.nvim_put({ log_statement }, "l", true, false)
end
