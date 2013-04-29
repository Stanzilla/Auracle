local LibOOP
--[===[@alpha@
LibOOP = LibStub("LibOOP-1.0-alpha", true)
--@end-alpha@]===]
LibOOP = LibOOP or LibStub("LibOOP-1.0") or error("Auracle: Required library LibOOP not found")
local Window = LibOOP:Class()

local LIB_AceLocale = LibStub("AceLocale-3.0") or error("Auracle: Required library AceLocale-3.0 not found")
local L = LIB_AceLocale:GetLocale("Auracle")


--[[ DECLARATIONS ]]--

-- classes

local Tracker,      DB_DEFAULT_TRACKER,      DB_VALID_TRACKER

-- constants

local UNLOCKED_BACKDROP = { bgFile="Interface\\Buttons\\WHITE8X8", tile=false, insets={left=0,right=0,top=0,bottom=0} }

local DB_DEFAULT_WINDOW = {
	label = false,
	style = L.DEFAULT,
	unit = "target", -- player|target|targettarget|pet|pettarget|focus|focustarget
	visibility = {
		plrSpec = {
			[1] = true,
			[2] = true
		},
		plrInstance = {
			none = true,
			pvp = true, -- bg
			arena = true,
			party = true, -- 5-man instance
			raid = true -- raid instance
		},
		plrGroup = {
			solo = true,
			party = true,
			raid = true
		},
		plrCombat = {
			[false] = true,
			[true] = true
		},
		plrForm = {
			[L.HUMANOID] = false -- backwards logic, so new forms default to visible
		},
		tgtMissing = true,
		tgtReact = {
			hostile = true,
			neutral = true,
			friendly = true
		},
		tgtType = {
			pc = true,
			worldboss = true,
			rareelite = true,
			elite = true,
			rare = true,
			normal = true,
			trivial = true
		}
	},
	layout = {
		wrap = 8
	},
	pos = {
		x = UIParent:GetWidth() / 2,
		y = UIParent:GetHeight() / -2,
	},
	trackers = {}
} -- {DB_DEFAULT_WINDOW}

local DB_VALID_WINDOW = {
	label = function(v) return (type(v) == "string" or v == false) end,
	style = "string",
	unit = "string",
	visibility = {
		plrSpec = {
			[1] = "boolean",
			[2] = "boolean"
		},
		plrInstance = {
			none = "boolean",
			pvp = "boolean",
			arena = "boolean",
			party = "boolean",
			raid = "boolean"
		},
		plrGroup = {
			solo = "boolean",
			party = "boolean",
			raid = "boolean"
		},
		plrCombat = {
			[false] = "boolean",
			[true] = "boolean"
		},
		plrForm = function(v)
			if (type(v) ~= "table") then
				return false
			end
			for form,vis in pairs(v) do
				if (type(form) ~= "string" or type(vis) ~= "boolean") then
					return false
				end
			end
			return true
		end,
		tgtMissing = "boolean",
		tgtReact = {
			hostile = "boolean",
			neutral = "boolean",
			friendly = "boolean"
		},
		tgtType = {
			pc = "boolean",
			worldboss = "boolean",
			rareelite = "boolean",
			elite = "boolean",
			rare = "boolean",
			normal = "boolean",
			trivial = "boolean",
		}
	},
	layout = {
		wrap = "number"
	},
	pos = {
		x = "number",
		y = "number"
	},
	trackers = function(v)
		if (type(v) ~= "table") then
			return false
		end
		for _,tdb in ipairs(v) do
			Auracle:ValidateSavedVars(tdb, DB_DEFAULT_TRACKER, DB_VALID_TRACKER)
		end
		return true
	end
} -- {DB_VALID_WINDOW}

