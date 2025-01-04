local rktmb_deepseek_complete = require("rktmb-deepseek-complete")
rktmb_deepseek_complete.log("Entered init.lua")

_G.completion_handler = nil

vim.api.nvim_create_autocmd("InsertEnter", {
    pattern = "*",
    callback = function()
        -- Set the completion handler
        _G.completion_handler = function()
            local current_col = vim.api.nvim_win_get_cursor(0)[2]
            local suggestion = rktmb_deepseek_complete.generate_sentence()

            -- Create a completion item with the correct structure
            local completion_items = {
                { word = suggestion, kind = "Random Sentence", menu = "[random]", icase = 1 }
            }

            -- Trigger the completion
            vim.fn.complete(current_col + 1, completion_items)  -- Use current_col + 1 for the correct position
        end

        -- Trigger the completion immediately after entering insert mode
        vim.defer_fn(_G.completion_handler, 0)

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
