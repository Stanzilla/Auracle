local LibOOP
--@alpha@
LibOOP = LibStub("LibOOP-1.0-alpha",true)
--@end-alpha@
LibOOP = LibOOP or LibStub("LibOOP-1.0") or error("LibOOP not found")
local Window = LibOOP:Class()

--[[ CONSTANTS ]]--

local DB_DEFAULT_WINDOW = {
	label = false,
	unit = "target", -- player|target|targettarget|pet|pettarget|focus|focustarget
	style = "Default",
	visibility = {
		plrGroup = {
			solo = true,
			party = true,
			raid = true
		},
		plrCombat = {
			[false] = true,
			[true] = true
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


--[[ INIT ]]--

local Tracker
function Window:__tracker(class, db_default)
	self.__tracker = nil
	Tracker = class
	DB_DEFAULT_TRACKER = db_default
end

Auracle:__window(Window, DB_DEFAULT_WINDOW)

local objectPool = {}


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

local function Window_OnMouseDown(self, button)
	if (button == "LeftButton") then
		self.Auracle_window:StartMoving()
	end
end -- Window_OnMouseDown()

local function Window_OnMouseUp(self, button)
	if (button == "LeftButton") then
		self.Auracle_window:StopMoving()
	end
end -- Window_OnMouseUp()

local function Window_OnHide(self)
	self.Auracle_window:StopMoving()
end -- Window_OnHide()


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
	window.plrGroup = "solo"
	window.plrCombat = "no"
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
	self.plrGroup = nil
	self.plrCombat = nil
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

function Window.prototype:SetPlayerStatus(plrGroup, plrCombat)
	self.plrGroup = plrGroup
	self.plrCombat = plrCombat
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
	local nowVis = dbvis.plrGroup[self.plrGroup] and dbvis.plrCombat[self.plrCombat]
	if (nowVis) then
		if (self.tgtExists) then
			nowVis = dbvis.tgtType[self.tgtType] and dbvis.tgtReact[self.tgtReact]
		else
			nowVis = dbvis.tgtMissing
		end
	end
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
	local backdrop = self.style:GetBackdropTable()
	if (next(backdrop)) then
		local sdb = self.style.db
		if (backdrop.insets and sdb.background.noScale) then
			local m = {}
			for size in string.gmatch(select(GetCurrentResolution(), GetScreenResolutions()), "[0-9]+") do
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
end -- UpdateBackdrop()

function Window.prototype:UpdateLayout()
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
		for size in string.gmatch(select(GetCurrentResolution(), GetScreenResolutions()), "[0-9]+") do
			m[#m+1] = size
		end
		local factor = ((768 / self.uiFrame:GetEffectiveScale()) / m[2])
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
end -- UpdateLayout()

function Window.prototype:UpdateTrackerLayout(tn)
	-- get style data
	local sdb = self.style.db.layout
	local padding = sdb.padding
	local spacing = sdb.spacing
	if (sdb.noScale) then
		local m = {}
		for size in string.gmatch(select(GetCurrentResolution(), GetScreenResolutions()), "[0-9]+") do
			m[#m+1] = size
		end
		local factor = ((768 / self.uiFrame:GetEffectiveScale()) / m[2])
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
		for size in string.gmatch(select(GetCurrentResolution(), GetScreenResolutions()), "[0-9]+") do
			m[#m+1] = size
		end
		local factor = ((768 / self.uiFrame:GetEffectiveScale()) / m[2])
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
	self.uiFrame:SetMovable(false) -- allows StartMoving
	self.uiFrame:EnableMouse(false) -- intercepts clicks, causes OnMouseDown,OnMouseUp
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
end -- UnlockTrackers()

function Window.prototype:LockTrackers()
	self.trackersLocked = true
	for n,tracker in ipairs(self.trackers) do
		tracker:Lock()
	end
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
					order = 10
				},
				removeWindow = {
					type = "execute",
					name = "Remove Window",
					func = "Remove",
					order = 11
				},
				unit = {
					type = "select",
					name = "Track Unit",
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
						i.handler:UpdateUnitAuras()
					end,
					order = 12
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
					order = 13
				}
			}
		},
		visibility = {
			type = "group",
			name = "Visibility",
			inline = false,
			order = 2,
			args = {
				plrGroup = {
					type = "group",
					name = "Show when player is...",
					inline = true,
					order = 20,
					args = {
						solo = {
							type = "toggle",
							name = "Solo",
							width = "full",
							get = function(i) return i.handler.db.visibility.plrGroup.solo end,
							set = function(i,v)
								i.handler.db.visibility.plrGroup.solo = v
								i.handler:UpdateVisibility()
							end,
							order = 200
						},
						party = {
							type = "toggle",
							name = "In a Party",
							get = function(i) return i.handler.db.visibility.plrGroup.party end,
							set = function(i,v)
								i.handler.db.visibility.plrGroup.party = v
								i.handler:UpdateVisibility()
							end,
							order = 201
						},
						raid = {
							type = "toggle",
							name = "In a Raid",
							get = function(i) return i.handler.db.visibility.plrGroup.raid end,
							set = function(i,v)
								i.handler.db.visibility.plrGroup.raid = v
								i.handler:UpdateVisibility()
							end,
							order = 202
						}
					}
				},
				plrCombat = {
					type = "group",
					name = "Show when player is...",
					inline = true,
					order = 21,
					args = {
						no = {
							type = "toggle",
							name = "Not in Combat",
							get = function(i) return i.handler.db.visibility.plrCombat[false] end,
							set = function(i,v)
								i.handler.db.visibility.plrCombat[false] = v
								i.handler:UpdateVisibility()
							end,
							order = 210
						},
						yes = {
							type = "toggle",
							name = "In Combat",
							get = function(i) return i.handler.db.visibility.plrCombat[true] end,
							set = function(i,v)
								i.handler.db.visibility.plrCombat[true] = v
								i.handler:UpdateVisibility()
							end,
							order = 211
						}
					}
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
					order = 22
				},
				tgtReact = {
					type = "group",
					name = "Show when unit is...",
					inline = true,
					order = 23,
					args = {
						hostile = {
							type = "toggle",
							name = "Hostile",
							get = function(i) return i.handler.db.visibility.tgtReact.hostile end,
							set = function(i,v)
								i.handler.db.visibility.tgtReact.hostile = v
								i.handler:UpdateVisibility()
							end,
							order = 230
						},
						neutral = {
							type = "toggle",
							name = "Neutral",
							get = function(i) return i.handler.db.visibility.tgtReact.neutral end,
							set = function(i,v)
								i.handler.db.visibility.tgtReact.neutral = v
								i.handler:UpdateVisibility()
							end,
							order = 231
						},
						friendly = {
							type = "toggle",
							name = "Friendly",
							get = function(i) return i.handler.db.visibility.tgtReact.friendly end,
							set = function(i,v)
								i.handler.db.visibility.tgtReact.friendly = v
								i.handler:UpdateVisibility()
							end,
							order = 232
						}
					}
				},
				tgtType = {
					type = "group",
					name = "Show when unit is a(n)...",
					inline = true,
					order = 24,
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
							order = 240
						},
						worldboss = {
							type = "toggle",
							name = "Boss",
							get = function(i) return i.handler.db.visibility.tgtType.worldboss end,
							set = function(i,v)
								i.handler.db.visibility.tgtType.worldboss = v
								i.handler:UpdateVisibility()
							end,
							order = 241
						},
						rareelite = {
							type = "toggle",
							name = "Rare Elite NPC",
							get = function(i) return i.handler.db.visibility.tgtType.rareelite end,
							set = function(i,v)
								i.handler.db.visibility.tgtType.rareelite = v
								i.handler:UpdateVisibility()
							end,
							order = 242
						},
						elite = {
							type = "toggle",
							name = "Elite NPC",
							get = function(i) return i.handler.db.visibility.tgtType.elite end,
							set = function(i,v)
								i.handler.db.visibility.tgtType.elite = v
								i.handler:UpdateVisibility()
							end,
							order = 243
						},
						rare = {
							type = "toggle",
							name = "Rare NPC",
							get = function(i) return i.handler.db.visibility.tgtType.rare end,
							set = function(i,v)
								i.handler.db.visibility.tgtType.rare = v
								i.handler:UpdateVisibility()
							end,
							order = 244
						},
						normal = {
							type = "toggle",
							name = "NPC",
							get = function(i) return i.handler.db.visibility.tgtType.normal end,
							set = function(i,v)
								i.handler.db.visibility.tgtType.normal = v
								i.handler:UpdateVisibility()
							end,
							order = 245
						},
						trivial = {
							type = "toggle",
							name = "Gray NPC",
							get = function(i) return i.handler.db.visibility.tgtType.trivial end,
							set = function(i,v)
								i.handler.db.visibility.tgtType.trivial = v
								i.handler:UpdateVisibility()
							end,
							order = 246
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
					order = 30
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
					order = 31
				}
			}
		}
	}
}


--[[ MENU METHODS ]]--

function Window.prototype:GetOptionsTable()
	if (not self.optionsTable) then
		self.optionsTable = {
			type = "group",
			handler = self,
			args = {
				addTracker = {
					type = "group",
					name = "|cff7fffff(Add Tracker...)",
					order = -1,
					args = {
						addTracker = {
							type = "execute",
							name = "Add Tracker",
							func = "AddTracker"
						}
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