local TRACKER_PRESET = {
	{
		[0] = L.BUFFS_BY_TYPE,
		{
			[0] = L.STATS,
			{
				[0] = L.PRESET_BUFF_PCTSTATS,
				{
					115921, -- Legacy of the Emperor (Monk)
					20217, -- Blessing of Kings (Paladin)
					90363, -- Embrace of the Shale Spider (Hunter: Shale Spider)
					1126, -- Mark of the Wild (Druid)
				}
			},
			{
				[0] = L.PRESET_BUFF_STA,
				{
					109773, -- Dark Intent (Warlock)
					469, -- Commanding Shout (Warrior)
					21562, -- Power Word: Fortitude (Prist)
					90364, -- Qiraji Fortitude (Hunter: Silithid)
				}
			},
		},
		{
		 	[0] = L.GENERAL,
			{
				[0] = L.PRESET_BUFF_CRIT,
				{
					24604, -- Furious Howl (Hunter: Wolf)
					116781, -- Legacy of the White Tiger (Monk)
					90309, -- Terrifying Roar (Hunter Pet)
					17007, -- Leader of the Pack (Guardian/Feral Druid)
					126373, -- Fearless Roar
					97229, -- Bellowing Roar
					126309, -- Still Water (Hunter: Water Strider)
					1459, -- Arcane Brilliance (Mage)
					61316, -- Dalaran Brilliance (Mage)
				}
			},
			{
				[0] = L.PRESET_BUFF_BIGHASTE,
				{
					90355, -- Ancient Hysteria (Hunter: Corehound)
					2825, -- Bloodlust (Shaman)
					32182, -- Heroism (Shaman)
					80353, -- Time Warp (Mage)
				}
			},
			{
				[0] = L.PRESET_BUFF_MASTERY,
				{
					19740, -- Blessing of Might (Paladin)
					116956, -- Grace of Air (Shaman)
					93435, -- Roar of Courage (Hunter Pet)
					128997, -- Spirit Beast Blessing (Hunter: Spirit Beast)
				}
			},
		},
		{
		 	[0] = L.PHYSICAL,
			{
				[0] = L.PRESET_BUFF_PCTAP,
				{
					57330, -- Horn of Winter (Death Knight)
					19506, -- Trueshot Aura (Hunter)
					6673, -- Battle Shout (Warrior)
				}
			},
			{
				[0] = L.PRESET_BUFF_P_HASTE,
				{
					55610, -- Unholy Aura (Death Knight)
					30809, -- Unleashed Rage (Shaman)
					113742, -- Swiftblade's Cunning (Rogue)
					128433, -- Serpent's Swiftness (Hunter: Serpent)
					128432, -- Cackling Howl (Hunter: Hyena)
				}
			},
		},
		{
			[0] = L.CASTER,
			{
				[0] = L.PRESET_BUFF_PCTSP,
				{
					1459, -- Arcane Brilliance (Mage)
					61316, -- Dalaran Brilliance (Mage)
					126309, -- Still Water (Hunter: Water Strider)
					77747, -- Burning Wrath (Shaman)
					109773, -- Dark Intent (Warlock)
				},
			},
			{
				[0] = L.PRESET_BUFF_S_HASTE,
				{
					24907, -- Moonkin Aura (Druid)
					49868, -- Mind Quickening (Priest Shadowform)
					51470, -- Elemental Oath (Shaman)
					135678, -- Energizing Spores (Hunter: Sporebat)
					
				}
			},
			{
				[0] = L.PRESET_BUFF_BIGMANAREGEN,
				{
					54428, -- Divine Plea (Paladin)
					12051, -- Evocation (Mage)
					64904, -- Hymn of Hope (Priest)
					29166, -- Innervate (Druid)
					16191, -- Mana Tide (Shaman)
				}
			},			
		},
		{
			[0] = L.DEFENSE,
			{
				[0] = L.PRESET_BUFF_BIGPCTDMGTAKEN,
				{
					65860, -- Barkskin (Druid)
					498, -- Divine Protection (Paladin)
					33206, -- Pain Suppression (Priest)
				}
			},
		},
		{
			[0] = L.TACTICAL,
			{
				[0] = L.IMMUNE,
				{
					642, -- Divine Shield (Paladin)
					45438, -- Ice Block (Mage)
				}
			},
			{
				[0] = L.PHYSICAL_IMMUNE,
				{
					5277, -- Evasion (Rogue)
					1022, -- Hand of Protection (Paladin)
				}
			},
			{
				[0] = L.MAGICAL_IMMUNE,
				{
					31224, -- Cloak of Shadows (Rogue)
					23920, -- Spell Reflection (Warrior)
				}
			},
			{
				[0] = L.SHIELDED,
				{
					11426, -- Ice Barrier (Mage)
					1463, -- Mana Shield (Mage)
					17, -- Power Word: Shield (Priest)
					7812, -- Sacrifice (Warlock)
				}
			},
			{
				[0] = L.FAST,
				{
					(((GetSpellInfo(68992)) and 68992) or 1850), -- Darkflight (Worgen racial)
					1850, -- Dash (Druid)
					13141, -- Gnomish Rocket Boots (item)
					8892, -- Goblin Rocket Boots (item)
					2379, -- Speed (Swiftness Potion item)
					14530, -- Speed (Nifty Stopwatch item)
					2983, -- Sprint (Rogue)
				}
			},
		},
	},
	{
		[0] = L.DEBUFFS_BY_TYPE,
		{
			[0] = L.DPS,
--TODO				[0] = L.PRESET_DEBUFF_AP,
			{
				[0] = L.PRESET_DEBUFF_PCTDMG,
				{
					24423, -- Demoralizing Screech	 (Hunter: Fire Roc)
					50256, -- Demoralizing Roar (Hunter: Bear)
					115798, -- Weakened Blows (Blood death knight, Feral and Guardian druid, Brewmaster monk, Protection or Retribution paladin, any warrior (any tank))
				}
			},
			--[[
			{
				[0] = L.PRESET_DEBUFF_M_HASTE,
				{
					54404, -- Dust Cloud (Hunter: Tallstrider)
					8042, -- Earth Shock (Shaman)
					55095, -- Frost Fever (Death Knight)
					58180, -- Infected Wounds (Druid)
					68055, -- Judgements of the Just (Paladin)
					90315, -- Tailspin (Hunter: Fox)
					6343, -- Thunder Clap (Warrior)
					51693, -- Waylay (Rogue)
				}
			},
			]]--
			{
				[0] = L.PRESET_DEBUFF_S_HASTE,
				{
					109466, -- Curse of Curse of Enfeeblement (Warlock)
					58604, -- Lava Breath (Hunter: Corehound)
					5761, -- Mind-numbing Poison (Rogue)
					73975, -- Necrotic Strike (Death Knight)
					31589, -- Slow (Mage)
					50274, -- Spore Cloud (Hunter: Sporebat)
					58604, -- Lava Breath (Hunter: Core Hound)
				}
			},
		},
		{
			[0] = L.PHYSICAL_TANK,
			{
				[0] = L.PRESET_DEBUFF_ARMOR,
				{
					113746, -- Weakened Armor (Any druid, any rogue, any warrior)
				}
			},
			{
				[0] = L.PRESET_DEBUFF_PCTPHYSDMGTAKEN,
				{
					57386, -- Stampede (Hunter: Rhino)
					50518, -- Ravage (Hunter: Ravager)
					35290, -- Gore (Hunter: Boar)
					81326, -- Brittle Bones (Frost and Unholy death knights, Retribution paladins, Arms and Fury warriors)
				}
			},
			
		},
		{
			[0] = L.CASTER_TANK,
			{
				[0] = L.PRESET_DEBUFF_PCTSPELLDMGTAKEN,
				{
					1490, -- Curse of the Elements (Warlock)
					34889, -- Fire Breath (Hunter: Dragonhawk)
					24844, -- Lightning Breath (Hunter: Wind Serpent)
					58410, -- Master Poisoner (Rogue)
					34889, -- Fire Breath (Hunter: Dragonhawk)
					24844, -- Lightning Breath (Hunter: Wind Serpent)
				}
			},
		},
		{
			[0] = L.TACTICAL,
			{
				[0] = L.PRESET_DEBUFF_TAUNTED,
				{
					56222, -- Dark Command (Death Knight)
					57603, -- Death Grip (Death Knight)
					115546, -- Provoke (Monk)
					20736, -- Distracting Shot (Hunter)
					6795, -- Growl (Druid)
					62124, -- Hand of Reckoning (Paladin)
					31790, -- Righteous Defense (Paladin)
					17735, -- Suffering (Warlock: Voidwalker)
					355, -- Taunt (Warrior)
					53477, -- Taunt (Hunter: tenacity)
				}
			},
			{
				[0] = L.PRESET_DEBUFF_PCTHEALTAKEN,
				{
	 				54680, -- Monstrous Bite (Hunter: Devilsaur)
					115804, -- Mortal Wounds (Arms or Fury warrior, any rogue, any hunter)
				}
			},
			{
				[0] = L.DISARM,
				{
					50541, -- Clench (Hunter: Scorpid)
					676, -- Disarm (Warrior)
					51722, -- Dismantle (Rogue)
					64058, -- Psychic Horror (Priest)
					91644, -- Snatch (Hunter: Bird of Prey)
				}
			},
			{
				[0] = L.SILENCE,
				{
					25046, -- Arcane Torrent (Blood Elf racial)
					31935, -- Avenger's Shield (Paladin)
					1330, -- Garrote - Silence (Rogue)
					50479, -- Nether Shock (Hunter: Nether Ray)
					15487, -- Silence (Priest)
					18498, -- Silenced - Gag Order (Warrior)
					34490, -- Silencing Shot (Hunter)
					81261, -- Solar Beam (Druid)
					24259, -- Spell Lock (Warlock: Fel Hunter)
					47476, -- Strangulate (Death Knight)
				}
			},
			{
				[0] = L.SPELL_LOCKOUT,
				{
					2139, -- Counterspell (Mage)
					1766, -- Kick (Rogue)
					47528, -- Mind Freeze (Death Knight)
					6552, -- Pummel (Warrior)
					26090, -- Pummel (Hunter: Gorilla)
					50318, -- Serenity Dust (Hunter: Moth)
					80964, -- Skull Bash (Bear) (Druid)
					80965, -- Skull Bash (Cat) (Druid)
					24259, -- Spell Lock (Warlock: Fel Hunter) --TODO: find SpellID for separate lockout component
					57994, -- Wind Shear (Shaman)
					50479, -- Nether Shock (Hunter: Nether Ray)
					50318, -- Serenity Dust (Hunter: Moth)
				}
			},
			{
				[0] = L.IMMUNE,
				{
					710, -- Banish (Warlock)
					33786, -- Cyclone (Druid)
				}
			},
			{
				[0] = L.STUN,
				{
					85387, -- Aftermath (Warlock)
					89766, -- Axe Toss (Warlock: Felguard)
					5211, -- Bash (Druid)
					93433, -- Burrow Attack (Hunter: Worm)
					7922, -- Charge Stun (Warrior)
					1833, -- Cheap Shot (Rogue)
					44572, -- Deep Freeze (Mage)
					45334, -- Feral Charge (Bear) (Druid)
					91800, -- Gnaw (Death Knight: Ghoul)
					853, -- Hammer of Justice (Paladin)
					88625, -- Holy Word: Chastise (Priest)
					2812, -- Holy Wrath (Paladin)
					19577, -- Intimidation (Hunter)
					408, -- Kidney Shot (Rogue)
					22570, -- Maim (Druid)
					9005, -- Pounce (Druid)
					82691, -- Ring of Frost (Mage)
					30283, -- Shadowfury (Warlock)
					46968, -- Shockwave (Warrior)
					50519, -- Sonic Blast (Hunter: Bat)
					56626, -- Sting (Hunter: Wasp)
					20549, -- War Stomp (Tauren racial)
				}
			},
			{
				[0] = L.FEAR,
				{
					6789, -- Death Coil (Warlock)
					5782, -- Fear (Warlock)
					5484, -- Howl of Terror (Warlock)
					5246, -- Intimidating Shout (Warrior)
					65545, -- Psychic Horror (Priest)
					8122, -- Psychic Scream (Priest)
					1513, -- Scare Beast (Hunter)
					10326, -- Turn Evil (Paladin)
					19725, -- Turn Undead
				}
			},
			{
				[0] = L.INCAPACITATE,
				{
					30217, -- Adamantite Grenade (item)
					76780, -- Bind Elemental (Shaman)
					30216, -- Fel Iron Bomb (item)
					3355, -- Freezing Trap (Hunter)
					1776, -- Gouge (Rogue)
					2637, -- Hibernate (Druid)
					13327, -- Reckless Charge (Goblin Rocket Helmet, Horned Viking Helmet items)
					20066, -- Repentance (Paladin)
					6770, -- Sap (Rogue)
					6358, -- Seduction (Warlock: Succubus)
					9484, -- Shackle Undead (Priest)
					19386, -- Wyvern Sting (Hunter)
				}
			},
			{
				[0] = L.DISORIENT,
				{
					90337, -- Bad Mannger (Hunter: Monkey)
					2094, -- Blind (Rogue)
					31661, -- Dragon's Breath (Mage)
					51514, -- Hex (Shaman)
					118, -- Polymorph (Mage)
					19503, -- Scatter Shot (Hunter)
				}
			},
			{
				[0] = L.ROOT,
				{
					64695, -- Earthgrab (Shaman)
					339, -- Entangling Roots (Druid)
					19185, -- Entrapment (Hunter)
					63685, -- Freeze [Frost Shock] (Shaman)
					33395, -- Freeze [Water Elemental] (Mage)
					39965, -- Frost Grenade (item)
					122, -- Frost Nova (Mage)
					55536, -- Frostweave Net (item)
					90327, -- Lock Jaw (Hunter: Dog)
					13099, -- Net-o-Matic (Gnomish Net-o-Matic Projector item)
					50245, -- Pin (Hunter: Crab)
					54706, -- Venom Web Spray (Hunter: Silithid)
					4167, -- Web (Hunter: Spider)
					50245, -- Pin (Hunter: Crab)
				}
			},
			{
				[0] = L.SLOW,
				{
					50433, -- Ankle Crack (Hunter: Crocolisk)
					11113, -- Blast Wave (Mage)
					45524, -- Chains of Ice (Death Knight)
					6136, -- Chilled (Frost Armor) (Mage)
					7321, -- Chilled (Ice Armor) (Mage)
					20005, -- Chilled (Icy Chill enchantment)
					16927, -- Chilled (Frostguard item)
					35101, -- Concussive Barrage (Hunter)
					5116, -- Concussive Shot (Hunter)
					120, -- Cone of Cold (Mage)
					3409, -- Crippling Poison (Rogue)
					18223, -- Curse of Exhaustion (Warlock)
					1604, -- Dazed
					50259, -- Dazed (Feral Charge Cat) (Druid)
					26679, -- Deadly Throw (Rogue)
					3600, -- Earthbind (Shaman)
					54644, -- Frost Breath (Hunter: Chimaera)
					8056, -- Frost Shock (Shaman)
					116, -- Frostbolt (Mage)
					8034, -- Frostbrand Attack (Shaman)
					44614, -- Frostfire Bolt (Mage)
					61394, -- Frozen Wake (Glyph of Freezing Trap) (Hunter)
					1715, -- Hamstring (Warrior)
					13810, -- Ice Trap (Hunter)
					58180, -- Infected Wounds (Druid)
					15407, -- Mind Flay (Priest)
					12323, -- Piercing Howl (Warrior)
					31589, -- Slow (Mage)
					35346, -- Time Warp (Hunter: Warp Stalker)
					54644, -- Frost Breath (Hunter: Chimaera)
				}
			},
		},
	},
} -- {TRACKER_PRESET}

