-- luacheck: globals Convars

local ResourceCommands = {}

local function ParsePlayerID(playerIDText)
  return tonumber(playerIDText)
end

function ResourceCommands.Register(gameMode)
  local resourceManager = gameMode.resourceManager

  Convars:RegisterCommand(
    "tag_resource_dump",
    function(_, playerIDText)
      local playerID = ParsePlayerID(playerIDText)

      if playerID == nil then
        print("USAGE: tag_resource_dump <playerID>")
        return
      end

      local resourceType =
          resourceManager:GetType(playerID)

      local current =
          resourceManager:GetCurrent(playerID)

      local max =
          resourceManager:GetMax(playerID)

      if resourceType == nil then
        print(
          "RESOURCE DEBUG: Player "
          .. playerID
          .. " | NONE"
        )
        return
      end

      local extra = ""

      if resourceType == "MOMENTUM" then
        local recovery =
            resourceManager:GetMomentumCooldownRecovery(
              playerID
            )

        extra = string.format(
          " | CDR %.1f%%",
          recovery * 100
        )
      end

      print(string.format(
        "RESOURCE DEBUG: Player %d | %s | %.1f/%d%s",
        playerID,
        resourceType,
        current,
        max,
        extra
      ))
    end,
    "Dump Runner resource state",
    0
  )

  Convars:RegisterCommand(
    "tag_test_energy_spend",
    function(_, playerIDText, amountText)
      local playerID = ParsePlayerID(playerIDText)
      local amount = tonumber(amountText)

      if playerID == nil or amount == nil then
        print(
          "USAGE: tag_test_energy_spend <playerID> <amount>"
        )
        return
      end

      local success =
          resourceManager:SpendEnergy(
            playerID,
            amount,
            "DEBUG"
          )

      print(
        "DEBUG ENERGY SPEND: "
        .. tostring(success)
      )
    end,
    "Spend Energy for testing",
    0
  )

  Convars:RegisterCommand(
    "tag_test_momentum_add",
    function(_, playerIDText, amountText)
      local playerID = ParsePlayerID(playerIDText)
      local amount = tonumber(amountText)

      if playerID == nil or amount == nil then
        print(
          "USAGE: tag_test_momentum_add <playerID> <amount>"
        )
        return
      end

      resourceManager:AddMomentum(
        playerID,
        amount,
        "DEBUG",
        GameRules:GetGameTime()
      )
    end,
    "Add Momentum for testing",
    0
  )
end

return ResourceCommands
