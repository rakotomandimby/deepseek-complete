local rktmb_deepseek_complete = require("rktmb-deepseek-complete")
rktmb_deepseek_complete.log("Entered init.lua")

-- Define the highlight group for the suggestion text
vim.api.nvim_set_hl(0, "InlineSuggestion", { fg = "#808080", bg = "NONE" })

-- Global variables to keep track of extmarks
_G.current_extmarks = nil

-- Function to clear the current suggestion
local function clear_suggestion()
  if _G.current_extmarks then
    for _, extmark in pairs(_G.current_extmarks) do
      vim.api.nvim_buf_del_extmark(0, extmark.ns, extmark.id)
    end
    _G.current_extmarks = nil
  end
end

local function show_suggestion()
  clear_suggestion()
  local bufnr = vim.api.nvim_get_current_buf()
  
  -- Move cursor to the end of the line
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>A", true, false, true), 'n', false)
  
  local current_cursor_pos = vim.api.nvim_win_get_cursor(0)
  local suggestion = rktmb_deepseek_complete.generate_sentence()
  
  -- Log the generated suggestion for debugging
  rktmb_deepseek_complete.log("Generated suggestion: " .. suggestion)

  local ns_id = vim.api.nvim_create_namespace('rktmb-deepseek-complete')
  _G.current_extmarks = {}
  
  -- Set the extmark *at the current cursor position*
  local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, ns_id, current_cursor_pos[1] - 1, current_cursor_pos[2], {
    virt_text = { { suggestion, "InlineSuggestion" } },
    virt_text_pos = 'eol',  -- Position the suggestion at the end of the line
    hl_mode = 'combine',     -- Combine highlight with existing text
  })
  
  table.insert(_G.current_extmarks, { ns = ns_id, id = extmark_id })
  
  -- Log the extmark ID for debugging
  rktmb_deepseek_complete.log("Set extmark ID: " .. extmark_id)

  -- Move the cursor back to the end of the line
  vim.api.nvim_feedkeys("a", 'n', false)
end

-- Map <M-PageDown> to show_suggestion in insert mode
vim.keymap.set('i', '<M-PageDown>', show_suggestion, { noremap = true, silent = true })

-- Auto command to clear the suggestion when typing
vim.api.nvim_create_autocmd("TextChangedI", {
  pattern = "*",
  callback = function()
    clear_suggestion()
  end,
})

-- Auto command to clear the suggestion when leaving insert mode
vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*",
  callback = function()
    clear_suggestion()
  end,
})

