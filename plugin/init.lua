local rktmb_deepseek_complete = require("rktmb-deepseek-complete")

_G.suggest_random_sentence = function()  -- Make this function global
  local current_line = vim.api.nvim_get_current_line()
  local current_row = vim.api.nvim_win_get_cursor(0)[1]

  vim.api.nvim_win_set_cursor(0, { current_row, #current_line })

  local sentence = rktmb_deepseek_complete.generate_sentence()

  local opts = {
    virt_text = { { sentence, "Comment" } },  -- Use "Comment" highlight group
    virt_text_pos = "overlay",
  }
  vim.api.nvim_buf_set_extmark(0, vim.fn.nsID("rktmb-deepseek-complete"), current_row - 1, #current_line, opts)

  local augroup_id = vim.api.nvim_create_augroup("RktmbDeepseekCompleteSuggestions", { clear = true })
  vim.api.nvim_create_autocmd("TextChangedI", {
    group = augroup_id,
    buffer = 0,
    callback = function()
      vim.api.nvim_buf_clear_namespace(0, vim.fn.nsID("rktmb-deepseek-complete"), 0, -1)
      vim.api.nvim_del_augroup_by_id(augroup_id) -- Clean up the autocommand group
    end,
  })
end


vim.api.nvim_set_keymap("i", "<M-PageDown>", "<Cmd>lua suggest_random_sentence()<CR>", { noremap = true, silent = true })

