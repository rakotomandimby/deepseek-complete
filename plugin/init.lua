local rktmb_deepseek_complete = require("rktmb-deepseek-complete")

_G.ns_id = vim.api.nvim_create_namespace('rktmb-deepseek-complete')

_G.suggest_random_sentence = function()
  -- 1. Move cursor to the end of the line *FIRST*
  local current_row = vim.api.nvim_win_get_cursor(0)[1]
  local current_line = vim.api.nvim_get_current_line()
  vim.api.nvim_win_set_cursor(0, { current_row, #current_line +1 })


  local sentence = rktmb_deepseek_complete.generate_sentence()
  local lines = vim.split(sentence, "\n", true)

  -- Log the lines (for debugging)
  rktmb_deepseek_complete.log("Lines:")
  for _, line in ipairs(lines) do
    rktmb_deepseek_complete.log(line)
  end
  rktmb_deepseek_complete.log("")

  -- Use virtual text for multi-line suggestions.  Crucially, use \n as the actual newline
  local chunks = {}
  for i, line in ipairs(lines) do
    table.insert(chunks, { line, "Comment" })  -- Use "Comment" highlight group for grey
    if i < #lines then
      table.insert(chunks, { "\n", "Comment" }) -- Preserve newlines with correct highlighting
    end
  end

  local current_col = vim.api.nvim_win_get_cursor(0)[2] -- Get updated column after moving cursor

  vim.api.nvim_buf_set_extmark(0, ns_id, current_row - 1, current_col, { virt_text = chunks, virt_text_pos = 'overlay' })

  -- Clear the suggestion on TextChangedI (unchanged)
  local augroup_id = vim.api.nvim_create_augroup("RktmbDeepseekCompleteSuggestions", { clear = true })
  vim.api.nvim_create_autocmd("TextChangedI", {
    group = augroup_id,
    buffer = 0,
    callback = function()
      vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
      vim.api.nvim_del_augroup_by_id(augroup_id)
    end,
  })
end


vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*",
  callback = function()
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
  end,
})

vim.api.nvim_set_keymap("i", "<M-PageDown>", "<Cmd>lua suggest_random_sentence()<CR>", { noremap = true, silent = true })

