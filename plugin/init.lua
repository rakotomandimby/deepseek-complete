local rktmb_deepseek_complete = require("rktmb-deepseek-complete")

_G.ns_id = vim.api.nvim_create_namespace('rktmb-deepseek-complete')

_G.current_extmark_id = nil
_G.current_suggestion = nil

_G.suggest_random_sentence = function()
  local current_row = vim.api.nvim_win_get_cursor(0)[1]

  -- Ensure the cursor is at the end of the current line
  local current_line = vim.api.nvim_get_current_line()
  vim.api.nvim_win_set_cursor(0, {current_row, #current_line})

  -- Generate the random sentence
  local sentence = rktmb_deepseek_complete.generate_sentence()
  local lines = vim.split(sentence, "\n", true)

  -- Store the suggestion globally
  _G.current_suggestion = lines

  -- Construct virt_lines with proper formatting
  local virt_lines = {}
  for _, line in ipairs(lines) do
    table.insert(virt_lines, { { line, "Comment" } }) -- Use "Comment" highlight group for grey text
  end

  -- Set the extmark with virt_lines
  local extmark_id = vim.api.nvim_buf_set_extmark(0, ns_id, current_row - 1, 0, {
    virt_lines = virt_lines,
    virt_lines_above = false, -- Place the virtual lines below the current line
    hl_mode = 'combine' -- Combine with existing text highlighting
  })

  -- Store the extmark ID globally
  _G.current_extmark_id = extmark_id

  -- Clear the suggestion on text change or insert leave
  local augroup_id = vim.api.nvim_create_augroup("RktmbDeepseekCompleteSuggestions", { clear = true })
  vim.api.nvim_create_autocmd({ "TextChangedI", "InsertLeave" }, {
    group = augroup_id,
    buffer = 0,
    callback = function()
      vim.api.nvim_buf_del_extmark(0, ns_id, extmark_id)
      _G.current_extmark_id = nil
      _G.current_suggestion = nil
      vim.api.nvim_del_augroup_by_id(augroup_id)
    end
  })
end

_G.accept_suggestion = function()
  if not _G.current_extmark_id or not _G.current_suggestion then
    -- No active suggestion to accept
    return
  end

  local bufnr = 0
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor_pos[1]

  -- Insert the suggestion lines into the buffer
  -- Lines are inserted below the current line
  vim.api.nvim_buf_set_lines(bufnr, current_line, current_line, false, _G.current_suggestion)

  -- Optional: Move the cursor to the end of the inserted text
  vim.api.nvim_win_set_cursor(0, { current_line + #_G.current_suggestion, 0 })

  -- Remove the extmark (inline suggestion)
  vim.api.nvim_buf_del_extmark(bufnr, ns_id, _G.current_extmark_id)

  -- Clear the stored extmark ID and suggestion
  _G.current_extmark_id = nil
  _G.current_suggestion = nil
end

vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*",
  callback = function()
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
  end
})

vim.api.nvim_set_keymap("i", "<M-PageDown>", "<Cmd>lua suggest_random_sentence()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("i", "<M-PageUp>", "<Cmd>lua accept_suggestion()<CR>", { noremap = true, silent = true })

