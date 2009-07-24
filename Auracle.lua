Auracle = LibStub("AceAddon-3.0"):NewAddon("Auracle",
	"AceConsole-3.0", "AceEvent-3.0", "AceBucket-3.0")
local Auracle = Auracle

local AceDB
local AceDBOptions
local AceConfig
local AceConfigDialog
local AceConfigCmd
local AceConfigRegistry
local LibDataBroker
--local LibUnitID
--local LibButtonFacade

--[[ CONSTANTS ]]--

local DB_DEFAULT = {
	version = 0,
	windowStyles = {},
	trackerStyles = {},
	windows = {}
}
local DB_DEFAULT_WINDOWSTYLE
local DB_DEFAULT_TRACKERSTYLE
local DB_DEFAULT_WINDOW
local DB_DEFAULT_TRACKER


--[[ INIT ]]--

local WindowStyle
function Auracle:__windowstyle(class, db_default)
	self.__windowstyle = nil
	WindowStyle = class
	DB_DEFAULT_WINDOWSTYLE = db_default
	--DB_DEFAULT.windowStyles.Default = DB_DEFAULT_WINDOWSTYLE
end

local TrackerStyle
function Auracle:__trackerstyle(class, db_default)
	self.__trackerstyle = nil
	TrackerStyle = class
	DB_DEFAULT_TRACKERSTYLE = db_default
	--DB_DEFAULT.trackerStyles.Default = DB_DEFAULT_TRACKERSTYLE
end

local Window
function Auracle:__window(class, db_default)
	self.__window = nil
	Window = class
	DB_DEFAULT_WINDOW = db_default
	--DB_DEFAULT.windows[1] = DB_DEFAULT_WINDOW
end

local Tracker
function Auracle:__tracker(class, db_default)
	self.__tracker = nil
	Tracker = class
	DB_DEFAULT_TRACKER = db_default
	Window:__tracker(class, db_default)
end

local commandTable = { type="group", handler=Auracle, args={} }
local optionsTable = { type="group", handler=Auracle, childGroups="tab", args={} }
local blizOptionsTable = { type="group", handler=Auracle, args={} }
local blizOptionsFrame

local API_GetTime = GetTime
local API_GetNumRaidMembers = GetNumRaidMembers
local API_GetNumPartyMembers = GetNumPartyMembers
local API_InCombatLockdown = InCombatLockdown
local API_IsInInstance = IsInInstance
local API_UnitAura = UnitAura
local API_UnitClassification = UnitClassification
local API_UnitExists = UnitExists
local API_UnitIsEnemy = UnitIsEnemy
local API_UnitIsFriend = UnitIsFriend
local API_UnitPlayerControlled = UnitPlayerControlled


--[[ UTILITY FUNCTIONS ]]--

local cloneTable = false
do
	local flag = {}
	cloneTable = function(tbl, cloneV, cloneK)
		assert(not flag[tbl], "cannot deep-clone table that contains reference to itself")
		flag[tbl] = 1
		local newtbl = {}
		for k,v in pairs(tbl) do
			if (cloneK and type(k)=="table") then k = cloneTable(k, cloneV, cloneK) end
			if (cloneV and type(v)=="table") then v = cloneTable(v, cloneV, cloneK) end
			newtbl[k] = v
		end
		flag[tbl] = nil
		return newtbl
	end -- cloneTable()
end
local __auracle_debug_table = __auracle_debug_table or function() return "" end
local __auracle_debug_array = __auracle_debug_array or function() return "" end
local __auracle_debug_call = __auracle_debug_call or function() end


--[[ Ace3 EVENT HANDLERS ]]--

function Auracle:OnInitialize()
	-- load libraries
	AceDB = LibStub("AceDB-3.0")
	AceDBOptions = LibStub("AceDBOptions-3.0")
	AceConfig = LibStub("AceConfig-3.0")
	AceConfigDialog = LibStub("AceConfigDialog-3.0")
	AceConfigCmd = LibStub("AceConfigCmd-3.0")
	AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
	LibDataBroker = LibStub("LibDataBroker-1.1")
	-- initialize stored data
