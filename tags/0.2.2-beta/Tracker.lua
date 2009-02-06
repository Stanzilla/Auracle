local LibOOP
--@alpha@
LibOOP = LibStub("LibOOP-1.0-alpha",true)
--@end-alpha@
LibOOP = LibOOP or LibStub("LibOOP-1.0") or error("LibOOP not found")
local Tracker = LibOOP:Class()

--[[ CONSTANTS ]]--

local ICON_QM = "Interface\\Icons\\INV_Misc_QuestionMark"
local DB_DEFAULT_TRACKER = {
	label = false,
	auratype = "debuff", -- buff|debuff
	style = "Default",
	auras = {},
	trackOthers = true,
	trackMine = true,
	maxTime = false,
	autoMaxTime = true,
	maxStacks = false,
	autoMaxStacks = true,
	icon = ICON_QM,
	autoIcon = true,
	spiral = "time", -- off|time|stacks
	spiralReverse = true,
	text = "time", -- off|time|stacks
	textColor = "time" -- time|timeRel|stacks
}
local S_TRACK = {                         others="trackOthers",  mine="trackMine" }
local S_SHOW  = { [false]="showMissing",  others="showOthers",   mine="showMine"  }
local S_SIZE  = { [false]="sizeMissing",  others="sizeOthers",   mine="sizeMine"  }
local S_GRAY  = { [false]="grayMissing",  others="grayOthers",   mine="grayMine"  }
local S_COLOR = { [false]="colorMissing", others="colorOthers",  mine="colorMine" }


--[[ INIT ]]--

Auracle:__tracker(Tracker, DB_DEFAULT_TRACKER)

local ceil,GetTime,max,min,tostring = ceil,GetTime,max,min,tostring
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


--[[ EVENT HANDLERS ]]--

local function Tracker_OnMouseDown(self, button)
	if (button == "LeftButton") then
		self.Auracle_tracker:StartMoving()
	end
end -- Tracker_OnMouseDown()

local function Tracker_OnUpdate(self)
	self.Auracle_tracker:UpdateMovingPosition()
end -- Tracker_OnUpdate()

local function Tracker_OnMouseUp(self, button)
	if (button == "LeftButton") then
		self.Auracle_tracker:StopMoving()
	end
end -- Tracker_OnMouseUp()

local function Tracker_OnHide(self)
	self.Auracle_tracker:StopMoving()
end -- Tracker_OnHide()

local function Tracker_OnEnter(self)
	local tracker = self.Auracle_tracker
	if (self:IsVisible() and tracker.auraApplied) then
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
		GameTooltip:SetUnitAura(tracker.window.db.unit, tracker.auraIndex, ((tracker.db.auratype == "buff") and "HELPFUL") or "HARMFUL")
	end
end -- Tracker_OnEnter()

local function Tracker_OnLeave(self)
	if ((GameTooltip:GetOwner()) == self) then
		GameTooltip:Hide()
	end
end -- Tracker_OnLeave()

local function TrackerCooldown_OnUpdate_Stacks(self, elapsed)
	self:SetCooldown(GetTime() - self.Auracle_tracker.auraStacks, self.Auracle_tracker.db.maxStacks)
end -- TrackerCooldown_OnUpdate_Stacks()

