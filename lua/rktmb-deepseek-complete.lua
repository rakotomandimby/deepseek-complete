-- Initialize a module
local M = {}

_G.num_lines_inserted = 0

function M.log(message)
  local log_file = io.open("/tmp/rktmb-deepseek-complete.log", "a")
  -- check if log_file is nil
  if log_file == nil then
    print("Error opening log file")
    return
  end
  log_file:write(message .. "\n")
  log_file:close()
end

function M.remove_markdown_delimiters(text)
  local lines = vim.split(text, "\n", true)
  local new_lines = {}

  for _, line in ipairs(lines) do
    if line:sub(1, 3) == "```" then
      table.insert(new_lines, "\n") -- Replace lines starting with "```" with newline
    else
      table.insert(new_lines, line)
    end
  end

  return table.concat(new_lines, "\n")
end

function M.clear_suggestion()
  local current_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(current_buf, _G.ns_id, 0, -1)

  -- Remove the inserted lines if any
  if _G.num_lines_inserted and _G.num_lines_inserted > 0 then
    local position = vim.api.nvim_win_get_cursor(0)
    local row = position[1] - 1 -- Adjust to 0-based indexing
    vim.api.nvim_buf_set_lines(current_buf, row + 1, row + 1 + _G.num_lines_inserted, false, {}) -- remove the inserted lines
    _G.num_lines_inserted = 0 -- Reset after removing lines
  end
end

