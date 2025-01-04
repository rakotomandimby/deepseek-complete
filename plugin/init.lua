local rktmb_deepseek_complete = require("rktmb-deepseek-complete")
rktmb_deepseek_complete.log("Entered init.lua")

_G.completion_handler = nil

vim.api.nvim_create_autocmd("InsertEnter", {
    pattern = "*",
    callback = function()
        -- Set the completion handler
        _G.completion_handler = function()
            local current_line = vim.api.nvim_get_current_line()
            local current_col = vim.api.nvim_win_get_cursor(0)[2]
            local current_word = vim.fn.expand("<cword>")

            local suggestion = rktmb_deepseek_complete.generate_sentence()

            vim.fn.complete(current_col, {
                { word = suggestion, kind = "random sentence", menu = "[random]", icase = 1, abbr = current_word }
            })
        end


        vim.keymap.set("i", "<M-PageDown>", function()
            vim.defer_fn(_G.completion_handler, 0)
            return ""
        end, { noremap = true, expr = true, silent = true })
    end
})

vim.api.nvim_create_autocmd("InsertLeave", {
    pattern = "*",
    callback = function()
        vim.keymap.del("i", "<M-PageDown>")
        _G.completion_handler = nil -- Clear the handler when leaving insert mode
    end
})
