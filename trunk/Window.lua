-- define and register class definition
local LibOOP = LibStub("LibOOP-0.2")
local Window = LibOOP:Class()
AuraHUD:RegisterWindow(Window)

-- define class pointers and one-shot linkers
local Tracker
function Window:RegisterTracker(class) Tracker = class; self.RegisterTracker = nil; end

-- initialize local runtime data
local windowPool = {}


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


--[[  EVENT HANDLERS ]]--

local function Window_OnMouseDown(self, button)
	if (button == "LeftButton") then
		self.AuraHUD_window:StartMoving()
	end
end -- Window_OnMouseDown()

local function Window_OnMouseUp(self, button)
	if (button == "LeftButton") then
		self.AuraHUD_window:StopMoving()
	end
end -- Window_OnMouseUp()

local function Window_OnHide(self)
	self.AuraHUD_window:StopMoving()
end -- Window_OnHide()


--[[ CONSTRUCT & DESTRUCT ]]--

function Window:New(db)
	-- re-use a window from the pool, or create a new one
	local window = next(windowPool)
	if (not window) then
		window = self:Super("New")
		window.uiFrame = CreateFrame("Frame", nil, UIParent)
		window.uiFrame.AuraHUD_window = window
		window.uiFrame:SetFrameStrata("LOW")
		window.uiFrame:EnableMouse(true) -- intercepts clicks, causes OnMouseDown,OnMouseUp
		window.uiFrame:SetClampedToScreen(true) -- so WoW polices position, no matter how it changes (StartMoving,SetPoint,etc)
		window.uiFrame:SetMovable(true) -- allows StartMoving
	end
	windowPool[window] = nil
	
	-- (re?)initialize window
	window.db = db
	window.backdrop = { insets={} }
	window.locked = true
	window.moving = false
	window.trackersLocked = true
	window.trackers = {}
	window.plrGroup = "solo"
	window.plrCombat = "no"
	window.tgtType = "none"
	window.tgtReact = "neutral"
	
	-- (re?)initialize frame
	window.uiFrame:Show()
	window.uiFrame:SetPoint("TOPLEFT", UIParent,"TOPLEFT", db.pos.x, db.pos.y) -- TODO pref anchor points
	
	-- create and initialize trackers
	local tracker
	for n,tdb in ipairs(db.trackers) do
		tracker = Tracker(tdb, window, window.uiFrame)
		window.trackers[n] = tracker
	end
	
	-- (re?)apply preferences
	window:UpdateLayout()
	window:UpdateAppearance()
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
	self.backdrop = nil
	self.locked = nil
	self.moving = nil
	self.trackersLocked = nil
	self.trackers = nil
	self.plrGroup = nil
	self.plrCombat = nil
	self.tgtType = nil
	self.tgtReact = nil
	-- add window to the pool for later re-use
	windowPool[self] = true
end -- Destroy()

function Window.prototype:Remove()
	if (AuraHUD:RemoveWindow(self)) then
		self:Destroy()
	end
end -- Remove()


--[[ AURA UPDATE METHODS ]]--

function Window.prototype:UpdateUnitAuras()
	AuraHUD:UpdateUnitAuras(self.db.unit)
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

function Window.prototype:SetPlayerStatus(plrGroup, plrCombat)
	self.plrGroup = plrGroup
	self.plrCombat = plrCombat
	return self:UpdateVisibility()
end -- SetPlayerStatus()

function Window.prototype:SetUnitStatus(tgtType, tgtReact)
	self.tgtType = tgtType
	self.tgtReact = tgtReact
	return self:UpdateVisibility()
end -- SetUnitStatus()


--[[ UI METHODS ]]--

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
	AuraHUD:Print(tag..": "..a.." , "..b.." , "..c.." , "..d.." , "..e)
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


--[[ CONFIG METHODS ]]--

function Window.prototype:IsLocked()
	return self.locked
end -- IsLocked()

function Window.prototype:Unlock()
	self.locked = false
	self.uiFrame:SetScript("OnMouseDown", Window_OnMouseDown)
	self.uiFrame:SetScript("OnMouseUp", Window_OnMouseUp)
	self.uiFrame:SetScript("OnHide", Window_OnHide)
end -- Unlock()

function Window.prototype:Lock()
	self:StopMoving(true)
	self.locked = true
	self.uiFrame:SetScript("OnMouseDown", nil)
	self.uiFrame:SetScript("OnMouseUp", nil)
	self.uiFrame:SetScript("OnHide", nil)
end -- Lock()

function Window.prototype:AddTracker()
	local n = #self.trackers + 1
	local tdb = cloneTable(self.db.trackerDefaults, true)
	self.db.trackers[n] = tdb
	self.trackers[n] = Tracker(tdb, self, self.uiFrame)
	self:UpdateLayout()
	AuraHUD:UpdateOptionsTable()
	AuraHUD:UpdateEventListeners()
