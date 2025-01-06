local rktmb_deepseek_complete = require("rktmb-deepseek-complete")

local ns_id = vim.api.nvim_create_namespace('rktmb-deepseek-complete')

local current_extmark_id = nil
local current_suggestion = nil

local function suggest_random_sentence()
  local current_row, current_col = unpack(vim.api.nvim_win_get_cursor(0))

  -- Ensure the cursor is at the end of the current line
  local current_line = vim.api.nvim_get_current_line()
  vim.api.nvim_win_set_cursor(0, { current_row, #current_line })

  local sentence = rktmb_deepseek_complete.generate_sentence()
  local lines = vim.split(sentence, "\n", true)

  current_suggestion = lines

  local virt_lines = {}
  for _, line in ipairs(lines) do
    table.insert(virt_lines, { { line, "Comment" } })
  end

  current_extmark_id = vim.api.nvim_buf_set_extmark(0, ns_id, current_row - 1, 0, {
    virt_lines = virt_lines,
    virt_lines_above = false,
    hl_mode = 'combine'
  })

  -- Use a single autocommand for both TextChangedI and InsertLeave
  vim.api.nvim_create_autocmd({ "TextChangedI", "InsertLeave" }, {
    buffer = 0,
    once = true,  -- This ensures the autocommand is removed after running once
    callback = function()
      if current_extmark_id then
        vim.api.nvim_buf_del_extmark(0, ns_id, current_extmark_id)
        current_extmark_id = nil
        current_suggestion = nil
      end
    end
  })
end

local function accept_suggestion()
  if not current_extmark_id or not current_suggestion then
    return
  end

  local bufnr = 0
  local current_row, _ = unpack(vim.api.nvim_win_get_cursor(0))

  vim.api.nvim_buf_set_lines(bufnr, current_row, current_row, false, current_suggestion)

  vim.api.nvim_buf_del_extmark(bufnr, ns_id, current_extmark_id)

  current_extmark_id = nil
  current_suggestion = nil

  -- Move cursor to the end of the inserted text (accounts for multi-line suggestions)
  vim.api.nvim_win_set_cursor(0, { current_row + #current_suggestion -1, 0 })
end


vim.api.nvim_set_keymap("i", "<M-PageDown>", "<Cmd>lua suggest_random_sentence()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("i", "<M-PageUp>", "<Cmd>lua accept_suggestion()<CR>", { noremap = true, silent = true })