local function TrackerOverlay_OnUpdate(self, elapsed)
	local tracker = self.Auracle_tracker
	local auraTimeleft = tracker.auraTimeleft
	if (auraTimeleft) then
		auraTimeleft = max(0, auraTimeleft - elapsed)
		tracker.auraTimeleft = auraTimeleft
	else
		auraTimeleft = 0
	end
	-- update text
	if (tracker.db.text == "time") then
		local text
		if (auraTimeleft >= 3600) then
			text = tostring(ceil(auraTimeleft / 3600)).."h"
		elseif (auraTimeleft >= 60) then
			text = tostring(ceil(auraTimeleft / 60)).."m"
		else
			text = tostring(ceil(auraTimeleft))
		end
		if (text ~= tracker.text) then
			tracker.text = text
			tracker.uiText:SetText(text)
			-- update color
			if (tracker.db.textColor == "time") then
				tracker.uiText:SetTextColor(tracker.style:GetTextColor(tracker.auraOrigin, false, auraTimeleft))
			elseif (tracker.db.textColor == "timeRel") then
				tracker.uiText:SetTextColor(tracker.style:GetTextColor(tracker.auraOrigin, true, auraTimeleft / (tracker.db.maxTime or 0.001)))
			end
		end
	else
		-- update color
		if (tracker.db.textColor == "time") then
			tracker.uiText:SetTextColor(tracker.style:GetTextColor(tracker.auraOrigin, false, auraTimeleft))
		elseif (tracker.db.textColor == "timeRel") then
			tracker.uiText:SetTextColor(tracker.style:GetTextColor(tracker.auraOrigin, true, auraTimeleft / (tracker.db.maxTime or 0.001)))
		end
	end
end -- TrackerOverlay_OnUpdate()


--[[ CONSTRUCT & DESTRUCT ]]--

function Tracker:New(db, window, parentFrame)
	-- re-use a tracker from the pool, or create a new one
	local tracker = next(objectPool)
	if (not tracker) then
		tracker = self:Super("New")
		tracker.uiFrame = CreateFrame("Frame") -- UIObject,Region
		tracker.uiFrame:SetFrameStrata("LOW")
		tracker.uiFrame:SetClampedToScreen(true) -- so WoW polices position, no matter how it changes (StartMoving,SetPoint,etc)
		tracker.uiFrame.Auracle_tracker = tracker
		tracker.uiIcon = tracker.uiFrame:CreateTexture(nil, "BACKGROUND") -- UIObject,Region,LayeredRegion
		tracker.uiIcon:SetAllPoints()
		tracker.uiCooldown = CreateFrame("Cooldown", nil, tracker.uiFrame) -- UIObject,Region,Frame
		tracker.uiCooldown:SetAllPoints()
		tracker.uiCooldown.Auracle_tracker = tracker
		tracker.uiOverlay = CreateFrame("Frame", nil, tracker.uiFrame) -- UIObject,Region
		tracker.uiOverlay:SetAllPoints()
		tracker.uiOverlay.Auracle_tracker = tracker
		tracker.uiText = tracker.uiOverlay:CreateFontString(nil, "OVERLAY") -- UIObject,FontInstance,Region,LayeredRegion
		tracker.uiText:SetPoint("CENTER") -- SetAllPoints() makes it just display "..." if it would overflow
		tracker.uiText:SetNonSpaceWrap(false)
		tracker.uiText:SetJustifyH("CENTER")
		tracker.uiText:SetJustifyV("MIDDLE")
	end
	objectPool[tracker] = nil
	
	-- (re?)initialize tracker
	tracker.window = window
	tracker.db = db
	tracker.style = Auracle.trackerStyles[db.style]
	tracker.locked = true
	tracker.moving = false
	tracker.backdrop = { edgeFile="Interface\\Addons\\Auracle\\white", edgeSize=1 }
	tracker.size = 4
	tracker.text = ""
	tracker.auraIndex = false
	tracker.auraOrigin = false
	tracker.auraApplied = false
	tracker.auraExpires = false
	tracker.auraStacks = false
	tracker.auralist = false
	
	-- (re?)initialize frames
	tracker.uiFrame:SetParent(parentFrame)
	tracker.uiFrame:Show()
	tracker:Lock()
	
	-- (re?)apply preferences
	tracker:UpdateStyle()
	
	return tracker
end -- New()

