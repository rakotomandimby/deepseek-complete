local rktmb_deepseek_complete = require("rktmb-deepseek-complete")
rktmb_deepseek_complete.log("Entered init.lua")

vim.api.nvim_set_hl(0, "InlineSuggestion", { fg = "#808080", bg = "NONE" }) 

_G.completion_handler = nil
_G.current_extmark = nil 

local function clear_suggestion()
    if _G.current_extmark then
        vim.api.nvim_buf_del_extmark(0, _G.current_extmark.ns, _G.current_extmark.id)
        _G.current_extmark = nil
    end
end

vim.api.nvim_create_autocmd("InsertEnter", {
    pattern = "*",
    callback = function()
        _G.completion_handler = function()
            local current_line = vim.api.nvim_get_current_line()
            local current_col = vim.api.nvim_win_get_cursor(0)[2]
            local current_word = vim.fn.expand("<cword>")

            local suggestion = rktmb_deepseek_complete.generate_sentence()

            clear_suggestion() 

            local ns_id = vim.api.nvim_create_namespace("rktmb-deepseek-complete-ns")
            local extmark_id = vim.api.nvim_buf_set_extmark(0, ns_id, vim.api.nvim_win_get_cursor(0)[1] - 1, current_col, {
                virt_text = {{suggestion, "InlineSuggestion"}}, 
                virt_text_pos = "overlay",
                hl_mode = "combine" 
            })

            _G.current_extmark = {ns = ns_id, id = extmark_id}

        end

        vim.keymap.set("i", "<M-PageDown>", function()
            vim.defer_fn(_G.completion_handler, 0)
            return ""
        end, { noremap = true, expr = true, silent = true })


        vim.keymap.set("i", "<M-PageDown>", function()
            vim.defer_fn(function()
                _G.completion_handler()

                vim.api.nvim_create_autocmd("TextChangedI", {
                    buffer = 0,
                    once = true,  
                    callback = function()
                        clear_suggestion()
                    end
                })
            end, 0)
            return ""
        end, { noremap = true, expr = true, silent = true })

    end
})

vim.api.nvim_create_autocmd("InsertLeave", {
    pattern = "*",
    callback = function()
        vim.keymap.del("i", "<M-PageDown>")
        _G.completion_handler = nil
        clear_suggestion()
    end
})
