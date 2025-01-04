-- Initialize a module
local M = {}

-- Function to generate a random sentence
function M.generate_sentence()
  local sentences = {
    "The quick brown fox jumps over the lazy dog.",
    "The five boxing wizards jump quickly.",
    "Pack my box with five dozen liquor jugs.",
    "How vexingly quick daft zebras jump.",
    "Pack my box with five dozen liquor jugs.",
    "How vexingly quick daft zebras jump.",
    "What do you get if you multiply six by nine.",
    "If six is nine, what do you get?",
    "If six is nine, what do you get?",
    "I'm not a number, I'm a free man.",
    "I'm not a number, I'm a free man.",
    "Hey, I'm a free man. What do you get if you multiply six by nine?",
    "Hey, I'm a free man. What do you get if you multiply six by nine?",
  }
  return sentences[math.random(#sentences)]
end


return M
