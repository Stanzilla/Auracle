local L = LibStub("AceLocale-3.0"):NewLocale("Auracle", "enUS", true, true)

L["ARENA"] = ARENA -- noun
L["AURAS"] = AURAS -- plural noun
L["BACKGROUND"] = EMBLEM_BACKGROUND -- noun
L["BATTLEGROUND"] = BATTLEGROUND -- noun
L["BORDER"] = EMBLEM_BORDER -- noun
L["COLOR"] = COLOR -- noun
L["DEFAULT"] = DEFAULT
L["DELETE"] = DELETE -- verb
L["DISPLAY"] = DISPLAY -- verb
L["FOCUS"] = FOCUS -- i.e. the "focus" unitid
L["FRIENDLY"] = FRIENDLY -- i.e. reacation type
L["HOSTILE"] = HOSTILE -- i.e. reacation type
L["ICON"] = EMBLEM_SYMBOL
L["NAME"] = NAME -- noun
L["NEUTRAL"] = FACTION_STANDING_LABEL4 -- i.e. reacation type
L["NONE"] = NONE -- adjective
L["PET"] = PET -- i.e. the "pet" unitid
L["PLAYER"] = PLAYER -- i.e. the "player" unitid
L["TARGET"] = TARGET -- i.e. the "target" unitid

-- Auracle.lua
L["LDB_MSG_DISABLED"] = "Disabled."
L["LDB_MSG_ENABLED"] = "Enabled."
L["LDB_STAT_ENABLED"] = "Auracle |cffffffff(|cff00ff00enabled|cffffffff)"
L["LDB_STAT_DISABLED"] = "Auracle |cffffffff(|cffff0000disabled|cffffffff)"
L["LDB_LEFTCLICK"] = "|cff7fffffLeft-click|cffffffff to toggle"
L["LDB_RIGHTCLICK"] = "|cff7fffffRight-click|cffffffff to open configuration"
L["HUMANOID"] = "Humanoid"
L["UNKNOWN_FORM"] = "(Unknown Stance/Form)"
L["ERR_REMOVE_LAST_WINDOW"] = "Can't remove the last window; disable the addon instead"
L["FMT_COPY_OF"] = "Copy of"
L["FMT_COPY_%d_OF"] = "Copy (%d) of"
L["CONFIGURE"] = "Configure" -- verb
L["DESC_CMD_CONFIGURE"] = "Open configuration panel"
L["ENABLE_ADDON"] = "Enable Auracle"
L["DISABLE_ADDON"] = "Disable Auracle"
L["GENERAL"] = "General" -- generic, basic, non-specific (not the military rank...)
L["ADDON_ENABLED"] = "Auracle Enabled"
L["WINDOWS_LOCKED"] = "Windows Locked"
L["DESC_OPT_WINDOWS_LOCKED"] = "When unlocked, windows may be moved by left-click-dragging"
L["WINDOW_STYLES"] = "Window Styles"
L["TRACKER_STYLES"] = "Tracker Styles"
L["WINDOWS"] = "Windows" -- plural noun (not the operating system...)
L["LIST_ADD_WINDOW"] = "|cff7fffff(Add Window...)"
L["ADD_WINDOW"] = "Add Window"
L["ABOUT"] = "About" -- as in "about the addon"
L["OPEN_CONFIGURATION"] = "Open Configuration"

