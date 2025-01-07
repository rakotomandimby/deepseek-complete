-- Initialize a module
local M = {}

-- Function to log a message into /tmp/rktmb-deepseek-complete.log
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

function M.get_open_buffers()
  local buffers = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf) ~= "" then
      table.insert(buffers, buf)
    end
  end

  -- log the list of buffers
  for _, buf in ipairs(buffers) do
    M.log(vim.api.nvim_buf_get_name(buf))
  end

  return buffers
end
-- get the content of a given buffer
function M.get_buffer_content(buf)
  local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return table.concat(content, "\n")
end

-- get the current buffer's nvim_buf_get_name
function M.get_current_buffer_name()
  return vim.api.nvim_buf_get_name(0)
end

function M.build_messages_table(text_before_cursor, text_after_cursor, line_the_cursor_is_on)
  local buffers = M.get_open_buffers()
  local messages = {}
  table.insert(messages, {
    role = "system",
    content = "You are a software developer assistant that will complete code based on the context provided."
    .." Just answer with indented raw code, NO explanations, NO markdown formatting."
    .. " The concatenation of the lines before the cursor,"
    .. " the line the cursor is on,"
    .. " the lines after the cursor AND the lines you propose MUST be valid code that can be executed." })
  table.insert(messages, { role = "user", content = "I need you to complete code." })

  for _, buf in ipairs(buffers) do
    local filename = vim.api.nvim_buf_get_name(buf)
    if not filename:match("%%.md$") then  -- Lua pattern matching for ".md" at the end
      local content = M.get_buffer_content(buf)
      -- log the filename then the content
      rktmb_deepseek_complete.log(filename)
      rktmb_deepseek_complete.log(content)

      table.insert(messages, { role = "assistant", content = "Give me the content of " .. filename })
      table.insert(messages, { role = "user", content = content })
    end
  end
  table.insert(messages, { role = "assistant", content = "What is the current buffer?" })
  table.insert(messages, { role = "user", content = M.get_current_buffer_name() })
  table.insert(messages, { role = "assistant", content = "What is before the cursor?" })
  table.insert(messages, { role = "user", content = text_before_cursor })
  table.insert(messages, { role = "assistant", content = "What is after the cursor?" })
  table.insert(messages, { role = "user", content = text_after_cursor })
  table.insert(messages, { role = "assistant", content = "What line do you want me to continue?" })
  table.insert(messages, { role = "user", content = line_the_cursor_is_on })

  return messages
end
return M