end -- AddTracker()

function Window.prototype:RemoveTracker(tracker)
	local tpos,t
	repeat
		tpos,t = next(self.trackers, tpos)
	until (not t or t == tracker)
	if (tpos and self.db.trackers[tpos] == tracker.db) then
		tremove(self.db.trackers, tpos)
		tremove(self.trackers, tpos)
		self:UpdateLayout()
		AuraHUD:UpdateOptionsTable()
		AuraHUD:UpdateEventListeners()
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
end -- UnlockTrackers()

function Window.prototype:LockTrackers()
	self.trackersLocked = true
	for n,tracker in ipairs(self.trackers) do
		tracker:Lock()
	end
end -- LockTrackers()

function Window.prototype:UpdateVisibility()
	local dbvis = self.db.vis
	local nowVis = (
		dbvis.plrGroup[self.plrGroup] and dbvis.plrCombat[self.plrCombat]
		and
		dbvis.tgtType[self.tgtType] and dbvis.tgtReact[self.tgtReact]
	)
	if (nowVis) then
		self.uiFrame:Show()
	else
		self.uiFrame:Hide()
	end
	return nowVis
end -- UpdateVisibility()

function Window.prototype:UpdateAppearance()
	--TODO sizes
	self.backdrop.bgFile = self.db.bg.style
	self.backdrop.tile = self.db.bg.tile
	self.backdrop.tileSize = 16 --self.db.bg.size
	self.backdrop.edgeFile = self.db.border.style
	self.backdrop.edgeSize = 16 --self.db.border.size
	self.backdrop.insets.left = 4 --self.db.border.inset
	self.backdrop.insets.right = 4 --self.db.border.inset
	self.backdrop.insets.top = 4 --self.db.border.inset
	self.backdrop.insets.bottom = 4 --self.db.border.inset
	self.uiFrame:SetBackdrop(self.backdrop)
	self.uiFrame:SetBackdropBorderColor(unpack(self.db.border.color))
	self.uiFrame:SetBackdropColor(unpack(self.db.bg.color))
end -- UpdateAppearance()

