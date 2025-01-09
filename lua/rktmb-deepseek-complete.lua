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

local function split_into_words(text)
  -- Simple word splitting using whitespace as delimiter.  Consider more robust methods if needed.
  return vim.split(text, "%%s+", {plain=true})
end

function M.accept_suggestion_word()
    if _G.current_suggestion then
        local words = split_into_words(_G.current_suggestion)
        if #words > 0 then
            local word = words[1]
            local current_buf = vim.api.nvim_get_current_buf()
            local position = vim.api.nvim_win_get_cursor(0)
            local row = position[1] - 1
            local col = position[2]

            -- Insert the accepted word into the buffer
            vim.api.nvim_buf_set_text(current_buf, row, col, row, col, {word})

            -- Remove the accepted word from the suggestion
            _G.current_suggestion = string.sub(_G.current_suggestion, #word + 1)

            -- Update the displayed suggestion (clear and redraw)
            M.clear_suggestion()
            if _G.current_suggestion and #_G.current_suggestion > 0 then
                M.set_suggestion_extmark(_G.current_suggestion)
            end

        else
            _G.current_suggestion = nil -- Clear suggestion if no words left
            M.clear_suggestion()
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
  M.log("Line to continue: " .. line_to_continue)
  return messages
end


return M