function Tracker.prototype:Destroy()
	self:StopMoving()
	-- clean up frame
	self.uiOverlay:SetScript("OnUpdate", nil)
	self.uiCooldown:Hide()
	self.uiCooldown:SetScript("OnUpdate", nil)
	self.uiFrame:Hide()
	self.uiFrame:SetScript("OnUpdate", nil)
	self.uiFrame:SetScript("OnMouseDown", nil)
	self.uiFrame:SetScript("OnMouseUp", nil)
	self.uiFrame:SetScript("OnHide", nil)
	self.uiFrame:SetScript("OnEnter", nil)
	self.uiFrame:SetScript("OnLeave", nil)
	self.uiFrame:ClearAllPoints()
	self.uiFrame:SetParent(UIParent)
	-- clean up tracker
	self.window = nil
	self.db = nil
	self.style = nil
	self.locked = nil
	self.moving = nil
	self.backdrop = nil
	self.size = nil
	self.text = nil
	self.auraIndex = nil
	self.auraOrigin = nil
	self.auraApplied = nil
	self.auraExpires = nil
	self.auraStacks = nil
	self.auralist = nil
	-- add object to the pool for later re-use
	objectPool[self] = true
end -- Destroy()

function Tracker.prototype:Remove()
	if (self.window:RemoveTracker(self)) then
		self:Destroy()
	end
end -- Remove()


--[[ INTERFACE METHODS ]]--

function Tracker.prototype:StartMoving()
	if (not self.locked and not self.moving) then
		self.moving = true
		self.uiFrame:SetScript("OnUpdate", Tracker_OnUpdate)
		local _,_,_,x,y = self.uiFrame:GetPoint(1)
		self.moving_frameX = x
		self.moving_frameY = y
		self.uiFrame:SetFrameStrata("DIALOG")
		self.uiFrame:StartMoving()
		_,_,_,x,y = self.uiFrame:GetPoint(1)
		self.moving_screenX = x
		self.moving_screenY = y
		self.moving_lastX = x
		self.moving_lastY = y
	end
end -- StartMoving()

function Tracker.prototype:UpdateMovingPosition()
	if (self.moving) then
		local _,_,_,x,y = self.uiFrame:GetPoint(1)
		if (x ~= self.moving_lastX or y ~= self.moving_lastY) then
			self.moving_lastX = x
			self.moving_lastY = y
			x = (x - self.moving_screenX) + self.moving_frameX
			y = (y - self.moving_screenY) + self.moving_frameY
			self.window:SetTrackerPosition(self, x, -y)
		end
	end
end -- UpdateMovingPosition()

function Tracker.prototype:StopMoving()
	if (self.moving) then
		self.moving = false
		self.uiFrame:SetScript("OnUpdate", nil)
		self.uiFrame:SetFrameStrata("LOW")
		self.uiFrame:StopMovingOrSizing()
		self.window:UpdateLayout()
		Auracle:UpdateConfig()
		self.moving_frameX = nil
		self.moving_frameY = nil
		self.moving_screenX = nil
		self.moving_screenY = nil
		self.moving_lastX = nil
		self.moving_lastY = nil
	end
end -- StopMoving()


--[[ AURA UPDATE METHODS ]]--

function Tracker.prototype:UpdateUnitAuras()
	self.window:UpdateUnitAuras()
end -- UpdateUnitAuras()

function Tracker.prototype:ResetAuraState()
	self:BeginAuraUpdate()
	self:EndAuraUpdate()
end -- ResetAuraState()

function Tracker.prototype:BeginAuraUpdate(now)
	self.update_index = false
	self.update_icon = false
	self.update_origin = false
	self.update_applied = false
	self.update_expires = false
	self.update_stacks = false
end -- BeginAuraUpdate()

function Tracker.prototype:UpdateAura(now,index,name,rank,icon,count,atype,duration,expires,origin,stealable)
	-- if we already have a qualifying, non-expiring aura, we don't care about anything else
	if (self.update_applied and not self.update_expires) then
		return
	end
	local ipairs = ipairs
	for _,auraname in ipairs(self.db.auras) do
		if (name == auraname) then
			if (self.db[S_TRACK[origin]]) then
				if (not self.update_applied or expires == 0 or expires > self.update_expires) then
					self.update_index = index
					self.update_icon = icon
					self.update_origin = origin
					if (duration > 0 and expires > 0) then
						self.update_applied = expires - duration
						self.update_expires = expires
					else
						self.update_applied = true
						self.update_expires = false
					end
					self.update_stacks = count
				end
			end
		end
	end
