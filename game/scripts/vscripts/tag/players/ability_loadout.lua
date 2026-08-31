local Config = require("tag/config/config")

local AbilityLoadout = class({})


local function MoveAbilityToSlot(
    hero,
    ability,
    slot
)
  local slotAbility =
      hero:GetAbilityByIndex(
        slot
      )

  if not slotAbility
      or slotAbility:IsNull()
      or slotAbility == ability
  then
    return
  end

  local slotAbilityName =
      slotAbility:GetAbilityName()

  local abilityName =
      ability:GetAbilityName()

  print(
    "ABILITY SLOT "
    .. slot
    .. ": "
    .. slotAbilityName
    .. " -> "
    .. abilityName
  )

  hero:SwapAbilities(
    slotAbilityName,
    abilityName,
    false,
    true
  )
end


local function InstallAbility(
    hero,
    abilityName,
    abilitySlot
)
  local ability =
      hero:FindAbilityByName(
        abilityName
      )

  if ability == nil then
    ability =
        hero:AddAbility(
          abilityName
        )
  end

  if ability == nil then
    return
  end

  ability:SetLevel(1)

  MoveAbilityToSlot(
    hero,
    ability,
    abilitySlot
  )

  ability:SetActivated(false)
end


function AbilityLoadout:Init(playerRegistry)
  self.players = playerRegistry
end

function AbilityLoadout:Install(playerID)
  local hero =
      self.players:GetHero(
        playerID
      )

  if not hero
      or hero:IsNull()
  then
    return
  end

  InstallAbility(
    hero,
    Config.LEAP.ABILITY_NAME,
    Config.LEAP.ABILITY_SLOT
  )

  InstallAbility(
    hero,
    Config.PASS.ABILITY_NAME,
    Config.PASS.ABILITY_SLOT
  )
end

function AbilityLoadout:SetCursedEnabled(
    playerID,
    enabled
)
  local hero =
      self.players:GetHero(
        playerID
      )

  if not hero
      or hero:IsNull()
  then
    return
  end

  local leap =
      hero:FindAbilityByName(
        Config.LEAP.ABILITY_NAME
      )

  if leap ~= nil then
    leap:SetActivated(
      enabled
    )
  end

  local pass =
      hero:FindAbilityByName(
        Config.PASS.ABILITY_NAME
      )

  if pass ~= nil then
    pass:SetActivated(
      enabled
    )
  end
end

return AbilityLoadout