-- API function upvalues

local API_GetNumShapeshiftForms = GetNumShapeshiftForms
local API_GetShapeshiftFormInfo = GetShapeshiftFormInfo


--[[ UTILITY FUNCTIONS ]]--

function Window:__tracker(class, db_default, db_valid)
	self.__tracker = function() error("Auracle/Window: redeclaration of Tracker class") end
	Tracker = class
	DB_DEFAULT_TRACKER = db_default
	DB_VALID_TRACKER = db_valid
end -- __tracker()


--[[ CLASS METHODS ]]--

function Window:UpdateSavedVars(version, db)
	-- v8: renamed plrStance to plrForm to match event names
	if (type(db.visibility) == "table" and type(db.visibility.plrStance) == "table") then
		db.visibility.plrForm = db.visibility.plrStance
		db.visibility.plrStance = nil
	end
	-- trackers
	local newVersion = 8
	local newTrackers = {}
	if (type(db.trackers) == "table") then
		for n,tdb in ipairs(db.trackers) do
			if (type(tdb) == "table") then
				newVersion = max(Tracker:UpdateSavedVars(version, tdb), newVersion)
				newTrackers[#newTrackers+1] = tdb
			end
		end
	end
	db.trackers = newTrackers
	return newVersion
end -- UpdateSavedVars()


--[[  EVENT HANDLERS ]]--

local function Frame_OnMouseDown(self, button)
	if (button == "LeftButton") then
		return self.Auracle_window:StartMoving()
	end
end -- Frame_OnMouseDown()

local function Frame_OnMouseUp(self, button)
	if (button == "LeftButton") then
		return self.Auracle_window:StopMoving()
	end
end -- Frame_OnMouseUp()

local function Frame_OnHide(self)
	return self.Auracle_window:StopMoving()
end -- Frame_OnHide()

local function Frame_OnSizeChanged(self)
	if (self:GetEffectiveScale() ~= self.Auracle_window.effectiveScale) then
		return self.Auracle_window:UpdateLayout()
	end
end -- Frame_OnSizeChanged()


--[[ CONSTRUCT & DESTRUCT ]]--

do
	local objectPool = {}
	
	function Window:New(db)
		-- re-use a window from the pool, or create a new one
		local window = next(objectPool)
		if (not window) then
			window = self:Super("New")
			window.uiFrame = CreateFrame("Frame", nil, UIParent)
			window.uiFrame.Auracle_window = window
			window.uiFrame:SetFrameStrata("LOW")
			window.uiFrame:SetClampedToScreen(true) -- so WoW polices position, no matter how it changes (StartMoving,SetPoint,etc)
		end
		objectPool[window] = nil
		
		-- (re?)initialize window
		window.db = db
		window.style = Auracle.windowStyles[db.style]
		window.locked = true
		window.moving = false
		window.effectiveScale = 1.0
		window.plrSpec = 1
		window.plrInstance = "none"
		window.plrGroup = "solo"
		window.plrCombat = false
		window.plrForm = L.HUMANOID
		window.tgtExists = false
		window.tgtType = "pc"
		window.tgtReact = "neutral"
		window.trackersLocked = true
		window.trackers = {}
		
		-- (re?)initialize frame
		window.uiFrame:SetPoint("TOPLEFT", UIParent,"TOPLEFT", db.pos.x, db.pos.y) -- TODO pref anchor points
		
		-- create and initialize trackers
		local tracker
		for n,tdb in ipairs(db.trackers) do
			tracker = Tracker(tdb, window, window.uiFrame)
			window.trackers[n] = tracker
		end
		
		-- (re?)apply preferences
		window:UpdateStyle()
		window:UpdateVisibility()
		
		return window
	end -- New()

	function Window.prototype:Destroy()
		-- clean up frame
		self:Lock()
		self.uiFrame:Hide()
		self.uiFrame:ClearAllPoints()
		-- destroy tracker frames
		if (type(self.trackers) == "table") then
			for n,tracker in ipairs(self.trackers) do
				tracker:Destroy()
			end
		end
		-- clean up window
		self.db = nil
		self.style = nil
		self.locked = nil
		self.moving = nil
		self.effectiveScale = nil
		self.plrSpec = nil
		self.plrInstance = nil
		self.plrGroup = nil
		self.plrCombat = nil
		self.plrForm = nil
		self.tgtExists = nil
		self.tgtType = nil
		self.tgtReact = nil
		self.trackersLocked = nil
		self.trackers = nil
		-- add object to the pool for later re-use
		objectPool[self] = true
	end -- Destroy()
	
end

function Window.prototype:Remove()
	if (Auracle:RemoveWindow(self)) then
		self:Destroy()
	end
end -- Remove()


--[[ INTERFACE METHODS ]]--

--[[--
local function DEBUG_ANCHOR(tag,frame)
	local a,b,c,d,e = frame:GetPoint(1);
	if (b) then
		local x = "("..b:GetWidth().."x"..b:GetHeight()..")"
		if (b == WorldFrame) then b = "WorldFrame"
		elseif (b == UIParent) then b = "UIParent"
		else b = b:GetName() or "<unknown>" end
		b = b..x
	else b = "nil" end
	Auracle:Print(tag..": "..a.." , "..b.." , "..c.." , "..d.." , "..e)
end -- DEBUG_ANCHOR()
--]]--

function Window.prototype:StartMoving()
	if (not self.locked and not self.moving) then
		self.moving = true
		local _,_,_,x,y = self.uiFrame:GetPoint(1)
		self.moving_frameX = x
		self.moving_frameY = y
--DEBUG_ANCHOR("start-pre",self.uiFrame)
		self.uiFrame:SetFrameStrata("DIALOG")
		self.uiFrame:StartMoving()
--DEBUG_ANCHOR("start-post",self.uiFrame)
		_,_,_,x,y = self.uiFrame:GetPoint(1)
		self.moving_screenX = x
		self.moving_screenY = y
	end
end -- StartMoving()

function Window.prototype:StopMoving()
	if (self.moving) then
		self.moving = false
		local _,_,_,x,y = self.uiFrame:GetPoint(1)
--DEBUG_ANCHOR("stop-pre",self.uiFrame)
		self.uiFrame:SetFrameStrata("LOW")
		self.uiFrame:StopMovingOrSizing()
--DEBUG_ANCHOR("stop-post",self.uiFrame)
		x = (x - self.moving_screenX) + self.moving_frameX
		y = (y - self.moving_screenY) + self.moving_frameY
		self.uiFrame:ClearAllPoints()
		self.uiFrame:SetPoint("TOPLEFT", self.uiFrame:GetParent(), "TOPLEFT", x, y) -- TODO pref anchor points
		self.db.pos.x = x
		self.db.pos.y = y
--DEBUG_ANCHOR("final",self.uiFrame)
		self.moving_frameX = nil
		self.moving_frameY = nil
		self.moving_screenX = nil
		self.moving_screenY = nil
	end
end -- StopMoving()


--[[ TRACKER UPDATE METHODS ]]--

function Window.prototype:ResetTrackerState()
	local ipairs = ipairs
	for n,tracker in ipairs(self.trackers) do
		tracker:ResetTrackerState()
	end
end -- ResetTrackerState()


--[[ AURA UPDATE METHODS ]]--

function Window.prototype:UpdateUnitAuras()
	Auracle:UpdateUnitAuras(self.db.unit)
end -- UpdateUnitAuras()

function Window.prototype:BeginAuraUpdate(now)
	local ipairs = ipairs
	for n,tracker in ipairs(self.trackers) do
		if (tracker.db.auratype == "buff" or tracker.db.auratype == "debuff") then
			tracker:BeginTrackerUpdate(now)
		end
	end
end -- BeginAuraUpdate()

function Window.prototype:UpdateBuff(now,index,name,rank,icon,count,atype,duration,expires,origin,stealable)
	local ipairs = ipairs
	for n,tracker in ipairs(self.trackers) do
		if (tracker.db.auratype == "buff") then
			tracker:UpdateTracker(now,index,name,rank,icon,count,atype,duration,expires,origin,stealable)
		end
	end
end -- UpdateBuff()

function Window.prototype:UpdateDebuff(now,index,name,rank,icon,count,atype,duration,expires,origin,stealable)
	local ipairs = ipairs
	for n,tracker in ipairs(self.trackers) do
		if (tracker.db.auratype == "debuff") then
			tracker:UpdateTracker(now,index,name,rank,icon,count,atype,duration,expires,origin,stealable)
		end
	end
end -- UpdateDebuff()

function Window.prototype:EndAuraUpdate(now, totalBuffs, totalDebuffs)
	local ipairs = ipairs
	for n,tracker in ipairs(self.trackers) do
		if (tracker.db.auratype == "buff") then
			tracker:EndTrackerUpdate(now, totalBuffs)
		elseif (tracker.db.auratype == "debuff") then
			tracker:EndTrackerUpdate(now, totalDebuffs)
		end
	end
end -- EndAuraUpdate()


--[[ WEAPON BUFF UPDATE METHODS ]]--

function Window.prototype:UpdateUnitWeaponBuffs()
	Auracle:UpdateUnitWeaponBuffs(self.db.unit)
end -- UpdateUnitWeaponBuffs()

function Window.prototype:BeginWeaponBuffUpdate(now)
	local ipairs = ipairs
	for n,tracker in ipairs(self.trackers) do
		if (tracker.db.auratype == "weaponbuff") then
			tracker:BeginTrackerUpdate(now)
		end
	end
end -- BeginWeaponBuffUpdate()

function Window.prototype:UpdateWeaponBuff(now,index,name,rank,icon,count,atype,duration,expires,origin,stealable)
	local ipairs = ipairs
	for n,tracker in ipairs(self.trackers) do
		if (tracker.db.auratype == "weaponbuff") then
			tracker:UpdateTracker(now,index,name,rank,icon,count,atype,duration,expires,origin,stealable)
		end
	end
end -- UpdateWeaponBuff()

function Window.prototype:EndWeaponBuffUpdate(now, totalWeaponBuffs)
	local ipairs = ipairs
	for n,tracker in ipairs(self.trackers) do
		if (tracker.db.auratype == "weaponbuff") then
			tracker:EndTrackerUpdate(now, totalWeaponBuffs)
		end
	end
end -- EndWeaponBuffUpdate()


--[[ SITUATION UPDATE METHODS ]]--

function Window.prototype:SetPlayerStatus(plrSpec, plrInstance, plrGroup, plrCombat, plrForm)
	self.plrSpec = plrSpec
	self.plrInstance = plrInstance
	self.plrGroup = plrGroup
	self.plrCombat = plrCombat
	self.plrForm = plrForm
	return self:UpdateVisibility()
end -- SetPlayerStatus()

function Window.prototype:SetUnitStatus(tgtExists, tgtType, tgtReact)
	self.tgtExists = tgtExists
	self.tgtType = tgtType
	self.tgtReact = tgtReact
	return self:UpdateVisibility()
end -- SetUnitStatus()


--[[ VISUAL UPDATE METHODS ]]--

function Window.prototype:UpdateVisibility()
	local dbvis = self.db.visibility
	local nowVis = (
		not (self.locked and self.trackersLocked)
		or (
			dbvis.plrSpec[self.plrSpec]
			and dbvis.plrInstance[self.plrInstance]
			and dbvis.plrGroup[self.plrGroup]
			and dbvis.plrCombat[self.plrCombat]
			and (not dbvis.plrForm[self.plrForm]) -- backwards logic, so new forms default to visible
			and (
				(
					self.tgtExists
					and dbvis.tgtType[self.tgtType]
					and dbvis.tgtReact[self.tgtReact]
				)
				or (
					not self.tgtExists
					and dbvis.tgtMissing
				)
			)
		)
	)
	if (nowVis) then
		self.uiFrame:Show()
	else
		self.uiFrame:Hide()
	end
	return nowVis
end -- UpdateVisibility()

function Window.prototype:UpdateStyle()
	self:UpdateBackdrop()
	self:UpdateLayout()
end -- UpdateStyle()

function Window.prototype:UpdateBackdrop()
	-- set frame opacity
	self.uiFrame:SetAlpha(self.style.db.windowOpacity)
	-- set frame backdrop
	if (self.locked) then
		local backdrop = self.style:GetBackdropTable()
		if (next(backdrop)) then
			local sdb = self.style.db
			if (backdrop.insets and sdb.background.noScale) then
				local inset = backdrop.insets.left * ((768 / self.uiFrame:GetEffectiveScale()) / Auracle.screenHeight)
				backdrop.insets.left = inset
				backdrop.insets.right = inset
				backdrop.insets.top = inset
				backdrop.insets.bottom = inset
			end
			self.uiFrame:SetBackdrop(backdrop)
			self.uiFrame:SetBackdropBorderColor(unpack(sdb.border.color))
			self.uiFrame:SetBackdropColor(unpack(sdb.background.color))
		else
			self.uiFrame:SetBackdrop(nil)
		end
	else
		self.uiFrame:SetBackdrop(UNLOCKED_BACKDROP)
		self.uiFrame:SetBackdropColor(0, 0.75, 0.75, 0.5)
	end
end -- UpdateBackdrop()

function Window.prototype:UpdateLayout()
	-- disable size handler
	self.uiFrame:SetScript("OnSizeChanged", nil)
	-- set frame scale
	self.uiFrame:SetScale(self.style.db.windowScale)
	self.effectiveScale = self.uiFrame:GetEffectiveScale()
	-- position each tracker
	for n,tracker in ipairs(self.trackers) do
		self:UpdateTrackerLayout(n)
	end
	-- get style data
	local sdb = self.style.db.layout
	local padding = sdb.padding
	local spacing = sdb.spacing
	if (sdb.noScale) then
		local factor = ((768 / self.effectiveScale) / Auracle.screenHeight)
		padding = padding * factor
		spacing = spacing * factor
	end
	local trackerSize = sdb.trackerSize
	local wrap = self.db.layout.wrap
	-- calculate total window size (enclosing box of trackers, whose bottom row might not be full)
	local num = #self.trackers
	local cols = max(1, min(num, wrap))
	local rows = max(1, ceil(num / wrap))
	self.uiFrame:SetWidth((padding * 2) + (cols * trackerSize) + ((cols-1) * spacing))
	self.uiFrame:SetHeight((padding * 2) + (rows * trackerSize) + ((rows-1) * spacing))
	-- re-set size handler
	self.uiFrame:SetScript("OnSizeChanged", Frame_OnSizeChanged)
end -- UpdateLayout()

function Window.prototype:UpdateTrackerLayout(tn)
	-- get style data
	local sdb = self.style.db.layout
	local padding = sdb.padding
	local spacing = sdb.spacing
	if (sdb.noScale) then
		local factor = ((768 / self.effectiveScale) / Auracle.screenHeight)
		padding = padding * factor
		spacing = spacing * factor
	end
	local trackerSize = sdb.trackerSize
	local wrap = self.db.layout.wrap
	-- position tracker
	local tracker = self.trackers[tn]
	if (tracker) then
		local x = padding + (floor((tn-1) % wrap) * (trackerSize + spacing))
		local y = padding + (floor((tn-1) / wrap) * (trackerSize + spacing))
		tracker:SetLayout(x, y, trackerSize)
	end
end -- UpdateTrackerLayout()

function Window.prototype:MoveTracker(tracker, delta)
	if (delta == 0) then return nil end
	-- make sure this is our tracker
	local tpos = self:GetTrackerPosition(tracker)
	if (not tpos) then return nil end
	assert(self.db.trackers[tpos] == tracker.db)
	-- shift tracker order
	local pos = tpos + delta
	if (pos < 1) then
		pos = 1
	elseif (pos > #self.db.trackers) then
		pos = #self.db.trackers
	end
	tremove(self.db.trackers, tpos)
	tinsert(self.db.trackers, pos, tracker.db)
	tremove(self.trackers, tpos)
	tinsert(self.trackers, pos, tracker)
	local tn = min(pos, tpos)
	local tnMax = max(pos, tpos)
	while (tn <= tnMax) do
		self:UpdateTrackerLayout(tn)
		tn = tn + 1
	end
	return pos
end -- MoveTracker()

function Window.prototype:GetNumTrackers()
	return #self.trackers
end -- GetNumTrackers()

function Window.prototype:GetTrackerPosition(tracker)
	for n,t in ipairs(self.trackers) do
		if (t == tracker) then
			return n
		end
	end
	return nil
end -- GetTrackerPosition()

function Window.prototype:SetTrackerPosition(tracker, x, y)
	-- make sure this is our tracker
	local tpos = self:GetTrackerPosition(tracker)
	if (not tpos) then
		return false
	end
	assert(self.db.trackers[tpos] == tracker.db)
	-- get style data
	local sdb = self.style.db.layout
	local padding = sdb.padding
	local spacing = sdb.spacing
	if (sdb.noScale) then
		local factor = ((768 / self.effectiveScale) / Auracle.screenHeight)
		padding = padding * factor
		spacing = spacing * factor
	end
	local trackerSize = sdb.trackerSize
	local wrap = self.db.layout.wrap
	-- calculate total window size
	local num = #self.trackers
	local cols = max(1, min(num, wrap))
	local rows = max(1, ceil(num / wrap))
	-- calculate which slot the given coordinates are closest to
	local col = max(1, min(cols, floor( ((x - padding) / (trackerSize + spacing)) + 0.5 ) + 1))
	local row = max(1, min(rows, floor( ((y - padding) / (trackerSize + spacing)) + 0.5 ) + 1))
	local pos = ((row - 1) * wrap) + col
	-- if it moved, swap it into position and update affected positions
	if (pos ~= tpos) then
		self:MoveTracker(tracker, pos - tpos)
	end
end -- SetTrackerPosition()


--[[ CONFIG METHODS ]]--

function Window.prototype:IsLocked()
	return self.locked
end -- IsLocked()

function Window.prototype:Unlock()
	self.locked = false
	self.uiFrame:EnableMouse(true) -- intercepts clicks, causes OnMouseDown,OnMouseUp
	self.uiFrame:SetMovable(true) -- allows StartMoving
	self.uiFrame:SetScript("OnMouseDown", Frame_OnMouseDown)
	self.uiFrame:SetScript("OnMouseUp", Frame_OnMouseUp)
	self.uiFrame:SetScript("OnHide", Frame_OnHide)
	self:UpdateBackdrop()
	self:UpdateVisibility()
end -- Unlock()

function Window.prototype:Lock()
	self:StopMoving(true)
	self.locked = true
	self.uiFrame:SetScript("OnMouseDown", nil)
	self.uiFrame:SetScript("OnMouseUp", nil)
	self.uiFrame:SetScript("OnHide", nil)
	self.uiFrame:SetMovable(false) -- allows StartMoving
	self.uiFrame:EnableMouse(false) -- intercepts clicks, causes OnMouseDown,OnMouseUp
	self:UpdateVisibility()
	self:UpdateBackdrop()
end -- Lock()

function Window.prototype:AddTracker()
	local n = #self.trackers + 1
	local tdb = Auracle:__cloneTable(DB_DEFAULT_TRACKER, true)
	self.db.trackers[n] = tdb
	local tracker = Tracker(tdb, self, self.uiFrame)
	self.trackers[n] = tracker
	if (not self:AreTrackersLocked()) then
		tracker:Unlock()
	end
	Auracle:UpdateConfig()
	Auracle:UpdateEventListeners()
	self:UpdateLayout()
	self:UpdateUnitAuras()
	-- don't need weapon buffs yet, new trackers track auras
end -- AddTracker()

function Window.prototype:AddPresetTracker(label, auratype, auras)
	local n = #self.trackers + 1
	local tdb = Auracle:__cloneTable(DB_DEFAULT_TRACKER, true)
	tdb.label = label
	tdb.auratype = auratype
	if (type(auras) == "table") then
		tdb.auras = auras
	elseif (type(auras) == "string") then
		for aura in auras:gmatch("[^\n\r]+") do
			tdb.auras[#tdb.auras+1] = aura
		end
	end
	self.db.trackers[n] = tdb
	local tracker = Tracker(tdb, self, self.uiFrame)
	self.trackers[n] = tracker
	if (not self:AreTrackersLocked()) then
		tracker:Unlock()
	end
	Auracle:UpdateConfig()
	Auracle:UpdateEventListeners()
	self:UpdateLayout()
	self:UpdateUnitAuras()
	-- don't need weapon buffs yet, presets only track auras
end -- AddPresetTracker()

function Window.prototype:RemoveTracker(tracker)
	local tpos,t
	repeat
		tpos,t = next(self.trackers, tpos)
	until (not t or t == tracker)
	if (tpos and self.db.trackers[tpos] == tracker.db) then
		tremove(self.db.trackers, tpos)
		tremove(self.trackers, tpos)
		self:UpdateLayout()
		Auracle:UpdateConfig()
		Auracle:UpdateEventListeners()
		return true
	end
	return false
end -- RemoveTracker()

function Window.prototype:AreTrackersLocked()
	return self.trackersLocked
end -- AreTrackersLocked()

function Window.prototype:UnlockTrackers()
	self.trackersLocked = false
	for n,tracker in ipairs(self.trackers) do
		tracker:Unlock()
	end
	self:UpdateVisibility()
end -- UnlockTrackers()

function Window.prototype:LockTrackers()
	self.trackersLocked = true
	for n,tracker in ipairs(self.trackers) do
		tracker:Lock()
	end
	self:UpdateVisibility()
end -- LockTrackers()


--[[ SHARED OPTIONS TABLES ]]--

local sharedOptions = {
	type = "group",
	name = "",
	inline = true,
	childGroups = "tab",
	args = {
		window = {
			type = "group",
			name = L.WINDOW,
			inline = false,
			order = 1,
			args = {
				label = {
					type = "input",
					name = L.LABEL,
					get = function(i) return i.handler.db.label end,
					set = function(i,v)
						v = strtrim(v)
						if (v == "") then v = false end
						i.handler.db.label = v
						Auracle:UpdateConfig()
					end,
					order = 1
				},
				removeWindow = {
					type = "execute",
					name = L.REMOVE_WINDOW,
					func = "Remove",
					order = 2
				},
				unit = {
					type = "select",
					name = L.WATCH_UNIT,
					values = {
						player = L.PLAYER,
						target = L.TARGET,
						targettarget = L.TARGETTARGET,
						pet = L.PET,
						pettarget = L.PETTARGET,
						focus = L.FOCUS,
						focustarget = L.FOCUSTARGET
					},
					get = function(i) return i.handler.db.unit end,
					set = function(i,v)
						i.handler.db.unit = v
						Auracle:UpdateEventListeners()
						if (not i.handler.db.label) then Auracle:UpdateConfig() end
						Auracle:UpdateUnitIdentity(v)
					end,
					order = 3
				},
				style = {
					type = "select",
					name = L.WINDOW_STYLE,
					values = function() return Auracle.windowStyleOptions end,
					get = function(i) return i.handler.db.style end,
					set = function(i,v)
						local style = Auracle.windowStyles[v]
						if (style) then
							i.handler.db.style = v
							i.handler.style = style
							style:Apply(i.handler)
						end
					end,
					order = 4
				}
			}
		},
		visibility = {
			type = "group",
			name = L.VISIBILITY,
			inline = false,
			order = 2,
			args = {
				plrSpec = {
					type = "group",
					name = L.OPT_SPEC_SHOW,
					inline = true,
					order = 1,
					args = {
						primary = {
							type = "toggle",
							name = L.PRIMARY_TALENTS,
							get = function(i) return i.handler.db.visibility.plrSpec[1] end,
							set = function(i,v)
								i.handler.db.visibility.plrSpec[1] = v
								Auracle:UpdateEventListeners()
								Auracle:UpdatePlayerStatus(i.handler)
							end,
							order = 1
						},
						secondary = {
							type = "toggle",
							name = L.SECONDARY_TALENTS,
							get = function(i) return i.handler.db.visibility.plrSpec[2] end,
							set = function(i,v)
								i.handler.db.visibility.plrSpec[2] = v
								Auracle:UpdateEventListeners()
								Auracle:UpdatePlayerStatus(i.handler)
							end,
							order = 2
						}
					}
				},
				plrInstance = {
					type = "group",
					name = L.OPT_INSTANCE_SHOW,
					inline = true,
					order = 2,
					args = {
						none = {
							type = "toggle",
							name = L.NO_INSTANCE,
							width = "full",
							get = function(i) return i.handler.db.visibility.plrInstance.none end,
							set = function(i,v)
								i.handler.db.visibility.plrInstance.none = v
								Auracle:UpdateEventListeners()
								Auracle:UpdatePlayerStatus(i.handler)
							end,
							order = 1
						},
						pvp = {
							type = "toggle",
							name = L.BATTLEGROUND,
							get = function(i) return i.handler.db.visibility.plrInstance.pvp end,
							set = function(i,v)
								i.handler.db.visibility.plrInstance.pvp = v
								Auracle:UpdateEventListeners()
								Auracle:UpdatePlayerStatus(i.handler)
							end,
							order = 2
						},
						arena = {
							type = "toggle",
							name = L.ARENA,
							get = function(i) return i.handler.db.visibility.plrInstance.arena end,
							set = function(i,v)
								i.handler.db.visibility.plrInstance.arena = v
								Auracle:UpdateEventListeners()
								Auracle:UpdatePlayerStatus(i.handler)
							end,
							order = 3
						},
						party = {
							type = "toggle",
							name = L.PARTY_INSTANCE,
							get = function(i) return i.handler.db.visibility.plrInstance.party end,
							set = function(i,v)
								i.handler.db.visibility.plrInstance.party = v
								Auracle:UpdateEventListeners()
								Auracle:UpdatePlayerStatus(i.handler)
							end,
							order = 4
						},
						raid = {
							type = "toggle",
							name = L.RAID_INSTANCE,
							get = function(i) return i.handler.db.visibility.plrInstance.raid end,
							set = function(i,v)
								i.handler.db.visibility.plrInstance.raid = v
								Auracle:UpdateEventListeners()
								Auracle:UpdatePlayerStatus(i.handler)
							end,
							order = 5
						}
					}
				},
				plrGroup = {
					type = "group",
					name = L.OPT_GROUP_SHOW,
					inline = true,
					order = 3,
					args = {
						solo = {
							type = "toggle",
							name = L.NONE_SOLO,
							width = "full",
							get = function(i) return i.handler.db.visibility.plrGroup.solo end,
							set = function(i,v)
								i.handler.db.visibility.plrGroup.solo = v
								Auracle:UpdateEventListeners()
								Auracle:UpdatePlayerStatus(i.handler)
							end,
							order = 1
						},
						party = {
							type = "toggle",
							name = L.PARTY,
							get = function(i) return i.handler.db.visibility.plrGroup.party end,
							set = function(i,v)
								i.handler.db.visibility.plrGroup.party = v
								Auracle:UpdateEventListeners()
								Auracle:UpdatePlayerStatus(i.handler)
							end,
							order = 2
						},
						raid = {
							type = "toggle",
							name = L.RAID_GROUP,
							get = function(i) return i.handler.db.visibility.plrGroup.raid end,
							set = function(i,v)
								i.handler.db.visibility.plrGroup.raid = v
								Auracle:UpdateEventListeners()
								Auracle:UpdatePlayerStatus(i.handler)
							end,
							order = 3
						}
					}
				},
				plrCombat = {
					type = "group",
					name = L.OPT_COMBAT_SHOW,
					inline = true,
					order = 4,
					args = {
						no = {
							type = "toggle",
							name = L.NOT_IN_COMBAT,
							get = function(i) return i.handler.db.visibility.plrCombat[false] end,
							set = function(i,v)
								i.handler.db.visibility.plrCombat[false] = v
								Auracle:UpdateEventListeners()
								Auracle:UpdatePlayerStatus(i.handler)
							end,
							order = 1
						},
						yes = {
							type = "toggle",
							name = L.IN_COMBAT,
							get = function(i) return i.handler.db.visibility.plrCombat[true] end,
							set = function(i,v)
								i.handler.db.visibility.plrCombat[true] = v
								Auracle:UpdateEventListeners()
								Auracle:UpdatePlayerStatus(i.handler)
							end,
							order = 2
						}
					}
				},
				plrForm = {
					type = "group",
					name = L.OPT_FORM_SHOW,
					inline = true,
					order = 5,
					args = {} -- populated in UpdateFormOptions()
				},
				tgtMissing = {
					type = "toggle",
					name = L.OPT_UNITMISSING_SHOW,
					width = "full",
					get = function(i) return i.handler.db.visibility.tgtMissing end,
					set = function(i,v)
						i.handler.db.visibility.tgtMissing = v
						i.handler:UpdateVisibility()
					end,
					order = 6
				},
				tgtReact = {
					type = "group",
					name = L.OPT_UNITREACT_SHOW,
					inline = true,
					order = 7,
					args = {
						hostile = {
							type = "toggle",
							name = L.HOSTILE,
							get = function(i) return i.handler.db.visibility.tgtReact.hostile end,
							set = function(i,v)
								i.handler.db.visibility.tgtReact.hostile = v
								i.handler:UpdateVisibility()
							end,
							order = 1
						},
						neutral = {
							type = "toggle",
							name = L.NEUTRAL,
							get = function(i) return i.handler.db.visibility.tgtReact.neutral end,
							set = function(i,v)
								i.handler.db.visibility.tgtReact.neutral = v
								i.handler:UpdateVisibility()
							end,
							order = 2
						},
						friendly = {
							type = "toggle",
							name = L.FRIENDLY,
							get = function(i) return i.handler.db.visibility.tgtReact.friendly end,
							set = function(i,v)
								i.handler.db.visibility.tgtReact.friendly = v
								i.handler:UpdateVisibility()
							end,
							order = 3
						}
					}
				},
				tgtType = {
					type = "group",
					name = L.OPT_UNITTYPE_SHOW,
					inline = true,
					order = 8,
					args = {
						pc = {
							type = "toggle",
							name = L.PLAYER,
							width = "double",
							get = function(i) return i.handler.db.visibility.tgtType.pc end,
							set = function(i,v)
								i.handler.db.visibility.tgtType.pc = v
								i.handler:UpdateVisibility()
							end,
							order = 1
						},
						worldboss = {
							type = "toggle",
							name = L.BOSS,
							get = function(i) return i.handler.db.visibility.tgtType.worldboss end,
							set = function(i,v)
								i.handler.db.visibility.tgtType.worldboss = v
								i.handler:UpdateVisibility()
							end,
							order = 2
						},
						rareelite = {
							type = "toggle",
							name = L.RARE_ELITE_NPC,
							get = function(i) return i.handler.db.visibility.tgtType.rareelite end,
							set = function(i,v)
								i.handler.db.visibility.tgtType.rareelite = v
								i.handler:UpdateVisibility()
							end,
							order = 3
						},
						elite = {
							type = "toggle",
							name = L.ELITE_NPC,
							get = function(i) return i.handler.db.visibility.tgtType.elite end,
							set = function(i,v)
								i.handler.db.visibility.tgtType.elite = v
								i.handler:UpdateVisibility()
							end,
							order = 4
						},
						rare = {
							type = "toggle",
							name = L.RARE_NPC,
							get = function(i) return i.handler.db.visibility.tgtType.rare end,
							set = function(i,v)
								i.handler.db.visibility.tgtType.rare = v
								i.handler:UpdateVisibility()
							end,
							order = 5
						},
						normal = {
							type = "toggle",
							name = L.NPC,
							get = function(i) return i.handler.db.visibility.tgtType.normal end,
							set = function(i,v)
								i.handler.db.visibility.tgtType.normal = v
								i.handler:UpdateVisibility()
							end,
							order = 6
						},
						trivial = {
							type = "toggle",
							name = L.GRAY_NPC,
							get = function(i) return i.handler.db.visibility.tgtType.trivial end,
							set = function(i,v)
								i.handler.db.visibility.tgtType.trivial = v
								i.handler:UpdateVisibility()
							end,
							order = 7
						}
					}
				}
			}
		},
		layout = {
			type = "group",
			name = L.LAYOUT,
			inline = false,
			order = 3,
			args = {
				locked = {
					type = "toggle",
					name = L.TRACKERS_LOCKED,
					desc = L.DESC_OPT_TRACKERS_LOCKED,
					get = "AreTrackersLocked",
					set = function(i,v)
						if (v) then
							i.handler:LockTrackers()
						else
							i.handler:UnlockTrackers()
						end
					end,
					order = 1
				},
				wrap = {
					type = "range",
					name = L.TRACKERS_PER_ROW,
					min = 1,
					max = 16,
					step = 1,
					get = function(i) return i.handler.db.layout.wrap end,
					set = function(i,v)
						i.handler.db.layout.wrap = v
						i.handler:UpdateLayout()
					end,
					order = 2
				}
			}
		}
	}
} -- {sharedOptions}

local sharedOptions_addTracker = {
	type = "group",
	name = L.LIST_ADD_TRACKER,
	childGroups = "tab",
	order = -1,
	args = {
		addTracker = {
			type = "execute",
			name = L.ADD_BLANK_TRACKER,
			func = "AddTracker",
			order = 1
		},
		assumeTalents = {
			type = "toggle",
			name = L.OPT_ASSUME_TALENTED,
			desc = L.DESC_OPT_ASSUME_TALENTED,
			get = function(i) return i.handler.db.assumeTalents end,
			set = function(i,v)
				i.handler.db.assumeTalents = (v and true) or false
			end,
			order = 2
		},
	}
} -- {sharedOptions_addTracker}

do
	local function get_auras(i)
		local type = tonumber(i[#i-2])
		local group = tonumber(i[#i-1])
		local set = tonumber(i[#i])
		if (i.handler.db.assumeTalents) then
			return TRACKER_PRESET[type][group][set][2]
		end
		return TRACKER_PRESET[type][group][set][1]
	end -- get_auras()
	
	local function add_preset(i)
		local type = tonumber(i[#i-2])
		local group = tonumber(i[#i-1])
		local set = tonumber(i[#i])
		-- hackish hardcode: the only two "types" right now are 1=buffsbytype, 2=debuffsbytype
		local label = TRACKER_PRESET[type][group][set][0]
		local auratype = ((type == 1) and "buff") or "debuff"
		local auras
		if (i.handler.db.assumeTalents) then
			auras = TRACKER_PRESET[type][group][set][2]
		else
			auras = TRACKER_PRESET[type][group][set][1]
		end
		i.handler:AddPresetTracker(label, auratype, auras)
	end -- add_preset()
	
	local GetSpellInfo = GetSpellInfo
	local tsort = table.sort
	local tconcat = table.concat
	
	local typeopt,groupopt
	local normal,talented,tbl,spellname
	local invalid = {}
	
	for t,typetable in ipairs(TRACKER_PRESET) do
		-- create AceOptions entry
		typeopt = {
			type = "group",
			name = typetable[0],
			childGroups = "tree",
			order = 2+t,
			args = {}
		}
		sharedOptions_addTracker.args[tostring(t)] = typeopt
		-- process subtable
		for g,grouptable in ipairs(typetable) do
			-- create AceOptions entry
			groupopt = {
				type = "group",
				name = grouptable[0],
				order = g,
				args = {}
			}
			typeopt.args[tostring(g)] = groupopt
			-- process subtable
			for s,settable in ipairs(grouptable) do
				-- create AceOptions entry
				groupopt.args[tostring(s)] = {
					type = "execute",
					name = settable[0],
					desc = get_auras,
					width = "full",
					func = add_preset,
					order = s
				}
				-- convert SpellIDs to aura names
				tbl = settable[1]
				for n,spellid in ipairs(tbl) do
					spellname = (GetSpellInfo(spellid))
					if (not spellname) then
						spellname = "!!UNKNOWN:" .. spellid
						invalid[#invalid+1] = spellid
					end
					tbl[n] = spellname
				end
				tsort(tbl)
				normal = tconcat(tbl, "\n")
				-- if there are talent-only auras, add them
				if (type(settable[2]) == "table" and type(settable[2][1]) == "number") then
					for n,spellid in ipairs(settable[2]) do
						tbl[#tbl+1] = (GetSpellInfo(spellid))
					end
					tsort(tbl)
					talented = tconcat(tbl, "\n")
				else
					talented = normal
				end
				-- replace lists with built strings
				settable[1] = normal
				settable[2] = talented
			end
		end
	end
	
	-- warn about invalid SpellIDs
	if (#invalid > 0) then
		Auracle:Print("Warning: These preset SpellIDs are no longer valid.\n", tconcat(invalid, ", "))
	end
end


--[[ MENU METHODS ]]--

local sharedOptions_plrForm_get = function(i)
	return not i.handler.db.visibility.plrForm[i.option.name] -- backwards logic, so new forms default to visible
end

local sharedOptions_plrForm_set = function(i,v)
	i.handler.db.visibility.plrForm[i.option.name] = not v -- backwards logic, so new forms default to visible
--[===[@debug@
--	print("Auracle.Window["..tostring(i.handler.db.label).."] plrForm["..tostring(i.option.name).."] = "..tostring(not v))
--@end-debug@]===]
	Auracle:UpdateEventListeners()
	Auracle:UpdatePlayerStatus(i.handler)
end

function Window:UpdateFormOptions()
--[===[@debug@
--	print("Auracle.Window:UpdateFormOptions()")
--@end-debug@]===]
	-- get list of available forms
	local forms = { [0] = L.HUMANOID }
	local maxform = API_GetNumShapeshiftForms()
	for f = 1,maxform do
		forms[f] = select(2, API_GetShapeshiftFormInfo(f)) or L.UNKNOWN_FORM
	end
	-- generate toggles for each
	local pFa = sharedOptions.args.visibility.args.plrForm.args
	wipe(pFa)
	for f = 0,maxform do
		pFa["form"..f] = {
			type = "toggle",
			name = forms[f],
			get = sharedOptions_plrForm_get,
			set = sharedOptions_plrForm_set,
			order = f + 1
		}
	end
end -- UpdateFormOptions()

function Window.prototype:GetOptionsTable()
	if (not self.optionsTable) then
		self.optionsTable = {
			type = "group",
			handler = self,
			args = {
				addTracker = sharedOptions_addTracker
			}
		}
	end
	self.optionsTable.name = self.db.label or (strupper(strsub(self.db.unit,1,1)) .. strsub(self.db.unit,2))
	local temp = self.optionsTable.args.addTracker
	wipe(self.optionsTable.args)
	self.optionsTable.args.shared = sharedOptions
	self.optionsTable.args.addTracker = temp
	if (self.trackers) then
		for n,tracker in ipairs(self.trackers) do
			self.optionsTable.args["tracker"..n] = tracker:GetOptionsTable()
			self.optionsTable.args["tracker"..n].order = n
		end
	end
	return self.optionsTable
end -- GetOptionsTable()


--[[ INIT ]]--

Auracle:__window(Window, DB_DEFAULT_WINDOW, DB_VALID_WINDOW)

