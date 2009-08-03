local LibOOP
--@alpha@
LibOOP = LibStub("LibOOP-1.0-alpha", true)
--@end-alpha@
LibOOP = LibOOP or LibStub("LibOOP-1.0") or error("Auracle: Required library LibOOP not found")
local Tracker = LibOOP:Class()

local LIB_AceLocale = LibStub("AceLocale-3.0") or error("Auracle: Required library AceLocale-3.0 not found")
local L = LIB_AceLocale:GetLocale("Auracle")


--[[ DECLARATIONS ]]--

-- constants

local ICON_QM = "Interface\\Icons\\INV_Misc_QuestionMark"
local S_SHOW  = { [false]="showMissing",  others="showOthers",   mine="showMine"  }
local S_SIZE  = { [false]="sizeMissing",  others="sizeOthers",   mine="sizeMine"  }
local S_GRAY  = { [false]="grayMissing",  others="grayOthers",   mine="grayMine"  }
local S_COLOR = { [false]="colorMissing", others="colorOthers",  mine="colorMine" }
local UNLOCKED_BACKDROP = { bgFile="Interface\\Buttons\\WHITE8X8", tile=false, insets={left=0,right=0,top=0,bottom=0} }

local DB_DEFAULT_TRACKER = {
	label = false,
	style = L.DEFAULT,
	auratype = "debuff", -- buff|debuff
	auras = {},
	showOthers = true,
	showMine = true,
	spiral = {
		mode = "time", -- off|time|stacks
		reverse = true,
		maxTime = false,
		maxTimeMode = "auto",
		maxStacks = false,
		maxStacksMode = "auto"
	},
	icon = {
		texture = ICON_QM,
		autoIcon = true
	},
	text = {
		mode = "time", -- off|time|stacks
		color = "time", -- time|timeRel|stacks
		maxTime = false,
		maxTimeMode = "auto",
		maxStacks = false,
		maxStacksMode = "auto"
	},
	tooltip = {
		showMissing = "off", -- off|summary
		showOthers = "off", -- off|summary|aura
		showMine = "off" -- off|summary|aura
	}
} -- {DB_DEFAULT_TRACKER}

local DB_VALID_TRACKER = {
	label = function(v) return (type(v) == "string" or v == false) end,
	style = "string",
	auratype = "string",
	auras = function(v)
		if (type(v) ~= "table") then
--@debug@
			print("Auracle: type(db.windows[?].trackers[?].auras) = "..type(v))
--@end-debug@
			return false
		end
		for _,aura in pairs(v) do
			if (type(aura) ~= "string") then return false end
		end
		return true
	end,
	showOthers = "boolean",
	showMine = "boolean",
	spiral = {
		mode = "string",
		reverse = "boolean",
		maxTime = function(v) return (type(v) == "number" or v == false) end,
		maxTimeMode = "string",
		maxStacks = function(v) return (type(v) == "number" or v == false) end,
		maxStacksMode = "string"
	},
	icon = {
		texture = "string",
		autoIcon = "boolean"
	},
	text = {
		mode = "string",
		color = "string",
		maxTime = function(v) return (type(v) == "number" or v == false) end,
		maxTimeMode = "string",
		maxStacks = function(v) return (type(v) == "number" or v == false) end,
		maxStacksMode = "string"
	},
	tooltip = {
		showMissing = "string",
		showOthers = "string",
		showMine = "string"
	}
} -- {DB_VALID_TRACKER}

-- API function upvalues

local ceil,max,min,select,tostring = ceil,max,min,select,tostring
local API_GetCurrentResolution = GetCurrentResolution
local API_GetScreenResolutions = GetScreenResolutions
local API_GetTime = GetTime


--[[ CLASS METHODS ]]--

