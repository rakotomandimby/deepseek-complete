-- Initialize a module
local M = {}

-- Function to log a message into /tmp/rktmb-deepseek-complete.log
function M.log(message)
    local log_file = io.open("/tmp/rktmb-deepseek-complete.log", "a")
    log_file:write(message .. "\n")
    log_file:close()
end

-- Function to generate a random sentence
function M.generate_sentence()
  M.log("Entered generate_sentence()")
  local sentences = {
    "The quick brown \nfox jumps over the lazy dog.",
    "The five boxing \nwizards jump quickly.",
    "Pack my box with \nfive dozen liquor jugs.",
    "How vexingly quick \ndaft zebras jump.",
    "Pack my box with five \ndozen liquor jugs.",
    "How vexingly quick \ndaft zebras jump.",
    "What do you get if \nyou multiply six by nine.",
    "If six is nine, \nwhat do you get?",
    "If six is nine, \nwhat do you get?",
    "I'm not a number, \nI'm a free man.",
    "I'm not a number, \nI'm a free man.",
    "Hey, I'm a free man. \nWhat do you get if you multiply six by nine?",
    "Hey, I'm a free man. \nWhat do you get if you multiply six by nine?",
  }
  return sentences[math.random(#sentences)]
end


return M