end -- UpdateAura()

function Tracker.prototype:EndAuraUpdate(now,total)
	-- find changes and autoupdate
	local statusChanged = (self.update_origin ~= self.auraOrigin)
	local timeChanged = (self.update_expires ~= self.auraExpires)
	local maxTimeChanged = false
	if (self.update_expires) then
		local duration = self.update_expires - self.update_applied
		if (not self.db.maxTime or self.db.autoMaxTime) then
			self.db.maxTime = duration
			maxTimeChanged = true
		end
	end
	local stacksChanged = (self.update_stacks ~= self.auraStacks)
	local maxStacksChanged = false
	if (self.update_stacks) then
		if (not self.db.maxStacks or (self.db.autoMaxStacks and self.update_stacks > self.db.maxStacks)) then
			self.db.maxStacks = self.update_stacks
			maxStacksChanged = true
		end
	end
	local iconChanged = false
	if (self.update_icon) then
		if (self.db.icon == ICON_QM or self.db.autoIcon) then
			self.db.icon = self.update_icon
			iconChanged = true
		end
	end
	-- store aura state
	self.auraIndex = self.update_index
	self.auraOrigin = self.update_origin
	self.auraApplied = self.update_applied
	self.auraTimeleft = self.update_expires and (self.update_expires - now)
	self.auraExpires = self.update_expires
	self.auraStacks = self.update_stacks
	self.update_index = nil
	self.update_icon = nil
	self.update_origin = nil
	self.update_applied = nil
	self.update_expires = nil
	self.update_stacks = nil
	-- update visuals as needed
	if (statusChanged) then
		self:UpdateBorder()
		self:UpdateIcon()
		self:UpdateSpiral()
		self:UpdateText()
	else
		if (iconChanged) then
			self:UpdateIcon()
		end
		if (self.db.spiral == "time" and (timeChanged or maxTimeChanged)) then
			self:UpdateSpiral()
		elseif (self.db.spiral == "stacks" and (stacksChanged or maxStacksChanged)) then
			self:UpdateSpiral()
		end
		if (self.db.text == "stacks" and maxStacksChanged) then
			self:UpdateText()
		elseif (self.db.textColor == "stacks" and (stacksChanged or maxStacksChanged)) then
			self:UpdateText()
		end
	end
end -- EndAuraUpdate()


--[[ VISUAL UPDATE METHODS ]]--

function Tracker.prototype:UpdateStyle()
	self:UpdateBorder()
	self:UpdateIcon()
	self:UpdateSpiral()
	self:UpdateFont()
	self:UpdateText()
end -- UpdateStyle()

