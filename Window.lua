local LibOOP
--@alpha@
LibOOP = LibStub("LibOOP-1.0-alpha",true)
--@end-alpha@
LibOOP = LibOOP or LibStub("LibOOP-1.0") or error("LibOOP not found")
local Window = LibOOP:Class()

--[[ CONSTANTS ]]--

local DB_DEFAULT_WINDOW = {
	label = false,
	style = "Default",
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
		plrStance = {
			Humanoid = false -- backwards logic, so new stances default to visible
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
}
local DB_DEFAULT_TRACKER
local UNLOCKED_BACKDROP = { bgFile="Interface\\Buttons\\WHITE8X8", tile=false, insets={left=0,right=0,top=0,bottom=0} }


--[[ INIT ]]--

local Tracker
function Window:__tracker(class, db_default)
	self.__tracker = nil
	Tracker = class
	DB_DEFAULT_TRACKER = db_default
end

Auracle:__window(Window, DB_DEFAULT_WINDOW)

local objectPool = {}

local API_GetCurrentResolution = GetCurrentResolution
local API_GetNumShapeshiftForms = GetNumShapeshiftForms
local API_GetScreenResolutions = GetScreenResolutions
local API_GetShapeshiftFormInfo = GetShapeshiftFormInfo


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
	window.plrStance = "Humanoid"
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
	for n,tracker in ipairs(self.trackers) do
		tracker:Destroy()
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
	self.plrStance = nil
	self.tgtExists = nil
	self.tgtType = nil
	self.tgtReact = nil
	self.trackersLocked = nil
	self.trackers = nil
	-- add object to the pool for later re-use
	objectPool[self] = true
end -- Destroy()

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

function Window.prototype:SetPlayerStatus(plrSpec, plrInstance, plrGroup, plrCombat, plrStance)
	self.plrSpec = plrSpec
	self.plrInstance = plrInstance
	self.plrGroup = plrGroup
	self.plrCombat = plrCombat
	self.plrStance = plrStance
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
			and not dbvis.plrStance[self.plrStance] -- backwards logic, so new stances default to visible
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
				local m = {}
				for size in string.gmatch(select(API_GetCurrentResolution(), API_GetScreenResolutions()), "[0-9]+") do
					m[#m+1] = size
				end
				local inset = backdrop.insets.left * ((768 / self.uiFrame:GetEffectiveScale()) / m[2])
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
		self.uiFrame:SetBackdropColor(0, 0.75, 0.75, 0.75)
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
		local m = {}
		for size in string.gmatch(select(API_GetCurrentResolution(), API_GetScreenResolutions()), "[0-9]+") do
			m[#m+1] = size
		end
		local factor = ((768 / self.effectiveScale) / m[2])
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
		local m = {}
		for size in string.gmatch(select(API_GetCurrentResolution(), API_GetScreenResolutions()), "[0-9]+") do
			m[#m+1] = size
		end
		local factor = ((768 / self.effectiveScale) / m[2])
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

function Window.prototype:SetTrackerPosition(tracker, x, y)
	-- make sure this is our tracker
	local tpos,t
	repeat
		tpos,t = next(self.trackers, tpos)
		if (not tpos) then
			return false
		end
	until (t == tracker)
	-- sanity check
	assert(self.db.trackers[tpos] == tracker.db)
	-- get style data
	local sdb = self.style.db.layout
	local padding = sdb.padding
	local spacing = sdb.spacing
	if (sdb.noScale) then
		local m = {}
		for size in string.gmatch(select(API_GetCurrentResolution(), API_GetScreenResolutions()), "[0-9]+") do
			m[#m+1] = size
		end
		local factor = ((768 / self.effectiveScale) / m[2])
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
	local tdb = cloneTable(DB_DEFAULT_TRACKER, true)
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

--[[ TODO
function Window.prototype:AddPresetTracker()
end -- AddPresetTracker()
--]]

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


--[[ SHARED OPTIONS TABLE ]]--

local sharedOptions = {
	type = "group",
	name = "",
	inline = true,
	childGroups = "tab",
	args = {
		window = {
			type = "group",
			name = "Window",
			inline = false,
			order = 1,
			args = {
				label = {
					type = "input",
					name = "Label",
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
					name = "Remove Window",
					func = "Remove",
					order = 2
				},
				unit = {
					type = "select",
					name = "Watch Unit",
					values = {
						player = "Player",
						target = "Target",
						targettarget = "Target's Target",
						pet = "Pet",
						pettarget = "Pet's Target",
						focus = "Focus",
						focustarget = "Focus' Target"
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
					name = "Window Style",
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
			name = "Visibility",
			inline = false,
			order = 2,
			args = {
				plrSpec = {
					type = "group",
					name = "Show when player is using...",
					inline = true,
					order = 1,
					args = {
						primary = {
							type = "toggle",
							name = "Primary Talents",
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
							name = "Secondary Talents",
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
					name = "Show when player is in...",
					inline = true,
					order = 2,
					args = {
						none = {
							type = "toggle",
							name = "No Instance",
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
							name = "Battleground",
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
							name = "Arena",
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
							name = "Party Instance",
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
							name = "Raid Instance",
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
					name = "Show when player is...",
					inline = true,
					order = 3,
					args = {
						solo = {
							type = "toggle",
							name = "Solo",
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
							name = "In a Party",
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
							name = "In a Raid Group",
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
					name = "Show when player is...",
					inline = true,
					order = 4,
					args = {
						no = {
							type = "toggle",
							name = "Not in Combat",
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
							name = "In Combat",
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
				plrStance = {
					type = "group",
					name = "Show when player is...",
					inline = true,
					order = 5,
					args = {} -- populated in UpdateStanceOptions()
				},
				tgtMissing = {
					type = "toggle",
					name = "Show when unit is Missing",
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
					name = "Show when unit is...",
					inline = true,
					order = 7,
					args = {
						hostile = {
							type = "toggle",
							name = "Hostile",
							get = function(i) return i.handler.db.visibility.tgtReact.hostile end,
							set = function(i,v)
								i.handler.db.visibility.tgtReact.hostile = v
								i.handler:UpdateVisibility()
							end,
							order = 1
						},
						neutral = {
							type = "toggle",
							name = "Neutral",
							get = function(i) return i.handler.db.visibility.tgtReact.neutral end,
							set = function(i,v)
								i.handler.db.visibility.tgtReact.neutral = v
								i.handler:UpdateVisibility()
							end,
							order = 2
						},
						friendly = {
							type = "toggle",
							name = "Friendly",
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
					name = "Show when unit is a(n)...",
					inline = true,
					order = 8,
					args = {
						pc = {
							type = "toggle",
							name = "Player",
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
							name = "Boss",
							get = function(i) return i.handler.db.visibility.tgtType.worldboss end,
							set = function(i,v)
								i.handler.db.visibility.tgtType.worldboss = v
								i.handler:UpdateVisibility()
							end,
							order = 2
						},
						rareelite = {
							type = "toggle",
							name = "Rare Elite NPC",
							get = function(i) return i.handler.db.visibility.tgtType.rareelite end,
							set = function(i,v)
								i.handler.db.visibility.tgtType.rareelite = v
								i.handler:UpdateVisibility()
							end,
							order = 3
						},
						elite = {
							type = "toggle",
							name = "Elite NPC",
							get = function(i) return i.handler.db.visibility.tgtType.elite end,
							set = function(i,v)
								i.handler.db.visibility.tgtType.elite = v
								i.handler:UpdateVisibility()
							end,
							order = 4
						},
						rare = {
							type = "toggle",
							name = "Rare NPC",
							get = function(i) return i.handler.db.visibility.tgtType.rare end,
							set = function(i,v)
								i.handler.db.visibility.tgtType.rare = v
								i.handler:UpdateVisibility()
							end,
							order = 5
						},
						normal = {
							type = "toggle",
							name = "NPC",
							get = function(i) return i.handler.db.visibility.tgtType.normal end,
							set = function(i,v)
								i.handler.db.visibility.tgtType.normal = v
								i.handler:UpdateVisibility()
							end,
							order = 6
						},
						trivial = {
							type = "toggle",
							name = "Gray NPC",
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
			name = "Layout",
			inline = false,
			order = 3,
			args = {
				locked = {
					type = "toggle",
					name = "Trackers Locked",
					desc = "When unlocked, trackers may be rearranged by left-click-dragging",
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
					name = "Trackers per Row",
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


--[[ MENU METHODS ]]--

local sharedOptions_plrStance_get = function(i)
	return not i.handler.db.visibility.plrStance[i[#i]] -- backwards logic, so new stances default to visible
end

local sharedOptions_plrStance_set = function(i,v)
	i.handler.db.visibility.plrStance[i[#i]] = not v -- backwards logic, so new stances default to visible
	Auracle:UpdateEventListeners()
	Auracle:UpdatePlayerStatus(i.handler)
end

function Window:UpdateStanceOptions()
	-- get list of available stances
	local _
	local stances = { [0] = "Humanoid" }
	local numStances = API_GetNumShapeshiftForms()
	for s = 1,numStances do
		_,stances[s],_,_ = API_GetShapeshiftFormInfo(s)
	end
	-- generate toggles for each
	local pSa = sharedOptions.args.visibility.args.plrStance.args
	wipe(pSa)
	for s = 0,numStances do
		pSa[stances[s]] = {
			type = "toggle",
			name = stances[s],
			get = sharedOptions_plrStance_get,
			set = sharedOptions_plrStance_set,
			order = s + 1
		}
	end
end -- UpdateStanceOptions()

function Window.prototype:GetOptionsTable()
	if (not self.optionsTable) then
		self.optionsTable = {
			type = "group",
			handler = self,
			args = {
				addTracker = {
					type = "group",
					name = "|cff7fffff(Add Tracker...)",
					childGroups = "tab",
					order = -1,
					args = {
						addTracker = {
							type = "execute",
							name = "Add Blank Tracker",
							func = "AddTracker",
							order = 1
						}
--[[
						,
						buffType = {
							type = "group",
							name = "Buffs by Type",
							order = 1,
							args = {
								stats = {
									type = "group",
									name = "Stats",
									order = 10,
									args = {
										stats = {
											type = "execute",
											name = "+% Stats",
											desc = "Blessing of Kings",
											width = "full",
											func = "", -- TODO
											order = 100
										},
										mark = {
											type = "execute",
											name = "+ Stats/Armor/Resists",
											desc = "Mark of the Wild, Gift of the Wild",
											width = "full",
											func = "", -- TODO
											order = 101
										},
										agistr = {
											type = "execute",
											name = "+ Agility/Strength",
											desc = "Strength of Earth, Horn of Winter",
											width = "full",
											func = "", -- TODO
											order = 102
										},
										stam = {
											type = "execute",
											name = "+ Stamina",
											desc = "Power Word: Fortitude, Prayer of Fortitude",
											width = "full",
											func = "", -- TODO
											order = 103
										},
										health = {
											type = "execute",
											name = "+ Health",
											desc = "Commanding Shout, Blood Pact",
											width = "full",
											func = "", -- TODO
											order = 104
										},
										intellect = {
											type = "execute",
											name = "+ Intellect",
											desc = "Arcane Intellect, Arcane Brilliance, Fel Intelligence",
											width = "full",
											func = "", -- TODO
											order = 105
										},
										spirit = {
											type = "execute",
											name = "+ Spirit",
											desc = "Divine Spirit, Prayer of Spirit, Fel Intelligence",
											width = "full",
											func = "", -- TODO
											order = 106
										},
									}
								},
								general = {
									type = "group",
									name = "General",
									order = 11,
									args = {
										dmg = {
											type = "execute",
											name = "+% Damage",
											desc = "Ferocious Inspiration, (Sanctified) Retribution Aura",
											width = "full",
											func = "", -- TODO
											order = 110
										},
										bighaste = {
											type = "execute",
											name = "++ Haste",
											desc = "Bloodlust, Heroism",
											width = "full",
											func = "", -- TODO
											order = 111
										},
										haste = {
											type = "execute",
											name = "+ Haste",
											desc = "(Improved) Moonkin Aura, (Swift) Retribution Aura",
											width = "full",
											func = "", -- TODO
											order = 112
										}
									}
								},
								physical = {
									type = "group",
									name = "Physical",
									order = 12,
									args = {
										pctAP = {
											type = "execute",
											name = "+% Attack Power",
											desc = "Abominable Might, Trueshot Aura, Unleashed Rage",
											width = "full",
											func = "", -- TODO
											order = 120
										},
										AP = {
											type = "execute",
											name = "+ Attack Power",
											desc = "Battle Shout, Blessing of Might, Furious Howl",
											width = "full",
											func = "", -- TODO
											order = 121
										},
										meleeHaste = {
											type = "execute",
											name = "+ Melee Haste",
											desc = "Improved Icy Talons, Windfury Totem",
											width = "full",
											func = "", -- TODO
											order = 122
										},
										meleeCrit = {
											type = "execute",
											name = "+ Melee Crit",
											desc = "Leader of the Pack, Rampage",
											width = "full",
											func = "", -- TODO
											order = 123
										},
									}
								},
								caster = {
									type = "group",
									name = "Caster",
									order = 13,
									args = {
										SP = {
											type = "execute",
											name = "+ Spell Power",
											desc = "Focus Magic, (Improved) Divine Spirit, (Improved) Prayer of Spirit, Flametongue Totem, Totem of Wrath, Demonic Pact",
											width = "full",
											func = "", -- TODO
											order = 130
										},
										spellHaste = {
											type = "execute",
											name = "+ Spell Haste",
											desc = "Wrath of Air Totem",
											width = "full",
											func = "", -- TODO
											order = 131
										},
										spellCrit = {
											type = "execute",
											name = "+ Spell Crit",
											desc = "Moonkin Aura, Elemental Oath",
											width = "full",
											func = "", -- TODO
											order = 132
										},
									}
								},
								tank = {
									type = "group",
									name = "Tank",
									order = 14,
									args = {
										armor = {
											type = "execute",
											name = "+% Armor",
											desc = "Inspiration, Ancestral Fortitude",
											width = "full",
											func = "", -- TODO
											order = 140
										},
										dmgTaken = {
											type = "execute",
											name = "-% Damage Taken",
											desc = "Grace, Blessing of Sanctuary, Greater Blessing of Sanctuary, Divine Protection, Barkskin",
											width = "full",
											func = "", -- TODO
											order = 141
										},
									}
								},
								
							}
						},
						debuffType = {
							type = "group",
							name = "Debuffs by Type",
							order = 3,
							args = {
								dps = {
									type = "group",
									name = "DPS",
									order = 30,
									args = {
										disarm = {
											type = "execute",
											name = "Disarm",
											desc = "Disarm, Dismantle, Chimera Shot - Scorpid, Snatch", -- Psychic Horror
											width = "full",
											func = "", -- TODO
											order = 300
										},
										AP = {
											type = "execute",
											name = "- AP",
											desc = "Demoralizing Shout, Demoralizing Roar, Demoralizing Screech, Curse of Weakness",
											width = "full",
											func = "", -- TODO
											order = 301
										},
										meleeHaste = {
											type = "execute",
											name = "- Melee Haste",
											desc = "Frost Fever, Infected Wounds, Thunder Clap, Waylay, Riposte", -- (Judgements of the Just)Judgement of *
											width = "full",
											func = "", -- TODO
											order = 302
										},
										meleeRangedHit = {
											type = "execute",
											name = "- Melee/Ranged Hit",
											desc = "Insect Swarm, Scorpid Sting",
											width = "full",
											func = "", -- TODO
											order = 303
										},
										rangedHaste = {
											type = "execute",
											name = "- Ranged Haste",
											desc = "Slow, Waylay",
											width = "full",
											func = "", -- TODO
											order = 304
										},
										spellHaste = {
											type = "execute",
											name = "- Spell Haste",
											desc = "Curse of Tongues, Slow, Mind-numbing Poison, Lava Breath",
											width = "full",
											func = "", -- TODO
											order = 305
										},
									}
								},
								physicalTank = {
									type = "group",
									name = "Physical Tank",
									order = 31,
									args = {
										bigArmor = {
											type = "execute",
											name = "-- Armor",
											desc = "Acid Spit, Expose Armor, Sunder Armor",
											width = "full",
											func = "", -- TODO
											order = 310
										},
										armor = {
											type = "execute",
											name = "- Armor",
											desc = "Faerie Fire, Faerie Fire (Feral), Sting, Curse of Recklessness",
											width = "full",
											func = "", -- TODO
											order = 311
										},
										physicalDmgTaken = {
											type = "execute",
											name = "+% Physical Damage Taken",
											desc = "Blood Frenzy, Blood Poisoning",
											width = "full",
											func = "", -- TODO
											order = 312
										},
										bleedDmgTaken = {
											type = "execute",
											name = "+% Bleed Damage Taken",
											desc = "Mangle - Bear, Mangle - Cat, Trauma",
											width = "full",
											func = "", -- TODO
											order = 313
										},
										critTaken = {
											type = "execute",
											name = "+ Crit Taken",
											desc = "Heart of the Crusader, Totem of Wrath", -- Master Poisoner
											width = "full",
											func = "", -- TODO
											order = 314
										},
									}
								},
								casterTank = {
									type = "group",
									name = "Caster Tank",
									order = 32,
									args = {
										resists = {
											type = "execute",
											name = "- Resists",
											desc = "Curse of the Elements",
											width = "full",
											func = "", -- TODO
											order = 320
										},
										spellDmgTaken = {
											type = "execute",
											name = "+% Spell Damage Taken",
											desc = "Ebon Plague, Earth and Moon, Curse of the Elements",
											width = "full",
											func = "", -- TODO
											order = 321
										},
										diseaseDmgTaken = {
											type = "execute",
											name = "+% Disease Damage Taken",
											desc = "Crypt Fever, Ebon Plague",
											width = "full",
											func = "", -- TODO
											order = 322
										},
										spellHitTaken = {
											type = "execute",
											name = "+ Spell Hit Taken",
											desc = "(Improved) Faerie Fire, Misery",
											width = "full",
											func = "", -- TODO
											order = 323
										},
										critTaken = {
											type = "execute",
											name = "+ Crit Taken",
											desc = "Heart of the Crusader, Totem of Wrath",
											width = "full",
											func = "", -- TODO
											order = 324
										},
										spellCritTaken = {
											type = "execute",
											name = "+ Spell Crit Taken",
											desc = "Improved Scorch, Winter's Chill",
											width = "full",
											func = "", -- TODO
											order = 325
										},
									}
								}
							}
						}
--]]
					}
				}
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

