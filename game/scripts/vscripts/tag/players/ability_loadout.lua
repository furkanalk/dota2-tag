local Config = require("tag/config/config")

local AbilityLoadout = class({})

local function MovePassToR(
    hero,
    passAbility
)
  local rAbility =
      hero:GetAbilityByIndex(
        Config.PASS_ABILITY_SLOT
      )

  if not rAbility
      or rAbility:IsNull()
      or rAbility == passAbility
  then
    return
  end

  local rAbilityName =
      rAbility:GetAbilityName()

  print(
    "R SLOT: "
    .. rAbilityName
    .. " -> "
    .. Config.PASS_ABILITY_NAME
  )

  hero:SwapAbilities(
    rAbilityName,
    Config.PASS_ABILITY_NAME,
    false,
    true
  )
end

function AbilityLoadout:Init(playerRegistry)
  self.players = playerRegistry
end

function AbilityLoadout:Install(playerID)
  local hero = self.players:GetHero(playerID)

  if not hero or hero:IsNull() then
    return
  end

  local ability =
      hero:FindAbilityByName(
        Config.PASS_ABILITY_NAME
      )

  if ability == nil then
    ability =
        hero:AddAbility(
          Config.PASS_ABILITY_NAME
        )
  end

  if ability == nil then
    return
  end

  ability:SetLevel(1)

  MovePassToR(hero, ability)

  ability:SetActivated(false)
end

function AbilityLoadout:SetPassEnabled(
    playerID,
    enabled
)
  local hero = self.players:GetHero(playerID)

  if not hero or hero:IsNull() then
    return
  end

  local ability =
      hero:FindAbilityByName(
        Config.PASS_ABILITY_NAME
      )

  if ability == nil then
    return
  end

  ability:SetActivated(enabled)
end

return AbilityLoadout
