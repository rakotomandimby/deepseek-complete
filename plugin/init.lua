local rktmb_deepseek_complete = require("rktmb-deepseek-complete")

_G.ns_id = vim.api.nvim_create_namespace('rktmb-deepseek-complete')

_G.suggest_random_sentence = function()
  local current_line = vim.api.nvim_get_current_line()
  local current_row = vim.api.nvim_win_get_cursor(0)[1]

  vim.api.nvim_win_set_cursor(0, { current_row, #current_line })

  local sentence = rktmb_deepseek_complete.generate_sentence()
  local lines = vim.split(sentence, "\n", true)

  local opts = {
    kind = "plaintext",
    menu = "[Random]",  -- Optional: Add a menu label
  }

    vim.api.nvim_buf_set_extmark(0, ns_id, current_row - 1, #current_line, {virt_text = {{' ', "Normal"}}, virt_text_pos='overlay'}) -- trick to push down the lines below

  vim.fn.complete(0, {
      { word = lines[1], opts = opts }, -- First line as the main completion item
      unpack(vim.tbl_map(function(line)
          return { word = line, opts = opts }
      end, vim.list_slice(lines, 2))) -- Subsequent lines as additional items
  })


  local augroup_id = vim.api.nvim_create_augroup("RktmbDeepseekCompleteSuggestions", { clear = true })
  vim.api.nvim_create_autocmd("TextChangedI", {
    group = augroup_id,
    buffer = 0,
    callback = function()
      vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
      vim.api.nvim_del_augroup_by_id(augroup_id)
      vim.cmd [[pumhide]] -- Hide the popup menu when typing starts
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
