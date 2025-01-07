-- Initialize a module
local M = {}

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
  if lines[1]:sub(1, 3) == "```" then
    table.remove(lines, 1)
  end
  if lines[#lines]:sub(-3) == "```" then
    lines[#lines] = nil
  end
  return table.concat(lines, "\n")
end


function M.set_suggestion_extmark(suggestion)
  local current_buf = vim.api.nvim_get_current_buf()
  local position = vim.api.nvim_win_get_cursor(0)
  local row = position[1] - 1 -- Adjust to 0-based indexing
  local col = position[2]

  -- Split the suggestion into lines
  local lines = vim.split(suggestion, '\n', true)

  -- Create virtual text segments for each line
  local virt_text_lines = {}
  for _, line in ipairs(lines) do
    table.insert(virt_text_lines, {line, "Comment"})
  end


  if _G.current_extmark_id then
    -- Update existing extmark
    vim.api.nvim_buf_set_extmark(
      current_buf,
      _G.ns_id,
      row,
      col,
      {
        virt_text = virt_text_lines,
        virt_text_pos = "overlay"
      }
    )
  else
    -- Create new extmark
    _G.current_extmark_id = vim.api.nvim_buf_set_extmark(
      current_buf,
      _G.ns_id,
      row,
      col,
      {
        virt_text = virt_text_lines,
        virt_text_pos = "overlay"
      }
    )
  end
end

function M.get_text_before_cursor()
  M.log("get_text_before_cursor")
  local position = vim.api.nvim_win_get_cursor(0)
  local current_line = position[1]
  local current_col = position[2]
  M.log(vim.inspect(current_line))
  M.log(vim.inspect(current_col))
  local lines = vim.api.nvim_buf_get_lines(0, 0, current_line, false)
  lines[#lines] = string.sub(lines[#lines], 1, current_col)
  local result = table.concat(lines, "\n")
  M.log(result)
  return result
end

function M.get_text_after_cursor()
  M.log("get_text_after_cursor")
  local position = vim.api.nvim_win_get_cursor(0)
  local current_line = position[1]
  local current_col = position[2]
  M.log(vim.inspect(current_line))
  M.log(vim.inspect(current_col))
  local lines = vim.api.nvim_buf_get_lines(0, current_line - 1, -1, false)
  lines[1] = string.sub(lines[1], current_col + 1)  -- Get text from the cursor position in the current line
  local result = table.concat(lines, "\n")
  M.log(result)
  return result
end

function M.get_text_before_cursor_line()
  M.log("get_text_before_cursor_line")
  local position = vim.api.nvim_win_get_cursor(0)
  local current_line = position[1]
  local current_col = position[2]
  M.log(vim.inspect(current_line))
  M.log(vim.inspect(current_col))
  local line = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)[1]
  local result = string.sub(line, 1, current_col)
  M.log(result)
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
    content = "You are a software developer assistant that will complete the code from the surcor position, based on the provided context."
      .. " Just answer with indented raw code, NO explanations, NO markdown formatting."
      .. " The concatenation of the code before the cursor,"
      .. " the code you propose,"
      .. " AND the code after your suggestion"
      .. " MUST be valid and consistent."
      .. " You continue the code, so start your suggestion with the next word to be placed after the cursor."
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
  table.insert(messages, { role = "assistant", content = "Give me the line you want me to continue."})
  table.insert(messages, { role = "user", content = line_to_continue })
  -- log the messages
  M.log("============ Messages table:")
  for _, message in ipairs(messages) do
    M.log(message.role .. ": " .. message.content)
  end
  M.log("=====================================")

  return messages
end


return M