function Tracker:UpdateSavedVars(version, db)
	-- v4: renamed trackOthers to showOthers
	if (type(db.trackOthers) == "boolean") then
		db.showOthers = db.trackOthers
		db.trackOthers = nil
	end
	-- v4: renamed trackMine to showMine
	if (type(db.trackMine) == "boolean") then
		db.showMine = db.trackMine
		db.trackMine = nil
	end
	-- v4: moved spiral,spiralReverse,maxTime,autoMaxTime,maxStacks,autoMaxStacks into spiral subtable
	if (type(db.spiral) == "string") then
		local spiral = {
			mode = db.spiral,
			reverse = ((db.spiralReverse == nil) and true) or db.spiralReverse,
			maxTime = db.maxTime or false,
			maxTimeMode = ((db.autoMaxTime == false) and "static") or "auto",
			maxStacks = maxStacks or false,
			maxStacksMode = ((db.autoMaxStacks == false) and "static") or "auto"
		}
		db.spiral = spiral
	end
	-- v4: moved text,textColor,maxTime,autoMaxTime,maxStacks,autoMaxStacks into text subtable
	if (type(db.text) == "string") then
		local text = {
			mode = db.text,
			color = db.textColor or "time",
			maxTime = db.maxTime or false,
			maxTimeMode = ((db.autoMaxTime == false) and "static") or "auto",
			maxStacks = maxStacks or false,
			maxStacksMode = ((db.autoMaxStacks == false) and "static") or "auto"
		}
		db.text = text
	end
	db.spiralReverse = nil
	db.textColor = nil
	db.maxTime = nil
	db.autoMaxTime = nil
	db.maxStacks = nil
	db.autoMaxStacks = nil
	-- v4: moved icon,autoIcon into icon subtable
	if (type(db.icon) == "string") then
		local icon = {
			texture = db.icon,
			autoIcon = ((db.autoIcon == nil) and true) or db.autoIcon
		}
		db.icon = icon
	end
	db.autoIcon = nil
	return 4
end -- UpdateSavedVars()


--[[ EVENT HANDLERS ]]--

local function Frame_OnMouseDown(self, button)
	if (button == "LeftButton") then
		self.Auracle_tracker:StartMoving()
	end
end -- Frame_OnMouseDown()

local function Frame_OnUpdate(self)
	self.Auracle_tracker:UpdateMovingPosition()
end -- Frame_OnUpdate()

local function Frame_OnMouseUp(self, button)
	if (button == "LeftButton") then
		self.Auracle_tracker:StopMoving()
	end
end -- Frame_OnMouseUp()

local function Frame_OnHide(self)
	self.Auracle_tracker:StopMoving()
end -- Frame_OnHide()

local function Frame_OnSizeChanged(self)
	return self.Auracle_tracker:UpdateBackdrop()
end -- Frame_OnSizeChanged()

local function Frame_OnEnter(self)
	if (self:IsVisible()) then
		local tt = GameTooltip
		local tracker = self.Auracle_tracker
		local mode = tracker.db.tooltip[S_SHOW[tracker.auraOrigin]]
		if (mode == "aura" and tracker.auraApplied) then
			tt:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
			tt:SetUnitAura(tracker.window.db.unit, tracker.auraIndex, ((tracker.db.auratype == "buff") and "HELPFUL") or "HARMFUL")
		elseif (mode == "summary") then
			local now = API_GetTime()
			local timeleft
			tt:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
			tt:ClearLines()
			tt:AddLine(tracker.db.label or tracker.db.auras[1] or L.NEW_TRACKER, 1, 1, 0)
			for i,aura in pairs(tracker.db.auras) do
				if (tracker.summary[aura] == true) then
					tt:AddLine(aura, 0, 1, 0)
				elseif (tracker.summary[aura]) then
					timeleft = tracker.summary[aura] - now
					if (timeleft >= 3600) then
						tt:AddDoubleLine(aura, tostring(ceil(timeleft / 3600))..L["_HOURS_ABBREV_"], 0, 1, 0, 0, 1, 0)
					elseif (timeleft >= 60) then
						tt:AddDoubleLine(aura, tostring(ceil(timeleft / 60))..L["_MINUTES_ABBREV_"], 0, 1, 0, 0, 1, 0)
					else
						tt:AddDoubleLine(aura, tostring(ceil(timeleft))..L["_SECONDS_ABBREV_"], 0, 1, 0, 0, 1, 0)
					end
				else
					tt:AddLine(aura, 1, 0, 0)
				end
			end
			tt:Show()
		end
	end
end -- Frame_OnEnter()

