assert(LibStub, "Auracle requires LibStub.")
local LIB_AceAddon = LibStub("AceAddon-3.0") or error("Auracle: Required library AceAddon-3.0 not found")
Auracle = LIB_AceAddon:NewAddon("Auracle", "AceConsole-3.0", "AceEvent-3.0", "AceBucket-3.0")
local Auracle = Auracle

local LIB_AceLocale = LibStub("AceLocale-3.0") or error("Auracle: Required library AceLocale-3.0 not found")
local L = LIB_AceLocale:GetLocale("Auracle")


--[[ DECLARATIONS ]]--

-- GLOBALS: LibStub Auracle UIParent GameFontNormal

-- constants

local MAINHAND = GetInventorySlotInfo("MainHandSlot")
local OFFHAND = GetInventorySlotInfo("SecondaryHandSlot")
local MAX_SPELLID = 105000 -- 73190 were defined as of 2010-01-23

-- classes

local WindowStyle,  DB_DEFAULT_WINDOWSTYLE,  DB_VALID_WINDOWSTYLE
local TrackerStyle, DB_DEFAULT_TRACKERSTYLE, DB_VALID_TRACKERSTYLE
local Window,       DB_DEFAULT_WINDOW,       DB_VALID_WINDOW
local Tracker --,   DB_DEFAULT_TRACKER,      DB_VALID_TRACKER

-- API function upvalues

local API_GetActiveTalentGroup = GetActiveSpecGroup
local API_GetCurrentResolution = GetCurrentResolution
local API_GetItemInfo = GetItemInfo
local API_GetNumPartyMembers = GetNumSubgroupMembers
local API_GetNumRaidMembers = GetNumGroupMembers
local API_GetNumShapeshiftForms = GetNumShapeshiftForms
local API_GetScreenResolutions = GetScreenResolutions
local API_GetShapeshiftForm = GetShapeshiftForm
local API_GetShapeshiftFormInfo = GetShapeshiftFormInfo
local API_GetSpellInfo = GetSpellInfo
local API_GetTime = GetTime
local API_GetWeaponEnchantInfo = GetWeaponEnchantInfo
local API_InCombatLockdown = InCombatLockdown
local API_IsInInstance = IsInInstance
local API_UnitAura = UnitAura
local API_UnitClassification = UnitClassification
local API_UnitExists = UnitExists
local API_UnitIsEnemy = UnitIsEnemy
local API_UnitIsFriend = UnitIsFriend
local API_UnitPlayerControlled = UnitPlayerControlled
local _G = _G

-- library references

local LIB_AceDB
local LIB_AceDBOptions
local LIB_AceConfig
local LIB_AceConfigDialog
local LIB_AceConfigCmd
local LIB_AceConfigRegistry
local LIB_AceTimer
local LIB_LibDataBroker
local LIB_LibDualSpec
--local LIB_LibUnitID
--local LIB_LibUnitAura
--local LIB_LibButtonFacade

-- options tables

local commandTable = { type="group", handler=Auracle, args={} }
local optionsTable = { type="group", handler=Auracle, childGroups="tab", args={} }
local blizOptionsTable = { type="group", handler=Auracle, args={} }
local blizOptionsFrame


--[[ UTILITY FUNCTIONS ]]--

do
	local flag = {}

	function Auracle:__cloneTable(tbl, cloneV, cloneK)
		assert(not flag[tbl], "Auracle:__cloneTable(): cannot deep-clone a table that contains a reference to itself")
		flag[tbl] = 1
		local newtbl = {}
		for k,v in pairs(tbl) do
			if (cloneK and type(k)=="table") then k = self:__cloneTable(k, cloneV, cloneK) end
			if (cloneV and type(v)=="table") then v = self:__cloneTable(v, cloneV, cloneK) end
			newtbl[k] = v
		end
		flag[tbl] = nil
		return newtbl
	end -- __cloneTable()

end

function Auracle:__windowstyle(class, db_default, db_valid)
	self.__windowstyle = function() error("Auracle: redeclaration of WindowStyle class") end
	WindowStyle = class
	DB_DEFAULT_WINDOWSTYLE = db_default
	DB_VALID_WINDOWSTYLE = db_valid
end -- __windowstyle()

function Auracle:__trackerstyle(class, db_default, db_valid)
	self.__trackerstyle = function() error("Auracle: redeclaration of TrackerStyle class") end
	TrackerStyle = class
	DB_DEFAULT_TRACKERSTYLE = db_default
	DB_VALID_TRACKERSTYLE = db_valid
end -- __trackerstyle()

function Auracle:__window(class, db_default, db_valid)
	self.__window = function() error("Auracle: redeclaration of Window class") end
	Window = class
	DB_DEFAULT_WINDOW = db_default
	DB_VALID_WINDOW = db_valid
end -- __window()

function Auracle:__tracker(class, db_default, db_valid)
	self.__tracker = function() error("Auracle: redeclaration of Tracker class") end
	Tracker = class
--	DB_DEFAULT_TRACKER = db_default
--	DB_VALID_TRACKER = db_valid
	Window:__tracker(class, db_default, db_valid)
end -- __tracker()


--[[ Ace3 EVENT HANDLERS ]]--