--Auracle_DB = nil
	self.db = AceDB:New("Auracle_DB", { profile = DB_DEFAULT })
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
	-- register configuration interface(s)
	AceConfig:RegisterOptionsTable("Auracle", commandTable, {"auracle"})
	AceConfig:RegisterOptionsTable("Auracle Setup", optionsTable)
	AceConfig:RegisterOptionsTable("Auracle Blizzard Setup", blizOptionsTable)
	blizOptionsFrame = AceConfigDialog:AddToBlizOptions("Auracle Blizzard Setup", "Auracle")
	-- register LDB launcher
	LibDataBroker:NewDataObject("Auracle", {
		type = "launcher",
		--icon = "Interface\\Icons\\Spell_Arcane_FocusedPower",
		--icon = "Interface\\Icons\\Spell_Holy_SpiritualGuidence",
		icon = "Interface\\Icons\\Spell_Holy_AuraMastery",
		OnClick = function(frame, button)
			if (button == "RightButton") then
				self:OpenOptionsWindow()
			else -- LeftButton or some other screwy argument
				if (self:IsEnabled()) then
					self:Print("Disabled.")
					self:Disable()
				else
					self:Enable()
					self:Print("Enabled.")
				end
			end
		end,
		OnTooltipShow = function(tt)
			--[[ how to make this update when clicked?
			if (self:IsEnabled()) then
				tt:AddLine("Auracle |cffffffff(|cff00ff00enabled|cffffffff)")
			else
				tt:AddLine("Auracle |cffffffff(|cffff0000disabled|cffffffff)")
			end
			--]]
			tt:AddLine("Auracle")
			tt:AddLine("|cff7fffffLeft-click|cffffffff to toggle")
			tt:AddLine("|cff7fffffRight-click|cffffffff to open configuration")
		end,
	})
end -- OnInitialize()

function Auracle:OnEnable()
	self:Startup()
	self:UpdateConfig()
end -- OnEnable()

function Auracle:OnDisable()
	-- AceEvent handles unregistering events (the equivalent of self:UnregisterAllEvents())
	self:Shutdown()
	self:UpdateConfig()
end -- OnDisable()

function Auracle:OnProfileChanged()
	if (self:IsEnabled()) then
		self:Shutdown()
		self:Startup()
		self:UpdateConfig()
	end
end -- OnProfileChanged()


--[[ WoW EVENT HANDLERS ]]--

function Auracle:PLAYER_TARGET_CHANGED()
	self:UpdateUnitIdentity("target")
	self:UpdateUnitIdentity("targettarget")
end -- PLAYER_TARGET_CHANGED()

function Auracle:UNIT_TARGET()
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

function Auracle:PLAYER_FOCUS_CHANGED()
	self:UpdateUnitIdentity("focus")
	self:UpdateUnitIdentity("focustarget")
end -- PLAYER_FOCUS_CHANGED()

function Auracle:UNIT_PET(event, unit)
	if (unit == "player") then
		self:UpdateUnitIdentity("pet")
		self:UpdateUnitIdentity("pettarget")
	end
end -- UNIT_PET()

function Auracle:PARTY_MEMBERS_CHANGED()
	-- determine player's group status
	self.plrGroup = "solo"
	if (API_GetNumRaidMembers() > 0) then -- includes player
		self.plrGroup = "raid"
	elseif (API_GetNumPartyMembers() > 0) then -- excludes player
		self.plrGroup = "party"
	end
	-- update windows
	for _,window in ipairs(self.windows) do
		if (window:SetPlayerStatus(self.plrInstance, self.plrGroup, self.plrCombat)) then
			self:UpdateUnitAuras(window.db.unit)
		end
	end
end -- PARTY_MEMBERS_CHANGED()

function Auracle:PLAYER_REGEN_DISABLED()
	self.plrCombat = true
	-- update windows
	for _,window in ipairs(self.windows) do
		if (window:SetPlayerStatus(self.plrInstance, self.plrGroup, self.plrCombat)) then
			self:UpdateUnitAuras(window.db.unit)
		end
	end
end -- PLAYER_REGEN_DISABLED()

function Auracle:PLAYER_REGEN_ENABLED()
	self.plrCombat = false
	-- update windows
	for _,window in ipairs(self.windows) do
		if (window:SetPlayerStatus(self.plrInstance, self.plrGroup, self.plrCombat)) then
			self:UpdateUnitAuras(window.db.unit)
		end
	end
end -- PLAYER_REGEN_ENABLED()

function Auracle:PLAYER_ENTERING_WORLD()
	local _,inst = API_IsInInstance()
	if (inst ~= self.plrInstance) then
		self.plrInstance = inst
		-- update windows
		for _,window in ipairs(self.windows) do
			if (window:SetPlayerStatus(self.plrInstance, self.plrGroup, self.plrCombat)) then
				self:UpdateUnitAuras(window.db.unit)
			end
		end
	end
