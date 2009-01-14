-- initialize addon
AuraHUD = LibStub("AceAddon-3.0"):NewAddon("AuraHUD",
	"AceConsole-3.0", "AceEvent-3.0", "AceBucket-3.0")
local AuraHUD = AuraHUD

-- define class pointers and one-shot linkers
local Window
function AuraHUD:RegisterWindow(class) Window = class; self.RegisterWindow = nil; end
function AuraHUD:RegisterTracker(class) Window:RegisterTracker(class); self.RegisterTracker = nil; end

-- define library pointers
local AceDB
local AceConfig
local AceConfigDialog
local AceConfigCmd
local AceConfigRegistry
--local LibSharedMedia
--local LibButtonFacade

-- initialize local static data
local ICON_QM = "Interface\\Icons\\INV_Misc_QuestionMark"
local DB_VERSION = 1
local DB_DEFAULT_TRACKER = {
--	enabled = 1,
	label = "New Tracker",
	auratype = "debuff", -- buff|debuff
	border = {
		colorMissing = {1, 0, 0, 1}, -- rgba
		colorMine = {0, 1, 1, 1}, -- rgba
		colorOthers = {0, 1, 0, 1}, -- rgba
	},
	icon = {
		texture = ICON_QM,
		autoTexture = true, -- autoupdate icon texture when new aura detected
		desaturateMissing = false,
		colorMissing = {1, 0.3, 0.3, 1}, -- rgba
		colorMine = {1, 1, 1, 1}, -- rgba
		colorOthers = {1, 1, 1, 1}, -- rgba
	},
	spiral = {
		mode = "time", -- off|time|stacks
		noCC = true, -- set "noCooldownCount" and "noOmniCC" to stop CooldownCount/OmniCC/etc from adding cooldown text
		length = 0,
		autoLength = true, -- autoupdate max when new aura detected
	},
	text = {
		mode = "time", -- off|time|stacks|tag
--		tag = nil,
		font = "Fonts\\FRIZQT__.TTF",
		sizeMult = 0.75,
		size = 0,
		outline = "OUTLINE", -- nil|OUTLINE|THICKOUTLINE
--		colorVLong = {1,1,1,1}, -- rgba
--		timeLong = 60,
--		colorLong = {1,1,0,1}, -- rgba
--		timeMed = 10,
--		colorMed = {1,0.5,0,1}, -- rgba
--		timeShort = 5,
--		colorShort = {1,0,0,1}, -- rgba
--		colorMissing = {1,0,0,1}, -- rgba
	},
	tooltip = {
--		mode = "active", -- off|active|all
	},
	filter = {
		origin = {
			me = true,
			other = true
		}
	},
	auras = {},
} -- {DB_DEFAULT_TRACKER}

local DB_TRACKER_OPTIONS = {
	auratype = {
		buff = "Buffs",
		debuff = "Debuffs"
	},
	filter_origin = {
		me = "Me",
		other = "Others"
	},
	spiral = {
		mode = {
			off = "Off",
			time = "Duration",
			stacks = "Stacks"
		}
	},
	text = {
		mode = {
			off = "Off",
			time = "Duration",
			stacks = "Stacks",
			tag = "Tag"
		},
		outline = {
			[""] = "none",
			OUTLINE = "thin",
			THICKOUTLINE = "thick"
		}
	}
} -- {DB_TRACKER_OPTIONS}