function Auracle:OnInitialize()
	-- initialize classes
	if (WindowStyle.Initialize) then WindowStyle:Initialize() end
	if (TrackerStyle.Initialize) then TrackerStyle:Initialize() end
	if (Window.Initialize) then Window:Initialize() end
	if (Tracker.Initialize) then Tracker:Initialize() end
	-- load libraries
	LIB_AceDB = LibStub("AceDB-3.0") or error("Auracle: Required library AceDB-3.0 not found")
	LIB_AceDBOptions = LibStub("AceDBOptions-3.0", true) -- optional
	LIB_AceConfig = LibStub("AceConfig-3.0", true) -- optional
	if (LIB_AceConfig) then
		LIB_AceConfigCmd = LibStub("AceConfigCmd-3.0", true) -- optional
		LIB_AceConfigDialog = LibStub("AceConfigDialog-3.0", true) -- optional
		LIB_AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true) -- optional
	end
	LIB_AceTimer = LibStub("AceTimer-3.0", true) -- optional
	LIB_LibDataBroker = LibStub("LibDataBroker-1.1", true) -- optional
	LIB_LibDualSpec = LibStub("LibDualSpec-1.0", true) -- optional
	-- initialize stored data
	self.db = LIB_AceDB:New("Auracle_DB", { profile = {} })
	if (LIB_LibDualSpec) then
		LIB_LibDualSpec:EnhanceDatabase(self.db, "Auracle")
	end
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
	-- register configuration interface(s)
	if (LIB_AceConfigCmd) then
		LIB_AceConfig:RegisterOptionsTable("Auracle", commandTable, {"auracle"})
	end
	if (LIB_AceConfigDialog) then
		LIB_AceConfig:RegisterOptionsTable("Auracle Setup", optionsTable)
		LIB_AceConfig:RegisterOptionsTable("Auracle Blizzard Setup", blizOptionsTable)
		blizOptionsFrame = LIB_AceConfigDialog:AddToBlizOptions("Auracle Blizzard Setup", "Auracle")
	end
	if (LIB_LibDataBroker) then
		-- register LDB launcher
		LIB_LibDataBroker:NewDataObject("Auracle", {
			type = "launcher",
			icon = "Interface\\Icons\\Spell_Holy_AuraMastery",
			OnClick = function(frame, button)
				if (button == "RightButton") then
					self:OpenOptionsWindow()
				else -- LeftButton or some other screwy argument
					if (self:IsOnline()) then
						self:Print(L.LDB_MSG_DISABLED)
						self:Disable()
					else
						self:Enable()
						self:Print(L.LDB_MSG_ENABLED)
					end
				end
			end,
			OnTooltipShow = function(tt)
				--[[ how to make this update when clicked?
				if (self:IsOnline()) then
					tt:AddLine(L.LDB_STAT_ENABLED)
				else
					tt:AddLine(L.LDB_STAT_DISABLED)
				end
				--]]
				tt:AddLine("Auracle")
				tt:AddLine(L.LDB_LEFTCLICK)
				tt:AddLine(L.LDB_RIGHTCLICK)
			end,
		})
	end
end -- OnInitialize()

local firstrun = true

function Auracle:OnEnable()
	if (firstrun and self.db.profile.disabled) then
		self:Disable()
	else
		self.db.profile.disabled = false
		self:Startup()
	end
	firstrun = nil
end -- OnEnable()

function Auracle:OnDisable()
	-- AceEvent handles unregistering events (the equivalent of self:UnregisterAllEvents())
	self.db.profile.disabled = true
	self:Shutdown()
	self:UpdateConfig()
end -- OnDisable()

function Auracle:OnProfileChanged()
	if (self:IsOnline()) then
		self:Startup() -- this calls :Shutdown() to clean up
	end
end -- OnProfileChanged()


--[[ WoW EVENT HANDLERS ]]--

function Auracle:PET_BATTLE_OPENING_DONE()
	self:Shutdown()
	self:Disable()
	self:RegisterEvent("PET_BATTLE_CLOSE")
end -- PET_BATTLE_OPENING_DONE()

function Auracle:PET_BATTLE_CLOSE()
	self:Enable()
	self:Startup()
end-- PET_BATTLE_CLOSE()

function Auracle:ACTIVE_TALENT_GROUP_CHANGED()
	self.plrSpec = API_GetActiveTalentGroup()
	self:DispatchPlayerStatus()
end -- ACTIVE_TALENT_GROUP_CHANGED()

function Auracle:PARTY_MEMBERS_CHANGED()
	if ((API_GetNumRaidMembers()) > 0) then -- includes player
		self.plrGroup = "raid"
	elseif ((API_GetNumPartyMembers()) > 0) then -- excludes player
		self.plrGroup = "party"
	else
		self.plrGroup = "solo"
	end
	self:DispatchPlayerStatus()
end -- PARTY_MEMBERS_CHANGED()

function Auracle:PLAYER_ENTERING_WORLD()
	self.plrInstance = select(2, API_IsInInstance())
	self:DispatchPlayerStatus()
end -- PLAYER_ENTERING_WORLD()

function Auracle:PLAYER_FOCUS_CHANGED()
	self:UpdateUnitIdentity("focus")
	self:UpdateUnitIdentity("focustarget")
end -- PLAYER_FOCUS_CHANGED()

function Auracle:PLAYER_REGEN_DISABLED()
	self.plrCombat = true
	self:DispatchPlayerStatus()
end -- PLAYER_REGEN_DISABLED()

function Auracle:PLAYER_REGEN_ENABLED()
	self.plrCombat = false
	self:DispatchPlayerStatus()
end -- PLAYER_REGEN_ENABLED()

function Auracle:PLAYER_TARGET_CHANGED()
	self:UpdateUnitIdentity("target")
	self:UpdateUnitIdentity("targettarget")
end -- PLAYER_TARGET_CHANGED()

function Auracle:UNIT_AURA(event, unit)
	self:UpdateUnitAuras(unit)
end -- UNIT_AURA()

function Auracle:UNIT_INVENTORY_CHANGED(event, unit)
	if (unit == "player") then
		self:UpdateUnitWeaponBuffs("player")
	end
end -- UNIT_INVENTORY_CHANGED()

function Auracle:UNIT_PET(event, unit)
	if (unit == "player") then
		self:UpdateUnitIdentity("pet")
		self:UpdateUnitIdentity("pettarget")
	end
end -- UNIT_PET()

function Auracle:UNIT_PORTRAIT_UPDATE(event, unit)
	-- this an UPDATE_FLOATING_CHAT_WINDOWS seem to be the only events that fire when the user changes screen resolutiosn :X
	if (unit == "player") then
		self:UpdateScreenResolution()
	end
end -- UNIT_PORTRAIT_UPDATE()

function Auracle:UNIT_TARGET(event, unit)
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

function Auracle:UPDATE_SHAPESHIFT_FORM()
	local f = API_GetShapeshiftForm()
	local maxform = API_GetNumShapeshiftForms()
	if (type(f) ~= "number" or f < 1 or f > maxform) then
		self.plrForm = L.HUMANOID
	else
		self.plrForm = select(2, API_GetShapeshiftFormInfo(f)) or L.UNKNOWN_FORM
	end
	self:DispatchPlayerStatus()
end -- UPDATE_SHAPESHIFT_FORM()

function Auracle:UPDATE_SHAPESHIFT_FORMS()
	self:UpdatePlayerStatus()
	self:UpdateEventListeners()
	Window:UpdateFormOptions()
	self:UpdateConfig()
end -- UPDATE_SHAPESHIFT_FORMS()


--[[ AceBucket EVENT HANDLERS ]]--

function Auracle:Bucket_UNIT_AURA(units)
	for unit,count in pairs(units) do
		if (count > 0) then
			self:UpdateUnitAuras(unit)
		end
	end