local function Frame_OnLeave(self)
	if ((GameTooltip:GetOwner()) == self) then
		GameTooltip:Hide()
	end
end -- Frame_OnLeave()

local function Cooldown_OnUpdate_Stacks(self, elapsed)
	self:SetCooldown((API_GetTime()) - self.Auracle_tracker.auraStacks, self.Auracle_tracker.db.spiral.maxStacks)
end -- Cooldown_OnUpdate_Stacks()

local function TrackerOverlay_OnUpdate(self, elapsed)
	local tracker = self.Auracle_tracker
	local dbtext = tracker.db.text
	local auraTimeleft = tracker.auraTimeleft
	if (auraTimeleft) then
		auraTimeleft = max(0, auraTimeleft - elapsed)
		tracker.auraTimeleft = auraTimeleft
	else
		auraTimeleft = 0
	end
	-- update text
	if (dbtext.mode == "time") then
		local text
		if (auraTimeleft >= 3600) then
			text = tostring(ceil(auraTimeleft / 3600))..L["_HOURS_ABBREV_"]
		elseif (auraTimeleft >= 60) then
			text = tostring(ceil(auraTimeleft / 60))..L["_MINUTES_ABBREV_"]
		else
			text = tostring(ceil(auraTimeleft))
		end
		if (text ~= tracker.text) then
			tracker.text = text
			tracker.uiText:SetText(text)
			-- update color
			if (dbtext.color == "time") then
				tracker.uiText:SetTextColor(tracker.style:GetTextColor(tracker.auraOrigin, false, auraTimeleft))
			elseif (dbtext.color == "timeRel") then
				tracker.uiText:SetTextColor(tracker.style:GetTextColor(tracker.auraOrigin, true, auraTimeleft / (dbtext.maxTime or 0.001)))
			end
		end
	else
		-- update color
		if (dbtext.color == "time") then
			tracker.uiText:SetTextColor(tracker.style:GetTextColor(tracker.auraOrigin, false, auraTimeleft))
		elseif (dbtext.color == "timeRel") then
			tracker.uiText:SetTextColor(tracker.style:GetTextColor(tracker.auraOrigin, true, auraTimeleft / (dbtext.maxTime or 0.001)))
		end
	end
end -- TrackerOverlay_OnUpdate()


--[[ CONSTRUCT & DESTRUCT ]]--

do
	local objectPool = {}
	
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
		tracker.backdrop = { edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1 }
		tracker.size = 4
		tracker.text = ""
		tracker.auraIndex = false
		tracker.auraOrigin = false
		tracker.auraApplied = false
		tracker.auraExpires = false
		tracker.auraStacks = false
		tracker.auralist = false
		tracker.summary = {}
		
		-- (re?)initialize frames
		tracker.uiFrame:SetParent(parentFrame)
		tracker.uiFrame:SetScript("OnSizeChanged", Frame_OnSizeChanged)
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
		self.uiFrame:SetScript("OnSizeChanged", nil)
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
		self.summary = nil
		-- add object to the pool for later re-use
		objectPool[self] = true
	end -- Destroy()
	
end

function Tracker.prototype:Remove()
	if (self.window:RemoveTracker(self)) then
		self:Destroy()
	end
end -- Remove()


--[[ INTERFACE METHODS ]]--

function Tracker.prototype:StartMoving()
	if (not self.locked and not self.moving) then
		self.moving = true
		self.uiFrame:SetScript("OnUpdate", Frame_OnUpdate)
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
	wipe(self.summary)
end -- BeginAuraUpdate()

function Tracker.prototype:UpdateAura(now,index,name,rank,icon,count,atype,duration,expires,origin,stealable)
	-- if we already have a qualifying, non-expiring aura, we don't care about anything else
	if (self.update_applied and not self.update_expires) then
		return
	end
	-- if we don't track this origin, we also don't care
	if (not self.db[S_SHOW[origin]]) then
		return
	end
	local ipairs = ipairs
	for _,auraname in ipairs(self.db.auras) do
		if (name == auraname) then
			self.summary[name] = expires or true
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
end -- UpdateAura()

