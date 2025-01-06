local rktmb_deepseek_complete = require("rktmb-deepseek-complete")
local curl = require('plenary.curl')

_G.ns_id = vim.api.nvim_create_namespace('rktmb-deepseek-complete')

_G.current_extmark_id = nil
_G.current_suggestion = nil

_G.suggest_random_sentence = function()

  local cursor_position_table = vim.api.nvim_win_get_cursor(0)
  local current_row = cursor_position_table[1]
  local current_col = cursor_position_table[2]

  -- Ensure the cursor is at the end of the current line
  local current_line = vim.api.nvim_get_current_line()
  vim.api.nvim_win_set_cursor(0, {current_row, #current_line})

  cursor_position_table = vim.api.nvim_win_get_cursor(0)
  current_row = cursor_position_table[1]
  current_col = cursor_position_table[2]

  -- Get buffer content before and after cursor
  local current_buffer = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(current_buffer, 0, -1, false)
  local text_before_cursor = table.concat(lines, "\n", 1, current_row - 1) .. "\n" .. string.sub(lines[current_row], 1, current_col)
  local text_after_cursor = string.sub(lines[current_row], current_col + 1) .. "\n" .. table.concat(lines, "\n", current_row + 1)

  -- Log the content of text_before_cursor and text_after_cursor
  rktmb_deepseek_complete.log("Text before cursor:\n" .. text_before_cursor)
  rktmb_deepseek_complete.log("Text after cursor:\n" .. text_after_cursor)

  -- Make the DeepSeek API request
  local deepseek_request_body = {
    model = "deepseek-chat",
    prompt = text_before_cursor,
    echo = false,
    frequency_penalty = 0,
    max_tokens = 1024,
    presence_penalty = 0,
    stop = nil,
    stream = false,
    stream_options = nil,
    -- suffix = text_after_cursor,
    temperature = 1,
    top_p = 1
  }

  -- Replace '<TOKEN>' with your actual DeepSeek API token
  local deepseek_api_token = os.getenv("DEEPSEEK_API_KEY")

  -- Asynchronously make the POST request
  curl.post('https://api.deepseek.com/beta/completions', {
    body = vim.fn.json_encode(deepseek_request_body),
    headers = {
      ["Content-Type"] = "application/json",
      ["Accept"] = "application/json",
      ["Authorization"] = "Bearer " .. deepseek_api_token
    },
    callback = function(response)
      if response.status == 200 then
        -- Log the API response
        rktmb_deepseek_complete.log("DeepSeek API response:\n" .. response.body)
        -- response.body is a Lua table of choices
        -- Loop on the choices and display them
        for _, choice in ipairs(response.body.choices) do
          rktmb_deepseek_complete.log(choice.text)
          rktmb_deepseek_complete.log("===========================")
        end
      else
        -- Log the error
        rktmb_deepseek_complete.log("DeepSeek API request failed with status: " .. tostring(response.status))
        rktmb_deepseek_complete.log("Response body:\n" .. response.body)
      end
    end
  })

-- Generate the random sentence
  local sentence = rktmb_deepseek_complete.generate_sentence()
  lines = vim.split(sentence, "\n", true)

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
    hl_mode = 'combine'       -- Combine with existing text highlighting
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

  vim.api.nvim_buf_set_lines(bufnr, current_line, current_line, false, _G.current_suggestion)
  vim.api.nvim_win_set_cursor(0, { current_line + #_G.current_suggestion, 0 })
  vim.api.nvim_buf_del_extmark(bufnr, ns_id, _G.current_extmark_id)

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

