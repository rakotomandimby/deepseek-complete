local rktmb_deepseek_complete = require("rktmb-deepseek-complete")
local curl = require('plenary.curl')

_G.ns_id = vim.api.nvim_create_namespace('rktmb-deepseek-complete')

_G.current_extmark_id = nil
_G.current_suggestion = nil


local function process_deepseek_response(response)
  if response.status == 200 then
    rktmb_deepseek_complete.log("DeepSeek status: 200")
    vim.schedule(function()
      rktmb_deepseek_complete.log("DeepSeek in the schedule")
      local body = vim.fn.json_decode(response.body)
      if body.choices and #body.choices > 0 then
        -- Extract the first choice from the API response
        local choice = body.choices[1]
        local suggestion = choice.message.content

        -- Remove Markdown code block delimiters if present
        suggestion = rktmb_deepseek_complete.remove_markdown_start_code_block_delimiter(suggestion)
        suggestion = rktmb_deepseek_complete.remove_markdown_end_code_block_delimiter(suggestion)
        rktmb_deepseek_complete.log("Suggestion from DeepSeek API:")
        rktmb_deepseek_complete.log(suggestion)

        -- Split the suggestion into lines
        local lines = vim.split(suggestion, "\n", true)

        -- Store the suggestion globally
        _G.current_suggestion = lines

        -- Construct virt_lines with proper formatting
        local virt_lines = {}
        for _, line in ipairs(lines) do
          table.insert(virt_lines, { { line, "Comment" } }) -- Use "Comment" highlight group for grey text
        end

        -- Get the current cursor position
        local cursor_position_table = vim.api.nvim_win_get_cursor(0)
        local current_row = cursor_position_table[1] - 1 -- Adjust for 0-based index

        -- Set the extmark with virt_lines
        local extmark_id = vim.api.nvim_buf_set_extmark(0, ns_id, current_row, 0, {
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
      else
        rktmb_deepseek_complete.log("DeepSeek API returned no choices.")
      end
    end)
  else
    rktmb_deepseek_complete.log("DeepSeek API request failed with status: " .. tostring(response.status))
    rktmb_deepseek_complete.log("Response body:\n" .. response.body)
  end
end


_G.suggest_random_sentence = function()
  local cursor_position_table = vim.api.nvim_win_get_cursor(0)
  local current_row = cursor_position_table[1]
  local current_col = cursor_position_table[2]

  -- Ensure the cursor is at the end of the current line
  local current_line = vim.api.nvim_get_current_line()
  vim.api.nvim_win_set_cursor(0, { current_row, #current_line })

  cursor_position_table = vim.api.nvim_win_get_cursor(0)
  current_row = cursor_position_table[1]
  current_col = cursor_position_table[2]

  -- Get buffer content before and after cursor
  local current_buffer = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(current_buffer, 0, -1, false)
  local text_before_cursor = table.concat(lines, "\n", 1, current_row - 1) .. "\n" .. string.sub(lines[current_row], 1, current_col)
  local text_after_cursor = string.sub(lines[current_row], current_col + 1) .. "\n" .. table.concat(lines, "\n", current_row + 1)
  local line_the_cursor_is_on = string.sub(lines[current_row], current_col + 1)

  -- Log the text before and after the cursor (optional)
  rktmb_deepseek_complete.log("Text before cursor:\n" .. text_before_cursor .. "\n=====================================")
  rktmb_deepseek_complete.log("Text after cursor:\n" .. text_after_cursor   .. "\n=====================================")
  rktmb_deepseek_complete.log("Line the cursor is on:\n" .. line_the_cursor_is_on .. "\n=====================================")

  local deepseek_request_body = {
    model = "deepseek-chat",
    echo = false,
    frequency_penalty = 0,
    max_tokens = 4096,
    presence_penalty = 0,
    stop = nil,
    stream = false,
    stream_options = nil,
    temperature = 1,
    top_p = 1,
    messages = {
      { role = "system", content = "You are a software developer assistant that will complete code based on the context provided. Just answer with indented raw code, NO explanations, NO markdown formatting." },
      { role = "user", content = "I need you to complete code." },
      { role = "assistant", content = "What is before the cursor?" },
      { role = "user", content = text_before_cursor },
      { role = "assistant", content = "What is after the cursor?" },
      { role = "user", content = text_after_cursor },
      { role = "assistant", content = "What line do you want me to continue?" },
      { role = "user", content = "Continue this line: \n" .. line_the_cursor_is_on }
    }
  }

  -- Retrieve the API token
  local deepseek_api_token = os.getenv("DEEPSEEK_API_KEY")

  -- Asynchronously make the POST request
  curl.post('https://api.deepseek.com/chat/completions', {
    body = vim.fn.json_encode(deepseek_request_body),
    headers = {
      ["Content-Type"] = "application/json",
      ["Accept"] = "application/json",
      ["Authorization"] = "Bearer " .. deepseek_api_token
    },
    callback = function(response)
      process_deepseek_response(response)
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