function Tracker.prototype:EndAuraUpdate(now,total)
	local dbicon = self.db.icon
	local dbspiral = self.db.spiral
	local dbtext = self.db.text
	-- find changes and autoupdate
	local statusChanged = (self.update_origin ~= self.auraOrigin)
	local timeChanged = (self.update_expires ~= self.auraExpires)
	local stacksChanged = (self.update_stacks ~= self.auraStacks)
	local auraApplied = (statusChanged or timeChanged or self.update_applied ~= self.auraApplied or self.update_index ~= self.auraIndex)
	local iconChanged = false
	if (self.update_icon) then
		if (dbicon.texture == ICON_QM
			or (dbicon.autoIcon and self.update_icon ~= dbicon.texture)
		) then
			dbicon.texture = self.update_icon
			iconChanged = true
		end
	end
	local spiralMaxTimeChanged = false
	local textMaxTimeChanged = false
	if (self.update_expires) then
		local duration = self.update_expires - self.update_applied
		if (not dbspiral.maxTime
			or (dbspiral.maxTimeMode == "autoUp" and duration > dbspiral.maxTime)
			or (dbspiral.maxTimeMode == "auto" and duration ~= dbspiral.maxTime)
		) then
			dbspiral.maxTime = duration
			spiralMaxTimeChanged = true
		end
		if (not dbtext.maxTime
			or (dbtext.maxTimeMode == "autoUp" and duration > dbtext.maxTime)
			or (dbtext.maxTimeMode == "auto" and duration ~= dbtext.maxTime)
		) then
			dbtext.maxTime = duration
			textMaxTimeChanged = true
		end
	end
	local spiralMaxStacksChanged = false
	local textMaxStacksChanged = false
	if (self.update_stacks) then
		if (not dbspiral.maxStacks
			or (dbspiral.maxStacksMode == "autoUp" and self.update_stacks > dbspiral.maxStacks)
			or (dbspiral.maxStacksMode == "auto" and auraApplied and self.update_stacks ~= dbspiral.maxStacks)
		) then
			dbspiral.maxStacks = self.update_stacks
			spiralMaxStacksChanged = true
		end
		if (not dbtext.maxStacks
			or (dbtext.maxStacksMode == "autoUp" and self.update_stacks > dbtext.maxStacks)
			or (dbtext.maxStacksMode == "auto" and auraApplied and self.update_stacks ~= dbtext.maxStacks)
		) then
			dbtext.maxStacks = self.update_stacks
			textMaxStacksChanged = true
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
		self:UpdateBackdrop()
		self:UpdateIcon()
		self:UpdateSpiral()
		self:UpdateText()
	else
		if (iconChanged) then
			self:UpdateIcon()
		end
		if (dbspiral.mode == "time" and (timeChanged or spiralMaxTimeChanged)) then
			self:UpdateSpiral()
		elseif (dbspiral.mode == "stacks" and (stacksChanged or spiralMaxStacksChanged)) then
			self:UpdateSpiral()
		end
		if (dbtext.mode == "stacks" and stacksChanged) then
			self:UpdateText()
		elseif (dbtext.color == "time" and timeChanged) then
			self:UpdateText()
		elseif (dbtext.color == "timeRel" and (timeChanged or textMaxTimeChanged)) then
			self:UpdateText()
		elseif (dbtext.color == "stacks" and (stacksChanged or textMaxStacksChanged)) then
			self:UpdateText()
		end
	end
end -- EndAuraUpdate()


--[[ VISUAL UPDATE METHODS ]]--

function Tracker.prototype:UpdateStyle()
	self:UpdateBackdrop()
	self:UpdateIcon()
	self:UpdateSpiral()
	self:UpdateFont()
	self:UpdateText()
end -- UpdateStyle()

function Tracker.prototype:UpdateBackdrop()
	if (self.locked) then
		local sdb = self.style.db.border
		if (sdb[S_SHOW[self.auraOrigin]]) then
			local borderSize = sdb[S_SIZE[self.auraOrigin]]
			if (sdb.noScale) then
				local m = {}
				for size in string.gmatch(select((API_GetCurrentResolution()), API_GetScreenResolutions()), "[0-9]+") do
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
	else
		self.uiFrame:SetBackdrop(UNLOCKED_BACKDROP)
		self.uiFrame:SetBackdropColor(0, 0.75, 0.75, 0.5)
	end