end -- PLAYER_ENTERING_WORLD()


--[[ AceBucket EVENT HANDLERS ]]--

function Auracle:Bucket_UNIT_AURA(units)
	for unit,count in pairs(units) do
		self:UpdateUnitAuras(unit)
	end
end -- Bucket_UNIT_AURA()


--[[ UNIT & AURA UPDATE METHODS ]]--

function Auracle:UpdateUnitIdentity(unit)
	local ipairs = ipairs
	if (API_UnitExists(unit)) then
		local tgtType,tgtReact = "pc","neutral"
		-- check unit type and reaction
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
		-- if at least one window that tracks this unit is visible, update auras
		if (vis) then
			self:UpdateUnitAuras(unit)
		end
	else
		-- update window visibility and reset trackers
		for _,window in ipairs(self.windows) do
			if (window.db.unit == unit) then
				window:SetUnitStatus(false)
				window:ResetAuraState()
			end
		end
	end
end -- UpdateUnitIdentity()

function Auracle:UpdateUnitAuras(unit)
	local ipairs = ipairs
	local now = API_GetTime()
	local index, totalBuffs, totalDebuffs, origin
	local name, rank, icon, count, atype, duration, expires, caster, stealable
	-- reset window states
	for _,window in ipairs(self.windows) do
		if (window.db.unit == unit) then
			window:BeginAuraUpdate(now)
		end
	end
	-- parse buffs
	index = 1
	name,rank,icon,count,atype,duration,expires,caster,stealable = API_UnitAura(unit, index, "HELPFUL")
	origin = ((caster == "player" or caster == "pet" or caster == "vehicle") and "mine") or "others"
	while (name) do
		for _,window in ipairs(self.windows) do
			if (window.db.unit == unit) then
				window:UpdateBuff(now,index,name,rank,icon,count,atype,duration,expires,origin,stealable)
			end
		end
		index = index + 1
		name,rank,icon,count,atype,duration,expires,caster,stealable = API_UnitAura(unit, index, "HELPFUL")
		origin = ((caster == "player" or caster == "pet" or caster == "vehicle") and "mine") or "others"
	end
	totalBuffs = index - 1
	-- parse debuffs
	index = 1
	name,rank,icon,count,atype,duration,expires,caster,stealable = API_UnitAura(unit, index, "HARMFUL")
	origin = ((caster == "player" or caster == "pet" or caster == "vehicle") and "mine") or "others"
	while (name) do
		for _,window in ipairs(self.windows) do
			if (window.db.unit == unit) then
				window:UpdateDebuff(now,index,name,rank,icon,count,atype,duration,expires,origin,stealable)
			end
		end
		index = index + 1
		name,rank,icon,count,atype,duration,expires,caster,stealable = API_UnitAura(unit, index, "HARMFUL")
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

--[[ SITUATION UPDATE METHODS ]]--

function Auracle:UpdatePlayerStatus()
	-- determine player's group and combat status
	local _
	_,self.plrInstance = API_IsInInstance()
	self.plrGroup = "solo"
	if (API_GetNumRaidMembers() > 0) then -- includes player
		self.plrGroup = "raid"
	elseif (API_GetNumPartyMembers() > 0) then -- excludes player
		self.plrGroup = "party"
	end
	self.plrCombat = (API_InCombatLockdown() and true) or false
	-- update windows
	for _,window in ipairs(self.windows) do
		window:SetPlayerStatus(self.plrInstance, self.plrGroup, self.plrCombat)
	end
end -- UpdatePlayerStatus()


--[[ CONFIG METHODS ]]--