-- WindowStyle.lua
L["STYLE"] = "Style" -- noun
L["COPY"] = "Copy" -- verb
L["ERR_RENAME_DEFAULT_STYLE"] = "You cannot rename the Default style"
L["ERR_NO_STYLE_NAME"] = "Every style needs a name"
L["ERR_DUP_STYLE_NAME"] = "Every style name must be unique"
L["WINDOW_OPACITY"] = "Window Opacity"
L["WINDOW_SCALE"] = "Window Scale"
L["SHOW"] = "Show" -- verb
L["TEXTURE"] = "Texture" -- noun
L["CORNER_SIZE"] = "Corner Size"
L["TILE_SIZE"] = "Tile Size"
L["DESC_OPT_TILE_SIZE"] = "0 to disable background tiling"
L["INSET_NOSCALE"] = "Don't scale inset"
L["DESC_OPT_INSET_NOSCALE"] = "Apply inset in pixels, by canceling out the effective scale"
L["INSET"] = "Inset" -- noun (gap between the inside edge of the border and the outside edge of the background image)
L["LAYOUT"] = "Layout" -- noun
L["LAYOUT_NOSCALE"] = "Don't scale padding and spacing"
L["DESC_OPT_LAYOUT_NOSCALE"] = "Apply padding and spacing in pixels, by canceling out the effective scale"
L["PADDING"] = "Padding" -- noun (gap between edge of background image and trackers)
L["DESC_OPT_WINDOW_PADDING"] = "The distance between trackers and the window border"
L["SPACING"] = "Spacing" -- noun (gap between each tracker)
L["DESC_OPT_WINDOW_SPACING"] = "The distance between each tracker"
L["TRACKER_SIZE"] = "Tracker Size"

-- TrackerStyle.lua
L["BORDER_NOSCALE"] = "Don't scale border"
L["DESC_OPT_BORDER_NOSCALE"] = "Apply border size in pixels, by canceling out the effective scale"
L["OPT_MISSING_SHOW"] = "Show when Missing"
L["OPT_MISSING_SIZE"] = "Size when Missing"
L["OPT_MISSING_COLOR"] = "Color when Missing"
L["OPT_OTHERS_SHOW"] = "Show when Other's"
L["OPT_OTHERS_SIZE"] = "Size when Other's"
L["OPT_OTHERS_COLOR"] = "Color when Other's"
L["OPT_MINE_SHOW"] = "Show when Mine"
L["OPT_MINE_SIZE"] = "Size when Mine"
L["OPT_MINE_COLOR"] = "Color when Mine"
L["ZOOM_ICON"] = "Zoom Icon"
L["OPT_MISSING_GRAY"] = "Gray when Missing"
L["OPT_MISSING_TINT"] = "Tint when Missing"
L["OPT_OTHERS_GRAY"] = "Gray when Other's"
L["OPT_OTHERS_TINT"] = "Tint when Other's"
L["OPT_MINE_GRAY"] = "Gray when Mine"
L["OPT_MINE_TINT"] = "Tint when Mine"
L["SPIRAL"] = "Spiral" -- noun (as in, "the cooldown spiral")
L["OPT_NOCC"] = "Block External Cooldown"
L["DESC_OPT_NOCC"] = "Prevent CooldownCount and OmniCC from adding timer text to the cooldown"
L["TEXT"] = "Text" -- noun
L["FONT"] = "Font" -- noun
L["OUTLINE"] = "Outline" -- noun
L["THIN"] = "Thin" -- adjective
L["THICK"] = "Thick" -- adjective
L["RELATIVE_SIZE"] = "Relative Size" -- i.e. a multiple of the tracker's size
L["DESC_OPT_RELATIVE_STATIC_SIZE"] = "Effective font size is (RelativeSize * TrackerSize) + StaticSize"
L["STATIC_SIZE"] = "Static Size" -- i.e. a base size, no matter the tracker's size
L["OPT_SMOOTH_COLORS"] = "Smooth-Fade Colors"
L["DESC_OPT_SMOOTH_COLORS"] = "When coloring based on time, fade smoothly between each marker"
--L["OPT_SMOOTH_RATE"] = "Smooth-Fade Rate"
--L["DESC_OPT_SMOOTH_RATE"] = "The interval at which the smooth-fade color will be updated; lower settings may impact performance"]
L["RELATIVE_COLORS"] = "Relative Colors" -- i.e. colors to use when coloring by some relative value (which will be 0-100%)
L["OPT_OTHERS_20%"] = "Other's 0-20%"
L["OPT_MINE_20%"] = "Mine 0-20%"
L["OPT_OTHERS_40%"] = "Other's 20-40%"
L["OPT_MINE_40%"] = "Mine 20-40%"
L["OPT_OTHERS_60%"] = "Other's 40-60%"
L["OPT_MINE_60%"] = "Mine 40-60%"
L["OPT_OTHERS_80%"] = "Other's 60-80%"
L["OPT_MINE_80%"] = "Mine 60-80%"
L["OPT_OTHERS_100%"] = "Other's 80-100%"
L["OPT_MINE_100%"] = "Mine 80-100%"
L["COLORS_BY_TIME"] = "Colors by Time" -- i.e. colors to use when coloring by time ranges
L["OPT_OTHERS_5S"] = "Other's 0-5s"
L["OPT_MINE_5S"] = "Mine 0-5s"
L["OPT_OTHERS_10S"] = "Other's 5-10s"
L["OPT_MINE_10S"] = "Mine 5-10s"
L["OPT_OTHERS_20S"] = "Other's 10-20s"
L["OPT_MINE_20S"] = "Mine 10-20s"
L["OPT_OTHERS_30S"] = "Other's 20-30s"
L["OPT_MINE_30S"] = "Mine 20-30s"
L["OPT_OTHERS_XS"] = "Other's 30s+"
L["OPT_MINE_XS"] = "Mine 30s+"

