local rktmb_deepseek_complete = require("rktmb-deepseek-complete")
local curl = require('plenary.curl')

local api_call_in_progress = false
local last_api_call_time = 0

_G.ns_id = vim.api.nvim_create_namespace('rktmb-deepseek-complete')

_G.current_extmark_id = nil
_G.current_suggestion = nil

-- Default keymappings
local default_opts = {
  deepseek_api_key = os.getenv("DEEPSEEK_API_KEY"),
  suggest_lines_keymap = "<M-ESC>",
  accept_all_keymap = "<M-PageDown>",
  accept_line_keymap = "<M-Down>",
  debounce_time = 1000,
}

local function clear_suggestion()
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


-- Read user configuration
local user_opts = vim.tbl_deep_extend("force", default_opts, vim.g.rktmb_deepseek_complete_opts or {})

local function process_deepseek_response(response)
  vim.schedule(function()  -- Use vim.schedule to run this in the main thread
    local response_body = vim.fn.json_decode(response.body)
    if response_body.choices and #response_body.choices > 0 then
      clear_suggestion()
      local choice = response_body.choices[1]
      local suggestion = choice.message.content
      rktmb_deepseek_complete.set_suggestion_extmark(suggestion)
      _G.current_suggestion = suggestion
      rktmb_deepseek_complete.log("\n\nSuggestion from DeepSeek API:")
      rktmb_deepseek_complete.log(suggestion)
    end
  end)
end

_G.suggest = function()

  local now = vim.loop.hrtime() / 1000000
  if api_call_in_progress or (now - last_api_call_time < user_opts.debounce_time) then
    rktmb_deepseek_complete.log("API call in progress or too recent, skipping.")
    return
  end

  api_call_in_progress = true
  last_api_call_time = now
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
    messages = rktmb_deepseek_complete.build_messages_table(
      rktmb_deepseek_complete.get_text_before_cursor(),
      rktmb_deepseek_complete.get_text_after_cursor(),
      rktmb_deepseek_complete.get_text_before_cursor_line()
    )
  }

  -- Asynchronously make the POST request
  curl.post('https://api.deepseek.com/chat/completions', {
    body = vim.fn.json_encode(deepseek_request_body),
    headers = {
      ["Content-Type"] = "application/json",
      ["Accept"] = "application/json",
      ["Authorization"] = "Bearer " .. user_opts.deepseek_api_key
    },
    callback = function(response)
      api_call_in_progress = false -- Reset the flag after receiving the response
      process_deepseek_response(response)
    end
  })
end

vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*",
  callback = function()
    clear_suggestion()
  end
})


vim.api.nvim_create_autocmd("InsertCharPre", {
  pattern = "*",
  callback = function()
    vim.schedule(function()
      clear_suggestion()
    end)
  end
})
-- Key mappings
vim.api.nvim_set_keymap("i", user_opts.suggest_lines_keymap, "<Cmd>lua suggest()<CR>", { noremap = true, silent = true })

-- Punctuation keys
-- local punctuation_keys = { "!", '"', "#", "$", "%%", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/", ":", ";", "<", "=", ">", "?", "@", "[", "\\", "]", "^", "_", "`", "{", "|", "}", "~" }
-- for _, key in ipairs(punctuation_keys) do
--   vim.api.nvim_set_keymap("i", key, "<Cmd>lua suggest()<CR>" .. key, { noremap = true, silent = true })
-- end

-- Space key
-- vim.api.nvim_set_keymap("i", " ", "<Cmd>lua suggest()<CR> ", { noremap = true, silent = true })

-- Uncomment these if you want to use them
-- vim.api.nvim_set_keymap("i", user_opts.accept_all_keymap,    "<Cmd>lua accept_the_whole_suggestion()<CR>", { noremap = true, silent = true })
-- vim.api.nvim_set_keymap("i", user_opts.accept_line_keymap,   "<Cmd>lua accept_one_suggestion_line()<CR>",  { noremap = true, silent = true })
-- vim.api.nvim_set_keymap("i", user_opts.accept_word_keymap   ,"<Cmd>lua accept_one_suggestion_word()<CR>",  { noremap = true, silent = true })