end -- UpdateBackdrop()

function Tracker.prototype:UpdateIcon()
	local sdb = self.style.db.icon
	if (sdb[S_SHOW[self.auraOrigin]]) then
		self.uiIcon:SetTexture(self.db.icon.texture)
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
		local dbspiral = self.db.spiral
		self.uiCooldown.noCooldownCount = sdb.noCC or nil
		self.uiCooldown.noOmniCC = sdb.noCC or nil
		self.uiCooldown:SetReverse(dbspiral.reverse)
		if (self.auraExpires) then
			self.uiCooldown:Show()
			if (dbspiral.mode == "time") then
				self.uiCooldown:SetScript("OnUpdate", nil)
				self.uiCooldown:SetCooldown(self.auraExpires - dbspiral.maxTime, dbspiral.maxTime)
			elseif (dbspiral.mode == "stacks") then
				self.uiCooldown:SetScript("OnUpdate", Cooldown_OnUpdate_Stacks)
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
	local fontsize = max(1, sdb.size + (sdb.sizeMult * self.size))
	self.uiText:SetFont(sdb.font, fontsize, sdb.outline)
end -- UpdateFont()

function Tracker.prototype:UpdateText()
	local text = "0"
	self.uiOverlay:SetScript("OnUpdate", nil)
	local sdb = self.style.db.text
	if (sdb[S_SHOW[self.auraOrigin]]) then
		local dbtext = self.db.text
		-- set text
		if (dbtext.mode == "label") then
			text = self.db.label
		elseif (dbtext.mode == "time") then
			if (self.auraTimeleft) then
				self.uiOverlay:SetScript("OnUpdate", TrackerOverlay_OnUpdate)
				if (self.auraTimeleft >= 3600) then
					text = tostring(ceil(self.auraTimeleft / 3600))..L["_HOURS_ABBREV_"]
				elseif (self.auraTimeleft >= 60) then
					text = tostring(ceil(self.auraTimeleft / 60))..L["_MINUTES_ABBREV_"]
				else
					text = tostring(ceil(self.auraTimeleft or 0))
				end
			end
		elseif (dbtext.mode == "stacks") then
			text = tostring(self.auraStacks or 0)
		end
		-- set color
		if (dbtext.color == "time") then
			self.uiText:SetTextColor(self.style:GetTextColor(self.auraOrigin, false, self.auraTimeleft or 0))
			self.uiOverlay:SetScript("OnUpdate", TrackerOverlay_OnUpdate)
		elseif (dbtext.color == "timeRel") then
			self.uiText:SetTextColor(self.style:GetTextColor(self.auraOrigin, true, (self.auraTimeleft or 0) / (dbtext.maxTime or 0.001)))
			self.uiOverlay:SetScript("OnUpdate", TrackerOverlay_OnUpdate)
		elseif (dbtext.color == "stacks") then
			self.uiText:SetTextColor(self.style:GetTextColor(self.auraOrigin, true, (self.auraStacks or 0) / (dbtext.maxStacks or 0.001)))
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
	Frame_OnLeave(self.uiFrame)
	self.locked = false
	self.uiFrame:EnableMouse(true) -- intercepts clicks, causes OnMouseDown,OnMouseUp
	self.uiFrame:SetMovable(true) -- allows StartMoving
	self.uiFrame:SetScript("OnMouseDown", Frame_OnMouseDown)
	self.uiFrame:SetScript("OnMouseUp", Frame_OnMouseUp)
	self.uiFrame:SetScript("OnHide", Frame_OnMouseUp)
	self.uiFrame:SetScript("OnEnter", nil)
	self.uiFrame:SetScript("OnLeave", nil)
	self:UpdateBackdrop()
end -- Unlock()