function Auracle:Startup()
	-- initialize addon
	self.windowStyles = {}
	self.windowStyleOptions = {}
	self.trackerStyles = {}
	self.trackerStyleOptions = {}
	self.windows = {}
	self.windowsLocked = true
	self.plrInstance = "none"
	self.plrGroup = "solo"
	self.plrCombat = false
	-- make sure the Default styles exist
	if (not self.db.profile.windowStyles[DB_DEFAULT_WINDOWSTYLE.name]) then
		self.db.profile.windowStyles[DB_DEFAULT_WINDOWSTYLE.name] = cloneTable(DB_DEFAULT_WINDOWSTYLE, true)
	end
	if (not self.db.profile.trackerStyles[DB_DEFAULT_TRACKERSTYLE.name]) then
		self.db.profile.trackerStyles[DB_DEFAULT_TRACKERSTYLE.name] = cloneTable(DB_DEFAULT_TRACKERSTYLE, true)
	end
	-- make sure at least one window exists
	if (not next(self.db.profile.windows)) then
		self.db.profile.windows[1] = cloneTable(DB_DEFAULT_WINDOW, true)
	end
	-- update old database versions
	self:ConvertDataStore(self.db.profile)
	-- initialize objects
	for name,db in pairs(self.db.profile.windowStyles) do
		self.windowStyles[name] = WindowStyle(db)
		self.windowStyleOptions[name] = name
	end
	for name,db in pairs(self.db.profile.trackerStyles) do
		self.trackerStyles[name] = TrackerStyle(db)
		self.trackerStyleOptions[name] = name
	end
	for n,db in ipairs(self.db.profile.windows) do
		self.windows[n] = Window(db)
	end
	-- initialize state
	self:UpdatePlayerStatus()
	self:UpdateEventListeners()
	for n,window in ipairs(self.windows) do
		self:UpdateUnitIdentity(window.db.unit)
	end
end -- Startup()

function Auracle:Shutdown()
	-- recycle objects
	for n,window in ipairs(self.windows) do
		window:Destroy()
	end
	for name,ts in pairs(self.trackerStyles) do
		ts:Destroy()
	end
	for name,ws in pairs(self.windowStyles) do
		ws:Destroy()
	end
	-- clean up addon
	self.windowStyles = nil
	self.windowStyleOptions = nil
	self.trackerStyles = nil
	self.trackerStyleOptions = nil
	self.windows = nil
	self.windowsLocked = nil
	self.plrInstance = nil
	self.plrGroup = nil
	self.plrCombat = nil
end -- Shutdown()

function Auracle:ConvertDataStore(dbProfile)
	if (dbProfile.version < 4) then
		self:Print("Updating saved vars to version 4")
		for _,wsdb in pairs(dbProfile.windowStyles) do
			if (wsdb.background and wsdb.background.texture == "Interface\\ChatFrame\\ChatFrameBackground") then
				wsdb.background.texture = "Interface\\Tooltips\\UI-Tooltip-Background"
			end
		end
		for _,wdb in pairs(dbProfile.windows) do
			-- visibility.plrInstance{}
			if (wdb.visibility and type(wdb.visibility.plrInstance) ~= "table") then
				wdb.visibility.plrInstance = cloneTable(DB_DEFAULT_WINDOW.visibility.plrInstance, true)
			end
			for _,tdb in pairs(wdb.trackers) do
				-- trackOthers => showOthers
				if (tdb.trackOthers ~= nil) then
					tdb.showOthers = tdb.trackOthers
					tdb.trackOthers = nil
				end
				-- trackMine => showMine
				if (tdb.trackMine ~= nil) then
					tdb.showMine = tdb.trackMine
					tdb.trackMine = nil
				end
				-- spiral{} and text{}
				local spiralReverse = tdb.spiralReverse
				if (spiralReverse == nil) then spiralReverse = true end
				local textColor = tdb.textColor or "time"
				local maxTime = tdb.maxTime
				if (maxTime == nil) then maxTime = false end
				local maxTimeMode = "auto"
				if (tdb.autoMaxTime == false) then maxTimeMode = "static" end
				local maxStacks = tdb.maxStacks
				if (maxStacks == nil) then maxStacks = false end
				local maxStacksMode = "auto"
				if (tdb.autoMaxStacks == false) then maxStacksMode = "static" end
				if (type(tdb.spiral) ~= "table") then
					local spiral = {
						mode = tdb.spiral,
						reverse = spiralReverse,
						maxTime = maxTime,
						maxTimeMode = maxTimeMode,
						maxStacks = maxStacks,
						maxStacksMode = maxStacksMode
					}
					tdb.spiral = spiral
				end
				if (type(tdb.text) ~= "table") then
					local text = {
						mode = tdb.text,
						color = textColor,
						maxTime = maxTime,
						maxTimeMode = maxTimeMode,
						maxStacks = maxStacks,
						maxStacksMode = maxStacksMode
					}
					tdb.text = text
				end
				tdb.spiralReverse = nil
				tdb.textColor = nil
				tdb.maxTime = nil
				tdb.autoMaxTime = nil
				tdb.maxStacks = nil
				tdb.autoMaxStacks = nil
				-- icon{}
				local autoIcon = tdb.autoIcon
				if (autoIcon == nil) then autoIcon = true end
				if (type(tdb.icon) ~= "table") then
					local icon = {
						texture = tdb.icon,
						autoIcon = autoIcon
					}
					tdb.icon = icon
				end
				tdb.autoIcon = nil
				-- tooltip{}
				if (type(tdb.tooltip) ~= "table") then
					tdb.tooltip = {
						showMissing = "off",
						showOthers = "off",
						showMine = "off"
					}
				end
			end
		end
		dbProfile.version = 4
	end
	if (dbProfile.version < 6) then
		self:Print("Updating saved vars to version 6")
		local fix
		fix = function(db, def)
			for key,val in pairs(def) do
				if (type(val) == "table") then
					if (type(db[key]) == "table") then
						fix(db[key], val)
					else
						db[key] = cloneTable(val, true)
					end
				elseif (db[key] == nil) then
					db[key] = val
				end
			end
		end
		fix(dbProfile.windowStyles.Default, DB_DEFAULT_WINDOWSTYLE)
		fix(dbProfile.trackerStyles.Default, DB_DEFAULT_TRACKERSTYLE)
		for i = 1,#dbProfile.windows do
			fix(dbProfile.windows[i], DB_DEFAULT_WINDOW)
		end
		dbProfile.version = 6
	end
