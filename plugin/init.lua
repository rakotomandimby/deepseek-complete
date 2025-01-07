local rktmb_deepseek_complete = require("rktmb-deepseek-complete")
local curl = require('plenary.curl')

_G.ns_id = vim.api.nvim_create_namespace('rktmb-deepseek-complete')

_G.current_extmark_id = nil
_G.current_suggestion = nil

-- Default keymappings
local default_opts = {
  deepseek_api_key = os.getenv("DEEPSEEK_API_KEY"),
  suggest_lines_keymap = "<M-ESC>",
  accept_all_keymap = "<M-PageDown>",
  accept_line_keymap = "<M-Down>",
}

-- Read user configuration
local user_opts = vim.tbl_deep_extend("force", default_opts, vim.g.rktmb_deepseek_complete_opts or {})
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
    rktmb_deepseek_complete.text_before_cursor,
    rktmb_deepseek_complete.text_after_cursor
  )
}

local function process_deepseek_response(response)
  local response_body = vim.fn.json_decode(response.body)
  if response_body.choices and #response_body.choices > 0 then
    local choice = response_body.choices[1]
    local suggestion = choice.message.content
    rktmb_deepseek_complete.log("\n\nSuggestion from DeepSeek API:")
    rktmb_deepseek_complete.log(suggestion)
  end
end

_G.suggest = function()
  -- Asynchronously make the POST request
  curl.post('https://api.deepseek.com/chat/completions', {
    body = vim.fn.json_encode(deepseek_request_body),
    headers = {
      ["Content-Type"] = "application/json",
      ["Accept"] = "application/json",
      ["Authorization"] = "Bearer " .. user_opts.deepseek_api_key
    },
    callback = function(response)
      process_deepseek_response(response)
    end
  })
end


vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*",
  callback = function()
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
  end
})


vim.api.nvim_set_keymap("i", user_opts.suggest_lines_keymap, "<Cmd>lua suggest()<CR>",                     { noremap = true, silent = true })
-- vim.api.nvim_set_keymap("i", user_opts.accept_all_keymap,    "<Cmd>lua accept_the_whole_suggestion()<CR>", { noremap = true, silent = true })
-- vim.api.nvim_set_keymap("i", user_opts.accept_line_keymap,   "<Cmd>lua accept_one_suggestion_line()<CR>",  { noremap = true, silent = true })
-- vim.api.nvim_set_keymap("i", user_opts.accept_word_keymap   ,"<Cmd>lua accept_one_suggestion_word()<CR>",  { noremap = true, silent = true })