-- Window.lua
L["BUFFS_BY_TYPE"] = "Buffs by Type"
L["STATS"] = "Stats"
L["PRESET_BUFF_PCTSTATS"] = "+% Stats"
L["PRESET_BUFF_MISCSTATS"] = "+ Stats/Armor/Resists"
L["PRESET_BUFF_AGISTR"] = "+ Agility/Strength"
L["PRESET_BUFF_STA"] = "+ Stamina"
L["PRESET_BUFF_HEALTH"] = "+ Health"
L["PRESET_BUFF_INT"] = "+ Intellect"
L["PRESET_BUFF_SPI"] = "+ Spirit"
L["PRESET_BUFF_PCTDMG"] = "+% Damage"
L["PRESET_BUFF_BIGHASTE"] = "++ Haste"
L["PRESET_BUFF_HASTE"] = "+ Haste"
--L["PRESET_BUFF_REPLEN"] = "Replenishment"
L["PHYSICAL"] = "Physical"
L["PRESET_BUFF_PCTAP"] = "+% Attack Power"
L["PRESET_BUFF_AP"] = "+ Attack Power"
L["PRESET_BUFF_M_HASTE"] = "+ Melee Haste"
L["PRESET_BUFF_M_CRIT"] = "+ Melee Crit"
L["CASTER"] = "Caster"
L["PRESET_BUFF_PCTSP"] = "+ Spell Power"
L["PRESET_BUFF_S_HASTE"] = "+ Spell Haste"
L["PRESET_BUFF_S_CRIT"] = "+ Spell Crit"
L["PRESET_BUFF_BIGMANAREGEN"] = "++ Mana Regen"
L["PRESET_BUFF_MANAREGEN"] = "+ Mana Regen"
L["DEFENSE"] = "Defense"
L["PRESET_BUFF_BIGPCTDMGTAKEN"] = "--% Damage Taken"
L["PRESET_BUFF_PCTDMGTAKEN"] = "-% Damage Taken"
L["PRESET_BUFF_PCTARMOR"] = "+% Armor"
L["PRESET_BUFF_PCTHEALTAKEN"] = "+% Healing Taken"
L["TACTICAL"] = "Tactical"
L["IMMUNE"] = "Immune"
L["PHYSICAL_IMMUNE"] = "Physical Immune"
L["MAGICAL_IMMUNE"] = "Magical Immune"
L["SHIELDED"] = "Shielded"
L["FAST"] = "Fast"
L["DEBUFFS_BY_TYPE"] = "Debuffs by Type"
L["DPS"] = "DPS"
L["PRESET_DEBUFF_AP"] = "- Attack Power"
L["PRESET_DEBUFF_M_HASTE"] = "- Melee Haste"
L["PRESET_DEBUFF_MR_HIT"] = "- Melee/Ranged Hit"
L["PRESET_DEBUFF_R_HASTE"] = "- Ranged Haste"
L["PRESET_DEBUFF_S_HASTE"] = "- Spell Haste"
L["PHYSICAL_TANK"] = "Physical Tank"
L["PRESET_DEBUFF_BIGARMOR"] = "-- Armor"
L["PRESET_DEBUFF_ARMOR"] = "- Armor"
L["PRESET_DEBUFF_PCTPHYSDMGTAKEN"] = "+% Physical Damage Taken"
L["PRESET_DEBUFF_PCTBLEEDDMGTAKEN"] = "+% Bleed Damage Taken"
L["PRESET_DEBUFF_CRITTAKEN"] = "+ Crit Taken"
L["CASTER_TANK"] = "Caster Tank"
L["PRESET_DEBUFF_RESISTS"] = "- Resists"
L["PRESET_DEBUFF_PCTSPELLDMGTAKEN"] = "+% Spell Damage Taken"
L["PRESET_DEBUFF_PCTDISEASEDMGTAKEN"] = "+% Disease Damage Taken"
L["PRESET_DEBUFF_SPELLHITTAKEN"] = "+ Spell Hit Taken"
L["PRESET_DEBUFF_SPELLCRITTAKEN"] = "+ Spell Crit Taken"
L["PRESET_DEBUFF_PCTHEALTAKEN"] = "-% Healing Taken"
L["DISARM"] = "Disarm"
L["SILENCE"] = "Silence"
L["STUN"] = "Stun"
L["FEAR"] = "Fear"
L["INCAPACITATE"] = "Incapacitate"
L["DISORIENT"] = "Disorient"
L["ROOT"] = "Root"
L["SLOW"] = "Slow"
L["WINDOW"] = "Window" -- noun
L["LABEL"] = "Label" -- noun
L["REMOVE_WINDOW"] = "Remove Window"
L["WATCH_UNIT"] = "Watch Unit"
L["TARGETTARGET"] = "Target's Target" -- i.e. the "targettarget" unitid
L["PETTARGET"] = "Pet's Target" -- i.e. the "pettarget" unitid
L["FOCUSTARGET"] = "Focus' Target" -- i.e. the "focustarget" unitid
L["WINDOW_STYLE"] = "Window Style"
L["VISIBILITY"] = "Visibility" -- noun
L["OPT_SPEC_SHOW"] = "Show while using talent group:"
L["PRIMARY_TALENTS"] = "Primary Talents"
L["SECONDARY_TALENTS"] = "Secondary Talents"
L["OPT_INSTANCE_SHOW"] = "Show while in instance:"
L["NO_INSTANCE"] = "No Instance"
L["PARTY_INSTANCE"] = "Party Instance"
L["RAID_INSTANCE"] = "Raid Instance"
L["OPT_GROUP_SHOW"] = "Show while in group:"
L["NONE_SOLO"] = "None (Solo)" -- i.e. ungrouped
L["PARTY"] = "Party" -- noun (i.e. in a 5-person group)
L["RAID_GROUP"] = "Raid Group" -- noun (i.e. in a 40-person group)
L["OPT_COMBAT_SHOW"] = "Show while in combat:"
L["NOT_IN_COMBAT"] = "Not in Combat"
L["IN_COMBAT"] = "In Combat"
L["OPT_FORM_SHOW"] = "Show while in stance/form:"
L["OPT_UNITMISSING_SHOW"] = "Show when unit is missing"
L["OPT_UNITREACT_SHOW"] = "Show while unit's reaction is:"
L["OPT_UNITTYPE_SHOW"] = "Show while unit type is:"
L["BOSS"] = "Boss" -- i.e. npc unit type
L["RARE_ELITE_NPC"] = "Rare Elite NPC" -- i.e. npc unit type
L["ELITE_NPC"] = "Elite NPC" -- i.e. npc unit type
L["RARE_NPC"] = "Rare NPC" -- i.e. npc unit type
L["NPC"] = "NPC" -- i.e. npc unit type
L["GRAY_NPC"] = "Gray NPC" -- i.e. npc unit type
L["TRACKERS_LOCKED"] = "Trackers Locked"
L["DESC_OPT_TRACKERS_LOCKED"] = "When unlocked, trackers may be rearranged by left-click-dragging"
L["TRACKERS_PER_ROW"] = "Trackers per Row"
L["LIST_ADD_TRACKER"] = "|cff7fffff(Add Tracker...)"
L["ADD_BLANK_TRACKER"] = "Add Blank Tracker"
L["OPT_ASSUME_TALENTED"] = "Assume talented"
L["DESC_OPT_ASSUME_TALENTED"] = "When checked, preset trackers added below will include auras that only have the specified effect when talented."