function Tracker.prototype:Lock()
	self:StopMoving()
	self.locked = true
	self.uiFrame:SetScript("OnMouseDown", nil)
	self.uiFrame:SetScript("OnMouseUp", nil)
	self.uiFrame:SetScript("OnHide", nil)
	self.uiFrame:SetScript("OnEnter", Frame_OnEnter)
	self.uiFrame:SetScript("OnLeave", Frame_OnLeave)
	self.uiFrame:SetMovable(false) -- allows StartMoving
	local dbtt = self.db.tooltip
	self.uiFrame:EnableMouse(dbtt.showMissing ~= "off" or dbtt.showOthers ~= "off" or dbtt.showMine ~= "off") -- intercepts clicks, causes OnMouseDown,OnMouseUp
	self:UpdateBackdrop()
end -- Lock()


--[[ SHARED OPTIONS TABLE ]]--

local sharedOptions = {
	tracker = {
		type = "group",
		name = L.TRACKER,
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
				order = 10
			},
			removeTracker = {
				type = "execute",
				name = L.REMOVE_TRACKER,
				func = "Remove",
				order = 11
			},
			auratype = {
				type = "select",
				name = L.AURA_TYPE,
				values = {
					buff = L.BUFFS,
					debuff = L.DEBUFFS
				},
				get = function(i) return i.handler.db.auratype end,
				set = function(i,v)
					i.handler.db.auratype = v
					i.handler:UpdateUnitAuras()
				end,
				order = 12
			},
			style = {
				type = "select",
				name = L.TRACKER_STYLE,
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
				order = 13
			},
			auras = {
				type = "input",
				name = L.AURAS,
				usage = L.DESC_OPT_AURAS,
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
				order = 14
			},
			showOthers = {
				type = "toggle",
				name = L.OPT_OTHERS_TRACK,
				get = function(i) return i.handler.db.showOthers end,
				set = function(i,v)
					i.handler.db.showOthers = v
					i.handler:UpdateUnitAuras()
				end,
				order = 15
			},
			showMine = {
				type = "toggle",
				name = L.OPT_MINE_TRACK,
				get = function(i) return i.handler.db.showMine end,
				set = function(i,v)
					i.handler.db.showMine = v
					i.handler:UpdateUnitAuras()
				end,
				order = 16
			}
		}
	},
	icon = {
		type = "group",
		name = L.ICON,
		order = 2,
		args = {
			autoIcon = {
				type = "toggle",
				name = L.AUTOUPDATE,
				desc = L.DESC_OPT_AUTOUPDATE,
				get = function(i) return i.handler.db.icon.autoIcon end,
				set = function(i,v)
					i.handler.db.icon.autoIcon = v
					if (v) then i.handler:UpdateUnitAuras() end
				end,
				order = 20
			},
			texture = {
				type = "input",
				name = L.TEXTURE,
				get = function(i) return i.handler.db.icon.texture end,
				set = function(i,v)
					i.handler.db.icon.texture = v
					i.handler:UpdateIcon()
				end,
				order = 21
			}
		}
	},
	spiral = {
		type = "group",
		name = L.SPIRAL,
		order = 3,
		args = {
			mode = {
				type = "select",
				name = L.DISPLAY,
				values = {
					stacks = L.STACKS,
					time = L.TIME_LEFT
				},
				get = function(i) return i.handler.db.spiral.mode end,
				set = function(i,v)
					i.handler.db.spiral.mode = v
					i.handler:UpdateSpiral()
				end,
				order = 30
			},
			reverse = {
				type = "select",
				name = L.DIRECTION,
				values = {
					drain = L.DRAIN_CLOCKWISE,
					fill = L.FILL_CLOCKWISE
				},
				get = function(i) return (i.handler.db.spiral.reverse and "drain") or "fill" end,
				set = function(i,v)
					i.handler.db.spiral.reverse = ((v == "drain") and true) or false
					i.handler:UpdateSpiral()
				end,
				order = 31
			},
			maxTime = {
				type = "group",
				name = L.MAXIMUM_DURATION,
				inline = true,
				order = 32,
				args = {
					mode = {
						type = "select",
						name = L.AUTOUPDATE_MODE,
						disabled = function(i) return i.handler.db.spiral.mode ~= "time" end,
						values = {
							auto = L.UPDATE_ALWAYS,
							autoUp = L.UPDATE_UPWARDS,
							static = L.STATIC
						},
						get = function(i) return i.handler.db.spiral.maxTimeMode end,
						set = function(i,v)
							i.handler.db.spiral.maxTimeMode = v
							if (v ~= "static") then i.handler:UpdateUnitAuras() end
						end,
						order = 320
					},
					maxTime = {
						type = "input",
						name = L.VALUE,
						disabled = function(i) return i.handler.db.spiral.mode ~= "time" end,
						get = function(i) return tostring(i.handler.db.spiral.maxTime or "") end,
						set = function(i,v)
							i.handler.db.spiral.maxTime = tonumber(v) or false
							if (i.handler.db.spiral.mode == "time") then i.handler:UpdateSpiral() end
						end,
						order = 321
					}
				}
			},
			maxStacks = {
				type = "group",
				name = L.MAXIMUM_STACKS,
				inline = true,
				order = 33,
				args = {
					mode = {
						type = "select",
						name = L.AUTOUPDATE_MODE,
						disabled = function(i) return i.handler.db.spiral.mode ~= "stacks" end,
						values = {
							auto = L.UPDATE_ALWAYS,
							autoUp = L.UPDATE_UPWARDS,
							static = L.STATIC
						},
						get = function(i) return i.handler.db.spiral.maxStacksMode end,
						set = function(i,v)
							i.handler.db.spiral.maxStacksMode = v
							if (v ~= "static") then i.handler:UpdateUnitAuras() end
						end,
						order = 330
					},
					maxStacks = {
						type = "input",
						name = L.VALUE,
						disabled = function(i) return i.handler.db.spiral.mode ~= "stacks" end,
						get = function(i) return tostring(i.handler.db.spiral.maxStacks or "") end,
						set = function(i,v)
							i.handler.db.spiral.maxStacks = tonumber(v) or false
							if (i.handler.db.spiral.mode == "stacks") then i.handler:UpdateSpiral() end
						end,
						order = 331
					}
				}
			}
		}
	},
	text = {
		type = "group",
		name = L.TEXT,
		order = 4,
		args = {
			mode = {
				type = "select",
				name = L.DISPLAY,
				values = {
					label = L.LABEL,
					stacks = L.STACKS,
					time = L.TIME_LEFT
				},
				get = function(i) return i.handler.db.text.mode end,
				set = function(i,v)
					i.handler.db.text.mode = v
					i.handler:UpdateText()
				end,
				order = 40
			},
			color = {
				type = "select",
				name = L.COLOR_BY,
				values = {
					time = L.ABSOLUTE_DURATION,
					timeRel = L.RELATIVE_DURATION,
					stacks = L.RELATIVE_STACKS
				},
				get = function(i) return i.handler.db.text.color end,
				set = function(i,v)
					i.handler.db.text.color = v
					i.handler:UpdateText()
				end,
				order = 41
			},
			maxTime = {
				type = "group",
				name = L.MAXIMUM_DURATION,
				inline = true,
				order = 42,
				args = {
					mode = {
						type = "select",
						name = L.AUTOUPDATE_MODE,
						disabled = function(i) return i.handler.db.text.mode ~= "time" and i.handler.db.text.color ~= "timeRel" end,
						values = {
							auto = L.UPDATE_ALWAYS,
							autoUp = L.UPDATE_UPWARDS,
							static = L.STATIC
						},
						get = function(i) return i.handler.db.text.maxTimeMode end,
						set = function(i,v)
							i.handler.db.text.maxTimeMode = v
							if (v ~= "static") then i.handler:UpdateUnitAuras() end
						end,
						order = 420
					},
					maxTime = {
						type = "input",
						name = L.VALUE,
						disabled = function(i) return i.handler.db.text.mode ~= "time" and i.handler.db.text.color ~= "timeRel" end,
						get = function(i) return tostring(i.handler.db.text.maxTime or "") end,
						set = function(i,v)
							i.handler.db.text.maxTime = tonumber(v) or false
							if (i.handler.db.text.color == "timeRel") then i.handler:UpdateText() end
						end,
						order = 421
					}
				}
			},
			maxStacks = {
				type = "group",
				name = L.MAXIMUM_STACKS,
				inline = true,
				order = 43,
				args = {
					mode = {
						type = "select",
						name = L.AUTOUPDATE_MODE,
						disabled = function(i) return i.handler.db.text.mode ~= "stacks" and i.handler.db.text.color ~= "stacks" end,
						values = {
							auto = L.UPDATE_ALWAYS,
							autoUp = L.UPDATE_UPWARDS,
							static = L.STATIC
						},
						get = function(i) return i.handler.db.text.maxStacksMode end,
						set = function(i,v)
							i.handler.db.text.maxStacksMode = v
							if (v ~= "static") then i.handler:UpdateUnitAuras() end
						end,
						order = 430
					},
					maxStacks = {
						type = "input",
						name = L.VALUE,
						disabled = function(i) return i.handler.db.text.mode ~= "stacks" and i.handler.db.text.color ~= "stacks" end,
						get = function(i) return tostring(i.handler.db.text.maxStacks or "") end,
						set = function(i,v)
							i.handler.db.text.maxStacks = tonumber(v) or false
							if (i.handler.db.text.color == "stacks") then i.handler:UpdateText() end
						end,
						order = 431
					}
				}
			}
		}
	},
	tooltip = {
		type = "group",
		name = L.TOOLTIP,
		order = 5,
		args = {
			modeMissing = {
				type = "select",
				name = L.OPT_MISSING_DISPLAY,
				values = {
					summary = L.SUMMARY,
					off = L.NOTHING
				},
				get = function(i) return i.handler.db.tooltip.showMissing end,
				set = function(i,v)
					i.handler.db.tooltip.showMissing = v
					if (v ~= "off") then
						i.handler.uiFrame:EnableMouse(true) -- intercepts clicks, causes OnMouseDown,OnMouseUp
					elseif (i.handler.db.tooltip.showOthers == "off" and i.handler.db.tooltip.showMine == "off" and i.handler.locked) then
						i.handler.uiFrame:EnableMouse(false) -- intercepts clicks, causes OnMouseDown,OnMouseUp
					end
				end,
				order = 50
			},
			_0 = {
				type = "description",
				name = "",
				width = "full",
				order = 51
			},
			modeOthers = {
				type = "select",
				name = L.OPT_OTHERS_DISPLAY,
				values = {
					aura = L.AURAS_TOOLTIP,
					summary = L.SUMMARY,
					off = L.NOTHING
				},
				get = function(i) return i.handler.db.tooltip.showOthers end,
				set = function(i,v)
					i.handler.db.tooltip.showOthers = v
					if (v ~= "off") then
						i.handler.uiFrame:EnableMouse(true) -- intercepts clicks, causes OnMouseDown,OnMouseUp
					elseif (i.handler.db.tooltip.showMissing == "off" and i.handler.db.tooltip.showMine == "off" and i.handler.locked) then
						i.handler.uiFrame:EnableMouse(false) -- intercepts clicks, causes OnMouseDown,OnMouseUp
					end
				end,
				order = 52
			},
			modeMine = {
				type = "select",
				name = L.OPT_MINE_DISPLAY,
				values = {
					aura = L.AURAS_TOOLTIP,
					summary = L.SUMMARY,
					off = L.NOTHING
				},
				get = function(i) return i.handler.db.tooltip.showMine end,
				set = function(i,v)
					i.handler.db.tooltip.showMine = v
					if (v ~= "off") then
						i.handler.uiFrame:EnableMouse(true) -- intercepts clicks, causes OnMouseDown,OnMouseUp
					elseif (i.handler.db.tooltip.showMissing == "off" and i.handler.db.tooltip.showOthers == "off" and i.handler.locked) then
						i.handler.uiFrame:EnableMouse(false) -- intercepts clicks, causes OnMouseDown,OnMouseUp
					end
				end,
				order = 53
			},
			_1 = {
				type = "description",
				name = L.WARN_TOOLTIP_BLOCKS_MOUSE,
				width = "double",
				order = 54
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
	self.optionsTable.name = self.db.label or self.db.auras[1] or L.NEW_TRACKER
	return self.optionsTable
end -- GetOptionsTable()


--[[ INIT ]]--

Auracle:__tracker(Tracker, DB_DEFAULT_TRACKER, DB_VALID_TRACKER)