local DB_DEFAULT_WINDOW = {
	trackerDefaults = DB_DEFAULT_TRACKER,
--	enabled = 1,
	label = false,
	unit = "target", -- player|target|targettarget|pet|pettarget|focus|focustarget
	vis = {
		plrGroup = {solo=true, party=true, raid=true}, -- on PARTY_MEMBERS_CHANGED, GetNum[Party|Raid]Members()
		plrCombat = {no=true, yes=true}, -- on PLAYER_REGEN_[DIS|EN]ABLED, InCombatLockdown()
		tgtType = {none=true, pc=true, trivial=true, normal=true, rare=true, elite=true, rareelite=true, worldboss=true}, -- on ident change, UnitExists(),UnitPlayerControlled(),UnitClassification()
		tgtReact = {hostile=true, neutral=true, friendly=true}, -- on ident change, UnitIsEnemy(),UnitIsFriend() (no event to catch changes)
--		tgtCombat = {[false]=true, [true]=true}, -- could poll UnitAffectingCombat(), but that still fails for proximity aggro
	},
	pos = {
--		windowAnchor = "TOPLEFT",
--		referenceAnchor = "TOPLEFT",
		x = UIParent:GetWidth() / 2,
		y = UIParent:GetHeight() / -2,
	},
	border = {
--		noScale = false,
		style = "Interface\\Tooltips\\UI-Tooltip-Border",
--		size = 16,
--		inset = 4,
		color = {0.5,0.5,0.5,0.75}, -- rgba
	},
	bg = {
--		noScale = false,
		style = "Interface\\ChatFrame\\ChatFrameBackground",
		tile = true,
--		size = 16,
		color = {0,0,0,0.75}, -- rgba
	},
	layout = {
		noLayoutScale = true,
		padding = 6,
		spacing = 2,
		noBorderScale = true,
--		borderSize = 1,
--		noTrackerScale = false,
		trackerSize = 24,
--		layoutVH = false, -- layout vertically before horizontally
		wrap = 8,
	},
	trackers = {},
} -- {DB_DEFAULT_WINDOW}

local DB_WINDOW_OPTIONS = {
	unit = {
		player = "Player",
		target = "Target",
		targettarget = "Target's Target",
		pet = "Pet",
		pettarget = "Pet's Target",
		focus = "Focus",
		focustarget = "Focus' Target"
	},
	vis_plrGroup = {
		solo = "Solo",
		party = "In a Party",
		raid = "In a Raid"
	},
	vis_plrCombat = {
		no = "Not in Combat",
		yes = "In Combat"
	},
	vis_tgtType = {
		none = "Doesn't Exist",
		pc = "Is a Player",
		trivial = "Is a Trivial NPC (grey to you)",
		normal = "Is an NPC",
		rare = "Is a Rare NPC",
		elite = "Is an Elite NPC",
		rareelite = "Is a Rare Elite NPC",
		worldboss = "Is a Boss"
	},
	vis_tgtReact = {
		hostile = "Hostile",
		neutral = "Neutral",
		friendly = "Friendly"
	}
} -- {DB_WINDOW_OPTIONS}

local DB_DEFAULT = {
	version = DB_VERSION,
	windowDefaults = DB_DEFAULT_WINDOW,
	trackerDefaults = DB_DEFAULT_TRACKER,
	windows = {
		DB_DEFAULT_WINDOW,
	},
} -- {DB_DEFAULT}


--[[ LOCAL UTILITY FUNCTIONS ]]--

local cloneTable
do
	local assert,pairs,type = assert,pairs,type
	local flag = {}
	cloneTable = function(tbl, recurseValues, recurseKeys)
		assert(not flag[tbl], "cloneTable(): table contains a reference to itself")
		flag[tbl] = 1
		local newtbl = {}
		for k,v in pairs(tbl) do
			if (recurseKeys and type(k) == "table") then
				k = cloneTable(k, recurseValues, recurseKeys)
			end
			if (recurseValues and type(v) == "table") then
				v = cloneTable(v, recurseValues, recurseKeys)
			end
			newtbl[k] = v
		end
		flag[tbl] = nil
		return newtbl
	end -- cloneTable()
end

