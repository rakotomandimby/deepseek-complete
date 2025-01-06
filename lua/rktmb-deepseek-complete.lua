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

return M