end -- Bucket_UNIT_AURA()

function Auracle:Bucket_UNIT_INVENTORY_CHANGED(units)
	if (units.player) then
		self:UpdateUnitWeaponBuffs("player")
	end
end -- Bucket_UNIT_INVENTORY_CHANGED()


--[[ UNIT, AURA & WEAPON BUFF UPDATE METHODS ]]--

function Auracle:UpdateUnitIdentity(unit)
	if (API_UnitExists(unit)) then
		-- check unit type and reaction
		local tgtType,tgtReact = "pc","neutral"
		if (not API_UnitPlayerControlled(unit)) then
			tgtType = API_UnitClassification(unit)
		end
		if (API_UnitIsEnemy("player",unit)) then
			tgtReact = "hostile"
		elseif (API_UnitIsFriend("player",unit)) then
			tgtReact = "friendly"
		end
		-- update window visibility
		local vis = false
		for _,window in ipairs(self.windows) do
			if (window.db.unit == unit) then
				vis = window:SetUnitStatus(true, tgtType, tgtReact) or vis
			end
		end
		-- if at least one window that tracks this unit is visible, update auras and weapon buffs
		if (vis) then
			self:UpdateUnitAuras(unit)
			self:UpdateUnitWeaponBuffs(unit)
		end
	else
		-- update window visibility and reset trackers
		for _,window in ipairs(self.windows) do
			if (window.db.unit == unit) then
				window:SetUnitStatus(false)
				window:ResetTrackerState()
			end
		end
	end
end -- UpdateUnitIdentity()

function Auracle:UpdateUnitAuras(unit)
	local ipairs = ipairs
	local now = API_GetTime()
	local index, totalBuffs, totalDebuffs, origin
	local name, icon, count, atype, duration, expires, caster, stealable
	-- reset window states
	for _,window in ipairs(self.windows) do
		if (window.db.unit == unit) then
			window:BeginAuraUpdate(now)
		end
	end
	-- parse buffs
	index = 1
	name,icon,count,atype,duration,expires,caster,stealable = API_UnitAura(unit, index, "HELPFUL")
	origin = ((caster == "player" or caster == "pet" or caster == "vehicle") and "mine") or "others"
	while (name) do
		for _,window in ipairs(self.windows) do
			if (window.db.unit == unit) then
				window:UpdateBuff(now,index,name,icon,count,atype,duration,expires,origin,stealable)
			end
		end
		index = index + 1
		name,icon,count,atype,duration,expires,caster,stealable = API_UnitAura(unit, index, "HELPFUL")
		origin = ((caster == "player" or caster == "pet" or caster == "vehicle") and "mine") or "others"
	end
	totalBuffs = index - 1
	-- parse debuffs
	index = 1
	name,icon,count,atype,duration,expires,caster,stealable = API_UnitAura(unit, index, "HARMFUL")
	origin = ((caster == "player" or caster == "pet" or caster == "vehicle") and "mine") or "others"
	while (name) do
		for _,window in ipairs(self.windows) do
			if (window.db.unit == unit) then
				window:UpdateDebuff(now,index,name,icon,count,atype,duration,expires,origin,stealable)
			end
		end
		index = index + 1
		name,icon,count,atype,duration,expires,caster,stealable = API_UnitAura(unit, index, "HARMFUL")
		origin = ((caster == "player" or caster == "pet" or caster == "vehicle") and "mine") or "others"
	end
	totalDebuffs = index - 1
	-- update windows
	for _,window in ipairs(self.windows) do
		if (window.db.unit == unit) then
			window:EndAuraUpdate(now, totalBuffs, totalDebuffs)
		end
	end
end -- UpdateUnitAuras()

do
	local tooltip_left = {}
	local tooltip_right = {}
	local tooltip_rev = {}

	local function tooltip_left__index(t,k)
		t[k] = _G["Auracle_Tooltip"..tooltip_rev[t].."TextLeft"..k]
--[===[@debug@
assert(t[k], "failed to fetch tooltip "..tooltip_rev[t].." textleft "..k)
--@end-debug@]===]
		return t[k]
	end -- tooltip_left__index()

	local function tooltip_right__index(t,k)
		t[k] = _G["Auracle_Tooltip"..tooltip_rev[t].."TextRight"..k]
--[===[@debug@
assert(t[k], "failed to fetch tooltip "..tooltip_rev[t].." textright "..k)
--@end-debug@]===]
		return t[k]
	end -- tooltip_right__index()

	local function tooltip_cache__index(t,k)
		-- create the tooltip
		t[k] = CreateFrame("GameTooltip", "Auracle_Tooltip"..k)
		t[k]:SetOwner(UIParent, "ANCHOR_NONE")
		-- create the left/right text line caches for this tooltip
		tooltip_left[k] = setmetatable({}, { __index = tooltip_left__index })
		tooltip_rev[tooltip_left[k]] = k
		tooltip_right[k] = setmetatable({}, { __index = tooltip_right__index })
		tooltip_rev[tooltip_right[k]] = k
		-- pre-generate all the text lines (on both sides)
		for i = 1,30 do
			tooltip_left[k][i] = t[k]:CreateFontString("Auracle_Tooltip"..k.."TextLeft"..i, nil, "GameTooltipText")
			tooltip_left[k][i]:SetFontObject(GameFontNormal)
			tooltip_right[k][i] = t[k]:CreateFontString("Auracle_Tooltip"..k.."TextRight"..i, nil, "GameTooltipText")
			tooltip_right[k][i]:SetFontObject(GameFontNormal)
			t[k]:AddFontStrings(tooltip_left[k][i], tooltip_right[k][i])
		end
		return t[k]
	end -- tooltip_cache__index()

	local tooltip_cache = setmetatable({}, { __index = tooltip_cache__index })

	--[[
	this method for guessing weapon buff icons is based on Shefki's version in Pitbull4 (no general license to copy; All Rights Reserved)
	on 2010-01-19 ckknight (Pitbull4 project manager) granted an MIT license for this routine only
	my version adds an initial lookup in case there's a spell with the same exact name, and a more easily configurable maximum spellID
	--]]

	local function weaponbuff_icon_cache__index(t,k)
		if (not k) then return end
		-- try the search key itself as a spell name first, maybe we get lucky
		local name,_,icon = API_GetSpellInfo(k)
		if (not icon) then
			for spellID = 1 , MAX_SPELLID do
				name,_,icon = API_GetSpellInfo(spellID)
				if (name and name:find(k)) then
					break
				end
			end
		end
		-- if we still came up with nil, store false so we don't search again later
		t[k] = icon or false
		return t[k]
	end -- weaponbuff_icon_cache__index()

	local weaponbuff_icon_cache = setmetatable({}, { __index = weaponbuff_icon_cache__index })

	--[[ END Pitbull4-inspired code ]]

	local duration_unit_seconds = setmetatable({}, { __index = function() return 1 end })

	for abbr in ITEM_ENCHANT_TIME_LEFT_DAYS:gmatch( "[^%%](%a+%.?)") do duration_unit_seconds[abbr] = 86400 end
	for abbr in ITEM_ENCHANT_TIME_LEFT_HOURS:gmatch("[^%%](%a+%.?)") do duration_unit_seconds[abbr] = 3600 end
	for abbr in ITEM_ENCHANT_TIME_LEFT_MIN:gmatch(  "[^%%](%a+%.?)") do duration_unit_seconds[abbr] = 60 end
	for abbr in ITEM_ENCHANT_TIME_LEFT_SEC:gmatch(  "[^%%](%a+%.?)") do duration_unit_seconds[abbr] = 1 end


	--[[
	this method for getting weapon buff names is inspired by Kitjan's NeedToKnow.DetermineTempEnchantFromTooltip in NeedToKnow 2.8.6 (licensed under GPLv3)
	my version has been restructured and optimized somewhat, but uses the same basic algorithm (2010-01-19)
	--]]

	function Auracle:GetWeaponBuffDetails(slot) -- return name,rank,icon,duration
		if (slot ~= MAINHAND and slot ~= OFFHAND) then
			return
		end
		-- we can't query weapon buffs directly, because there's no such API call (lazy lazy, Blizzard!)
		-- we also don't want to search for specific text in the current tooltip, because then we'd have to hardcode (and localize) every possible name
		-- instead, we compare the current tooltip to the item's base tooltip, looking for any new green lines, which must be weapon buffs
		local ttCur,ttBase = tooltip_cache[0],tooltip_cache[1]