local renderTable
do
	local assert,pairs,strrep,tostring,type = assert,pairs,strrep,tostring,type
	local flag = {}
	renderTable = function(tbl, recurse, indent, indentWith)
		assert(not flag[tbl], "renderTable(): table contains a reference to itself")
		flag[tbl] = 1
		if (not indent) then
			indent = 0
		end
		if (not indentWith) then
			indentWith = "  "
		end
		local s = ""
		for k,v in pairs(tbl) do
			s = s..strrep(indentWith,indent)..tostring(k).." = "
			if (recurse and type(v) == "table") then
				s = s.."{\n"..renderTable(v,true,indent+1,indentWith)..strrep(indentWith,indent).."}\n"
			else
				s = s..tostring(v).."\n"
			end
		end
		flag[tbl] = nil
		return s
	end -- renderTable()
end

local renderArray
do
	local assert,ipairs,strrep,tostring,type = assert,ipairs,strrep,tostring,type
	local flag = {}
	renderArray = function(tbl, recurse, indent, indentWith)
		assert(not flag[tbl], "renderArray(): table contains a reference to itself")
		flag[tbl] = 1
		if (not indent) then
			indent = 0
		end
		if (not indentWith) then
			indentWith = "  "
		end
		local s = ""
		for n,v in ipairs(tbl) do
			s = s..strrep(indentWith,indent)..n..": "
			if (recurse and type(v) == "table") then
				if (recurse == "table") then
					s = s.."{\n"..renderTable(v,true,indent+1,indentWith)..strrep(indentWith,indent).."}\n"
				else
					s = s.."{\n"..renderArray(v,true,indent+1,indentWith)..strrep(indentWith,indent).."}\n"
				end
			else
				s = s..tostring(v).."\n"
			end
		end
		flag[tbl] = nil
		return s
	end -- renderArray()
end

function AuraHUD:DebugCall(func, ...)
	local s = ""
	local i,n = 1,select('#',...)
	while i <= n do
		a = select(i,...)
		i = i + 1
		if (type(a)=="table") then
			s = s..",{ --"..tostring(a).."\n"..renderTable(a,false,1,"  ").."}"
		else
			s = s..","..tostring(a)
		end
	end
	self:Print(func.."("..strsub(s,2)..")")
end


--[[ Ace3 EVENT HANDLERS ]]--

function AuraHUD:OnInitialize()
	-- load libraries
	AceDB = LibStub("AceDB-3.0")
	AceConfig = LibStub("AceConfig-3.0")
	AceConfigDialog = LibStub("AceConfigDialog-3.0")
	AceConfigCmd = LibStub("AceConfigCmd-3.0")
	AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
	--LibSharedMedia = LibStub("LibSharedMedia-3.0")
	--LibButtonFacade = LibStub("LibButtonFacade",true) -- optional
	-- initialize stored data
--AuraHUD_DB = {}
	self.db = AceDB:New(AuraHUD_DB, { profile = DB_DEFAULT })
	-- reset corrupt data or roll-forward older schemes
--self.db.profile.version = nil
	if (not self.db.profile or not self.db.profile.version) then
		self.db.profile = cloneTable(DB_DEFAULT, true)
	end
--self.db.profile.version = 0
	if (self.db.profile.version < DB_VERSION) then
		self:ConvertDataStore(self.db.profile)
	end
--self:Print(renderTable(self.db.profile.windows[1],true))
--self:Print("ui="..UIParent:GetWidth()..","..UIParent:GetHeight().." ; *"..UIParent:GetScale().." ("..UIParent:GetEffectiveScale()..")")
	-- register command-line config handler
	AceConfig:RegisterOptionsTable("AuraHUD", self:GetCommandTable(), {"aurahud"})
	-- register gui config handler
	AceConfig:RegisterOptionsTable("AuraHUD Setup", self:GetOptionsTable())
	--self.blizOptionsFrame = AceConfigDialog:AddToBlizOptions("AuraHUD", "AuraHUD")
end -- OnInitialize()

function AuraHUD:OnEnable()
	-- initialize addon
	self.windows = {}
	self.windowsLocked = true
	self.plrGroup = "solo"
	self.plrCombat = "no"
	-- create windows
	local window
	for n,wdb in ipairs(self.db.profile.windows) do
		window = Window(wdb)
		self.windows[n] = window
	end
	-- initialize state
	self:UpdatePlayerStatus()
	self:UpdateEventListeners()
	-- update tracked units
	for n,window in ipairs(self.windows) do
		self:UpdateUnitIdentity(window.db.unit)
	end
	-- update menus
	self:UpdateCommandTable()
	self:UpdateOptionsTable()
