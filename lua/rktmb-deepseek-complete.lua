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

function M.generate_sentence()
  M.log("Entered generate_sentence()")
  local sentences = {
    "The quick brown \nfox jumps over the lazy \ndog in the park.\nIt enjoys the sunny day.",
    "The five boxing \nwizards jump quickly,\nwhile the lazy dog\nsleeps under the tree.",
    "Pack my box with \nfive dozen liquor jugs.\nThe jugs are heavy,\nbut the party will be fun.",
    "How vexingly quick \ndaft zebras jump.\nThey leap over the fence,\nchasing after the butterflies.",
    "In a world of chaos,\nwhere dreams collide,\nwe find solace in the\nwhispers of the night.",
    "The stars twinkle brightly,\nilluminating the dark sky.\nEach one tells a story,\nwaiting to be discovered.",
    "What do you get if \nyou multiply six by nine?\nA riddle wrapped in mystery,\nwaiting for an answer.",
    "If six is nine, \nwhat do you get?\nA paradox of numbers,\nwhere logic takes a break.",
    "I'm not a number, \nI'm a free man.\nI wander through life,\nseeking adventures untold.",
    "Hey, I'm a free man. \nWhat do you get if you multiply six by nine?\nA question that lingers,\nlike a shadow in the dark.",
  }
  return sentences[math.random(#sentences)]
end

return M
