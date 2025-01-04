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

-- Function to show the suggestion when triggered
local function show_suggestion()
  clear_suggestion()

  -- Get the current buffer and cursor position *BEFORE* moving the cursor
  local bufnr = vim.api.nvim_get_current_buf()

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>A", true, false, true), 'n', true)

  -- Generate a random sentence
  local suggestion = rktmb_deepseek_complete.generate_sentence()
  rktmb_deepseek_complete.log("Generated suggestion: " .. suggestion)

  -- Split the suggestion into lines
  local lines = vim.split(suggestion, "\n")

  -- Create a namespace for our extmarks
  local ns_id = vim.api.nvim_create_namespace('rktmb-deepseek-complete')

  -- Set extmarks for each line of the suggestion
  _G.current_extmarks = {}

  local current_cursor_pos = vim.api.nvim_win_get_cursor(0)

  for i, line in ipairs(lines) do
    local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, ns_id, current_cursor_pos[1] + i - 1, current_cursor_pos[2] -1 , {
      virt_text = { { line, "InlineSuggestion" } },
      virt_text_pos = 'overlay',
    })
    table.insert(_G.current_extmarks, { ns = ns_id, id = extmark_id })
  end


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