function Tracker.prototype:UpdateBorder()
	local sdb = self.style.db.border
	if (sdb[S_SHOW[self.auraOrigin]]) then
		local borderSize = sdb[S_SIZE[self.auraOrigin]]
		if (sdb.noScale) then
			local m = {}
			for size in string.gmatch(select(GetCurrentResolution(), GetScreenResolutions()), "[0-9]+") do
				m[#m+1] = size
			end
			borderSize = borderSize * ((768 / self.uiFrame:GetEffectiveScale()) / m[2])
		end
		self.backdrop.edgeSize = borderSize
		self.uiFrame:SetBackdrop(self.backdrop)
		self.uiFrame:SetBackdropBorderColor(unpack(sdb[S_COLOR[self.auraOrigin]]))
	else
		self.uiFrame:SetBackdrop(nil)
	end
end -- UpdateBorder()

function Tracker.prototype:UpdateIcon()
	local sdb = self.style.db.icon
	if (sdb[S_SHOW[self.auraOrigin]]) then
		self.uiIcon:SetTexture(self.db.icon)
		if (sdb.zoom) then
			self.uiIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		else
			self.uiIcon:SetTexCoord(   0,    1,    0,    1)
		end
		self.uiIcon:SetDesaturated(sdb[S_GRAY[self.auraOrigin]])
		self.uiIcon:SetVertexColor(unpack(sdb[S_COLOR[self.auraOrigin]]))
		self.uiIcon:Show();
	else
		self.uiIcon:Hide();
	end
end -- UpdateIcon()

function Tracker.prototype:UpdateSpiral()
	local sdb = self.style.db.spiral
	if (sdb[S_SHOW[self.auraOrigin]]) then
		self.uiCooldown.noCooldownCount = sdb.noCC or nil
		self.uiCooldown.noOmniCC = sdb.noCC or nil
		self.uiCooldown:SetReverse(self.db.spiralReverse)
		if (self.auraExpires) then
			self.uiCooldown:Show()
			if (self.db.spiral == "time") then
				self.uiCooldown:SetScript("OnUpdate", nil)
				self.uiCooldown:SetCooldown(self.auraExpires - self.db.maxTime, self.db.maxTime)
			elseif (self.db.spiral == "stacks") then
				self.uiCooldown:SetScript("OnUpdate", TrackerCooldown_OnUpdate_Stacks)
			end
		else
			self.uiCooldown:Hide()
		end
	else
		self.uiCooldown:Hide()
	end
end -- UpdateSpiral()

function Tracker.prototype:UpdateFont()
	local sdb = self.style.db.text
	local fontsize = sdb.size + (sdb.sizeMult * self.size)
	self.uiText:SetFont(sdb.font, fontsize, sdb.outline)
end -- UpdateFont()

function Tracker.prototype:UpdateText()
	local text = "0"
	self.uiOverlay:SetScript("OnUpdate", nil)
	local sdb = self.style.db.text
	if (sdb[S_SHOW[self.auraOrigin]]) then
		-- set text
		if (self.db.text == "label") then
			text = self.db.label
		elseif (self.db.text == "time") then
			if (self.auraTimeleft) then
				self.uiOverlay:SetScript("OnUpdate", TrackerOverlay_OnUpdate)
				if (self.auraTimeleft >= 3600) then
					text = tostring(ceil(self.auraTimeleft / 3600)).."h"
				elseif (self.auraTimeleft >= 60) then
					text = tostring(ceil(self.auraTimeleft / 60)).."m"
				else
					text = tostring(ceil(self.auraTimeleft or 0))
				end
			end
		elseif (self.db.text == "stacks") then
			text = tostring(self.auraStacks or 0)
		end
		-- set color
		if (self.db.textColor == "time") then
			self.uiText:SetTextColor(self.style:GetTextColor(self.auraOrigin, false, self.auraTimeleft or 0))
			self.uiOverlay:SetScript("OnUpdate", TrackerOverlay_OnUpdate)
		elseif (self.db.textColor == "timeRel") then
			self.uiText:SetTextColor(self.style:GetTextColor(self.auraOrigin, true, (self.auraTimeleft or 0) / (self.db.maxTime or 0.0001)))
			self.uiOverlay:SetScript("OnUpdate", TrackerOverlay_OnUpdate)
		elseif (self.db.textColor == "stacks") then
			self.uiText:SetTextColor(self.style:GetTextColor(self.auraOrigin, true, (self.auraStacks or 0) / (self.db.maxStacks or 0.0001)))
		end
		self.text = text
		self.uiText:SetText(text)
		self.uiText:Show()
	else
		self.uiText:Hide()
	end
end -- UpdateText()

function Tracker.prototype:SetLayout(x, y, trackerSize)
	if (not self.moving) then
		self.uiFrame:ClearAllPoints()
		self.uiFrame:SetPoint("TOPLEFT", self.uiFrame:GetParent(), "TOPLEFT", x, -y) -- WoW's 0,0 is lowerleft
		self.uiFrame:SetWidth(trackerSize)
		self.uiFrame:SetHeight(trackerSize)
		if (trackerSize ~= self.size) then
			self.size = trackerSize
			self:UpdateFont()
		end
	end
end -- SetLayout()


--[[ CONFIG METHODS ]]--

function Tracker.prototype:IsLocked()
	return self.locked
end -- IsLocked()

function Tracker.prototype:Unlock()
	Tracker_OnLeave(self.uiFrame)
	self.locked = false
	self.uiFrame:EnableMouse(true) -- intercepts clicks, causes OnMouseDown,OnMouseUp
	self.uiFrame:SetMovable(true) -- allows StartMoving
	self.uiFrame:SetScript("OnMouseDown", Tracker_OnMouseDown)
	self.uiFrame:SetScript("OnMouseUp", Tracker_OnMouseUp)
	self.uiFrame:SetScript("OnHide", Tracker_OnMouseUp)
	self.uiFrame:SetScript("OnEnter", nil)
	self.uiFrame:SetScript("OnLeave", nil)
end -- Unlock()

function Tracker.prototype:Lock()
	self:StopMoving()
	self.locked = true
	self.uiFrame:SetScript("OnMouseDown", nil)
	self.uiFrame:SetScript("OnMouseUp", nil)
	self.uiFrame:SetScript("OnHide", nil)
	self.uiFrame:SetScript("OnEnter", Tracker_OnEnter)
	self.uiFrame:SetScript("OnLeave", Tracker_OnLeave)
	self.uiFrame:SetMovable(false) -- allows StartMoving
	self.uiFrame:EnableMouse(false) -- intercepts clicks, causes OnMouseDown,OnMouseUp
end -- Lock()


--[[ SHARED OPTIONS TABLE ]]--

local sharedOptions = {
	tracker = {
		type = "group",
		name = "Tracker",
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
			removeTracker = {
				type = "execute",
				name = "Remove Tracker",
				func = "Remove",
				order = 11
			},
			style = {
				type = "select",
				name = "Tracker Style",
				values = function() return Auracle.trackerStyleOptions end,
				get = function(i) return i.handler.db.style end,
				set = function(i,v)
					local style = Auracle.trackerStyles[v]
					if (style) then
						i.handler.db.style = v
						i.handler.style = style
						style:Apply(i.handler)
					end
				end,
				order = 12
			}
		}
	},
	auras = {
		type = "group",
		name = "Auras",
		order = 2,
		args = {
			auratype = {
				type = "select",
				name = "Aura Type",
				values = {
					buff = "Buffs",
					debuff = "Debuffs"
				},
				get = function(i) return i.handler.db.auratype end,
				set = function(i,v)
					i.handler.db.auratype = v
					i.handler:UpdateUnitAuras()
				end,
				order = 20
			},
			auras = {
				type = "input",
				name = "Auras",
				usage = "One buff or debuff name per line",
				multiline = true,
				width = "double",
				get = function(i)
					if (not i.handler.auralist) then
						local l = ""
						for _,auraname in ipairs(i.handler.db.auras) do
							l = l .. "\n" .. auraname
						end
						i.handler.auralist = strsub(l,2)
					end
					return i.handler.auralist
				end,
				set = function(i,v)
					local auras = i.handler.db.auras
					wipe(auras)
					for aura in string.gmatch(v, "[^\n\r]+") do
						auras[#auras+1] = aura
					end
					i.handler.auralist = false
					if (not i.handler.db.label) then Auracle:UpdateConfig() end
					i.handler:UpdateUnitAuras()
				end,
				order = 21
			},
			trackOthers = {
				type = "toggle",
				name = "Track Other's",
				get = function(i) return i.handler.db.trackOthers end,
				set = function(i,v)
					i.handler.db.trackOthers = v
					i.handler:UpdateUnitAuras()
				end,
				order = 22
			},
			trackMine = {
				type = "toggle",
				name = "Track Mine",
				get = function(i) return i.handler.db.trackMine end,
				set = function(i,v)
					i.handler.db.trackMine = v
					i.handler:UpdateUnitAuras()
				end,
				order = 23
			},
			maxTime = {
				type = "input",
				name = "Maximum Duration",
				get = function(i) return i.handler.db.maxTime end,
				set = function(i,v)
					i.handler.db.maxTime = v
					if (i.handler.db.spiral == "time") then i.handler:UpdateSpiral() end
				end,
				order = 24
			},
			autoMaxTime = {
				type = "toggle",
				name = "Autoupdate",
				desc = "Update maximum duration whenever a new aura activates the tracker",
				get = function(i) return i.handler.db.autoMaxTime end,
				set = function(i,v)
					i.handler.db.autoMaxTime = v
					if (v) then i.handler:UpdateUnitAuras() end
				end,
				order = 25
			},
			maxStacks = {
				type = "input",
				name = "Maximum Stacks",
				get = function(i) return i.handler.db.maxStacks end,
				set = function(i,v)
					i.handler.db.maxStacks = v
					if (i.handler.db.spiral == "stacks") then i.handler:UpdateSpiral() end
				end,
				order = 26
			},
			autoMaxStacks = {
				type = "toggle",
				name = "Autoupdate",
				desc = "Update maximum stacks whenever a higher stack count is seen",
				get = function(i) return i.handler.db.autoMaxStacks end,
				set = function(i,v)
					i.handler.db.autoMaxStacks = v
					if (v) then i.handler:UpdateUnitAuras() end
				end,
				order = 27
			},
			icon = {
				type = "input",
				name = "Icon Texture",
				get = function(i) return i.handler.db.icon end,
				set = function(i,v)
					i.handler.db.icon = v
					i.handler:UpdateIcon()
				end,
				order = 28
			},
			autoIcon = {
				type = "toggle",
				name = "Autoupdate",
				desc = "Update icon texture whenever a new aura activates the tracker",
				get = function(i) return i.handler.db.autoIcon end,
				set = function(i,v)
					i.handler.db.autoIcon = v
					if (v) then i.handler:UpdateUnitAuras() end
				end,
				order = 29
			}
		}
	},
	spiral = {
		type = "group",
		name = "Spiral",
		order = 3,
		args = {
			mode = {
				type = "select",
				name = "Display",
				values = {
					time = "Duration",
					stacks = "Stacks"
				},
				get = function(i) return i.handler.db.spiral end,
				set = function(i,v)
					i.handler.db.spiral = v
					i.handler:UpdateSpiral()
				end,
				order = 30
			},
			reverse = {
				type = "select",
				name = "Direction",
				values = {
					fill = "Fill Clockwise",
					drain = "Drain Clockwise"
				},
				get = function(i) return (i.handler.db.spiralReverse and "drain") or "fill" end,
				set = function(i,v)
					i.handler.db.spiralReverse = ((v == "drain") and true) or false
					i.handler:UpdateSpiral()
				end,
				order = 31
			}
		}
	},
	text = {
		type = "group",
		name = "Text",
		order = 4,
		args = {
			mode = {
				type = "select",
				name = "Display",
				values = {
					label = "Label",
					time = "Duration",
					stacks = "Stacks"
				},
				get = function(i) return i.handler.db.text end,
				set = function(i,v)
					i.handler.db.text = v
					-- TODO text
				end,
				order = 40
			},
			color = {
				type = "select",
				name = "Color By",
				values = {
					time = "Absolute Duration",
					timeRel = "Relative Duration",
					stacks = "Relative Stacks"
				},
				get = function(i) return i.handler.db.textColor end,
				set = function(i,v)
					i.handler.db.textColor = v
					-- TODO text
				end,
				order = 41
			}
		}
	}
}


--[[ MENU METHODS ]]--

function Tracker.prototype:GetOptionsTable()
	if (not self.optionsTable) then
		self.optionsTable = {
			type = "group",
			childGroups = "tab",
			handler = self,
			args = sharedOptions
		}
	end
	self.optionsTable.name = self.db.label or self.db.auras[1] or "New Tracker"
	return self.optionsTable
end -- GetOptionsTable()

