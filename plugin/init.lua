local rktmb_deepseek_complete = require("rktmb-deepseek-complete")

_G.ns_id = vim.api.nvim_create_namespace('rktmb-deepseek-complete')

_G.suggest_random_sentence = function()
  local current_row = vim.api.nvim_win_get_cursor(0)[1]
  local current_line = vim.api.nvim_get_current_line()

  -- Move to the end of the current line *before* generating the sentence
  vim.api.nvim_win_set_cursor(0, {current_row, #current_line +1})

  local sentence = rktmb_deepseek_complete.generate_sentence()
  local lines = vim.split(sentence, "\n", true)


  -- Construct virtual text chunks with proper newlines
  local chunks = {}
  for _, line in ipairs(lines) do
    table.insert(chunks, {line .. '\n', "Comment"})
    -- Log the line
    rktmb_deepseek_complete.log(line)
    -- Add newline chunk after each line *except* the last
    if _ < #lines then
      table.insert(chunks, {"\n", "Comment"}) -- Actual newline character
    end
  end

  local current_col = vim.api.nvim_win_get_cursor(0)[2]

  vim.api.nvim_buf_set_extmark(0, ns_id, current_row - 1, current_col, {
    virt_text = chunks,
    virt_text_pos = 'overlay'
  })

  -- Clear on TextChangedI (this part is correct)
  local augroup_id = vim.api.nvim_create_augroup("RktmbDeepseekCompleteSuggestions", {clear = true})
  vim.api.nvim_create_autocmd("TextChangedI", {
    group = augroup_id,
    buffer = 0,
    callback = function()
      vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
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