function Window.prototype:UpdateLayout()
	-- TODO size
	-- find client's pixel height, if needed
	local uiPixelWidth,uiPixelHeight
	if (self.db.layout.noLayoutScale or self.db.layout.noBorderScale) then
		local m = {}
		for size in string.gmatch(select(GetCurrentResolution(), GetScreenResolutions()), "[0-9]+") do
			m[#m+1] = size
		end
		uiPixelWidth = m[1]
		uiPixelHeight = m[2]
	end
	-- grab pref settings
	local padding = self.db.layout.padding
	local spacing = self.db.layout.spacing
	if (self.db.layout.noLayoutScale) then
		padding = padding * ((768 / self.uiFrame:GetEffectiveScale()) / uiPixelHeight)
		spacing = spacing * ((768 / self.uiFrame:GetEffectiveScale()) / uiPixelHeight)
	end
	local borderSize = 1 --TODO self.db.layout.borderSize
	if (self.db.layout.noBorderScale) then
		borderSize = borderSize * ((768 / self.uiFrame:GetEffectiveScale()) / uiPixelHeight)
	end
	local trackerSize = self.db.layout.trackerSize
	local wrap = self.db.layout.wrap
	local outerSize = trackerSize + (2 * borderSize) + spacing
	
	-- position each tracker
	for n,tracker in ipairs(self.trackers) do
		self:UpdateTrackerLayout(n)
	end
	
	-- calculate total window size (enclosing box of trackers, whose bottom row might not be full)
	local num = #self.trackers
	local cols = max(1, min(num, wrap))
	local rows = max(1, ceil(num / wrap))
	self.uiFrame:SetWidth((padding * 2) + (cols * outerSize) - spacing)
	self.uiFrame:SetHeight((padding * 2) + (rows * outerSize) - spacing)
end -- UpdateLayout()

function Window.prototype:UpdateTrackerLayout(tn)
	-- TODO size
	-- find client's pixel height, if needed
	local uiPixelWidth,uiPixelHeight
	if (self.db.layout.noLayoutScale or self.db.layout.noBorderScale) then
		local m = {}
		for size in string.gmatch(select(GetCurrentResolution(), GetScreenResolutions()), "[0-9]+") do
			m[#m+1] = size
		end
		uiPixelWidth = m[1]
		uiPixelHeight = m[2]
	end
	-- grab pref settings
	local padding = self.db.layout.padding
	local spacing = self.db.layout.spacing
	if (self.db.layout.noLayoutScale) then
		padding = padding * ((768 / self.uiFrame:GetEffectiveScale()) / uiPixelHeight)
		spacing = spacing * ((768 / self.uiFrame:GetEffectiveScale()) / uiPixelHeight)
	end
	local borderSize = 1 --TODO self.db.layout.borderSize
	if (self.db.layout.noBorderScale) then
		borderSize = borderSize * ((768 / self.uiFrame:GetEffectiveScale()) / uiPixelHeight)
	end
	local trackerSize = self.db.layout.trackerSize
	local wrap = self.db.layout.wrap
	local outerSize = trackerSize + (2 * borderSize) + spacing
	
	-- position tracker
	local tracker = self.trackers[tn]
	if (tracker) then
		local x = padding + (floor((tn-1) % wrap) * outerSize)
		local y = padding + (floor((tn-1) / wrap) * outerSize)
		tracker:SetLayout(x, y, borderSize, trackerSize)
	end
end -- UpdateTrackerLayout()

function Window.prototype:SetTrackerPosition(tracker, x, y)
	-- TODO size
	local next = next
	
	-- find client's pixel height, if needed
	local uiPixelWidth,uiPixelHeight
	if (self.db.layout.noLayoutScale or self.db.layout.noBorderScale) then
		local m = {}
		for size in string.gmatch(select(GetCurrentResolution(), GetScreenResolutions()), "[0-9]+") do
			m[#m+1] = size
		end
		uiPixelWidth = m[1]
		uiPixelHeight = m[2]
	end
	-- grab pref settings
	local padding = self.db.layout.padding
	local spacing = self.db.layout.spacing
	if (self.db.layout.noLayoutScale) then
		padding = padding * ((768 / self.uiFrame:GetEffectiveScale()) / uiPixelHeight)
		spacing = spacing * ((768 / self.uiFrame:GetEffectiveScale()) / uiPixelHeight)
	end
	local borderSize = 1 --TODO self.db.layout.borderSize
	if (self.db.layout.noBorderScale) then
		borderSize = borderSize * ((768 / self.uiFrame:GetEffectiveScale()) / uiPixelHeight)
	end
	local trackerSize = self.db.layout.trackerSize
	local wrap = self.db.layout.wrap
	local outerSize = trackerSize + (2 * borderSize) + spacing
	
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
	
	-- calculate total window size
	local num = #self.trackers
	local cols = max(1, min(num, wrap))
	local rows = max(1, ceil(num / wrap))
	
	-- calculate which slot the given coordinates are closest to
	local col = max(1, min(cols, floor(((x - padding) / outerSize) + 0.5 ) + 1))
	local row = max(1, min(rows, floor(((y - padding) / outerSize) + 0.5 ) + 1))
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


--[[ MENU METHODS ]]--

function Window.prototype:GetConfigOption(i, v1, v2, v3, v4)
	-- i[1] == "window#"
	if (i[3] ~= nil) then
		if ((i[2] == "border" or i[2] == "bg") and i[3] == "color") then
			return unpack(self.db[i[2]][i[3]])
		elseif (self.db[i[2]] and self.db[i[2]][i[3]] ~= nil) then
			if (v1 ~= nil) then
				return self.db[i[2]][i[3]][v1]
			end
			return self.db[i[2]][i[3]]
		end
	elseif (i[2] ~= nil) then
		if (i[2] == "locked") then
			return self:AreTrackersLocked()
		elseif (type(self.db[i[2]]) ~= "nil") then
			if (v1 ~= nil) then
				return self.db[i[2]][v1]
			end
			return self.db[i[2]]
		end
	end
	AuraHUD:DebugCall("Window.GetConfigOption", i, v1, v2, v3, v4)
end -- GetConfigOption()

function Window.prototype:SetConfigOption(i, v1, v2, v3, v4)
	-- i[1] == "window#"
	if (i[3] ~= nil) then
		if (i[3] == "color") then
			local c = self.db[i[2]][i[3]]
			c[1],c[2],c[3],c[4] = v1,v2,v3,v4
			self:UpdateAppearance()
		elseif (i[2] == "vis") then
			self.db.vis[i[3]][v1] = v2
			AuraHUD:UpdateEventListeners()
			self:UpdateVisibility()
		elseif (i[2] == "layout") then
			self.db.layout[i[3]] = v1
			self:UpdateLayout()
		else
			self.db[i[2]][i[3]] = v1
			self:UpdateAppearance()
		end
	elseif (i[2] == "label") then
		v1 = strtrim(v1)
		if (v1 == "") then
			v1 = false
		end
		self.db.label = v1
		AuraHUD:UpdateOptionsTable()
	elseif (i[2] == "unit") then
		self.db.unit = v1
		AuraHUD:UpdateEventListeners()
		self:UpdateUnitAuras()
	elseif (i[2] == "locked") then
		if (v1) then
			self:LockTrackers()
		else
			self:UnlockTrackers()
		end
	else
		AuraHUD:DebugCall("Window.SetConfigOption", i, v1, v2, v3, v4)
	end
end -- SetConfigOption()

function Window.prototype:GetOptionsTable(DB_WINDOW_OPTIONS, DB_TRACKER_OPTIONS)
	if (not self.optionsTable) then
		self.optionsTable = {
			type = "group",
			name = "ERR", -- filled in below, in case it changes
			handler = self,
			get = "GetConfigOption",
			set = "SetConfigOption",
			args = {
				label = {
					type = "input",
					name = "Label",
					width = "double",
					order = 11
				},
				do_removeWindow = {
					type = "execute",
					name = "Remove This Window",
					func = "Remove",
					order = 12
				},
				unit = {
					type = "select",
					name = "Track Unit",
					values = DB_WINDOW_OPTIONS.unit,
					order = 13
				},
				locked = {
					type = "toggle",
					name = "Trackers Locked",
					desc = "When unlocked, trackers may be rearranged by dragging",
					order = 14
				},
				do_newTracker = {
					type = "execute",
					name = "Add Tracker",
					func = "AddTracker",
					order = 15
				},
				vis = {
					type = "group",
					name = "Visibility",
					inline = true,
					order = 20,
					args = {
						plrGroup = {
							type = "multiselect",
							name = "Show while...",
							desc = "Group status",
							values = DB_WINDOW_OPTIONS.vis_plrGroup,
							order = 21
						},
						plrCombat = {
							type = "multiselect",
							name = "Show while...",
							desc = "Combat status",
							values = DB_WINDOW_OPTIONS.vis_plrCombat,
							order = 22
						},
						tgtType = {
							type = "multiselect",
							name = "Show while unit...",
							desc = "Unit type",
							values = DB_WINDOW_OPTIONS.vis_tgtType,
							order = 23
						},
						tgtReact = {
							type = "multiselect",
							name = "Show while unit is...",
							desc = "Unit reacton",
							values = DB_WINDOW_OPTIONS.vis_tgtReact,
							order = 24
						}
					}
				},
				border = {
					type = "group",
					name = "Border",
					inline = true,
					order = 30,
					args = {
--[[ TODO
						size = {
							type = "range",
							name = "Width",
							min = 0,
							max = 64,
							step = 1,
							order = 31
						},
						inset = {
							type = "range",
							name = "Inset",
							min = -8,
							max = 64,
							step = 1,
							order = 32
						},
--]]
						color = {
							type = "color",
							name = "Color",
							hasAlpha = true,
							order = 33
						}
					}
				},
				bg = {
					type = "group",
					name = "Background",
					inline = true,
					order = 40,
					args = {
--[[ TODO
						size = {
							type = "range",
							name = "Tile size",
							min = 4,
							max = 64,
							step = 1,
							order = 41
						},
--]]
						color = {
							type = "color",
							name = "Color",
							hasAlpha = true,
							order = 42
						}
					}
				},
				layout = {
					type = "group",
					name = "Layout",
					inline = true,
					order = 50,
					args = {
						noLayoutScale = {
							type = "toggle",
							name = "Don't scale padding or spacing",
							width = "full",
							order = 51
						},
						padding = {
							type = "range",
							name = "Window padding",
							min = -8,
							max = 64,
							step = 1,
							order = 52
						},
						spacing = {
							type = "range",
							name = "Tracker spacing",
							min = 0,
							max = 32,
							step = 1,
							order = 53
						},
						noBorderScale = {
							type = "toggle",
							name = "Don't scale tracker border",
							width = "full",
							order = 54
						},
--[[ TODO
						borderSize = {
							type = "range",
							name = "Tracker border width",
							min = 0,
							max = 64,
							step = 1,
							order = 55
						},
--]]
						trackerSize = {
							type = "range",
							name = "Tracker icon size",
							min = 4,
							max = 64,
							step = 1,
							order = 56
						},
						wrap = {
							type = "range",
							name = "Trackers per row",
							min = 1,
							max = 64,
							step = 1,
							order = 57
						}
					}
				}
			}
		}
	end
	self.optionsTable.name = self.db.label or (strupper(strsub(self.db.unit,1,1)) .. strsub(self.db.unit,2))
	if (self.trackers) then
		for n,tracker in ipairs(self.trackers) do
			self.optionsTable.args["tracker"..n] = tracker:GetOptionsTable(DB_TRACKER_OPTIONS)
			self.optionsTable.args["tracker"..n].order = 60 + n
		end
	end
	local n = ((self.trackers and #self.trackers) or 0) + 1
	while (self.optionsTable.args["tracker"..n]) do
		self.optionsTable.args["tracker"..n] = nil
		n = n + 1
	end
	return self.optionsTable
end -- GetOptionsTable()
