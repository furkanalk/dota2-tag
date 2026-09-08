-- luacheck: globals CustomNetTables

local Config = require("tag/config/config")

local CursedKitManager = class({})

-- Universal Cursed abilities temporarily replace the host hero slots.
-- Keep this list ordered by the HUD slot each ability owns.
local CURSED_ABILITIES = {
  {
    name = "tag_cursed_dread_presence",
    index = 0,
    fearCostKey = "DREAD_PRESENCE"
  },
  {
    name = "tag_cursed_curse_wave",
    index = 1,
    fearCostKey = "CURSE_WAVE"
  }
}

local CURSED_ABILITY_SET = {}

for _, definition in ipairs(CURSED_ABILITIES) do
  CURSED_ABILITY_SET[definition.name] = true
end

local function IsValidHero(hero)
  return hero
      and not hero:IsNull()
      and hero:IsRealHero()
end

local function FindSnapshotAtIndex(
    snapshot,
    index
)
  if snapshot == nil then
    return nil
  end

  for _, saved in ipairs(snapshot) do
    if saved.index == index then
      return saved
    end
  end

  return nil
end

function CursedKitManager:Init(
    tagManager,
    fearManager,
    cursedStabilityManager
)
  self.tagManager = tagManager
  self.fearManager = fearManager
  self.cursedStabilityManager = cursedStabilityManager

  self.ownerPlayerID = nil
  self.ownerHero = nil
  self.runnerAbilitySnapshot = nil

  -- Cache the last replicated affordability state so the 20 Hz game think
  -- does not spam CustomNetTables while nothing relevant has changed.
  self.lastFearUiPlayerID = nil
  self.lastQFearLocked = nil
  self.lastWFearLocked = nil
end

-- Snapshot the Runner kit before possession so Curse removal can restore
-- the exact slot, visibility, and activation state that existed before.
function CursedKitManager.CaptureRunnerAbilities(hero)
  local snapshot = {}

  for index = 0, hero:GetAbilityCount() - 1 do
    local ability = hero:GetAbilityByIndex(index)

    if ability
        and not ability:IsNull()
        and not CURSED_ABILITY_SET[ability:GetAbilityName()]
    then
      table.insert(snapshot, {
        name = ability:GetAbilityName(),
        index = index,
        hidden = ability:IsHidden(),
        activated = ability:IsActivated()
      })
    end
  end

  return snapshot
end

-- Runner abilities stay on the hero internally but are unavailable while Cursed.
function CursedKitManager.HideRunnerAbilities(
    hero,
    snapshot
)
  for _, saved in ipairs(snapshot or {}) do
    local ability =
        hero:FindAbilityByName(saved.name)

    if ability ~= nil then
      ability:SetHidden(true)
      ability:SetActivated(false)
    end
  end
end

-- Swap each universal Cursed ability into the native hero slot so Dota keeps
-- the expected Q/W/E hotkey ownership instead of merely changing HUD order.
function CursedKitManager.AddCursedAbilities(
    hero,
    snapshot
)
  for _, definition in ipairs(CURSED_ABILITIES) do
    local ability =
        hero:FindAbilityByName(definition.name)

    if ability == nil then
      ability = hero:AddAbility(definition.name)
    end

    if ability ~= nil then
      ability:SetLevel(1)
      ability:SetHidden(false)
      ability:SetActivated(true)

      local slotOwner =
          FindSnapshotAtIndex(
            snapshot,
            definition.index
          )

      if slotOwner ~= nil then
        local original =
            hero:FindAbilityByName(
              slotOwner.name
            )

        if original ~= nil then
          hero:SwapAbilities(
            slotOwner.name,
            definition.name,
            false,
            true
          )
        end
      else
        ability:SetAbilityIndex(
          definition.index
        )
      end
    end
  end
end

-- Reverse the slot swaps before removing the temporary Cursed abilities.
function CursedKitManager.RestoreCursedSlots(
    hero,
    snapshot
)
  for index = #CURSED_ABILITIES, 1, -1 do
    local definition =
        CURSED_ABILITIES[index]

    local cursed =
        hero:FindAbilityByName(
          definition.name
        )

    local slotOwner =
        FindSnapshotAtIndex(
          snapshot,
          definition.index
        )

    if cursed ~= nil and slotOwner ~= nil then
      local original =
          hero:FindAbilityByName(
            slotOwner.name
          )

      if original ~= nil then
        hero:SwapAbilities(
          slotOwner.name,
          definition.name,
          slotOwner.activated,
          false
        )
      end
    end
  end
end

function CursedKitManager.RemoveCursedAbilities(hero)
  hero:RemoveModifierByName(
    "modifier_tag_dread_presence"
  )

  hero:RemoveModifierByName(
    "modifier_tag_cursed_kit"
  )

  for _, definition in ipairs(CURSED_ABILITIES) do
    if hero:FindAbilityByName(definition.name) ~= nil then
      hero:RemoveAbility(definition.name)
    end
  end
end

function CursedKitManager:RestoreRunnerAbilities(hero)
  if self.runnerAbilitySnapshot == nil then
    return
  end

  table.sort(
    self.runnerAbilitySnapshot,
    function(left, right)
      return left.index < right.index
    end
  )

  for _, saved in ipairs(self.runnerAbilitySnapshot) do
    local ability =
        hero:FindAbilityByName(saved.name)

    if ability ~= nil then
      ability:SetAbilityIndex(saved.index)
      ability:SetHidden(saved.hidden)
      ability:SetActivated(saved.activated)
    end
  end
