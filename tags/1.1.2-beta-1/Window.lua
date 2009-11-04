local LibOOP
--@alpha@
LibOOP = LibStub("LibOOP-1.0-alpha", true)
--@end-alpha@
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
					56525, -- Blessing of Kings
					43223, -- Greater Blessing of Kings
				}
			},
			{
				[0] = L.PRESET_BUFF_MISCSTATS,
				{
					16878, -- Mark of the Wild
					21849, -- Gift of the Wild
				}
			},
			{
				[0] = L.PRESET_BUFF_AGISTR,
				{
					57623, -- Horn of Winter
					8076, -- Strength of Earth
				}
			},
			{
				[0] = L.PRESET_BUFF_STA,
				{
					13864, -- Power Word: Fortitude
					39231, -- Prayer of Fortitude
				}
			},
			{
				[0] = L.PRESET_BUFF_HEALTH,
				{
					6307, -- Blood Pact
					45517, -- Commanding Shout
				}
			},
			{
				[0] = L.PRESET_BUFF_INT,
				{
					23030, -- Arcane Brilliance
					13326, -- Arcane Intellect
					54424, -- Fel Intelligence
				}
			},
			{
				[0] = L.PRESET_BUFF_SPI,
				{
					16875, -- Divine Spirit
					54424, -- Fel Intelligence
					27681, -- Prayer of Spirit
				}
			},
		},
		{
		 	[0] = L.GENERAL,
			{
				[0] = L.PRESET_BUFF_PCTDMG,
				{
					34456, -- Ferocious Inspiration
				},
				{
					8990, -- (Sanctified) Retribution Aura
				}
			},
			{
				[0] = L.PRESET_BUFF_BIGHASTE,
				{
					6742, -- Bloodlust
					65983, -- Heroism
				}
			},
			{
			 	[0] = L.PRESET_BUFF_HASTE,
				{
				},
				{
					24907, -- (Improved) Moonkin Aura
					8990, -- (Swift) Retribution Aura
				}
			},
--[[
			{ -- 57669
				[0] = L.PRESET_BUFF_REPLEN,
				{
					44561, -- Enduring Winter
					53367, -- Hunting Party
				--	(Judgements of the Wise) Judgement of *
					54300, -- Soul Leech Mana
					34919, -- Vampiric Touch
				}
			},
--]]
		},
		{
		 	[0] = L.PHYSICAL,
			{
				[0] = L.PRESET_BUFF_PCTAP,
				{
					53136, -- Abominable Might
					31519, -- Trueshot Aura
					30803, -- Unleashed Rage
				}
			},
			{
				[0] = L.PRESET_BUFF_AP,
				{
					9128, -- Battle Shout
					56520, -- Blessing of Might
					30636, -- Furious Howl
					29381, -- Greater Blessing of Might
				}
			},
			{
				[0] = L.PRESET_BUFF_M_HASTE,
				{
					55610, -- Improved Icy Talons
					8515, -- Windfury Totem
				}
			},
			{
				[0] = L.PRESET_BUFF_M_CRIT,
				{
					24932, -- Leader of the Pack
					30029, -- Rampage
				}
			},
		},
		{
			[0] = L.CASTER,
			{
				[0] = L.PRESET_BUFF_PCTSP,
				{
					48090, -- Demonic Pact
					52109, -- Flametongue Totem
					54646, -- Focus Magic
					30708, -- Totem of Wrath
				},
				{
					16875, -- (Improved) Divine Spirit
					27681, -- (Improved) Prayer of Spirit
				}
			},
			{
				[0] = L.PRESET_BUFF_S_HASTE,
				{
					3738, -- Wrath of Air Totem
				}
			},
			{
				[0] = L.PRESET_BUFF_S_CRIT,
				{
					53410, -- Elemental Oath
					24907, -- Moonkin Aura
				}
			},
			{
				[0] = L.PRESET_BUFF_BIGMANAREGEN,
				{
					54428, -- Divine Plea
					12051, -- Evocation
					29166, -- Innervate
				}
			},
			{
				[0] = L.PRESET_BUFF_MANAREGEN,
				{
					56521, -- Blessing of Wisdom
					25894, -- Greater Blessing of Wisdom
				}
			},
		},
		{
			[0] = L.DEFENSE,
			{
				[0] = L.PRESET_BUFF_BIGPCTDMGTAKEN,
				{
					65860, -- Barkskin
					498, -- Divine Protection
					33206, -- Pain Suppression
				}
			},
			{
				[0] = L.PRESET_BUFF_PCTDMGTAKEN,
				{
					67480, -- Blessing of Sanctuary
					47930, -- Grace
					25899, -- Greater Blessing of Sanctuary
				}
			},
			{
				[0] = L.PRESET_BUFF_PCTARMOR,
				{
					16177, -- Ancestral Fortitude
					14893, -- Inspiration
				}
			},
			{
				[0] = L.PRESET_BUFF_PCTHEALTAKEN,
				{
					34123, -- Tree of Life
				},
				{
					8258, -- (Improved) Devotion Aura
				}
			},
		},
		{
			[0] = L.TACTICAL,
			{
				[0] = L.IMMUNE,
				{
					19752, -- Divine Intervention
					642, -- Divine Shield
					27619, -- Ice Block
				}
			},
			{
				[0] = L.PHYSICAL_IMMUNE,
				{
					1022, -- Hand of Protection
					4086, -- Evasion
				}
			},
			{
				[0] = L.MAGICAL_IMMUNE,
				{
					39666, -- Cloak of Shadows
					23920, -- Spell Reflection
				}
			},
			{
				[0] = L.SHIELDED,
				{
					11426, -- Ice Barrier
					1463, -- Mana Shield
					17, -- Power Word: Shield
					58597, -- Sacred Shield
					7812, -- Sacrifice
				}
			},
			{
				[0] = L.FAST,
				{
					36589, -- Dash
					13141, -- Gnomish Rocket Boots
					8892, -- Goblin Rocket Boots
					2379, -- Speed [Swiftness Potion]
					14530, -- Speed [Nifty Stopwatch]
					32720, -- Sprint
				}
			},
		},
	},
	{
		[0] = L.DEBUFFS_BY_TYPE,
		{
			[0] = L.DPS,
			{
				[0] = L.PRESET_DEBUFF_AP,
				{
					8552, -- Curse of Weakness
					10968, -- Demoralizing Roar
					24423, -- Demoralizing Screech
					13730, -- Demoralizing Shout
				}
			},
			{
				[0] = L.PRESET_DEBUFF_M_HASTE,
				{
					59921, -- Frost Fever
					58179, -- Infected Wounds
				--	(Judgements of the Just) Judgement of *
					14251, -- Riposte
					13532, -- Thunder Clap
					51693, -- Waylay
				}
			},
			{
				[0] = L.PRESET_DEBUFF_MR_HIT,
				{
					65855, -- Insect Swarm
					52604, -- Scorpid Sting
				}
			},
			{
				[0] = L.PRESET_DEBUFF_R_HASTE,
				{
					31589, -- Slow
					51693, -- Waylay
				}
			},
			{
				[0] = L.PRESET_DEBUFF_S_HASTE,
				{
					13338, -- Curse of Tongues
					58605, -- Lava Breath
					5760, -- Mind-numbing Poison
					31589, -- Slow
				}
			},
		},
		{
			[0] = L.PHYSICAL_TANK,
			{
				[0] = L.PRESET_DEBUFF_BIGARMOR,
				{
					55749, -- Acid Spit
					8649, -- Expose Armor
					58567, -- Sunder Armor
				}
			},
			{
				[0] = L.PRESET_DEBUFF_ARMOR,
				{
					16231, -- Curse of Recklessness
					770, -- Faerie Fire
					60089, -- Faerie Fire (Feral)
					56626, -- Sting
				}
			},
			{
				[0] = L.PRESET_DEBUFF_PCTPHYSDMGTAKEN,
				{
				--	772, -- (Blood Frenzy) Rend
				--	12162, -- (Blood Frenzy) Deep Wounds
					29859, -- Blood Frenzy
					58413, -- Savage Combat
				}
			},
			{
				[0] = L.PRESET_DEBUFF_PCTBLEEDDMGTAKEN,
				{
					33878, -- Mangle (Bear)
					33876, -- Mangle (Cat)
					57386, -- Stampede
					46856, -- Trauma
				}
			},
			{
				[0] = L.PRESET_DEBUFF_CRITTAKEN,
				{
					21183, -- Heart of the Crusader
					31226, -- Master Poisoner
					30708, -- Totem of Wrath
				}
			},
		},
		{
			[0] = L.CASTER_TANK,
			{
				[0] = L.PRESET_DEBUFF_RESISTS,
				{
					1490, -- Curse of the Elements
				}
			},
			{
				[0] = L.PRESET_DEBUFF_PCTSPELLDMGTAKEN,
				{
					1490, -- Curse of the Elements
					60431, -- Earth and Moon
					51726, -- Ebon Plague
				}
			},
			{
				[0] = L.PRESET_DEBUFF_PCTDISEASEDMGTAKEN,
				{
					50508, -- Crypt Fever
					51726, -- Ebon Plague
				}
			},
			{
				[0] = L.PRESET_DEBUFF_SPELLHITTAKEN,
				{
					33196, -- Misery
				},
				{
					770, -- (Improved) Faerie Fire
				}
			},
			{
				[0] = L.PRESET_DEBUFF_CRITTAKEN,
				{
					21183, -- Heart of the Crusader
					31226, -- Master Poisoner
					30708, -- Totem of Wrath
				}
			},
			{
				[0] = L.PRESET_DEBUFF_SPELLCRITTAKEN,
				{
					22959, -- Improved Scorch
					12579, -- Winter's Chill
				}
			},
		},
		{
			[0] = L.TACTICAL,
			{
				[0] = L.PRESET_DEBUFF_PCTHEALTAKEN,
				{
					20900, -- Aimed Shot
					56112, -- Furious Attacks
					21551, -- Mortal Strike
					13218, -- Wound Poison
					13222, -- Wound Poison II
					13223, -- Wound Poison III
					13224, -- Wound Poison IV
					27189, -- Wound Poison V
					57974, -- Wound Poison VI
					57975, -- Wound Poison VII
				}
			},
			{
				[0] = L.DISARM,
				{
					53359, -- Chimera Shot - Scorpid
					676, -- Disarm
					51722, -- Dismantle
					64346, -- Fiery Payback
					51514, -- Hex
					64058, -- Psychic Horror
					50541, -- Snatch
				}
			},
			{
				[0] = L.SILENCE,
				{
					25046, -- Arcane Torrent
					1330, -- Garrote - Silence
					51514, -- Hex
					15487, -- Silence
					18498, -- Silenced - Gag Order
					18469, -- Silenced - Improved Counterspell
					18425, -- Silenced - Improved Kick
					63529, -- Silenced - Shield of the Templar
					34490, -- Silencing Shot
					24259, -- Spell Lock
					47476, -- Strangulate
				}
			},
			{
				[0] = L.IMMUNE,
				{
					710, -- Banish
					33786, -- Cyclone
				}
			},
			{
				[0] = L.STUN,
				{
					5211, -- Bash
					1833, -- Cheap Shot
					12809, -- Concussion Blow
					44572, -- Deep Freeze
					47481, -- Gnaw
					853, -- Hammer of Justice
					2812, -- Holy Wrath
					12355, -- Impact
				--	51880, -- Improved Fire Nova Totem -- totem replaced by Fire Nova spell in WoW 3.3, talent no longer stuns
					20253, -- Intercept
					24394, -- Intimidation
					408, -- Kidney Shot
					22570, -- Maim
					9005, -- Pounce
					50518, -- Ravage
					12798, -- Revenge Stun
					30283, -- Shadowfury
					46968, -- Shockwave
					50519, -- Sonic Blast
					20170, -- Stun [Seal of Justice]
					20549, -- War Stomp
				}
			},
			{
				[0] = L.FEAR,
				{
					6789, -- Death Coil
					5782, -- Fear
					5484, -- Howl of Terror
					20511, -- Intimidating Shout
					65545, -- Psychic Horror
					8122, -- Psychic Scream
					1513, -- Scare Beast
					10326, -- Turn Evil
					19725, -- Turn Undead
				}
			},
			{
				[0] = L.INCAPACITATE,
				{
					30217, -- Adamantite Grenade
					30216, -- Fel Iron Bomb
					3355, -- Freezing Trap Effect
					1776, -- Gouge
					2637, -- Hibernate
					51209, -- Hungering Cold
					13327, -- Reckless Charge [Goblin Rocket Helmet, Horned Viking Helmet]
					20066, -- Repentance
					6770, -- Sap
					6358, -- Seduction
					24132, -- Wyvern Sting
				}
			},
			{
				[0] = L.DISORIENT,
				{
					2094, -- Blind
					31661, -- Dragon's Breath
					118, -- Polymorph
					37506, -- Scatter Shot
				}
			},
			{
				[0] = L.ROOT,
				{
					7922, -- Charge Stun
					19306, -- Counterattack
					64695, -- Earthgrab
					339, -- Entangling Roots
					19185, -- Entrapment
					19675, -- Feral Charge Effect
					63685, -- Freeze [Frost Shock]
					33395, -- Freeze [Water Elemental]
					60210, -- Freezing Arrow Effect
					39965, -- Frost Grenade
					122, -- Frost Nova
					11071, -- Frostbite
					55536, -- Frostweave Net
					58373, -- Glyph of Hamstring
					23694, -- Improved Hamstring
					13099, -- Net-o-Matic
					50245, -- Pin
					9484, -- Shackle Undead
					55080, -- Shattered Barrier
					54706, -- Venom Web Spray
					4167, -- Web
				}
			},
			{
				[0] = L.SLOW,
				{
					18118, -- Aftermath
					31125, -- Blade Twisting
					11113, -- Blast Wave
					45524, -- Chains of Ice
					6136, -- Chilled [Frost Armor, Ice Armor, (Improved) Blizzard, ...]
					35101, -- Concussive Barrage
					5116, -- Concussive Shot
					120, -- Cone of Cold
					3409, -- Crippling Poison
					18223, -- Curse of Exhaustion
					29703, -- Dazed
					26679, -- Deadly Throw
					55666, -- Desecration
					3600, -- Earthbind
					61132, -- Feral Charge - Cat
					8056, -- Frost Shock
					13810, -- Frost Trap Aura
					116, -- Frostbolt
					8034, -- Frostbrand Attack
					44614, -- Frostfire Bolt
					54689, -- Froststorm Breath
					61394, -- Glyph of Freezing Trap
					58617, -- Glyph of Heart Strike
					1715, -- Hamstring
					50434, -- Icy Clutch
					58179, -- Infected Wounds
					15407, -- Mind Flay
					12323, -- Piercing Howl
					31589, -- Slow
					50271, -- Tendon Rip
					61390, -- Typhoon
					51693, -- Waylay
					2974, -- Wing Clip
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


--[[ AURA UPDATE METHODS ]]--

function Window.prototype:UpdateUnitAuras()
	Auracle:UpdateUnitAuras(self.db.unit)
end -- UpdateUnitAuras()

function Window.prototype:ResetAuraState()
	local ipairs = ipairs
	for n,tracker in ipairs(self.trackers) do
		tracker:ResetAuraState()
	end
end -- ResetAuraState()

function Window.prototype:BeginAuraUpdate(now)
	local ipairs = ipairs
	for n,tracker in ipairs(self.trackers) do
		tracker:BeginAuraUpdate(now)
	end
end -- BeginAuraUpdate()

function Window.prototype:UpdateBuff(now,index,name,rank,icon,count,atype,duration,expires,origin,stealable)
	local ipairs = ipairs
	for n,tracker in ipairs(self.trackers) do
		if (tracker.db.auratype == "buff") then
			tracker:UpdateAura(now,index,name,rank,icon,count,atype,duration,expires,origin,stealable)
		end
	end
end -- UpdateBuff()

function Window.prototype:UpdateDebuff(now,index,name,rank,icon,count,atype,duration,expires,origin,stealable)
	local ipairs = ipairs
	for n,tracker in ipairs(self.trackers) do
		if (tracker.db.auratype == "debuff") then
			tracker:UpdateAura(now,index,name,rank,icon,count,atype,duration,expires,origin,stealable)
		end
	end
end -- UpdateDebuff()

function Window.prototype:EndAuraUpdate(now,totalBuffs, totalDebuffs)
	local ipairs = ipairs
	for n,tracker in ipairs(self.trackers) do
		if (tracker.db.auratype == "buff") then
			tracker:EndAuraUpdate(now, totalBuffs)
		elseif (tracker.db.auratype == "debuff") then
			tracker:EndAuraUpdate(now, totalDebuffs)
		end
	end
end -- EndAuraUpdate()


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
--@debug@
--	print("Auracle.Window["..tostring(i.handler.db.label).."] plrForm["..tostring(i.option.name).."] = "..tostring(not v))
--@end-debug@
	Auracle:UpdateEventListeners()
	Auracle:UpdatePlayerStatus(i.handler)
end

function Window:UpdateFormOptions()
--@debug@
--	print("Auracle.Window:UpdateFormOptions()")
--@end-debug@
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