end -- OnEnable()

function AuraHUD:OnDisable()
	-- AceEvent handles unregistering events (the equivalent of self:UnregisterAllEvents())
	-- destroy windows (we can't actually destroy their frames, but :Destroy() will handle pooling them for later re-use)
	for n,window in ipairs(self.windows) do
		window:Destroy()
	end
	-- clean up addon
	self.windows = nil
	self.windowsLocked = nil
	self.plrGroup = nil
	self.plrCombat = nil
	-- update menus
	self:UpdateCommandTable()
	self:UpdateOptionsTable()
end -- OnDisable()


--[[ WoW EVENT HANDLERS ]]--

function AuraHUD:PLAYER_TARGET_CHANGED()
	--self:Print("PLAYER_TARGET_CHANGED("..tostring(event)..","..tostring(arg2)..","..tostring(arg3)..","..tostring(arg4)..")")
	self:UpdateUnitIdentity("target")
	self:UpdateUnitIdentity("targettarget")
end -- PLAYER_TARGET_CHANGED()

function AuraHUD:UNIT_TARGET(event, unit, arg3, arg4)
	self:Print("UNIT_TARGET("..tostring(event)..","..tostring(unit)..","..tostring(arg3)..","..tostring(arg4)..")")
	if (unit == "player") then
		self:UpdateUnitIdentity("target")
		self:UpdateUnitIdentity("targettarget")
	elseif (unit == "target") then
		self:UpdateUnitIdentity("targettarget")
	elseif (unit == "pet") then
		self:UpdateUnitIdentity("pettarget")
	elseif (unit == "focus") then
		self:UpdateUnitIdentity("focustarget")
	end
end -- UNIT_TARGET()

function AuraHUD:PLAYER_FOCUS_CHANGED(event, arg2, arg3, arg4)
	self:Print("PLAYER_FOCUS_CHANGED("..tostring(event)..","..tostring(arg2)..","..tostring(arg3)..","..tostring(arg4)..")")
	self:UpdateUnitIdentity("focus")
	self:UpdateUnitIdentity("focustarget")
end -- PLAYER_FOCUS_CHANGED()

function AuraHUD:UNIT_PET(event, unit, arg3, arg4)
	self:Print("UNIT_PET("..tostring(event)..","..tostring(unit)..","..tostring(arg3)..","..tostring(arg4)..")")
	if (unit == "player") then
		self:UpdateUnitIdentity("pet")
		self:UpdateUnitIdentity("pettarget")
	end
end -- UNIT_PET()

function AuraHUD:PARTY_MEMBERS_CHANGED(event, arg2, arg3, arg4)
	self:Print("PARTY_MEMBERS_CHANGED("..tostring(event)..","..tostring(arg2)..","..tostring(arg3)..","..tostring(arg4)..")")
	-- determine player's group status
	self.plrGroup = "solo"
	if (GetNumRaidMembers() > 0) then -- includes player
		self.plrGroup = "raid"
	elseif (GetNumPartyMembers() > 0) then -- excludes player
		self.plrGroup = "party"
	end
	-- update windows
	local nowVis
	for _,window in ipairs(self.windows) do
		nowVis = window:SetPlayerStatus(self.plrGroup, self.plrCombat)
		-- if this window is (now?) visible, update its unit
		if (nowVis) then
			self:UpdateUnitAuras(window.db.unit)
		end
	end
end -- PARTY_MEMBERS_CHANGED()

function AuraHUD:PLAYER_REGEN_DISABLED(event, arg2, arg3, arg4)
	self:Print("PLAYER_REGEN_DISABLED("..tostring(event)..","..tostring(arg2)..","..tostring(arg3)..","..tostring(arg4)..")")
	self.plrCombat = "yes"
	-- update windows
	local nowVis
	for _,window in ipairs(self.windows) do
		nowVis = window:SetPlayerStatus(self.plrGroup, self.plrCombat)
		-- if this window is (now?) visible, update its unit
		if (nowVis and not wasVis) then
			self:UpdateUnitAuras(window.db.unit)
		end
	end
end -- PLAYER_REGEN_DISABLED()

function AuraHUD:PLAYER_REGEN_ENABLED(event, arg2, arg3, arg4)
	self:Print("PLAYER_REGEN_ENABLED("..tostring(event)..","..tostring(arg2)..","..tostring(arg3)..","..tostring(arg4)..")")
	self.plrCombat = "no"
	-- update windows
	local nowVis
	for _,window in ipairs(self.windows) do
		nowVis = window:SetPlayerStatus(self.plrGroup, self.plrCombat)
		-- if this window is (now?) visible, update its unit
		if (nowVis and not wasVis) then
			self:UpdateUnitAuras(window.db.unit)
		end
	end
end -- PLAYER_REGEN_ENABLED()


--[[ AceBucket EVENT HANDLERS ]]--

function AuraHUD:Bucket_UNIT_AURA(units)
	--self:Print("Bucket_UNIT_AURA("..tostring(units)..","..tostring(arg2)..","..tostring(arg3)..","..tostring(arg4)..")")
	--self:Print("  units = {\n"..renderTable(units,true,2,"  ").."  }")
	for unit,count in pairs(units) do
		self:UpdateUnitAuras(unit)
	end
end -- Bucket_UNIT_AURA()


--[[ UNIT/AURA UPDATE METHODS ]]--

function AuraHUD:UpdateUnitIdentity(unit)
	local ipairs = ipairs
	if (UnitExists(unit)) then
		local tgtType,tgtReact = "pc","neutral"
		-- check unit type and reaction
		if (not UnitPlayerControlled(unit)) then
			tgtType = UnitClassification(unit)
		end
		if (UnitIsEnemy("player",unit)) then
			tgtReact = "hostile"
		elseif (UnitIsFriend("player",unit)) then
			tgtReact = "friendly"
		end
		-- update window visibility
		local vis = false
		for _,window in ipairs(self.windows) do
			if (window.db.unit == unit) then
				vis = window:SetUnitStatus(tgtType, tgtReact) or vis
			end
		end
		--self:Print("  "..((vis and "->auras") or "nobody cares"))
		-- if at least one window that tracks this unit is visible, update auras
		if (vis) then
			self:UpdateUnitAuras(unit)
		end
	else
		-- update window visibility and reset trackers
		for _,window in ipairs(self.windows) do
			if (window.db.unit == unit) then
				window:SetUnitStatus("none", "neutral")
				window:ResetAuraState()
			end
		end
	end
end -- UpdateUnitIdentity()

function AuraHUD:UpdateUnitAuras(unit)
	local ipairs = ipairs
	local now = GetTime()
	local index, totalBuffs, totalDebuffs
	local name, rank, icon, count, atype, duration, expires, origin, stealable
	-- reset window states
	for _,window in ipairs(self.windows) do
		if (window.db.unit == unit) then
			window:BeginAuraUpdate(now)
		end
	end
	-- parse buffs
	index = 1
	name,rank,icon,count,atype,duration,expires,origin,stealable = UnitAura(unit, index, "HELPFUL")
	origin = (origin and "me") or "other"
	while (name) do
		for _,window in ipairs(self.windows) do
			if (window.db.unit == unit) then
				window:UpdateBuff(now,index,name,rank,icon,count,atype,duration,expires,origin,stealable)
			end
		end
		index = index + 1
		name,rank,icon,count,atype,duration,expires,origin,stealable = UnitAura(unit, index, "HELPFUL")
		origin = (origin and "me") or "other"
	end
	totalBuffs = index - 1
	-- parse debuffs
	index = 1
	name,rank,icon,count,atype,duration,expires,origin,stealable = UnitAura(unit, index, "HARMFUL")
	origin = (origin and "me") or "other"
	while (name) do
		for _,window in ipairs(self.windows) do
			if (window.db.unit == unit) then
				window:UpdateDebuff(now,index,name,rank,icon,count,atype,duration,expires,origin,stealable)
			end
		end
		index = index + 1
		name,rank,icon,count,atype,duration,expires,origin,stealable = UnitAura(unit, index, "HARMFUL")
		origin = (origin and "me") or "other"
	end
	totalDebuffs = index - 1
	-- update windows
	for _,window in ipairs(self.windows) do
		if (window.db.unit == unit) then
			window:EndAuraUpdate(now, totalBuffs, totalDebuffs)
		end
	end
end -- UpdateUnitAuras()


--[[ SITUATION UPDATE METHODS ]]--

function AuraHUD:UpdatePlayerStatus()
	-- determine player's group and combat status
	self.plrGroup = "solo"
	if (GetNumRaidMembers() > 0) then -- includes player
		self.plrGroup = "raid"
	elseif (GetNumPartyMembers() > 0) then -- excludes player
		self.plrGroup = "party"
	end
	self.plrCombat = (InCombatLockdown() and "yes") or "no"
	-- update windows
	for _,window in ipairs(self.windows) do
		window:SetPlayerStatus(self.plrGroup, self.plrCombat)
	end
end -- UpdatePlayerStatus()


--[[ CONFIG METHODS ]]--

function AuraHUD:ConvertDataStore(dbProfile)
	-- TODO real roll-forward based on DB_VERSION
	local t = dbProfile.windows[1].trackers
	
	--[[-- easy testing
	dbProfile.windows[1].layout.wrap = 3
	
	t[1] = cloneTable(DB_DEFAULT_TRACKER, true)
	t[1].label = "My Druid Buff"
	t[1].filter.origin.other = false
	t[1].auratype = "buff"
	t[1].auras = { "Thorns", "Mark of the Wild", "Gift of the Wild" }
	
	t[2] = cloneTable(DB_DEFAULT_TRACKER, true)
	t[2].label = "Not My Druid Buff"
	t[2].filter.origin.me = false
	t[2].auratype = "buff"
	t[2].auras = { "Thorns", "Mark of the Wild", "Gift of the Wild" }
	
	t[3] = cloneTable(DB_DEFAULT_TRACKER, true)
	t[3].label = "Persistent Druid Buff"
	t[3].auratype = "buff"
	t[3].auras = { "Leader of the Pack" }
	
	t[4] = cloneTable(DB_DEFAULT_TRACKER, true)
	t[4].label = "Druid Debuff (Static Icon)"
	t[4].icon.autoTexture = false
	t[4].auras = { "Moonfire", "Entangling Roots" }
	--]]--
	
	--[[-- feral druid ]]
	dbProfile.windows[1].layout.wrap = 4
	
	t[1] = cloneTable(DB_DEFAULT_TRACKER, true)
	t[1].label = "+ Bleed Dmg"
	t[1].auras = { "Trauma", "Mangle - Bear", "Mangle - Cat" }
	
	t[2] = cloneTable(DB_DEFAULT_TRACKER, true)
	t[2].label = "My Rake"
	t[2].filter.origin.other = false
	t[2].auras = { "Rake" }
	
	t[3] = cloneTable(DB_DEFAULT_TRACKER, true)
	t[3].label = "My Rip"
	t[3].filter.origin.other = false
	t[3].auras = { "Rip" }
	
	t[4] = cloneTable(DB_DEFAULT_TRACKER, true)
	t[4].label = "- AC (minor)"
	t[4].auras = { "Curse of Recklessness", "Faerie Fire", "Faerie Fire (Feral)" }
	
	t[5] = cloneTable(DB_DEFAULT_TRACKER, true)
	t[5].label = "My Lacerate"
	t[5].filter.origin.other = false
	t[5].auras = { "Lacerate" }
	
	t[6] = cloneTable(DB_DEFAULT_TRACKER, true)
	t[6].label = "- Melee Spd"
	t[6].auras = { "Icy Touch", "Infected Wounds", "Judgements of the Just", "Thunder Clap" }
	
	t[7] = cloneTable(DB_DEFAULT_TRACKER, true)
	t[7].label = "- AP"
	t[7].auras = { "Curse of Weakness", "Demoralizing Shout", "Demoralizing Roar" }
	--]]--
	
	dbProfile.version = DB_VERSION
	return true
