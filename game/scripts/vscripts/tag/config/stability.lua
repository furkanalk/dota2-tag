return {
  DEFAULT_MAX = 6,
  DEFAULT_REGEN_PROFILE = "NORMAL",

  HERO_MAX = {
    npc_dota_hero_puck = 4,
    npc_dota_hero_hoodwink = 5,
    npc_dota_hero_earth_spirit = 8,
    npc_dota_hero_morphling = 7,
    npc_dota_hero_phantom_assassin = 5,
    npc_dota_hero_mirana = 6,
    npc_dota_hero_slark = 6,
    npc_dota_hero_dark_seer = 7,
    npc_dota_hero_weaver = 5,
    npc_dota_hero_rubick = 6,
    npc_dota_hero_marci = 7,
    npc_dota_hero_faceless_void = 5,
    npc_dota_hero_void_spirit = 6,
    npc_dota_hero_enchantress = 6,
    npc_dota_hero_windrunner = 5,
    npc_dota_hero_bounty_hunter = 5
  },

  HERO_REGEN_PROFILE = {
    npc_dota_hero_puck = "SLOW",
    npc_dota_hero_hoodwink = "NORMAL",
    npc_dota_hero_earth_spirit = "NORMAL",
    npc_dota_hero_morphling = "FAST",
    npc_dota_hero_phantom_assassin = "SLOW",
    npc_dota_hero_mirana = "NORMAL",
    npc_dota_hero_slark = "NORMAL",
    npc_dota_hero_dark_seer = "NORMAL",
    npc_dota_hero_weaver = "SLOW",
    npc_dota_hero_rubick = "NORMAL",
    npc_dota_hero_marci = "NORMAL",
    npc_dota_hero_faceless_void = "SLOW",
    npc_dota_hero_void_spirit = "NORMAL",
    npc_dota_hero_enchantress = "NORMAL",
    npc_dota_hero_windrunner = "SLOW",
    npc_dota_hero_bounty_hunter = "SLOW"
  },

  REGEN_DELAY = 5.0,

  REGEN_PROFILES = {
    FAST = {
      BASE = 0.65,
      RAMP = 1.10
    },
    NORMAL = {
      BASE = 0.80,
      RAMP = 1.35
    },
    SLOW = {
      BASE = 0.95,
      RAMP = 1.60
    }
  },

  UNSTABLE_DURATION = 7.0,
  UNSTABLE_IMPAIRMENT_DURATION = 5.0,
  UNSTABLE_ENTRY_SLOW = 30,
  UNSTABLE_ENTRY_TURN_SLOW = 50
}
