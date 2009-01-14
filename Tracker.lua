-- define and register class definition
local LibOOP = LibStub("LibOOP-0.2")
local Tracker = LibOOP:Class()
AuraHUD:RegisterTracker(Tracker)

-- initialize local static data
local ICON_QM = "Interface\\Icons\\INV_Misc_QuestionMark"

-- initialize local runtime data
local trackerPool = {}


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


--[[ EVENT HANDLERS ]]--

local function Tracker_OnMouseDown(self, button)
	if (button == "LeftButton") then
		self.AuraHUD_tracker:StartMoving()
	end
end -- Tracker_OnMouseDown()

local function Tracker_OnUpdate(self)
	self.AuraHUD_tracker:UpdateMovingPosition()
end -- Tracker_OnUpdate()

local function Tracker_OnMouseUp(self, button)
	if (button == "LeftButton") then
		self.AuraHUD_tracker:StopMoving()
	end
end -- Tracker_OnMouseUp()

local function Tracker_OnHide(self)
	self.AuraHUD_tracker:StopMoving()
end -- Tracker_OnHide()

local function Tracker_OnEnter(self)
	local tracker = self.AuraHUD_tracker
	if (self:IsVisible() and tracker.auraApplied) then
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
		GameTooltip:SetUnitAura(tracker.unit, tracker.auraIndex, tracker.flag)
	end
end -- Tracker_OnEnter()

local function Tracker_OnLeave(self)
	if ((GameTooltip:GetOwner()) == self) then
		GameTooltip:Hide()
	end
end -- Tracker_OnLeave()

local function TrackerTextFrame_OnUpdate(self, elapsed)
	if (self.AuraHUD_timeleft) then
		self.AuraHUD_timeleft = self.AuraHUD_timeleft - elapsed
		local timestr
		if (self.AuraHUD_timeleft >= 3600) then
			timestr = tostring(ceil(self.AuraHUD_timeleft / 3600)).."h"
		elseif (self.AuraHUD_timeleft >= 60) then
			timestr = tostring(ceil(self.AuraHUD_timeleft / 60)).."m"
		elseif (self.AuraHUD_timeleft > 0) then
			timestr = tostring(ceil(self.AuraHUD_timeleft)) -- TODO precision
		end
		if (timestr ~= self.AuraHUD_timestr) then
			self.AuraHUD_timestr = timestr
			-- TODO color prefs
			local text = self.AuraHUD_tracker.uiText
			if (self.AuraHUD_timeleft > 10) then 
				text:SetTextColor(0, 1, 0)
			elseif (self.AuraHUD_timeleft > 5) then
				text:SetTextColor(1, 0.5, 0)
			else
				text:SetTextColor(1, 0, 0)
			end
			text:SetText(timestr)
		end
	end
end -- TrackerTextFrame_OnUpdate()


--[[ CONSTRUCT & DESTRUCT ]]--

