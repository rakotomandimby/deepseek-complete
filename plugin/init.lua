-- Require the module containing the generate_sentence function
local deepseek_complete = require('rktmb-deepseek-complete')

-- Create a table to store our functions and state
local M = {}

-- Function to clear the suggestion when the user types or moves
function M.clear_suggestion()
  if M._suggestion then
    local bufnr = M._suggestion.bufnr
    local start_line = M._suggestion.start_line
    local end_line = M._suggestion.end_line
    local namespace = M._suggestion.namespace

    -- Delete the inserted lines
    vim.api.nvim_buf_set_lines(bufnr, start_line, end_line, false, {})

    -- Clear the namespace (highlights)
    vim.api.nvim_buf_clear_namespace(bufnr, namespace, start_line, end_line)

    -- Clear the stored suggestion
    M._suggestion = nil

    -- Clear the autocmd group
    vim.cmd('augroup SuggestionAutocmd | autocmd! | augroup END')
  end
end

-- Function to show the suggestion when triggered
function M.show_suggestion()
  -- Clear any existing suggestion
  M.clear_suggestion()

  -- Move cursor to end of line
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>A", true, false, true), 'n', false)

  -- Generate a random multiline sentence
  local suggestion = deepseek_complete.generate_sentence()

  -- Get current buffer and cursor position
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1  -- Zero-based index

  -- Split the suggestion into lines
  local lines = vim.split(suggestion, '\n', true)

  -- Insert the suggestion lines after the current line
  vim.api.nvim_buf_set_lines(bufnr, line + 1, line + 1, false, lines)

  -- Apply grey color (#808080) to the inserted text
  local namespace = vim.api.nvim_create_namespace('suggestion_ns')
  local hl_group = 'SuggestionGrey'

  -- Define the highlight group for grey color
  vim.cmd('highlight ' .. hl_group .. ' guifg=#808080')

  -- Apply the highlight to each line of the suggestion
  for i = 1, #lines do
    vim.api.nvim_buf_add_highlight(bufnr, namespace, hl_group, line + i, 0, -1)
  end

  -- Create an autocmd group to clear the suggestion when typing or moving
  vim.cmd([[
    augroup SuggestionAutocmd
    autocmd!
    autocmd TextChangedI,CursorMovedI * lua require('plugin.init').clear_suggestion()
    augroup END
    ]])

  -- Store the suggestion state to clear it later
  M._suggestion = {
    bufnr = bufnr,
    start_line = line + 1,
    end_line = line + 1 + #lines,
    namespace = namespace,
  }
end

-- Map <M-PageDown> in INSERT mode to trigger the suggestion
vim.api.nvim_set_keymap('i', '<M-PageDown>', '<Cmd>lua require("plugin.init").show_suggestion()<CR>', { noremap = true, silent = true })

return M

