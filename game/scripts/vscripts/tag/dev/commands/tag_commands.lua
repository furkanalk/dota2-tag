-- luacheck: globals Convars

local TagCommands = {}

function TagCommands.Register(gameMode)
  local tagManager = gameMode.tagManager

  Convars:RegisterCommand(
    "tag_test_set_it",
    function(_, playerIDText)
      local playerID = tonumber(playerIDText)

      if playerID == nil then
        print(
          "USAGE: tag_test_set_it <playerID>"
        )
        return
      end

      tagManager:SetIt(playerID)

      print(
        "DEBUG IT SET: Player "
        .. playerID
      )
    end,
    "Change IT for resource lifecycle testing",
    0
  )
end

return TagCommands