--[===[@debug@
assert(ttCur, "failed to generate utility tooltip 0")
assert(ttBase, "failed to generate utility tooltip 1")
--@end-debug@]===]
		ttCur:ClearLines()
		ttCur:SetInventoryItem("player", slot)
		local itemName,itemLink = ttCur:GetItem()
		if (not itemLink) then
			return
		end
		ttBase:ClearLines()
		ttBase:SetHyperlink(itemLink)
		-- look for green lines on the current tooltip that aren't in the base item tooltip
		local ttCurL,ttBaseL = tooltip_left[0],tooltip_left[1]
		local iCur,iBase = 1,1
		local xCur,xBase = ttCur:NumLines(),ttBase:NumLines()
		local _,r,g,b,name,rank,duration,durationUnit,icon
		-- find each green line in the current tooltip
		while (iCur <= xCur) do
			r,g,b = ttCurL[iCur]:GetTextColor()
			if (r == 0 and g ~= 0 and b == 0) then
				name = ttCurL[iCur]:GetText()
				-- find the next green line in the base tooltip
				while (iBase <= xBase) do
					r,g,b = ttBaseL[iBase]:GetTextColor()
					if (r == 0 and g ~= 0 and b == 0) then
						break
					end
					iBase = iBase + 1
				end
				-- if there are no more green lines, or the next green line was different, it's a hit
				if (iBase > xBase or name ~= ttBaseL[iBase]:GetText()) then
					-- if there is a rank or duration at the end of the string, extract them
					_,duration,durationUnit = name:match("^(.+) %((%d+) ([^)]+)%)$")
					if (duration) then
						name = _
						duration = duration * duration_unit_seconds[durationUnit]
					end
					_,rank = name:match("^(.+) ([%dIVX]+)$") -- include roman numerals, just in case
					if (rank) then
						name = _
					end
					-- if we can't find an appropriate spell icon, just use the item
					icon = weaponbuff_icon_cache[name]
					if (not icon) then
						_,_,_,_,_,_,_,_,_,icon,_ = API_GetItemInfo(itemLink)
					end
					return name,rank,icon,duration
				end
				iCur = iCur + 1
				iBase = iBase + 1
			else
				iCur = iCur + 1
			end
		end
	end -- GetWeaponBuffDetails()

	--[[ END NeedToKnow-inspired code ]]
end

function Auracle:UpdateUnitWeaponBuffs(unit)
	-- weapon buffs are only supported for the player
	if (unit ~= "player") then
		return
	end
	local now = API_GetTime()
	local totalWeaponBuffs = 0
	local _, name, rank, icon, count, duration, expires
	local name2, rank2, icon2, count2, duration2, expires2
	-- reset window states
	for _,window in ipairs(self.windows) do
		if (window.db.unit == unit) then
			window:BeginWeaponBuffUpdate(now)
		end
	end
	-- parse weapon buffs
	-- GetWeaponEnchantInfo() doesn't actually give us the name or rank (lazy lazy, blizzard), just the existance (nil or 1), duration and stacks
	name,duration,count,name2,duration2,count2 = API_GetWeaponEnchantInfo()
	-- mainhand
	if (name) then
		name,rank,icon,_ = self:GetWeaponBuffDetails(MAINHAND)
		if (duration) then
			duration = duration / 1000
			expires = now + duration
		elseif (_) then
			duration = _
			expires = now + duration
		end
		for _,window in ipairs(self.windows) do
			if (window.db.unit == "player") then
				window:UpdateWeaponBuff(now,MAINHAND,name,rank,icon,count,nil,duration,expires,"mine",nil)
			end
		end
		totalWeaponBuffs = totalWeaponBuffs + 1
	end
	-- offhand
	if (name2) then
		name2,rank2,icon2,_ = self:GetWeaponBuffDetails(OFFHAND)
		if (duration2) then
			duration2 = duration2 / 1000
			expires2 = now + duration2
		elseif (_) then
			duration2 = _
			expires2 = now + duration2
		end
		for _,window in ipairs(self.windows) do
			if (window.db.unit == "player") then
				window:UpdateWeaponBuff(now,OFFHAND,name2,rank2,icon2,count2,nil,duration2,expires2,"mine",nil)
			end
		end
		totalWeaponBuffs = totalWeaponBuffs + 1
	end
	-- update windows
	for _,window in ipairs(self.windows) do
		if (window.db.unit == unit) then
			window:EndWeaponBuffUpdate(now, totalWeaponBuffs)
		end
	end