end -- ConvertDataStore()

function Auracle:UpdateEventListeners()
	-- clear them all
	self:UnregisterAllEvents()
	-- determine which listeners we need according to current settings
	local ePTarget,eUTarget,ePFocus,ePet,eWorld,eParty,eCombat,eAuras
	local u,vI,vG,vC
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
		vI = window.db.visibility.plrInstance
		if (vI.none ~= vI.pvp or vI.none ~= vI.arena or vI.none ~= vI.party or vI.none ~= vI.raid) then
			eWorld = true
		end
		vG = window.db.visibility.plrGroup
		if (vG.solo ~= vG.party or vG.solo ~= vG.raid) then
			eParty = true
		end
		vC = window.db.visibility.plrCombat
		if (vC[false] ~= vC[true]) then
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
	if (eWorld) then self:RegisterEvent("PLAYER_ENTERING_WORLD") end
	if (eParty) then self:RegisterEvent("PARTY_MEMBERS_CHANGED") end
	if (eCombat) then
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	end
end -- UpdateEventListeners()

function Auracle:AddWindow()
	local n = #self.windows + 1
	local wdb = cloneTable(DB_DEFAULT_WINDOW, true)
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
			self:UpdateConfig()
			self:UpdateEventListeners()
			return true
		end
	end
	return false
end -- RemoveWindow()

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
	if (ws.db.name == "Default" or name == "" or self.windowStyles[name]) then
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
	local c,name = 1,"Copy of "..ws.db.name
	while (self.windowStyles[name]) do
		c = c + 1
		name = "Copy ("..c..") of "..ws.db.name
	end
	local wdb = cloneTable(ws.db, true)
	wdb.name = name
	self.db.profile.windowStyles[name] = wdb
	local obj = WindowStyle(wdb)
	self.windowStyles[name] = obj
	self.windowStyleOptions[name] = name
	self:UpdateConfig()
	return true
end -- CopyWindowStyle()

function Auracle:RemoveWindowStyle(ws)
	if (not (ws and ws.db.name and ws.db.name ~= "Default" and self.windowStyles[ws.db.name] == ws)) then
		return false
	end
	for n,window in ipairs(self.windows) do
		if (window.style == ws) then
			window.db.style = "Default"
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
	if (ts.db.name == "Default" or name == "" or self.trackerStyles[name]) then
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
	local c,name = 1,"Copy of "..ts.db.name
	while (self.trackerStyles[name]) do
		c = c + 1
		name = "Copy ("..c..") of "..ts.db.name
	end
	local tdb = cloneTable(ts.db, true)
	tdb.name = name
	self.db.profile.trackerStyles[name] = tdb
	local obj = TrackerStyle(tdb)
	self.trackerStyles[name] = obj
	self.trackerStyleOptions[name] = name
	self:UpdateConfig()
	return true
end -- CopyTrackerStyle()