function Tracker:New(db, window, parentFrame)
	-- re-use a tracker from the pool, or create a new one
	local tracker = next(trackerPool)
	if (not tracker) then
		tracker = self:Super("New")
		tracker.uiFrame = CreateFrame("Frame") -- UIObject,Region
		tracker.uiFrame:SetFrameStrata("LOW")
		tracker.uiFrame:EnableMouse(true) -- intercepts clicks, causes OnMouseDown,OnMouseUp
		tracker.uiFrame:SetClampedToScreen(true) -- so WoW polices position, no matter how it changes (StartMoving,SetPoint,etc)
		tracker.uiFrame:SetMovable(true) -- allows StartMoving
		tracker.uiFrame.AuraHUD_tracker = tracker
		tracker.uiIcon = tracker.uiFrame:CreateTexture(--[[nil, "BACKGROUND"]]) -- UIObject,Region,LayeredRegion
		tracker.uiIcon:SetAllPoints()
		tracker.uiIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- left, right, top, bottom (0,0=UL) to strip the borders off the texture
		tracker.uiCooldown = CreateFrame("Cooldown", nil, tracker.uiFrame) -- UIObject,Region,Frame
		tracker.uiCooldown:SetAllPoints()
		tracker.uiCooldown:SetReverse(true)
		tracker.uiTextFrame = CreateFrame("Frame", nil, tracker.uiFrame) -- UIObject,Region
		tracker.uiTextFrame:SetAllPoints()
		tracker.uiTextFrame.AuraHUD_tracker = tracker
		tracker.uiText = tracker.uiTextFrame:CreateFontString(--[[nil, "OVERLAY"]]) -- UIObject,FontInstance,Region,LayeredRegion
		tracker.uiText:SetPoint("CENTER") -- SetAllPoints() makes it just display "..." if it would overflow
		tracker.uiText:SetNonSpaceWrap(false)
		tracker.uiText:SetJustifyH("CENTER")
		tracker.uiText:SetJustifyV("MIDDLE")
	end
	trackerPool[tracker] = nil
	
	-- (re?)initialize tracker
	tracker.window = window
	tracker.db = db
	tracker.locked = true
	tracker.moving = false
	tracker.unit = window.db.unit
	tracker.flag = ((db.auratype == "buff") and "HELPFUL") or "HARMFUL"
	tracker.size = 12
	tracker.auraIndex = false
	tracker.auraOrigin = false
	tracker.auraApplied = false
	tracker.auraExpires = false
	
	-- (re?)initialize frames
	tracker.uiFrame:SetParent(parentFrame)
	tracker.uiFrame:Show()
	tracker.uiFrame:SetBackdrop({
		edgeFile = "Interface\\Addons\\AuraHUD\\white", edgeSize = 1 -- TODO sharedmedia borders
	--	insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	tracker.uiTextFrame:SetScript("OnUpdate", TrackerTextFrame_OnUpdate)
	tracker:Lock()
	
	-- (re?)apply preferences
	tracker:UpdateFont()
	tracker:UpdateAppearance()
	
	return tracker
end -- New()

function Tracker.prototype:Destroy()
	self:StopMoving()
	-- clean up frame
	self.uiTextFrame:Hide()
	self.uiTextFrame:SetScript("OnUpdate", nil)
	self.uiCooldown:Hide()
	self.uiFrame:Hide()
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
	self.locked = nil
	self.moving = nil
	self.unit = nil
	self.flag = nil
	self.size = nil
	self.auraIndex = nil
	self.auraOrigin = nil
	self.auraApplied = nil
	self.auraExpires = nil
	-- add tracker to the pool for later re-use
	trackerPool[self] = true
end -- Destroy()

function Tracker.prototype:Remove()
	if (self.window:RemoveTracker(self)) then
		self:Destroy()
	end
end -- Remove()


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
end -- BeginAuraUpdate()

function Tracker.prototype:UpdateAura(now,index,name,rank,icon,count,atype,duration,expires,origin,stealable)
	-- TODO optimize
	-- if we already have a qualifying, non-expiring aura, we don't care about anything else
	if (self.update_applied and not self.update_expires) then
		return
	end
	local ipairs = ipairs
	for _,auraname in ipairs(self.db.auras) do
		if (name == auraname) then
			if (self.db.filter.origin[origin]) then
				if (expires == 0 or not self.update_applied or expires > self.update_expires) then
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
				end
			end
		end
	end
end -- UpdateAura()

function Tracker.prototype:EndAuraUpdate(now,total)
	-- if we're (now?) satisfied...
	local unpack = unpack
	if (self.update_applied) then
		-- ...and we weren't satisfied before, or were satisfied from a different source:
		if (not self.auraApplied or self.auraOrigin ~= self.update_origin) then
			if (self.db.icon.desaturateMissing) then
				self.uiIcon:SetDesaturated(false)
			end
			if (self.update_origin == "me") then
				self.uiFrame:SetBackdropBorderColor(unpack(self.db.border.colorMine))
				self.uiIcon:SetVertexColor(unpack(self.db.icon.colorMine))
			else
				self.uiFrame:SetBackdropBorderColor(unpack(self.db.border.colorOthers))
				self.uiIcon:SetVertexColor(unpack(self.db.icon.colorOthers))
			end
		end
		-- ...and the icon changed:
		if (self.update_icon ~= self.db.icon.texture) then
			if (self.db.icon.autoTexture or self.db.icon.texture == ICON_QM) then
				self.db.icon.texture = self.update_icon
				self.uiIcon:SetTexture(self.update_icon)
			end
		end
		-- ...and the expiration changed...
		if (self.update_expires ~= self.auraExpires) then
			-- ...and the expiration isn't "never"...
			if (self.update_expires) then
				-- ...and our spiral shows expiration:
				if (self.db.spiral.mode == "time") then
					if (self.db.spiral.autoLength or self.db.spiral.length <= 0) then
						self.db.spiral.length = self.update_expires - self.update_applied
					end
					self.uiCooldown.noCooldownCount = (self.db.spiral.noCC or nil)
					self.uiCooldown.noOmniCC = (self.db.spiral.noCC or nil)
					self.uiCooldown:Show()
					self.uiCooldown:SetCooldown(self.update_applied, self.db.spiral.length)
				end
				-- ...and our text shows expiration:
				if (self.db.text.mode == "time") then
					self.uiTextFrame:Show()
					self.uiTextFrame.AuraHUD_timeleft = self.update_expires - now
				end
			else -- ...or, if the expiration IS "never":
				self.uiCooldown:Hide()
				self.uiTextFrame:Hide()
				self.uiTextFrame.AuraHUD_timeleft = nil
				self.uiTextFrame.AuraHUD_timestr = nil
			end
		end
	else -- ...or, we're (no longer?) satisfied...
		-- ...and we were satisfied before:
		if (self.auraApplied) then
			self.uiFrame:SetBackdropBorderColor(unpack(self.db.border.colorMissing))
			if (self.db.icon.desaturateMissing) then
				self.uiIcon:SetDesaturated(true)
			end
			self.uiIcon:SetVertexColor(unpack(self.db.icon.colorMissing))
		end
		-- ...and we used to have an expiration:
		if (self.auraExpires) then
			-- ...and our spiral shows expiration:
			if (self.db.spiral.mode == "time") then
				self.uiCooldown:Hide()
			end
			-- ...and our text shows expiration:
			if (self.db.text.mode == "time") then
				self.uiTextFrame:Hide()
				self.uiTextFrame.AuraHUD_timeleft = nil
				self.uiTextFrame.AuraHUD_timestr = nil
			end
		end
	end
	-- update our state
	self.auraIndex = self.update_index
	self.auraOrigin = self.update_origin
	self.auraApplied = self.update_applied
	self.auraExpires = self.update_expires
	self.update_index = nil
	self.update_icon = nil
	self.update_origin = nil
	self.update_applied = nil
	self.update_expires = nil
end -- EndAuraUpdate()


--[[ UI METHODS ]]--

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
		self.moving_frameX = nil
		self.moving_frameY = nil
		self.moving_screenX = nil
		self.moving_screenY = nil
		self.moving_lastX = nil
		self.moving_lastY = nil
	end
end -- StopMoving()

function Tracker.prototype:SetLayout(x, y, borderSize, trackerSize)
	if (not self.moving) then
		self.size = trackerSize
		self.uiFrame:ClearAllPoints()
		self.uiFrame:SetPoint("TOPLEFT", self.uiFrame:GetParent(), "TOPLEFT", x, -y) -- WoW's 0,0 is lowerleft
		self.uiFrame:SetWidth(trackerSize + (2 * borderSize))
		self.uiFrame:SetHeight(trackerSize + (2 * borderSize))
		self.uiIcon:ClearAllPoints()
		self.uiIcon:SetPoint("TOPLEFT", self.uiFrame, "TOPLEFT", borderSize, -borderSize)
		self.uiIcon:SetPoint("BOTTOMRIGHT", self.uiFrame, "BOTTOMRIGHT", -borderSize, borderSize)
		if (self.db.text.sizeMult ~= 0) then
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
end -- Lock()

function Tracker.prototype:UpdateFont()
	local size = (self.db.text.sizeMult * self.size) + self.db.text.size
	self.uiText:SetFont(self.db.text.font, size, self.db.text.outline)
end -- UpdateFont()

function Tracker.prototype:UpdateAppearance()
	local unpack = unpack
	self.uiIcon:SetTexture(self.db.icon.texture)
	if (self.auraApplied) then
		self.uiIcon:SetDesaturated(false)
		if (self.auraOrigin == "me") then
			self.uiFrame:SetBackdropBorderColor(unpack(self.db.border.colorMine))
			self.uiIcon:SetVertexColor(unpack(self.db.icon.colorMine))
		else
			self.uiFrame:SetBackdropBorderColor(unpack(self.db.border.colorOthers))
			self.uiIcon:SetVertexColor(unpack(self.db.icon.colorOthers))
		end
		if (self.auraExpires) then
			if (self.db.spiral.mode == "time") then
				self.uiCooldown.noCooldownCount = (self.db.spiral.noCC or nil)
				self.uiCooldown.noOmniCC = (self.db.spiral.noCC or nil)
				self.uiCooldown:Show()
				self.uiCooldown:SetCooldown(self.auraApplied, self.db.spiral.length)
			end
			if (self.db.text.mode == "time") then
				self.uiTextFrame:Show()
				self.uiTextFrame.AuraHUD_timeleft = self.auraExpires - GetTime()
			end
		else
			self.uiCooldown:Hide()
			self.uiTextFrame:Hide()
			self.uiTextFrame.AuraHUD_timeleft = nil
			self.uiTextFrame.AuraHUD_timestr = nil
		end
	else
		self.uiFrame:SetBackdropBorderColor(unpack(self.db.border.colorMissing))
		self.uiIcon:SetDesaturated(self.db.icon.desaturateMissing)
		self.uiIcon:SetVertexColor(unpack(self.db.icon.colorMissing))
		self.uiCooldown:Hide()
		if (self.db.text.mode == "time") then
			self.uiTextFrame:Hide()
			self.uiTextFrame.AuraHUD_timeleft = nil
			self.uiTextFrame.AuraHUD_timestr = nil
		end
	end
end -- UpdateAppearance()


--[[ MENU METHODS ]]--

function Tracker.prototype:GetConfigOption(i, v1, v2, v3, v4)
	-- i[1] == "window#"
	-- i[2] == "tracker#"
	if (i[4] ~= nil) then
		if (i[3] == "border" or i[3] == "icon") and (i[4] == "colorMissing" or i[4] == "colorMine" or i[4] == "colorOthers") then
			return unpack(self.db[i[3]][i[4]])
		elseif (type(self.db[i[3]][i[4]]) ~= "nil") then
			return self.db[i[3]][i[4]]
		end
	elseif (i[3] ~= nil) then
		if (i[3] == "auras") then
			local str = ""
			for _,auraname in ipairs(self.db.auras) do
				str = str .. "\n" .. auraname
			end
			return strsub(str,2)
		elseif (i[3] == "filter_origin") then
			return self.db.filter.origin[v1]
		elseif (self.db[i[3]] ~= nil) then
			return self.db[i[3]]
		end
	end
	AuraHUD:DebugCall("Tracker.GetConfigOption", i, v1, v2, v3, v4)
end -- GetConfigOption()

function Tracker.prototype:SetConfigOption(i, v1, v2, v3, v4)
	-- i[1] == "window#"
	-- i[2] == "tracker#"
	if (i[4] ~= nil) then
		if (i[3] == "border" or i[3] == "icon") and (i[4] == "colorMissing" or i[4] == "colorMine" or i[4] == "colorOthers") then
			local c = self.db[i[3]][i[4]]
			c[1],c[2],c[3],c[4] = v1,v2,v3,v4
		else
			self.db[i[3]][i[4]] = v1
		end
		self:UpdateFont()
		self:UpdateAppearance()
		if ((i[3] == "icon" and i[4] == "autoTexture") or (i[3] == "spiral" and i[4] == "autoLength")) then
			self:UpdateUnitAuras()
		end
	elseif (i[3] == "label") then
		v1 = strtrim(v1)
		if (v1 == "") then
			v1 = false
		end
		self.db.label = v1
		AuraHUD:UpdateOptionsTable()
	elseif (i[3] == "auratype") then
		self.db.auratype = v1
		self:UpdateUnitAuras()
	elseif (i[3] == "auras") then
		wipe(self.db.auras)
		for aura in string.gmatch(v1, "[^\n\r]+") do
			tinsert(self.db.auras, aura)
			--print(aura)
		end
		self:UpdateUnitAuras()
	elseif (i[3] == "filter_origin") then
		self.db.filter.origin[v1] = v2
		self:UpdateUnitAuras()
	else
		AuraHUD:DebugCall("Tracker.SetConfigOption", i, v1, v2, v3, v4)
	end
end -- SetConfigOption()

function Tracker.prototype:GetOptionsTable(DB_TRACKER_OPTIONS)
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
				do_removeTracker = {
					type = "execute",
					name = "Remove This Tracker",
					func = "Remove",
					order = 12
				},
				auratype = {
					type = "select",
					name = "Aura Type",
					values = DB_TRACKER_OPTIONS.auratype,
					order = 13
				},
				auras = {
					type = "input",
					name = "Auras",
					usage = "One aura name per line",
					multiline = true,
					width = "double",
					order = 14
				},
				filter_origin = {
					type = "multiselect",
					name = "Show auras applied by...",
					desc = "Origin",
					values = DB_TRACKER_OPTIONS.filter_origin,
					order = 15
				},
				border = {
					type = "group",
					name = "Border",
					inline = true,
					order = 20,
					args = {
						colorMissing = {
							type = "color",
							name = "Color when missing",
							hasAlpha = true,
							order = 21
						},
						colorMine = {
							type = "color",
							name = "Color when mine",
							hasAlpha = true,
							order = 22
						},
						colorOthers = {
							type = "color",
							name = "Color when others",
							hasAlpha = true,
							order = 23
						}
					}
				},
				icon = {
					type = "group",
					name = "Background",
					inline = true,
					order = 30,
					args = {
						texture = {
							type = "input",
							name = "Icon",
							width = "full",
							order = 31
						},
						autoTexture = {
							type = "toggle",
							name = "Autoupdate icon",
							order = 32
						},
						desaturateMissing = {
							type = "toggle",
							name = "Grey-out icon when missing",
							width = "double",
							order = 33
						},
						colorMissing = {
							type = "color",
							name = "Tint when missing",
							hasAlpha = true,
							order = 34
						},
						colorMine = {
							type = "color",
							name = "Tint when mine",
							hasAlpha = true,
							order = 35
						},
						colorOthers = {
							type = "color",
							name = "Tint when others",
							hasAlpha = true,
							order = 36
						}
					}
				},
				spiral = {
					type = "group",
					name = "Cooldown Spiral",
					inline = true,
					order = 40,
					args = {
						noCC = {
							type = "toggle",
							name = "Disable external cooldown count",
							width = "double",
							order = 41
						},
						length = {
							type = "range",
							name = "Maximum duration",
							min = 1,
							max = 300,
							step = 1,
							order = 42
						},
						autoLength = {
							type = "toggle",
							name = "Autoupdate maximum duration",
							width = "full",
							order = 43
						}
					}
				},
				text = {
					type = "group",
					name = "Text",
					inline = true,
					order = 50,
					args = {
						font = {
							type = "input",
							name = "Font",
							width = "full",
							order = 51
						},
						sizeMult = {
							type = "range",
							name = "Relative size",
							desc = "Effective font size is (relativeSize * trackerSize) + staticSize",
							min = 0,
							max = 2,
							step = 0.05,
							order = 52
						},
						size = {
							type = "range",
							name = "Static size",
							desc = "Effective font size is (relativeSize * trackerSize) + staticSize",
							min = 0,
							max = 64,
							step = 1,
							order = 53
						},
						outline = {
							type = "select",
							name = "Outline",
							values = DB_TRACKER_OPTIONS.text.outline,
							order = 54
						}
					}
				}
			}
		}
	end
	self.optionsTable.name = self.db.label or "(unlabeled)"
	return self.optionsTable
end -- GetOptionsTable()