end -- UpdateUnitWeaponBuffs()

local function timer_update_weaponbuffs()
	-- because AceTimer only allows one arg to the callback, and I don't like embedding libraries,
	-- and technically this function needs two args (Auracle,"player")
	return Auracle:UpdateUnitWeaponBuffs("player")
end -- timer_update_weaponbuffs()


--[[ SITUATION UPDATE METHODS ]]--

function Auracle:UpdateScreenResolution()
	local w,h = strsplit("x", (select(API_GetCurrentResolution(), API_GetScreenResolutions())))
	w = tonumber(w)
	h = tonumber(h)
	if (h ~= self.screenHeight or w ~= self.screenWidth) then
		self.screenWidth = w
		self.screenHeight = h
		if (type(self.windowStyles) == "table") then
			for name,ws in pairs(self.windowStyles) do
				ws:Apply(nil, "Backdrop")
				ws:Apply(nil, "Layout")
			end
		end
		if (type(self.trackerStyles) == "table") then
			for name,ts in pairs(self.trackerStyles) do
				ts:Apply(nil, "Backdrop")
			end
		end
	end
end -- UpdateScreenResolution()

function Auracle:UpdatePlayerStatus(window)
	-- determine player's spec, instance, group, combat and form status
	self.plrSpec = API_GetActiveTalentGroup()
	self.plrInstance = select(2, API_IsInInstance())
	if ((API_GetNumRaidMembers()) > 0) then -- includes player
		self.plrGroup = "raid"
	elseif ((API_GetNumPartyMembers()) > 0) then -- excludes player
		self.plrGroup = "party"
	else
		self.plrGroup = "solo"
	end
	self.plrCombat = ((API_InCombatLockdown()) and true) or false
	local f = API_GetShapeshiftForm()
	local maxform = API_GetNumShapeshiftForms()
	if (type(f) ~= "number" or f < 1 or f > maxform) then
		self.plrForm = L.HUMANOID
	else
		self.plrForm = select(2, API_GetShapeshiftFormInfo(f)) or L.UNKNOWN_FORM
	end
	-- update window(s)
	self:DispatchPlayerStatus(window)
end -- UpdatePlayerStatus()

do
	local units = {}
	function Auracle:DispatchPlayerStatus(window)
		-- update windows and flag units of windows that appear
		if (window) then
			if (window:SetPlayerStatus(self.plrSpec, self.plrInstance, self.plrGroup, self.plrCombat, self.plrForm)) then
				units[window.db.unit] = true
			end
		else
			for _,window in ipairs(self.windows) do
				if (window:SetPlayerStatus(self.plrSpec, self.plrInstance, self.plrGroup, self.plrCombat, self.plrForm)) then
					units[window.db.unit] = true
				end
			end
		end
		-- update auras as necessary
		for unit,_ in pairs(units) do
			self:UpdateUnitAuras(unit)
		end
		wipe(units)
	end -- DispatchPlayerStatus()
end


--[[ CONFIG METHODS ]]--

function Auracle:Startup()
	-- make sure everything was cleaned up from before..
	self:Shutdown()
	-- initialize addon
	self.online = true
	self.screenWidth = 1024
	self.screenHeight = 768
	self.windowStyles = {}
	self.windowStyleOptions = {}
	self.trackerStyles = {}
	self.trackerStyleOptions = {}
	self.windows = {}
	self.windowsLocked = true
	self.plrSpec = 1
	self.plrInstance = "none"
	self.plrGroup = "solo"
	self.plrCombat = false
	self.plrForm = L.HUMANOID
	-- update old database versions
	--self:ConvertDataStore(self.db.profile)
	self:UpdateSavedVars(self.db.profile)
	-- initialize objects
	for name,wsdb in pairs(self.db.profile.windowStyles) do
		self.windowStyles[name] = WindowStyle(wsdb)
		self.windowStyleOptions[name] = name
	end
	for name,tsdb in pairs(self.db.profile.trackerStyles) do
		self.trackerStyles[name] = TrackerStyle(tsdb)
		self.trackerStyleOptions[name] = name
	end
	for n,wdb in ipairs(self.db.profile.windows) do
		self.windows[n] = Window(wdb)
	end
	-- initialize state
	self:UpdateScreenResolution()
	self:UpdatePlayerStatus()
	self:UpdateEventListeners()
	for n,window in ipairs(self.windows) do
		self:UpdateUnitIdentity(window.db.unit)
	end
	-- initialize configuration options
	Window:UpdateFormOptions()
	self:UpdateConfig()
	-- schedule timer to re-scan weapon buffs, since durations aren't available at first login
	LIB_AceTimer:ScheduleTimer(timer_update_weaponbuffs, 1)
end -- Startup()

function Auracle:Shutdown()
	self.online = nil
	-- recycle objects
	if (type(self.windows) == "table") then
		for n,w in ipairs(self.windows) do
			w:Destroy()
		end
	end
	if (type(self.trackerStyles) == "table") then
		for name,ts in pairs(self.trackerStyles) do
			ts:Destroy()
		end
	end
	if (type(self.windowStyles) == "table") then
		for name,ws in pairs(self.windowStyles) do
			ws:Destroy()
		end
	end
	-- clean up addon
	self.screenWidth = nil
	self.screenHeight = nil
	self.windowStyles = nil
	self.windowStyleOptions = nil
	self.trackerStyles = nil
	self.trackerStyleOptions = nil
	self.windows = nil
	self.windowsLocked = nil
	self.plrSpec = nil
	self.plrInstance = nil
	self.plrGroup = nil
	self.plrCombat = nil
	self.plrForm = nil
end -- Shutdown()

