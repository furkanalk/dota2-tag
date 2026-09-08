-- luacheck: globals Convars

local CursedCommands = {}

local function ParsePlayerID(playerIDText)
  return tonumber(playerIDText)
end

function CursedCommands.Register(gameMode)
  local fearManager = gameMode.fearManager
  local stabilityManager = gameMode.cursedStabilityManager

  Convars:RegisterCommand(
    "tag_fear_dump",
    function(_, playerIDText)
      local currentTime = GameRules:GetGameTime()
      fearManager:Update(currentTime)

      local playerID = ParsePlayerID(playerIDText)

      if playerID == nil then
        playerID = fearManager:GetOwnerPlayerID()
      end

      if playerID == nil then
        print("FEAR DEBUG: no active IT")
        return
      end

      local current = fearManager:GetCurrent(playerID)
      local max = fearManager:GetMax(playerID)

      if current == nil then
        print("FEAR DEBUG: Player " .. playerID .. " | NOT_CURSED")
        return
      end

      print(string.format(
        "FEAR DEBUG: Player %d | %.1f/%d | CURSED",
        playerID,
        current,
        max
      ))
    end,
    "Dump current Cursed Fear state",
    0
  )

  Convars:RegisterCommand(
    "tag_test_fear_add",
    function(_, playerIDText, amountText)
      local playerID = ParsePlayerID(playerIDText)
      local amount = tonumber(amountText)

      if playerID == nil or amount == nil then
        print("USAGE: tag_test_fear_add <playerID> <amount>")
        return
      end

      local gained = fearManager:AddFear(
        playerID,
        amount,
        "DEBUG",
        GameRules:GetGameTime()
      )

      print(string.format(
        "DEBUG FEAR ADD: requested=%.1f | gained=%.1f",
        amount,
        gained
      ))
    end,
    "Add Fear for testing",
    0
  )

  Convars:RegisterCommand(
    "tag_test_fear_spend",
    function(_, playerIDText, amountText)
      local playerID = ParsePlayerID(playerIDText)
      local amount = tonumber(amountText)

      if playerID == nil or amount == nil then
        print("USAGE: tag_test_fear_spend <playerID> <amount>")
        return
      end

      local success = fearManager:SpendFear(
        playerID,
        amount,
        "DEBUG",
        GameRules:GetGameTime()
      )

      print("DEBUG FEAR SPEND: " .. tostring(success))
    end,
    "Spend Fear for testing",
    0
  )

  Convars:RegisterCommand(
    "tag_cursed_stability_dump",
    function(_, playerIDText)
      local currentTime = GameRules:GetGameTime()
      stabilityManager:Update(currentTime)

      local playerID = ParsePlayerID(playerIDText)

      if playerID == nil then
        playerID = stabilityManager:GetOwnerPlayerID()
      end

      if playerID == nil then
        print("CURSED STABILITY DEBUG: no active IT")
        return
      end

      local current = stabilityManager:GetCurrent(playerID)
      local max = stabilityManager:GetMax(playerID)
      local phase = stabilityManager:GetPhase(playerID)

      if current == nil then
        print(
          "CURSED STABILITY DEBUG: Player "
          .. playerID
          .. " | NOT_CURSED"
        )
        return
      end

      local fractured = stabilityManager:IsFractured(playerID)

      print(string.format(
        "CURSED STABILITY DEBUG: Player %d | %d/%d | %s%s",
        playerID,
        current,
        max,
        phase,
        fractured and " | FRACTURED" or ""
      ))
    end,
    "Dump current Cursed Stability state",
    0
  )

  Convars:RegisterCommand(
    "tag_test_cursed_stability_damage",
    function(_, playerIDText, amountText)
      local playerID = ParsePlayerID(playerIDText)
      local amount = tonumber(amountText)

      if playerID == nil or amount == nil then
        print(
          "USAGE: tag_test_cursed_stability_damage <playerID> <amount>"
        )
        return
      end

      local applied, result = stabilityManager:ApplyImpact(
        -1,
        playerID,
        amount,
        GameRules:GetGameTime()
      )

      print(
        "DEBUG CURSED STABILITY DAMAGE: "
        .. tostring(applied)
        .. " | "
        .. tostring(result)
      )
    end,
    "Damage Cursed Stability for testing",
    0
  )

  Convars:RegisterCommand(
    "tag_test_cursed_stability_heal",
    function(_, playerIDText, amountText)
      local playerID = ParsePlayerID(playerIDText)
      local amount = tonumber(amountText)

      if playerID == nil or amount == nil then
        print(
          "USAGE: tag_test_cursed_stability_heal <playerID> <amount>"
        )
        return
      end

      local healed = stabilityManager:Heal(
        playerID,
        amount,
        "DEBUG",
        GameRules:GetGameTime()
      )

      print("DEBUG CURSED STABILITY HEAL: +" .. tostring(healed))
    end,
    "Heal Cursed Stability for testing",
    0
  )
end

return CursedCommands
