local rktmb_deepseek_complete = require("rktmb-deepseek-complete")
rktmb_deepseek_complete.log("Entered init.lua")

vim.api.nvim_set_hl(0, "InlineSuggestion", { fg = "#808080", bg = "NONE" })

_G.completion_handler = nil
_G.current_extmarks = nil

local function clear_suggestion()
    if _G.current_extmarks then
        for _, extmark in ipairs(_G.current_extmarks) do
            vim.api.nvim_buf_del_extmark(0, extmark.ns, extmark.id)
        end
        _G.current_extmarks = nil
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
            local lines = vim.split(suggestion, "\n")
            -- log the lines
            rktmb_deepseek_complete.log("Lines:")
            for _, line in ipairs(lines) do
                rktmb_deepseek_complete.log(line)
            end
            rktmb_deepseek_complete.log("End of lines")

            clear_suggestion()

            local ns_id = vim.api.nvim_create_namespace("rktmb-deepseek-complete-ns")
            _G.current_extmarks = {}

            -- Adjust the column index to be within the line length
            local adjusted_col = math.min(current_col, #current_line)

            for i, line in ipairs(lines) do
                local extmark_id = vim.api.nvim_buf_set_extmark(0, ns_id, vim.api.nvim_win_get_cursor(0)[1] - 1 + i - 1, adjusted_col, {
                    virt_text = {{line, "InlineSuggestion"}},
                    virt_text_pos = "overlay",
                    hl_mode = "combine"
                })
                table.insert(_G.current_extmarks, {ns = ns_id, id = extmark_id})
            end
        end

        vim.keymap.set("i", "<M-PageDown>", function()
            vim.defer_fn(_G.completion_handler, 0)
            return ""
        end, { noremap = true, expr = true, silent = true })

        vim.api.nvim_create_autocmd("TextChangedI", {
            buffer = 0,
            once = true,
            callback = function()
                clear_suggestion()
            end
        })
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