-- Tracker.lua
L["NEW_TRACKER"] = "New Tracker"
L["_HOURS_ABBREV_"] = "h"
L["_MINUTES_ABBREV_"] = "m"
L["_SECONDS_ABBREV_"] = "s"
L["TRACKER"] = "Tracker" -- noun
L["REMOVE_TRACKER"] = "Remove Tracker"
L["MOVE_TRACKER_UP"] = "Move Up"
L["MOVE_TRACKER_DOWN"] = "Move Down"
L["AURA_TYPE"] = "Aura Type"
L["BUFFS"] = "Buffs" -- plural noun
L["DEBUFFS"] = "Debuffs" -- plural noun
L["TRACKER_STYLE"] = "Tracker Style"
L["DESC_OPT_AURAS"] = "One buff or debuff name or SpellID per line (if the line is numeric, it will be interpreted as a SpellID; if that ID is invalid, the line will be ignored)"
L["OPT_OTHERS_TRACK"] = "Track Other's"
L["OPT_MINE_TRACK"] = "Track Mine"
L["AUTOUPDATE"] = "Autoupdate" -- verb
L["DESC_OPT_AUTOUPDATE"] = "Update icon texture whenever a new aura activates the tracker"
L["STACKS"] = "Stacks" -- plural noun
L["TIME_LEFT"] = "Time Left"
L["DIRECTION"] = "Direction"
L["DRAIN_CLOCKWISE"] = "Drain Clockwise"
L["FILL_CLOCKWISE"] = "Fill Clockwise"
L["MAXIMUM_DURATION"] = "Maximum Duration"
L["AUTOUPDATE_MODE"] = "Autoupdate Mode"
L["UPDATE_ALWAYS"] = "Update Always"
L["UPDATE_UPWARDS"] = "Update Upwards"
L["STATIC"] = "Static" -- unchanging
L["VALUE"] = "Value"
L["MAXIMUM_STACKS"] = "Maximum Stacks"
L["COLOR_BY"] = "Color By"
L["ABSOLUTE_DURATION"] = "Absolute Duration" -- i.e. use the "colors by time"
L["RELATIVE_DURATION"] = "Relative Duration" -- i.e. use the "relative colors" for time / maxtime
L["RELATIVE_STACKS"] = "Relative Stacks" -- i.e. use the "relative colors" for stacks / maxstacks
L["TOOLTIP"] = "Tooltip" -- noun
L["OPT_MISSING_DISPLAY"] = "Display when Missing"
L["SUMMARY"] = "Summary" -- noun
L["NOTHING"] = "Nothing" -- noun
L["OPT_OTHERS_DISPLAY"] = "Display when Other's"
L["AURAS_TOOLTIP"] = "Aura's Tooltip"
L["OPT_MINE_DISPLAY"] = "Display when Mine"
L["WARN_TOOLTIP_BLOCKS_MOUSE"] = "Note that enabling any tooltip will cause the tracker to block mouse clicks even while locked.  If the tracker is near the middle of the screen, this can interfere with your camera and movement control."