end

-- Possession entry point: preserve Runner state, suppress the Runner kit,
-- then install the universal Cursed kit on the current host.
function CursedKitManager:Activate(
    playerID,
    hero
)
  if not IsValidHero(hero) then
    return false
  end

  self.ownerPlayerID = playerID
  self.ownerHero = hero

  self.runnerAbilitySnapshot =
      CursedKitManager.CaptureRunnerAbilities(
        hero
      )

  hero:AddNewModifier(
    hero,
    nil,
    "modifier_tag_cursed_kit",
    {}
  )

  CursedKitManager.AddCursedAbilities(
    hero,
    self.runnerAbilitySnapshot
  )

  CursedKitManager.HideRunnerAbilities(
    hero,
    self.runnerAbilitySnapshot
  )

  print(
    "CURSED KIT APPLIED: Player "
    .. playerID
    .. " | Dread Presence / Curse Wave"
  )

  return true
end

-- Possession exit point: remove Curse-only state and restore the Runner kit.
function CursedKitManager:Deactivate()
  local hero = self.ownerHero
  local playerID = self.ownerPlayerID

  -- Clear the old host's replicated Curse HUD state before ownership moves.
  self:ClearFearAvailability(playerID)

  if IsValidHero(hero) then
    CursedKitManager.RestoreCursedSlots(
      hero,
      self.runnerAbilitySnapshot
    )

    CursedKitManager.RemoveCursedAbilities(
      hero
    )

    self:RestoreRunnerAbilities(hero)
  end

  if playerID ~= nil then
    print(
      "CURSED KIT REMOVED: Player "
      .. playerID
    )
  end

  self.ownerPlayerID = nil
  self.ownerHero = nil
  self.runnerAbilitySnapshot = nil
end

-- Replicate Fear affordability as its own UI reason. Cooldown and Stagger
-- are separate states; Panorama can therefore keep an unaffordable ability
-- grey even while Dota's native cooldown rendering is active.
function CursedKitManager:PublishFearAvailability(
    playerID,
    currentFear
)
  local qFearLocked =
      currentFear
      < Config.CURSED.FEAR.COST.DREAD_PRESENCE

  local wFearLocked =
      currentFear
      < Config.CURSED.FEAR.COST.CURSE_WAVE

  if self.lastFearUiPlayerID == playerID
      and self.lastQFearLocked == qFearLocked
      and self.lastWFearLocked == wFearLocked
  then
    return
  end

  CustomNetTables:SetTableValue(
    "tag_cursed_ui",
    tostring(playerID),
    {
      is_cursed = 1,
      q_fear_locked = qFearLocked and 1 or 0,
      w_fear_locked = wFearLocked and 1 or 0
    }
  )

  self.lastFearUiPlayerID = playerID
  self.lastQFearLocked = qFearLocked
  self.lastWFearLocked = wFearLocked
end

function CursedKitManager:ClearFearAvailability(playerID)
  if playerID == nil then
    return
  end

  CustomNetTables:SetTableValue(
    "tag_cursed_ui",
    tostring(playerID),
    {
      is_cursed = 0,
      q_fear_locked = 0,
      w_fear_locked = 0
    }
  )

  self.lastFearUiPlayerID = nil
  self.lastQFearLocked = nil
  self.lastWFearLocked = nil
end

-- Keep HUD/input availability synchronized with the possession's Fear pool.
-- SetActivated(false) prevents Q/W from entering cast/targeting mode at all;
-- server-side cast filters remain as a safety net for stale or scripted orders.
function CursedKitManager:UpdateAvailability()
  local hero = self.ownerHero
  local playerID = self.ownerPlayerID

  if not IsValidHero(hero)
      or playerID == nil
  then
    return
  end

  local currentFear =
      self.fearManager:GetCurrent(playerID)
      or 0

  self:PublishFearAvailability(
    playerID,
    currentFear
  )

  local staggered =
      self.cursedStabilityManager:IsStaggered(
        playerID
      )

  for _, definition in ipairs(CURSED_ABILITIES) do
    local ability =
        hero:FindAbilityByName(
          definition.name
        )

    if ability ~= nil then
      -- Fear never deactivates the ability at engine level; doing so causes
      -- Dota to emit the generic "Ability inactive" error instead of our
      -- authored "Not enough Fear" validation message.
      local available = not staggered

      if ability:IsActivated() ~= available then
        ability:SetActivated(available)
      end
    end
  end
end

-- Follow TagManager ownership changes; no work is done while the same hero
-- remains the active Curse host.
function CursedKitManager:Update()
  local playerID =
      self.tagManager:GetItPlayerID()

  local hero = nil

  if playerID ~= nil then
    hero = self.tagManager:GetHero(playerID)
  end

  if playerID == self.ownerPlayerID
      and hero == self.ownerHero
  then
    return
  end

  if self.ownerPlayerID ~= nil then
    self:Deactivate()
  end

  if playerID ~= nil and IsValidHero(hero) then
    self:Activate(playerID, hero)
  end
end

return CursedKitManager