function M.accept_suggestion_word()
  if _G.current_suggestion == nil then
    return
  end

  local suggestion = _G.current_suggestion
  M.clear_suggestion() -- Clear the suggestion extmark

  local lines = vim.split(suggestion, "\n", true)
  local first_line = lines[1]
  local rest_of_lines = {}
  for i = 2, #lines do
    table.insert(rest_of_lines, lines[i])
  end

  local current_line = vim.api.nvim_get_current_line()
  local current_pos = vim.api.nvim_win_get_cursor(0)
  local current_row, current_col = current_pos[1], current_pos[2]

  -- Extract the first word from the suggestion
  local first_word = string.match(first_line, "^%%s*(%%S+)") or ""
  if first_word ~= "" then
    -- Insert the first word into the current line
    vim.api.nvim_buf_set_text(0, current_row - 1, current_col, current_row - 1, current_col, { first_word })

    -- Move the cursor after the inserted word
    vim.api.nvim_win_set_cursor(0, { current_row, current_col + #first_word })

    -- Update current_suggestion, removing the accepted word
    _G.current_suggestion = string.sub(first_line, #first_word + 1) .. "\n" .. table.concat(rest_of_lines, "\n")

    -- If the remaining suggestion is not empty, re-display it
    if _G.current_suggestion and string.match(_G.current_suggestion, "^%%s*(%%S+)") then
      M.set_suggestion_extmark(_G.current_suggestion)
    end
  end
end

function M.set_suggestion_extmark(suggestion)
  -- Remove Markdown code block delimiters from the suggestion
  suggestion = M.remove_markdown_delimiters(suggestion)

  local current_buf = vim.api.nvim_get_current_buf()
  local position = vim.api.nvim_win_get_cursor(0)
  local row = position[1] - 1 -- Adjust to 0-based indexing
  local col = position[2]

  -- Split the suggestion into lines
  local lines = vim.split(suggestion, '\n', true)

  -- Clear existing extmarks
  -- vim.api.nvim_buf_clear_namespace(current_buf, _G.ns_id, 0, -1)

  local num_lines_to_insert = 0
  -- Insert empty lines into the buffer if necessary
  if #lines > 1 then
    num_lines_to_insert = #lines - 1
    -- Insert empty lines after current line
    vim.api.nvim_buf_set_lines(current_buf, row + 1, row + 1, false, vim.fn['repeat']({' '}, num_lines_to_insert))
  end

  -- Now set the extmarks
  -- First line: virt_text on current line starting at cursor column
  vim.api.nvim_buf_set_extmark(
    current_buf,
    _G.ns_id,
    row,
    col,
    {
      virt_text = { { lines[1], "Comment" } },
      hl_mode = 'combine',
    }
  )

  -- Remaining lines: virt_text on the inserted empty lines
  for i = 2, #lines do
    local extmark_row = row + i - 1 -- Adjust row for each line
    vim.api.nvim_buf_set_extmark(
      current_buf,
      _G.ns_id,
      extmark_row,
      0,
      {
        virt_text = { { lines[i], "Comment" } },
        hl_mode = 'combine',
      }
    )
  end
  _G.num_lines_inserted = num_lines_to_insert
end


function M.get_text_before_cursor()
  local position = vim.api.nvim_win_get_cursor(0)
  local current_line = position[1]
  local current_col = position[2]
  local lines = vim.api.nvim_buf_get_lines(0, 0, current_line, false)
  lines[#lines] = string.sub(lines[#lines], 1, current_col)
  local result = table.concat(lines, "\n")
  return result
end

function M.get_text_after_cursor()
  local position = vim.api.nvim_win_get_cursor(0)
  local current_line = position[1]
  local current_col = position[2]
  local lines = vim.api.nvim_buf_get_lines(0, current_line - 1, -1, false)
  lines[1] = string.sub(lines[1], current_col + 1)  -- Get text from the cursor position in the current line
  local result = table.concat(lines, "\n")
  return result
end

function M.get_text_before_cursor_line()
  local position = vim.api.nvim_win_get_cursor(0)
  local current_line = position[1]
  local current_col = position[2]
  local line = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)[1]
  local result = string.sub(line, 1, current_col)
  return result
end

function M.get_open_buffers()
  local buffers = {}
  local current_buf = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf) ~= "" and buf ~= current_buf then
      table.insert(buffers, buf)
    end
  end
  return buffers
end

-- get the content of a given buffer
function M.get_buffer_content(buf)
  if not vim.api.nvim_buf_is_loaded(buf) then
    vim.fn.bufload(buf)
  end
  local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return table.concat(content, "\n")
end

-- get the current buffer's nvim_buf_get_name
function M.get_current_buffer_name()
  return vim.api.nvim_buf_get_name(0)
end


function M.build_messages_table(text_before_cursor, text_after_cursor, line_to_continue)
  local buffers = M.get_open_buffers()
  local messages = {}
  table.insert(messages, {
    role = "system",
    content = "You are a software developer assistant that continues a line from the surcor position,"
      .. " based on the provided context."
      .. " DO NOT repeat what is before the cursor."
      .. " You might have to continue either text or code."
      .. " Answer with the continuation of the provided line. When providing code, "
      .. " the concatenation of the code before the cursor,"
      .. " the code you propose,"
      .. " AND the code after your suggestion"
      .. " MUST be valid and consistent."
      .. " You continue the text or the code: start your suggestion with the next word to be placed after the cursor."
  })
  table.insert(messages, { role = "user", content = "I need you to complete the code." })

  for _, buf in ipairs(buffers) do
    local filename = vim.api.nvim_buf_get_name(buf)
    local content = M.get_buffer_content(buf)
    table.insert(messages, { role = "assistant", content = "Give me the content of `" .. filename .. "`" })
    table.insert(messages, { role = "user", content = "The content of `" .. filename .. "` is:\n```\n" .. content .. "\n```" })
  end
  table.insert(messages, { role = "assistant", content = "What is the current buffer?" })
  table.insert(messages, { role = "user", content = "The current buffer is `" .. M.get_current_buffer_name() .. "`" })
  table.insert(messages, { role = "assistant", content = "What is before the cursor?" })
  table.insert(messages, { role = "user", content = "From the begining of the buffer to the cursor, we have:\n```\n" .. text_before_cursor .. "\n```" })
  table.insert(messages, { role = "assistant", content = "What is after the cursor?" })
  table.insert(messages, { role = "user", content = "From the cursor to the end of the buffer, we have:\n```\n" .. text_after_cursor .. "\n```" })
  table.insert(messages, { role = "assistant", content = "Give me the line you want me to continue in the current buffer."})
  table.insert(messages, { role = "user", content = "Continue this line: `" ..line_to_continue .. "`" })
  M.log("Line to continue: " .. line_to_continue)
  return messages
end


return M