function Auracle:UpdateSavedVars(dbProfile)
	local version = dbProfile.version or 0
	local newVersion = 09080201

	-- update windowStyles
	if (type(dbProfile.windowStyles) == "table") then
		for name,wsdb in pairs(dbProfile.windowStyles) do
			if (type(wsdb) == "table") then
				newVersion = max(WindowStyle:UpdateSavedVars(version, wsdb), newVersion)
			else
				dbProfile.windowStyles[name] = nil
			end
		end
	else
		dbProfile.windowStyles = {}
	end

	-- update trackerStyles
	if (type(dbProfile.trackerStyles) == "table") then
		for name,tsdb in pairs(dbProfile.trackerStyles) do
			if (type(tsdb) == "table") then
				newVersion = max(TrackerStyle:UpdateSavedVars(version, tsdb), newVersion)
			else
				dbProfile.trackerStyles[name] = nil
			end
		end
	else
		dbProfile.trackerStyles = {}
	end

	-- update windows
	local newWindows = {}
	if (type(dbProfile.windows) == "table") then
		for n,wdb in ipairs(dbProfile.windows) do
			if (type(wdb) == "table") then
				newVersion = max(Window:UpdateSavedVars(version, wdb), newVersion)
				newWindows[#newWindows+1] = wdb
			end
		end
	end
	dbProfile.windows = newWindows

	-- validate windowStyles
	for name,wsdb in pairs(dbProfile.windowStyles) do
		self:ValidateSavedVars(wsdb, DB_DEFAULT_WINDOWSTYLE, DB_VALID_WINDOWSTYLE)
		if (name ~= wsdb.name) then
			dbProfile.windowStyles[name] = nil
		end
	end
	if (not dbProfile.windowStyles[DB_DEFAULT_WINDOWSTYLE.name]) then
		dbProfile.windowStyles[DB_DEFAULT_WINDOWSTYLE.name] = self:__cloneTable(DB_DEFAULT_WINDOWSTYLE, true)
	end

	-- validate trackerStyles
	for name,tsdb in pairs(dbProfile.trackerStyles) do
		self:ValidateSavedVars(tsdb, DB_DEFAULT_TRACKERSTYLE, DB_VALID_TRACKERSTYLE)
		if (name ~= tsdb.name) then
			dbProfile.trackerStyles[name] = nil
		end
	end
	if (not dbProfile.trackerStyles[DB_DEFAULT_TRACKERSTYLE.name]) then
		dbProfile.trackerStyles[DB_DEFAULT_TRACKERSTYLE.name] = self:__cloneTable(DB_DEFAULT_TRACKERSTYLE, true)
	end

	-- validate windows
	for n,wdb in ipairs(dbProfile.windows) do
		self:ValidateSavedVars(wdb, DB_DEFAULT_WINDOW, DB_VALID_WINDOW)
	end
	if (not dbProfile.windows[1]) then
		dbProfile.windows[1] = self:__cloneTable(DB_DEFAULT_WINDOW, true)
	end

	-- store version tag
	dbProfile.version = newVersion
end -- UpdateSavedVars()

function Auracle:ValidateSavedVars(db, default, valid)
	if (type(db) == "table" and type(default) == "table" and type(valid) == "table") then
		local ok
		for k,v in pairs(valid) do
			ok = true
			if (db[k] == nil) then
				ok = false
			elseif (type(valid[k]) == "table") then
				if (type(db[k]) == "table") then
					self:ValidateSavedVars(db[k], default[k], valid[k])
				else
					ok = false
				end
			elseif (type(valid[k]) == "function") then
				ok = (valid[k])(db[k])
			elseif (type(valid[k]) == "string") then
				ok = (type(db[k]) == valid[k])
			end
			if (not ok) then
				if (type(default[k]) == "table") then
					db[k] = self:__cloneTable(default[k], true)
				else
					db[k] = default[k]
				end
			end
		end
	end
end -- ValidateSavedVars()

function Auracle:UpdateEventListeners()
	-- clear them all and set the ones we always need
	self:UnregisterAllEvents()
	self:RegisterEvent("UNIT_PORTRAIT_UPDATE")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
	-- determine which listeners we need according to current settings
	local ePTarget,eUTarget,ePFocus,ePet,eSpec,eWorld,eParty,eCombat,eForm,eAuras,eWeaponBuffs
	local form,unit,vis
	local maxform = API_GetNumShapeshiftForms()
	for _,window in ipairs(self.windows) do
		-- based on window.unit
		unit = window.db.unit
		if (unit == "target") then
			ePTarget = true
		elseif (unit == "targettarget") then
			eUTarget = true
		elseif (unit == "pet") then
			ePet = true
		elseif (unit == "pettarget") then
			ePet = true
			eUTarget = true
		elseif (unit == "focus") then
			ePFocus = true
		elseif (unit == "focustarget") then
			ePFocus = true
			eUTarget = true
		end
		-- based on window.visibility
		if (not eSpec) then
			vis = window.db.visibility.plrSpec
			eSpec = (vis[1] ~= vis[2])
		end
		if (not eWorld) then
			vis = window.db.visibility.plrInstance
			eWorld = (vis.none ~= vis.pvp or vis.none ~= vis.arena or vis.none ~= vis.party or vis.none ~= vis.raid)
		end
		if (not eParty) then
			vis = window.db.visibility.plrGroup
			eParty = (vis.solo ~= vis.party or vis.solo ~= vis.raid)
		end
		if (not eCombat) then
			vis = window.db.visibility.plrCombat
			eCombat = (vis[false] ~= vis[true])
		end
		if (not eForm) then
			vis = window.db.visibility.plrForm
			for f = 1,maxform do
				form = select(2, API_GetShapeshiftFormInfo(f)) or L.UNKNOWN_FORM
				if ((not vis[form]) ~= (not vis[L.HUMANOID])) then
					eForm = true
					break
				end
			end
		end
		-- based on window.trackers
		for _,tracker in ipairs(window.trackers) do
			if (eAuras and eWeaponBuffs) then
				break
			end
			if (tracker.db.auratype == "weaponbuff") then
				eWeaponBuffs = true
			else
				eAuras = true
			end
		end
	end
	ePTarget = (ePTarget and not eUTarget)
	-- register the needed events
	if (ePTarget) then self:RegisterEvent("PLAYER_TARGET_CHANGED") end
	if (eUTarget) then self:RegisterEvent("UNIT_TARGET") end
	if (ePFocus) then self:RegisterEvent("PLAYER_FOCUS_CHANGED") end
	if (ePet) then self:RegisterEvent("UNIT_PET") end
	if (eSpec) then self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED") end
	if (eWorld) then self:RegisterEvent("PLAYER_ENTERING_WORLD") end
	if (eParty) then self:RegisterEvent("PARTY_MEMBERS_CHANGED") end
	if (eCombat) then
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	end
	if (eForm) then self:RegisterEvent("UPDATE_SHAPESHIFT_FORM") end
--	if (eAuras) then self:RegisterBucketEvent("UNIT_AURA", 0.1, "Bucket_UNIT_AURA") end
	if (eAuras) then self:RegisterEvent("UNIT_AURA") end
--	if (eWeaponBuffs) then self:RegisterEvent("UNIT_INVENTORY_CHANGED") end
	if (eWeaponBuffs) then self:RegisterBucketEvent("UNIT_INVENTORY_CHANGED", 0.25, "Bucket_UNIT_INVENTORY_CHANGED") end
	self:RegisterEvent("PET_BATTLE_CLOSE")
	self:RegisterEvent("PET_BATTLE_OPENING_DONE")

end -- UpdateEventListeners()

function Auracle:GetWindowPosition(window)
	for n,w in ipairs(self.windows) do
		if (w == window) then
			return n
		end
	end
	return nil
end -- GetWindowPosition()

function Auracle:AddWindow()
	local n = #self.windows + 1
	local wdb = self:__cloneTable(DB_DEFAULT_WINDOW, true)
	self.db.profile.windows[n] = wdb
	local window = Window(wdb)
	self.windows[n] = window
	if (not self:AreWindowsLocked()) then
		window:Unlock()
	end
	self:UpdateConfig()
	self:UpdateEventListeners()
	self:UpdatePlayerStatus()
	self:UpdateUnitAuras(wdb.unit)
end -- AddWindow()

function Auracle:RemoveWindow(window)
	local wpos = self:GetWindowPosition(window)
	if (wpos and self.db.profile.windows[wpos] == window.db) then
		if (wpos == 1 and #self.windows == 1) then
			self:Print(L.ERR_REMOVE_LAST_WINDOW)
		else
			tremove(self.db.profile.windows, wpos)
			tremove(self.windows, wpos)
			self:UpdateConfig()
			self:UpdateEventListeners()
			return true
		end
	end
	return false
end -- RemoveWindow()

function Auracle:IsOnline()
	return self.online
end -- IsOnline()

function Auracle:AreWindowsLocked()
	return self.windowsLocked
end -- AreWindowsLocked()

function Auracle:UnlockWindows()
	self.windowsLocked = false
	for _,window in ipairs(self.windows) do
		window:Unlock()
	end
	self:UpdateCommandTable()
end -- UnlockWindows()

function Auracle:LockWindows()
	self.windowsLocked = true
	for _,window in ipairs(self.windows) do
		window:Lock()
	end
	self:UpdateCommandTable()
end -- LockWindows()

function Auracle:RenameWindowStyle(ws, name)
	name = strtrim(name)
	if (ws.db.name == L.DEFAULT or name == "" or self.windowStyles[name]) then
		return false
	end
	self.db.profile.windowStyles[ws.db.name] = nil
	self.db.profile.windowStyles[name] = ws.db
	self.windowStyles[ws.db.name] = nil
	self.windowStyles[name] = ws
	self.windowStyleOptions[ws.db.name] = nil
	self.windowStyleOptions[name] = name
	ws.db.name = name
	for n,window in ipairs(self.windows) do
		if (window.style == ws) then
			window.db.style = name
		end
	end
	self:UpdateConfig()
end -- RenameWindowStyle()

function Auracle:CopyWindowStyle(ws)
	if (not (ws and ws.db.name and self.windowStyles[ws.db.name] == ws)) then
		return false
	end
	local c = 1
	local name = L.FMT_COPY_OF .. " " .. ws.db.name
	while (self.windowStyles[name]) do
		c = c + 1
		name = format(L["FMT_COPY_%d_OF"], c) .. " " .. ws.db.name
	end
	local wdb = self:__cloneTable(ws.db, true)
	wdb.name = name
	self.db.profile.windowStyles[name] = wdb
	local obj = WindowStyle(wdb)
	self.windowStyles[name] = obj
	self.windowStyleOptions[name] = name
	self:UpdateConfig()
	return true
end -- CopyWindowStyle()

function Auracle:RemoveWindowStyle(ws)
	if (not (ws and ws.db.name and ws.db.name ~= L.DEFAULT and self.windowStyles[ws.db.name] == ws)) then
		return false
	end
	for n,window in ipairs(self.windows) do
		if (window.style == ws) then
			window.db.style = L.DEFAULT
			window.style = self.windowStyles.Default
			window.style:Apply(window)
		end
	end
	self.windowStyleOptions[ws.db.name] = nil
	self.windowStyles[ws.db.name] = nil
	self.db.profile.windowStyles[ws.db.name] = nil
	ws:Destroy()
	self:UpdateConfig()
	return true
end -- RemoveWindowStyle()

function Auracle:RenameTrackerStyle(ts, name)
	name = strtrim(name)
	if (ts.db.name == L.DEFAULT or name == "" or self.trackerStyles[name]) then
		return false
	end
	self.db.profile.trackerStyles[ts.db.name] = nil
	self.db.profile.trackerStyles[name] = ts.db
	self.trackerStyles[ts.db.name] = nil
	self.trackerStyles[name] = ts
	self.trackerStyleOptions[ts.db.name] = nil
	self.trackerStyleOptions[name] = name
	ts.db.name = name
	for n,window in ipairs(self.windows) do
		for m,tracker in ipairs(window.trackers) do
			if (tracker.style == ts) then
				tracker.db.style = name
			end
		end
	end
	self:UpdateConfig()
end -- RenameTrackerStyle()

function Auracle:CopyTrackerStyle(ts)
	if (not (ts and ts.db.name and self.trackerStyles[ts.db.name] == ts)) then
		return false
	end
	local c = 1
	local name = L.FMT_COPY_OF .. " " .. ts.db.name
	while (self.trackerStyles[name]) do
		c = c + 1
		name = format(L["FMT_COPY_%d_OF"], c) .. " " .. ts.db.name
	end
	local tdb = self:__cloneTable(ts.db, true)
	tdb.name = name
	self.db.profile.trackerStyles[name] = tdb
	local obj = TrackerStyle(tdb)
	self.trackerStyles[name] = obj
	self.trackerStyleOptions[name] = name
	self:UpdateConfig()
	return true
end -- CopyTrackerStyle()

function Auracle:RemoveTrackerStyle(ts)
	if (not (ts and ts.db.name and ts.db.name ~= L.DEFAULT and self.trackerStyles[ts.db.name] == ts)) then
		return false
	end
	for n,window in ipairs(self.windows) do
		for m,tracker in ipairs(window.trackers) do
			if (tracker.style == ts) then
				tracker.db.style = L.DEFAULT
				tracker.style = self.trackerStyles.Default
				tracker.style:Apply(tracker)
			end
		end
	end
	self.trackerStyleOptions[ts.db.name] = nil
	self.trackerStyles[ts.db.name] = nil
	self.db.profile.trackerStyles[ts.db.name] = nil
	ts:Destroy()
	self:UpdateConfig()
	return true
end -- RemoveWindowStyle()


--[[ MENU METHODS ]]--

function Auracle:UpdateConfig()
	self:UpdateCommandTable()
	self:UpdateOptionsTable()
	self:UpdateBlizOptions()
end -- UpdateConfig()

function Auracle:UpdateCommandTable()
	local args = commandTable.args
	if (not next(args)) then
		args = {
			config = {
				type = "execute",
				name = L.CONFIGURE,
				desc = L.DESC_CMD_CONFIGURE,
				func = "OpenOptionsWindow",
				order = 1
			},
			enable = {
				type = "execute",
				name = L.ENABLE_ADDON,
				func = "Enable",
				order = 2
			},
			disable = {
				type = "execute",
				name = L.DISABLE_ADDON,
				func = "Disable",
				order = 2
			}
		}
		commandTable.args = args
	end
	local online = self:IsOnline()
	args.disable.disabled = not online
	args.disable.hidden = not online
	args.enable.disabled = online
	args.enable.hidden = online
	if (LIB_AceConfigRegistry) then
		LIB_AceConfigRegistry:NotifyChange("Auracle")
	end
end -- UpdateCommandTable()

function Auracle:UpdateOptionsTable()
	local args = optionsTable.args
	if (not next(args)) then
		args = {
			general = {
				type = "group",
				name = L.GENERAL,
				order = 1,
				args = {
					enabled = {
						type = "toggle",
						name = L.ADDON_ENABLED,
						width = "full",
						get = "IsOnline",
						set = function(i,v) if (v) then Auracle:Enable() else Auracle:Disable() end end,
						order = 10
					},
					locked = {
						type = "toggle",
						name = L.WINDOWS_LOCKED,
						desc = L.DESC_OPT_WINDOWS_LOCKED,
						width = "full",
						get = "AreWindowsLocked",
						set = function(i,v) if (v) then Auracle:LockWindows() else Auracle:UnlockWindows() end end,
						order = 11
					}
				}
			},
			windowStyles = {
				type = "group",
				name = L.WINDOW_STYLES,
				childGroups = "tree",
				order = 2,
				args = {}
			},
			trackerStyles = {
				type = "group",
				name = L.TRACKER_STYLES,
				childGroups = "tree",
				order = 3,
				args = {}
			},
			windows = {
				type = "group",
				name = L.WINDOWS,
				childGroups = "tree",
				order = 4,
				args = {
					addWindow = {
						type = "group",
						name = L.LIST_ADD_WINDOW,
						order = -1,
						args = {
							addWindow = {
								type = "execute",
								name = L.ADD_WINDOW,
								func = "AddWindow"
							}
						}
					}
				}
			},
		--	profiles = ...
--[[ TODO
			about = {
				type = "group",
				name = L.ABOUT,
				order = -1,
				args = {
				}
			}
--]]
		}
		if (LIB_AceDBOptions) then
			args.profiles = LIB_AceDBOptions:GetOptionsTable(self.db)
			if (args.profiles and LIB_LibDualSpec) then
				LIB_LibDualSpec:EnhanceOptions(args.profiles, self.db)
			end
		end
		optionsTable.args = args
	end
	local online = self:IsOnline()
	args.general.args.locked.disabled = not online
	args.windowStyles.disabled = not online
	args.trackerStyles.disabled = not online
	args.windows.disabled = not online
	-- populate windowstyle subtables
	wipe(args.windowStyles.args)
	if (self.windowStyles) then
		local i = 0
		for name,ws in pairs(self.windowStyles) do
			i = i + 1
			args.windowStyles.args["ws"..i] = ws:GetOptionsTable()
			if (name == L.DEFAULT) then args.windowStyles.args["ws"..i].order = 1 end
		end
	end
	-- populate trackerstyle subtables
	wipe(args.trackerStyles.args)
	if (self.trackerStyles) then
		local i = 0
		for name,ts in pairs(self.trackerStyles) do
			i = i + 1
			args.trackerStyles.args["ts"..i] = ts:GetOptionsTable()
			if (name == L.DEFAULT) then args.trackerStyles.args["ts"..i].order = 1 end
		end
	end
	-- populate window subtables
	local temp = args.windows.args.addWindow
	wipe(args.windows.args)
	args.windows.args.addWindow = temp
	if (self.windows) then
		for n,window in ipairs(self.windows) do
			args.windows.args["window"..n] = window:GetOptionsTable()
			args.windows.args["window"..n].order = (args.windows.order*10) + n
		end
	end
	if (LIB_AceConfigRegistry) then
		LIB_AceConfigRegistry:NotifyChange("Auracle Setup")
	end
end -- UpdateOptionsTable()

function Auracle:OpenOptionsWindow()
	if (LIB_AceConfigDialog) then
		LIB_AceConfigDialog:Open("Auracle Setup")
	end
end -- OpenOptionsWindow()

function Auracle:SelectOptionsGroup(w, t)
	if (LIB_AceConfigDialog) then
		if (type(w) == "number") then
			if (type(t) == "number") then
				LIB_AceConfigDialog:SelectGroup("Auracle Setup", "windows", "window"..w, "tracker"..t)
			else
				LIB_AceConfigDialog:SelectGroup("Auracle Setup", "windows", "window"..w)
			end
		else
			LIB_AceConfigDialog:SelectGroup("Auracle Setup")
		end
	end
end -- SelectOptionsGroup()

function Auracle:UpdateBlizOptions()
	local args = blizOptionsTable.args
	if (not next(args)) then
		args = {
			enabled = {
				type = "toggle",
				name = L.ADDON_ENABLED,
				get = "IsOnline",
				set = function(i,v)
					if (v) then
						Auracle:Enable()
					else
						Auracle:Disable()
					end
				end,
				order = 1
			},
			configure = {
				type = "execute",
				name = L.OPEN_CONFIGURATION,
				func = "OpenOptionsWindow",
				order = 2
			}
		}
		blizOptionsTable.args = args
	end
	if (LIB_AceConfigRegistry) then
		LIB_AceConfigRegistry:NotifyChange("Auracle Blizzard Setup")
	end
end -- UpdateBlizOptions()


--[[ INIT ]]--

CONFIGMODE_CALLBACKS = CONFIGMODE_CALLBACKS or {}
function CONFIGMODE_CALLBACKS.Auracle(action)
	if (Auracle:IsOnline()) then
		if (action == 'ON') then
			Auracle:UnlockWindows()
		elseif (action == 'OFF') then
			Auracle:LockWindows()
		end
	end
end