function Auracle:RemoveTrackerStyle(ts)
	if (not (ts and ts.db.name and ts.db.name ~= "Default" and self.trackerStyles[ts.db.name] == ts)) then
		return false
	end
	for n,window in ipairs(self.windows) do
		for m,tracker in ipairs(window.trackers) do
			if (tracker.style == ts) then
				tracker.db.style = "Default"
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
				name = "Configure",
				desc = "Open configuration panel",
				func = "OpenOptionsWindow",
				order = 1
			},
			enable = {
				type = "execute",
				name = "Enable Auracle",
				func = "Enable",
				order = 2
			},
			disable = {
				type = "execute",
				name = "Disable Auracle",
				func = "Disable",
				order = 2
			}
		}
		commandTable.args = args
	end
	args.disable.disabled = not self:IsEnabled()
	args.disable.hidden = not self:IsEnabled()
	args.enable.disabled = self:IsEnabled()
	args.enable.hidden = self:IsEnabled()
	AceConfigRegistry:NotifyChange("Auracle")
end -- UpdateCommandTable()

function Auracle:UpdateOptionsTable()
	local args = optionsTable.args
	if (not next(args)) then
		args = {
			general = {
				type = "group",
				name = "General",
				order = 1,
				args = {
					enabled = {
						type = "toggle",
						name = "Auracle Enabled",
						width = "full",
						get = "IsEnabled",
						set = function(i,v) if (v) then i.handler:Enable() else i.handler:Disable() end end,
						order = 10
					},
					locked = {
						type = "toggle",
						name = "Windows Locked",
						desc = "When unlocked, windows may be moved by left-click-dragging",
						width = "full",
						get = "AreWindowsLocked",
						set = function(i,v) if (v) then i.handler:LockWindows() else i.handler:UnlockWindows() end end,
						order = 11
					}
				}
			},
			windowStyles = {
				type = "group",
				name = "Window Styles",
				childGroups = "tree",
				order = 2,
				args = {}
			},
			trackerStyles = {
				type = "group",
				name = "Tracker Styles",
				childGroups = "tree",
				order = 3,
				args = {}
			},
			windows = {
				type = "group",
				name = "Windows",
				childGroups = "tree",
				order = 4,
				args = {
					addWindow = {
						type = "group",
						name = "|cff7fffff(Add Window...)",
						order = -1,
						args = {
							addWindow = {
								type = "execute",
								name = "Add Window",
								func = "AddWindow"
							}
						}
					}
				}
			},
			profiles = AceDBOptions:GetOptionsTable(self.db),
--[[ TODO
			about = {
				type = "group",
				name = "About",
				order = -1,
				args = {
				}
			}
--]]
		}
		optionsTable.args = args
	end
	args.general.args.locked.disabled = not self:IsEnabled()
	args.windowStyles.disabled = not self:IsEnabled()
	args.trackerStyles.disabled = not self:IsEnabled()
	args.windows.disabled = not self:IsEnabled()
	-- populate windowstyle subtables
	wipe(args.windowStyles.args)
	if (self.windowStyles) then
		local i = 0
		for name,ws in pairs(self.windowStyles) do
			i = i + 1
			args.windowStyles.args["ws"..i] = ws:GetOptionsTable()
			if (name == "Default") then args.windowStyles.args["ws"..i].order = 1 end
		end
	end
	-- populate trackerstyle subtables
	wipe(args.trackerStyles.args)
	if (self.trackerStyles) then
		local i = 0
		for name,ts in pairs(self.trackerStyles) do
			i = i + 1
			args.trackerStyles.args["ts"..i] = ts:GetOptionsTable()
			if (name == "Default") then args.trackerStyles.args["ts"..i].order = 1 end
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
	AceConfigRegistry:NotifyChange("Auracle Setup")
end -- UpdateOptionsTable()

function Auracle:OpenOptionsWindow()
	AceConfigDialog:Open("Auracle Setup")
end -- OpenOptionsWindow()

function Auracle:UpdateBlizOptions()
	local args = blizOptionsTable.args
	if (not next(args)) then
		args = {
			enabled = {
				type = "toggle",
				name = "Auracle Enabled",
				get = "IsEnabled",
				set = function(i,v) if (v) then Auracle:Enable() else Auracle:Disable() end end,
				order = 1
			},
			configure = {
				type = "execute",
				name = "Open Configuration",
				func = "OpenOptionsWindow",
				order = 2
			}
		}
		blizOptionsTable.args = args
	end
	AceConfigRegistry:NotifyChange("Auracle Blizzard Setup")
end -- UpdateBlizOptions()


--[[ CROSS-INIT ]]--

CONFIGMODE_CALLBACKS = CONFIGMODE_CALLBACKS or {}
function CONFIGMODE_CALLBACKS.Auracle(action)
	if (action == 'ON') then
		Auracle:UnlockWindows()
	elseif (action == 'OFF') then
		Auracle:LockWindows()
	end
end

