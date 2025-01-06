local rktmb_deepseek_complete = require("rktmb-deepseek-complete")

_G.ns_id = vim.api.nvim_create_namespace('rktmb-deepseek-complete')

_G.suggest_random_sentence = function()
  local current_row = vim.api.nvim_win_get_cursor(0)[1]

  -- Ensure the cursor is at the end of the current line
  local current_line = vim.api.nvim_get_current_line()
  vim.api.nvim_win_set_cursor(0, {current_row, #current_line})

  -- Generate the random sentence
  local sentence = rktmb_deepseek_complete.generate_sentence()
  local lines = vim.split(sentence, "\n", true)

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

  -- Clear the suggestion on text change or insert leave
  local augroup_id = vim.api.nvim_create_augroup("RktmbDeepseekCompleteSuggestions", { clear = true })
  vim.api.nvim_create_autocmd({ "TextChangedI", "InsertLeave" }, {
    group = augroup_id,
    buffer = 0,
    callback = function()
      vim.api.nvim_buf_del_extmark(0, ns_id, extmark_id)
      vim.api.nvim_del_augroup_by_id(augroup_id)
    end
  })
end

vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*",
  callback = function()
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
  end
})

vim.api.nvim_set_keymap("i", "<M-PageDown>", "<Cmd>lua suggest_random_sentence()<CR>", {noremap = true, silent = true})