end -- ConvertDataStore()

function AuraHUD:UpdateEventListeners()
	-- clear them all
	self:UnregisterAllEvents()
	-- determine which listeners we need according to current settings
	local ePTarget,eUTarget,ePFocus,ePet,eParty,eCombat,eAuras
	local u,v
	for wn,window in ipairs(self.windows) do
		-- based on window.unit
		u = window.db.unit
		if (u == "target") then
			ePTarget = true
		elseif (u == "targettarget") then
			eUTarget = true
		elseif (u == "pet") then
			ePet = true
		elseif (u == "pettarget") then
			ePet = true
			eUTarget = true
		elseif (u == "focus") then
			ePFocus = true
		elseif (u == "focustarget") then
			ePFocus = true
			eUTarget = true
		end
		-- based on window.vis
		v = window.db.vis
		if (v.plrGroup.solo ~= v.plrGroup.party or v.plrGroup.solo ~= v.plrGroup.raid) then
			eParty = true
		end
		if (v.plrCombat.no ~= v.plrCombat.yes) then
			eCombat = true
		end
		-- based on window.trackers
		if (#window.trackers > 0) then
			eAuras = true
		end
	end
	ePTarget = (ePTarget and not eUTarget)
	-- register the needed events
	if (eAuras) then self:RegisterBucketEvent("UNIT_AURA", 0.1, "Bucket_UNIT_AURA") end
	if (ePTarget) then self:RegisterEvent("PLAYER_TARGET_CHANGED") end
	if (eUTarget) then self:RegisterEvent("UNIT_TARGET") end
	if (ePFocus) then self:RegisterEvent("PLAYER_FOCUS_CHANGED") end
	if (ePet) then self:RegisterEvent("UNIT_PET") end
	if (eParty) then self:RegisterEvent("PARTY_MEMBERS_CHANGED") end
	if (eCombat) then
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	end
end -- UpdateEventListeners()

function AuraHUD:AddWindow()
	local n = #self.windows + 1
	local wdb = cloneTable(self.db.profile.windowDefaults, true)
	self.db.profile.windows[n] = wdb
	self.windows[n] = Window(wdb)
	self:UpdateOptionsTable()
end -- AddWindow()

function AuraHUD:RemoveWindow(window)
	local wpos,t
	repeat
		wpos,w = next(self.windows, wpos)
	until (not w or w == window)
	if (wpos and self.db.profile.windows[wpos] == window.db) then
		if (wpos == 1 and #self.windows == 1) then
			self:Print("Can't remove the last window; disable the addon instead")
		else
			tremove(self.db.profile.windows, wpos)
			tremove(self.windows, wpos)
			self:UpdateOptionsTable()
			return true
		end
	end
	return false
end -- RemoveWindow()

function AuraHUD:AreWindowsLocked()
	return self.windowsLocked
end -- AreWindowsLocked()

function AuraHUD:UnlockWindows()
	self.windowsLocked = false
	for _,window in ipairs(self.windows) do
		window:Unlock()
	end
	self:UpdateCommandTable()
end -- UnlockWindows()

function AuraHUD:LockWindows()
	self.windowsLocked = true
	for _,window in ipairs(self.windows) do
		window:Lock()
	end
	self:UpdateCommandTable()
end -- LockWindows()


--[[ MENU METHODS ]]--

function AuraHUD:GetCommandTable()
	if (not self.commandTable) then
		self.commandTable = {
			type = "group",
			handler = self,
			args = {
				config = {
					type = "execute",
					name = "Configure",
					desc = "Open configuration panel",
					func = function() AceConfigDialog:Open("AuraHUD Setup") end,
					order = 1
				},
				disable = {
					type = "execute",
					name = "Disable AuraHUD",
					func = "Disable",
					order = 2
				},
				enable = {
					type = "execute",
					name = "Enable AuraHUD",
					func = "Enable",
					order = 3
				},
				lock = {
					type = "execute",
					name = "Lock windows",
					func = "LockWindows",
					order = 4
				},
				unlock = {
					type = "execute",
					name = "Unlock windows",
					desc = "When unlocked, the windows can be moved by dragging",
					func = "UnlockWindows",
					order = 5
				}
			}
		}
	end
	self.commandTable.args.disable.disabled = not self:IsEnabled()
	self.commandTable.args.disable.hidden = not self:IsEnabled()
	self.commandTable.args.enable.disabled = self:IsEnabled()
	self.commandTable.args.enable.hidden = self:IsEnabled()
	self.commandTable.args.unlock.disabled = not self:AreWindowsLocked()
	self.commandTable.args.unlock.hidden = not self:AreWindowsLocked()
	self.commandTable.args.lock.disabled = self:AreWindowsLocked()
	self.commandTable.args.lock.hidden = self:AreWindowsLocked()
	return self.commandTable
end -- GetCommandTable()

function AuraHUD:UpdateCommandTable()
	self:GetCommandTable()
	AceConfigRegistry:NotifyChange("AuraHUD")
end -- UpdateCommandTable()


function AuraHUD:GetConfigOption(i)
	if (i[1]=="enabled") then
		return self:IsEnabled()
	elseif (i[1]=="locked") then
		return self:AreWindowsLocked()
	end
	self:DebugCall("GetConfigOption",i)
end -- GetConfigOption()

function AuraHUD:SetConfigOption(i, v1, v2, v3, v4)
	if (i[1]=="enabled") then
		if (v1) then
			self:Enable()
		else
			self:Disable()
		end
	elseif (i[1]=="locked") then
		if (v1) then
			self:LockWindows()
		else
			self:UnlockWindows()
		end
	else
		self:DebugCall("SetConfigOption", i, v1, v2, v3, v4)
	end
end -- SetConfigOption()

function AuraHUD:GetOptionsTable()
	if (not self.optionsTable) then
		self.optionsTable = {
			type = "group",
			handler = self,
			get = "GetConfigOption",
			set = "SetConfigOption",
			args = {
				enabled = {
					type = "toggle",
					name = "AddOn Enabled",
					desc = "AuraHUD enabled and running",
					order = 11
				},
				locked = {
					type = "toggle",
					name = "Windows Locked",
					desc = "When unlocked, windows may be moved by dragging",
					order = 12
				},
				do_newWindow = {
					type = "execute",
					name = "Add Window",
					func = "AddWindow",
					order = 13
				}
			}
		}
	end
	self.optionsTable.args.locked.disabled = not self:IsEnabled()
	self.optionsTable.args.do_newWindow.disabled = not self:IsEnabled()
	if (self.windows) then
		for n,window in ipairs(self.windows) do
			self.optionsTable.args["window"..n] = window:GetOptionsTable(DB_WINDOW_OPTIONS, DB_TRACKER_OPTIONS)
			self.optionsTable.args["window"..n].order = 20 + n
		end
	end
	local n = ((self.windows and #self.windows) or 0) + 1
	while (self.optionsTable.args["window"..n]) do
		self.optionsTable.args["window"..n] = nil
		n = n + 1
	end
	return self.optionsTable
end -- GetOptionsTable()

function AuraHUD:UpdateOptionsTable()
	self:GetOptionsTable()
	AceConfigRegistry:NotifyChange("AuraHUD Setup")
end -- UpdateOptionsTable()
