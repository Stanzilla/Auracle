local LibOOP
--@alpha@
LibOOP = LibStub("LibOOP-1.0-alpha", true)
--@end-alpha@
LibOOP = LibOOP or LibStub("LibOOP-1.0") or error("Auracle: Required library LibOOP not found")
local TrackerStyle = LibOOP:Class()

local LIB_AceLocale = LibStub("AceLocale-3.0") or error("Auracle: Required library AceLocale-3.0 not found")
local L = LIB_AceLocale:GetLocale("Auracle")


--[[ DECLARATIONS ]]--

-- constants

local S_5     = {                         others="others5",     mine="mine5"     }
local S_10    = {                         others="others10",    mine="mine10"    }
local S_20    = {                         others="others20",    mine="mine20"    }
local S_30    = {                         others="others30",    mine="mine30"    }
local S_40    = {                         others="others40",    mine="mine40"    }
local S_60    = {                         others="others60",    mine="mine60"    }
local S_80    = {                         others="others80",    mine="mine80"    }
local S_100   = {                         others="others100",   mine="mine100"   }
local S_LONG  = {                         others="othersLong",  mine="mineLong"  }

local DB_DEFAULT_TRACKERSTYLE = {
	name = L.DEFAULT,
	border = {
		noScale        = true,
		showMissing    = true,
		sizeMissing    = 1,
		colorMissing   = {   1,   0,   0,   1 },
		showOthers     = true,
		sizeOthers     = 1,
		colorOthers    = {   0,   1,   0,   1 },
		showMine       = true,
		sizeMine       = 1,
		colorMine      = {   0,   1,   1,   1 }
	},
	icon = {
		zoom           = true,
		showMissing    = true,
		grayMissing    = false,
		colorMissing   = {   1, 0.3, 0.3,   1 },
		showOthers     = true,
		grayOthers     = false,
		colorOthers    = {   1,   1,   1,   1 },
		showMine       = true,
		grayMine       = false,
		colorMine      = {   1,   1,   1,   1 }
	},
	spiral = {
		showOthers     = true,
		showMine       = true,
		noCC           = true
	},
	text = {
		font           = "Fonts\\FRIZQT__.TTF",
		outline        = "OUTLINE", -- nil|OUTLINE|THICKOUTLINE
		sizeMult       = 0.65,
		size           = 0,
		smooth         = true,
		smoothRate     = 0.5,
		showMissing    = false,
		colorMissing   = {   1,   0,   0,   1 },
		showOthers     = true,
		showMine       = true,
		colorRel = {
			others20   = {   1, 0.5,   0,   1 },
			mine20     = {   1, 0.5,   0,   1 },
			others40   = {   1,   1,   0,   1 },
			mine40     = {   1,   1,   0,   1 },
			others60   = { 0.5,   1,   0,   1 },
			mine60     = { 0.5,   1,   0,   1 },
			others80   = {   0,   1,   0,   1 },
			mine80     = {   0,   1,   0,   1 },
			others100  = {   1,   1,   1,   1 },
			mine100    = {   1,   1,   1,   1 }
		},
		colorTime = {
			others5    = {   1, 0.5,   0,   1 },
			mine5      = {   1, 0.5,   0,   1 },
			others10   = {   1,   1,   0,   1 },
			mine10     = {   1,   1,   0,   1 },
			others20   = { 0.5,   1,   0,   1 },
			mine20     = { 0.5,   1,   0,   1 },
			others30   = {   0,   1,   0,   1 },
			mine30     = {   0,   1,   0,   1 },
			othersLong = {   1,   1,   1,   1 },
			mineLong   = {   1,   1,   1,   1 }
		}
	}
} -- {DB_DEFAULT_TRACKERSTYLE}

local DB_VALID_TRACKERSTYLE = {
	name = "string",
	border = {
		noScale        = "boolean",
		showMissing    = "boolean",
		sizeMissing    = "number",
		colorMissing   = {"number","number","number","number"},
		showOthers     = "boolean",
		sizeOthers     = "number",
		colorOthers    = {"number","number","number","number"},
		showMine       = "boolean",
		sizeMine       = "number",
		colorMine      = {"number","number","number","number"}
	},
	icon = {
		zoom           = "boolean",
		showMissing    = "boolean",
		grayMissing    = "boolean",
		colorMissing   = {"number","number","number","number"},
		showOthers     = "boolean",
		grayOthers     = "boolean",
		colorOthers    = {"number","number","number","number"},
		showMine       = "boolean",
		grayMine       = "boolean",
		colorMine      = {"number","number","number","number"}
	},
	spiral = {
		showOthers     = "boolean",
		showMine       = "boolean",
		noCC           = "boolean",
	},
	text = {
		font           = "string",
		outline        = "string",
		sizeMult       = "number",
		size           = "number",
		smooth         = "boolean",
		smoothRate     = "number",
		showMissing    = "boolean",
		colorMissing   = {"number","number","number","number"},
		showOthers     = "boolean",
		showMine       = "boolean",
		colorRel = {
			others20   = {"number","number","number","number"},
			mine20     = {"number","number","number","number"},
			others40   = {"number","number","number","number"},
			mine40     = {"number","number","number","number"},
			others60   = {"number","number","number","number"},
			mine60     = {"number","number","number","number"},
			others80   = {"number","number","number","number"},
			mine80     = {"number","number","number","number"},
			others100  = {"number","number","number","number"},
			mine100    = {"number","number","number","number"}
		},
		colorTime = {
			others5    = {"number","number","number","number"},
			mine5      = {"number","number","number","number"},
			others10   = {"number","number","number","number"},
			mine10     = {"number","number","number","number"},
			others20   = {"number","number","number","number"},
			mine20     = {"number","number","number","number"},
			others30   = {"number","number","number","number"},
			mine30     = {"number","number","number","number"},
			othersLong = {"number","number","number","number"},
			mineLong   = {"number","number","number","number"}
		}
	}
} -- {DB_VALID_TRACKERSTYLE}

-- library references

local LIB_LibSharedMedia


--[[ CLASS METHODS ]]--

function TrackerStyle:Initialize()
	LIB_LibSharedMedia = LibStub("LibSharedMedia-3.0", true) -- optional
end -- Initialize()

function TrackerStyle:UpdateSavedVars(version, db)
	return 0
end -- UpdateSavedVars()


--[[ CONSTRUCT & DESTRUCT ]]--

function TrackerStyle:New(db)
	local obj = self:Super("New")
	obj.db = db
	return obj
end -- New()

function TrackerStyle.prototype:Destroy()
	self.db = nil
end -- Destroy()


--[[ STYLE METHODS ]]--

function TrackerStyle.prototype:GetTextColor(status, relative, value)
	if (not status) then
		return unpack(self.db.text.colorMissing)
	end
	if (self.db.text.smooth) then
		if (relative) then
			-- smooth, relative
			local c,lo,hi = self.db.text.colorRel,nil,nil
			if     (value > 0.8) then lo=c[S_80[status]];           hi=c[S_100[status]]; value=(value-0.8)/0.2
			elseif (value > 0.6) then lo=c[S_60[status]];           hi=c[S_80[status]];  value=(value-0.6)/0.2
			elseif (value > 0.4) then lo=c[S_40[status]];           hi=c[S_60[status]];  value=(value-0.4)/0.2
			elseif (value > 0.2) then lo=c[S_20[status]];           hi=c[S_40[status]];  value=(value-0.2)/0.2
			else                      lo=self.db.text.colorMissing; hi=c[S_20[status]];  value=value/0.2
			end
			local lowValue = 1 - value
			return (lowValue*lo[1]+value*hi[1]),(lowValue*lo[2]+value*hi[2]),(lowValue*lo[3]+value*hi[3]),(lowValue*lo[4]+value*hi[4])
		end
		-- smooth, not relative
		local c,lo,hi = self.db.text.colorTime,nil,nil
		if     (value > 30) then lo=c[S_30[status]];           hi=c[S_LONG[status]]; value=min(1.0, (value-30)/30)
		elseif (value > 20) then lo=c[S_20[status]];           hi=c[S_30[status]];   value=(value-20)/10
		elseif (value > 10) then lo=c[S_10[status]];           hi=c[S_20[status]];   value=(value-10)/10
		elseif (value > 5)  then lo=c[S_5[status]];            hi=c[S_10[status]];   value=(value-5)/5
		else                     lo=self.db.text.colorMissing; hi=c[S_5[status]];    value=value/5
		end
		local lowValue = 1 - value
		return (lowValue*lo[1]+value*hi[1]),(lowValue*lo[2]+value*hi[2]),(lowValue*lo[3]+value*hi[3]),(lowValue*lo[4]+value*hi[4])
	elseif (relative) then
		-- not smooth, relative
		if     (value > 0.8) then return unpack(self.db.text.colorRel[S_100[status]]);
		elseif (value > 0.6) then return unpack(self.db.text.colorRel[S_80[status]]);
		elseif (value > 0.4) then return unpack(self.db.text.colorRel[S_60[status]]);
		elseif (value > 0.2) then return unpack(self.db.text.colorRel[S_40[status]]);
		end
		return unpack(self.db.text.colorRel[S_20[status]]);
	end
	-- not smooth, not relative
	if     (value > 30) then return unpack(self.db.text.colorTime[S_LONG[status]]);
	elseif (value > 20) then return unpack(self.db.text.colorTime[S_30[status]]);
	elseif (value > 10) then return unpack(self.db.text.colorTime[S_20[status]]);
	elseif (value > 5)  then return unpack(self.db.text.colorTime[S_10[status]]);
	end
	return unpack(self.db.text.colorTime[S_5[status]]);
end -- GetTextColor()


--[[ UPDATE METHODS ]]--

function TrackerStyle.prototype:Apply(tracker, method)
	method = method or "Style"
	if (tracker) then
		tracker["Update"..method](tracker)
	else
		for i,window in pairs(Auracle.windows) do
			for j,tracker in pairs(window.trackers) do
				if (tracker.style == self) then
					tracker["Update"..method](tracker)
				end
			end
		end
	end
end -- Apply()


--[[ SHARED OPTIONS TABLE ]]--

local sharedOptions

local function get_shared_options()
	if (not sharedOptions) then
		sharedOptions = {
			style = {
				type = "group",
				name = L.STYLE,
				order = 1,
				args = {
					delete = {
						type = "execute",
						name = L.DELETE,
						disabled = function(i) return i.handler.db.name == L.DEFAULT end,
						func = function(i) Auracle:RemoveTrackerStyle(i.handler) end,
						order = 10
					},
					copy = {
						type = "execute",
						name = L.COPY,
						func = function(i) Auracle:CopyTrackerStyle(i.handler) end,
						order = 11
					},
					name = {
						type = "input",
						name = L.NAME,
						width = "double",
						disabled = function(i) return i.handler.db.name == L.DEFAULT end,
						get = function(i) return i.handler.db.name end,
						set = function(i,v) Auracle:RenameTrackerStyle(i.handler, v) end,
						validate = function(i,v)
							if (i.handler.db.name == L.DEFAULT) then
								return L.ERR_RENAME_DEFAULT_STYLE
							end
							v = strtrim(v)
							if (v == "") then
								return L.ERR_NO_STYLE_NAME
							elseif (Auracle.trackerStyles[v] and Auracle.trackerStyles[v] ~= i.handler) then
								return L.ERR_DUP_STYLE_NAME
							end
							return true
						end,
						order = 12
					}
				}
			},
			border = {
				type = "group",
				name = L.BORDER,
				order = 2,
				args = {
					noScale = {
						type = "toggle",
						name = L.BORDER_NOSCALE,
						desc = L.DESC_OPT_BORDER_NOSCALE,
						width = "double",
						get = function(i) return i.handler.db.border.noScale end,
						set = function(i,v)
							i.handler.db.border.noScale = v
							i.handler:Apply(nil, "Backdrop")
						end,
						order = 20
					},
					showMissing = {
						type = "toggle",
						name = L.OPT_MISSING_SHOW,
						width = "full",
						get = function(i) return i.handler.db.border.showMissing end,
						set = function(i,v)
							i.handler.db.border.showMissing = v
							i.handler:Apply(nil, "Backdrop")
						end,
						order = 21
					},
					sizeMissing = {
						type = "range",
						name = L.OPT_MISSING_SIZE,
						min = 1,
						max = 8,
						step = 1,
						disabled = function(i) return not i.handler.db.border.showMissing end,
						get = function(i) return i.handler.db.border.sizeMissing end,
						set = function(i,v)
							i.handler.db.border.sizeMissing = v
							i.handler:Apply(nil, "Backdrop")
						end,
						order = 22
					},
					colorMissing = {
						type = "color",
						name = L.OPT_MISSING_COLOR,
						hasAlpha = true,
						disabled = function(i) return not i.handler.db.border.showMissing end,
						get = function(i) return unpack(i.handler.db.border.colorMissing) end,
						set = function(i,v1,v2,v3,v4)
							local c = i.handler.db.border.colorMissing
							c[1],c[2],c[3],c[4] = v1,v2,v3,v4
							i.handler:Apply(nil, "Backdrop")
						end,
						order = 23
					},
					showOthers = {
						type = "toggle",
						name = L.OPT_OTHERS_SHOW,
						width = "full",
						get = function(i) return i.handler.db.border.showOthers end,
						set = function(i,v)
							i.handler.db.border.showOthers = v
							i.handler:Apply(nil, "Backdrop")
						end,
						order = 24
					},
					sizeOthers = {
						type = "range",
						name = L.OPT_OTHERS_SIZE,
						min = 1,
						max = 8,
						step = 1,
						disabled = function(i) return not i.handler.db.border.showOthers end,
						get = function(i) return i.handler.db.border.sizeOthers end,
						set = function(i,v)
							i.handler.db.border.sizeOthers = v
							i.handler:Apply(nil, "Backdrop")
						end,
						order = 25
					},
					colorOthers = {
						type = "color",
						name = L.OPT_OTHERS_COLOR,
						hasAlpha = true,
						disabled = function(i) return not i.handler.db.border.showOthers end,
						get = function(i) return unpack(i.handler.db.border.colorOthers) end,
						set = function(i,v1,v2,v3,v4)
							local c = i.handler.db.border.colorOthers
							c[1],c[2],c[3],c[4] = v1,v2,v3,v4
							i.handler:Apply(nil, "Backdrop")
						end,
						order = 26
					},
					showMine = {
						type = "toggle",
						name = L.OPT_MINE_SHOW,
						width = "full",
						get = function(i) return i.handler.db.border.showMine end,
						set = function(i,v)
							i.handler.db.border.showMine = v
							i.handler:Apply(nil, "Backdrop")
						end,
						order = 27
					},
					sizeMine = {
						type = "range",
						name = L.OPT_MINE_SIZE,
						min = 1,
						max = 8,
						step = 1,
						disabled = function(i) return not i.handler.db.border.showMine end,
						get = function(i) return i.handler.db.border.sizeMine end,
						set = function(i,v)
							i.handler.db.border.sizeMine = v
							i.handler:Apply(nil, "Backdrop")
						end,
						order = 28
					},
					colorMine = {
						type = "color",
						name = L.OPT_MINE_COLOR,
						hasAlpha = true,
						disabled = function(i) return not i.handler.db.border.showMine end,
						get = function(i) return unpack(i.handler.db.border.colorMine) end,
						set = function(i,v1,v2,v3,v4)
							local c = i.handler.db.border.colorMine
							c[1],c[2],c[3],c[4] = v1,v2,v3,v4
							i.handler:Apply(nil, "Backdrop")
						end,
						order = 29
					}
				}
			},
			icon = {
				type = "group",
				name = L.ICON,
				order = 3,
				args = {
					zoom = {
						type = "toggle",
						name = L.ZOOM_ICON,
						width = "full",
						get = function(i) return i.handler.db.icon.zoom end,
						set = function(i,v)
							i.handler.db.icon.zoom = v
							i.handler:Apply(nil, "Icon")
						end,
						order = 30
					},
					showMissing = {
						type = "toggle",
						name = L.OPT_MISSING_SHOW,
						width = "full",
						get = function(i) return i.handler.db.icon.showMissing end,
						set = function(i,v)
							i.handler.db.icon.showMissing = v
							i.handler:Apply(nil, "Icon")
						end,
						order = 31
					},
					grayMissing = {
						type = "toggle",
						name = L.OPT_MISSING_GRAY,
						disabled = function(i) return not i.handler.db.icon.showMissing end,
						get = function(i) return i.handler.db.icon.grayMissing end,
						set = function(i,v)
							i.handler.db.icon.grayMissing = v
							i.handler:Apply(nil, "Icon")
						end,
						order = 32
					},
					colorMissing = {
						type = "color",
						name = L.OPT_MISSING_TINT,
						hasAlpha = true,
						disabled = function(i) return not i.handler.db.icon.showMissing end,
						get = function(i) return unpack(i.handler.db.icon.colorMissing) end,
						set = function(i,v1,v2,v3,v4)
							local c = i.handler.db.icon.colorMissing
							c[1],c[2],c[3],c[4] = v1,v2,v3,v4
							i.handler:Apply(nil, "Icon")
						end,
						order = 33
					},
					showOthers = {
						type = "toggle",
						name = L.OPT_OTHERS_SHOW,
						width = "full",
						get = function(i) return i.handler.db.icon.showOthers end,
						set = function(i,v)
							i.handler.db.icon.showOthers = v
							i.handler:Apply(nil, "Icon")
						end,
						order = 34
					},
					grayOthers = {
						type = "toggle",
						name = L.OPT_OTHERS_GRAY,
						disabled = function(i) return not i.handler.db.icon.showOthers end,
						get = function(i) return i.handler.db.icon.grayOthers end,
						set = function(i,v)
							i.handler.db.icon.grayOthers = v
							i.handler:Apply(nil, "Icon")
						end,
						order = 35
					},
					colorOthers = {
						type = "color",
						name = L.OPT_OTHERS_TINT,
						hasAlpha = true,
						disabled = function(i) return not i.handler.db.icon.showOthers end,
						get = function(i) return unpack(i.handler.db.icon.colorOthers) end,
						set = function(i,v1,v2,v3,v4)
							local c = i.handler.db.icon.colorOthers
							c[1],c[2],c[3],c[4] = v1,v2,v3,v4
							i.handler:Apply(nil, "Icon")
						end,
						order = 36
					},
					showMine = {
						type = "toggle",
						name = L.OPT_MINE_SHOW,
						width = "full",
						get = function(i) return i.handler.db.icon.showMine end,
						set = function(i,v)
							i.handler.db.icon.showMine = v
							i.handler:Apply(nil, "Icon")
						end,
						order = 37
					},
					grayMine = {
						type = "toggle",
						name = L.OPT_MINE_GRAY,
						disabled = function(i) return not i.handler.db.icon.showMine end,
						get = function(i) return i.handler.db.icon.grayMine end,
						set = function(i,v)
							i.handler.db.icon.grayMine = v
							i.handler:Apply(nil, "Icon")
						end,
						order = 38
					},
					colorMine = {
						type = "color",
						name = L.OPT_MINE_TINT,
						hasAlpha = true,
						disabled = function(i) return not i.handler.db.icon.showMine end,
						get = function(i) return unpack(i.handler.db.icon.colorMine) end,
						set = function(i,v1,v2,v3,v4)
							local c = i.handler.db.icon.colorMine
							c[1],c[2],c[3],c[4] = v1,v2,v3,v4
							i.handler:Apply(nil, "Icon")
						end,
						order = 39
					}
				}
			},
			spiral = {
				type = "group",
				name = L.SPIRAL,
				order = 4,
				args = {
					showOthers = {
						type = "toggle",
						name = L.OPT_OTHERS_SHOW,
						width = "full",
						get = function(i) return i.handler.db.spiral.showOthers end,
						set = function(i,v)
							i.handler.db.spiral.showOthers = v
							i.handler:Apply(nil, "Spiral")
						end,
						order = 40
					},
					showMine = {
						type = "toggle",
						name = L.OPT_MINE_SHOW,
						width = "full",
						get = function(i) return i.handler.db.spiral.showMine end,
						set = function(i,v)
							i.handler.db.spiral.showMine = v
							i.handler:Apply(nil, "Spiral")
						end,
						order = 41
					},
					noCC = {
						type = "toggle",
						name = L.OPT_NOCC,
						desc = L.DESC_OPT_NOCC,
						width = "full",
						get = function(i) return i.handler.db.spiral.noCC end,
						set = function(i,v)
							i.handler.db.spiral.noCC = v
							i.handler:Apply(nil, "Spiral")
						end,
						order = 42
					}
				}
			},
			text = {
				type = "group",
				name = L.TEXT,
				order = 5,
				args = {
					font = {
						type = (LIB_LibSharedMedia and "select") or "input",
						dialogControl = (LIB_LibSharedMedia and "LSM30_Font") or nil,
						name = L.FONT,
						values = (LIB_LibSharedMedia and AceGUIWidgetLSMlists.font) or nil,
						get = (LIB_LibSharedMedia and function(i)
							for key,data in pairs(AceGUIWidgetLSMlists.font) do
								if (data == i.handler.db.text.font) then return key end
							end
							return L.NONE
						end) or (function(i)
							return i.handler.db.text.font
						end),
						set = (LIB_LibSharedMedia and function(i,v)
							i.handler.db.text.font = LibSharedMedia:Fetch("font", v)
							i.handler:Apply(nil, "Font")
						end) or (function(i,v)
							i.handler.db.text.font = v
							i.handler:Apply(nil, "Font")
						end),
						order = 50
					},
					outline = {
						type = "select",
						name = L.OUTLINE,
						values = {
							[""] = L.NONE,
							OUTLINE = L.THIN,
							THICKOUTLINE = L.THICK
						},
						get = function(i) return i.handler.db.text.outline end,
						set = function(i,v)
							i.handler.db.text.outline = v
							i.handler:Apply(nil, "Font")
						end,
						order = 51
					},
					sizeMult = {
						type = "range",
						name = L.RELATIVE_SIZE,
						desc = L.DESC_OPT_RELATIVE_STATIC_SIZE,
						min = 0,
						max = 2,
						step = 0.05,
						get = function(i) return i.handler.db.text.sizeMult end,
						set = function(i,v)
							i.handler.db.text.sizeMult = v
							i.handler:Apply(nil, "Font")
						end,
						order = 52
					},
					size = {
						type = "range",
						name = L.STATIC_SIZE,
						desc = L.DESC_OPT_RELATIVE_STATIC_SIZE,
						min = 4,
						max = 32,
						step = 1,
						get = function(i) return i.handler.db.text.size end,
						set = function(i,v)
							i.handler.db.text.size = v
							i.handler:Apply(nil, "Font")
						end,
						order = 53
					},
					smooth = {
						type = "toggle",
						name = L.OPT_SMOOTH_COLORS,
						desc = L.DESC_OPT_SMOOTH_COLORS,
						width = "full",
						get = function(i) return i.handler.db.text.smooth end,
						set = function(i,v)
							i.handler.db.text.smooth = v
							i.handler:Apply(nil, "Text")
						end,
						order = 54
					},
		--[[ TODO
					smoothRate = {
						type = "range",
						name = L.OPT_SMOOTH_RATE,
						desc = L.DESC_OPT_SMOOTH_RATE,
						disabled = function(i) return not i.handler.db.text.smooth end,
						min = 0.1,
						max = 1,
						step = 0.1,
						get = function(i) return i.handler.db.text.smoothRate end,
						set = function(i,v)
							i.handler.db.text.smoothRate = v
							i.handler:Apply(nil, "Text")
						end,
						order = 55
					},
		--]]
					showMissing = {
						type = "toggle",
						name = L.OPT_MISSING_SHOW,
						width = "full",
						get = function(i) return i.handler.db.text.showMissing end,
						set = function(i,v)
							i.handler.db.text.showMissing = v
							i.handler:Apply(nil, "Text")
						end,
						order = 56
					},
					colorMissing = {
						type = "color",
						name = L.OPT_MISSING_COLOR,
						hasAlpha = true,
						disabled = function(i) return not i.handler.db.text.showMissing end,
						get = function(i) return unpack(i.handler.db.text.colorMissing) end,
						set = function(i,v1,v2,v3,v4)
							local c = i.handler.db.text.colorMissing
							c[1],c[2],c[3],c[4] = v1,v2,v3,v4
							i.handler:Apply(nil, "Text")
						end,
						order = 57
					},
					showOthers = {
						type = "toggle",
						name = L.OPT_OTHERS_SHOW,
						get = function(i) return i.handler.db.text.showOthers end,
						set = function(i,v)
							i.handler.db.text.showOthers = v
							i.handler:Apply(nil, "Text")
						end,
						order = 58
					},
					showMine = {
						type = "toggle",
						name = L.OPT_MINE_SHOW,
						get = function(i) return i.handler.db.text.showMine end,
						set = function(i,v)
							i.handler.db.text.showMine = v
							i.handler:Apply(nil, "Text")
						end,
						order = 59
					},
					colorRel = {
						type = "group",
						name = L.RELATIVE_COLORS,
						inline = true,
						order = 510,
						args = {
							others20 = {
								type = "color",
								name = L["OPT_OTHERS_20%"],
								hasAlpha = true,
								disabled = function(i) return not i.handler.db.text.showOthers end,
								get = function(i) return unpack(i.handler.db.text.colorRel.others20) end,
								set = function(i,v1,v2,v3,v4)
									local c = i.handler.db.text.colorRel.others20
									c[1],c[2],c[3],c[4] = v1,v2,v3,v4
									i.handler:Apply(nil, "Text")
								end,
								order = 5100
							},
							mine20 = {
								type = "color",
								name = L["OPT_MINE_20%"],
								hasAlpha = true,
								disabled = function(i) return not i.handler.db.text.showMine end,
								get = function(i) return unpack(i.handler.db.text.colorRel.mine20) end,
								set = function(i,v1,v2,v3,v4)
									local c = i.handler.db.text.colorRel.mine20
									c[1],c[2],c[3],c[4] = v1,v2,v3,v4
									i.handler:Apply(nil, "Text")
								end,
								order = 5101
							},
							others40 = {
								type = "color",
								name = L["OPT_OTHERS_40%"],
								hasAlpha = true,
								disabled = function(i) return not i.handler.db.text.showOthers end,
								get = function(i) return unpack(i.handler.db.text.colorRel.others40) end,
								set = function(i,v1,v2,v3,v4)
									local c = i.handler.db.text.colorRel.others40
									c[1],c[2],c[3],c[4] = v1,v2,v3,v4
									i.handler:Apply(nil, "Text")
								end,
								order = 5102
							},
							mine40 = {
								type = "color",
								name = L["OPT_MINE_40%"],
								hasAlpha = true,
								disabled = function(i) return not i.handler.db.text.showMine end,
								get = function(i) return unpack(i.handler.db.text.colorRel.mine40) end,
								set = function(i,v1,v2,v3,v4)
									local c = i.handler.db.text.colorRel.mine40
									c[1],c[2],c[3],c[4] = v1,v2,v3,v4
									i.handler:Apply(nil, "Text")
								end,
								order = 5103
							},
							others60 = {
								type = "color",
								name = L["OPT_OTHERS_60%"],
								hasAlpha = true,
								disabled = function(i) return not i.handler.db.text.showOthers end,
								get = function(i) return unpack(i.handler.db.text.colorRel.others60) end,
								set = function(i,v1,v2,v3,v4)
									local c = i.handler.db.text.colorRel.others60
									c[1],c[2],c[3],c[4] = v1,v2,v3,v4
									i.handler:Apply(nil, "Text")
								end,
								order = 5104
							},
							mine60 = {
								type = "color",
								name = L["OPT_MINE_60%"],
								hasAlpha = true,
								disabled = function(i) return not i.handler.db.text.showMine end,
								get = function(i) return unpack(i.handler.db.text.colorRel.mine60) end,
								set = function(i,v1,v2,v3,v4)
									local c = i.handler.db.text.colorRel.mine60
									c[1],c[2],c[3],c[4] = v1,v2,v3,v4
									i.handler:Apply(nil, "Text")
								end,
								order = 5105
							},
							others80 = {
								type = "color",
								name = L["OPT_OTHERS_80%"],
								hasAlpha = true,
								disabled = function(i) return not i.handler.db.text.showOthers end,
								get = function(i) return unpack(i.handler.db.text.colorRel.others80) end,
								set = function(i,v1,v2,v3,v4)
									local c = i.handler.db.text.colorRel.others80
									c[1],c[2],c[3],c[4] = v1,v2,v3,v4
									i.handler:Apply(nil, "Text")
								end,
								order = 5106
							},
							mine80 = {
								type = "color",
								name = L["OPT_MINE_80%"],
								hasAlpha = true,
								disabled = function(i) return not i.handler.db.text.showMine end,
								get = function(i) return unpack(i.handler.db.text.colorRel.mine80) end,
								set = function(i,v1,v2,v3,v4)
									local c = i.handler.db.text.colorRel.mine80
									c[1],c[2],c[3],c[4] = v1,v2,v3,v4
									i.handler:Apply(nil, "Text")
								end,
								order = 5107
							},
							others100 = {
								type = "color",
								name = L["OPT_OTHERS_100%"],
								hasAlpha = true,
								disabled = function(i) return not i.handler.db.text.showOthers end,
								get = function(i) return unpack(i.handler.db.text.colorRel.others100) end,
								set = function(i,v1,v2,v3,v4)
									local c = i.handler.db.text.colorRel.others100
									c[1],c[2],c[3],c[4] = v1,v2,v3,v4
									i.handler:Apply(nil, "Text")
								end,
								order = 5108
							},
							mine100 = {
								type = "color",
								name = L["OPT_MINE_100%"],
								hasAlpha = true,
								disabled = function(i) return not i.handler.db.text.showMine end,
								get = function(i) return unpack(i.handler.db.text.colorRel.mine100) end,
								set = function(i,v1,v2,v3,v4)
									local c = i.handler.db.text.colorRel.mine100
									c[1],c[2],c[3],c[4] = v1,v2,v3,v4
									i.handler:Apply(nil, "Text")
								end,
								order = 5109
							}
						}
					},
					colorTime = {
						type = "group",
						name = L.COLORS_BY_TIME,
						inline = true,
						order = 511,
						args = {
							others5 = {
								type = "color",
								name = L.OPT_OTHERS_5S,
								hasAlpha = true,
								disabled = function(i) return not i.handler.db.text.showOthers end,
								get = function(i) return unpack(i.handler.db.text.colorTime.others5) end,
								set = function(i,v1,v2,v3,v4)
									local c = i.handler.db.text.colorTime.others5
									c[1],c[2],c[3],c[4] = v1,v2,v3,v4
									i.handler:Apply(nil, "Text")
								end,
								order = 5110
							},
							mine5 = {
								type = "color",
								name = L.OPT_MINE_5S,
								hasAlpha = true,
								disabled = function(i) return not i.handler.db.text.showMine end,
								get = function(i) return unpack(i.handler.db.text.colorTime.mine5) end,
								set = function(i,v1,v2,v3,v4)
									local c = i.handler.db.text.colorTime.mine5
									c[1],c[2],c[3],c[4] = v1,v2,v3,v4
									i.handler:Apply(nil, "Text")
								end,
								order = 5111
							},
							others10 = {
								type = "color",
								name = L.OPT_OTHERS_10S,
								hasAlpha = true,
								disabled = function(i) return not i.handler.db.text.showOthers end,
								get = function(i) return unpack(i.handler.db.text.colorTime.others10) end,
								set = function(i,v1,v2,v3,v4)
									local c = i.handler.db.text.colorTime.others10
									c[1],c[2],c[3],c[4] = v1,v2,v3,v4
									i.handler:Apply(nil, "Text")
								end,
								order = 5112
							},
							mine10 = {
								type = "color",
								name = L.OPT_MINE_10S,
								hasAlpha = true,
								disabled = function(i) return not i.handler.db.text.showMine end,
								get = function(i) return unpack(i.handler.db.text.colorTime.mine10) end,
								set = function(i,v1,v2,v3,v4)
									local c = i.handler.db.text.colorTime.mine10
									c[1],c[2],c[3],c[4] = v1,v2,v3,v4
									i.handler:Apply(nil, "Text")
								end,
								order = 5113
							},
							others20 = {
								type = "color",
								name = L.OPT_OTHERS_20S,
								hasAlpha = true,
								disabled = function(i) return not i.handler.db.text.showOthers end,
								get = function(i) return unpack(i.handler.db.text.colorTime.others20) end,
								set = function(i,v1,v2,v3,v4)
									local c = i.handler.db.text.colorTime.others20
									c[1],c[2],c[3],c[4] = v1,v2,v3,v4
									i.handler:Apply(nil, "Text")
								end,
								order = 5114
							},
							mine20 = {
								type = "color",
								name = L.OPT_MINE_20S,
								hasAlpha = true,
								disabled = function(i) return not i.handler.db.text.showMine end,
								get = function(i) return unpack(i.handler.db.text.colorTime.mine20) end,
								set = function(i,v1,v2,v3,v4)
									local c = i.handler.db.text.colorTime.mine20
									c[1],c[2],c[3],c[4] = v1,v2,v3,v4
									i.handler:Apply(nil, "Text")
								end,
								order = 5115
							},
							others30 = {
								type = "color",
								name = L.OPT_OTHERS_30S,
								hasAlpha = true,
								disabled = function(i) return not i.handler.db.text.showOthers end,
								get = function(i) return unpack(i.handler.db.text.colorTime.others30) end,
								set = function(i,v1,v2,v3,v4)
									local c = i.handler.db.text.colorTime.others30
									c[1],c[2],c[3],c[4] = v1,v2,v3,v4
									i.handler:Apply(nil, "Text")
								end,
								order = 5116
							},
							mine30 = {
								type = "color",
								name = L.OPT_MINE_30S,
								hasAlpha = true,
								disabled = function(i) return not i.handler.db.text.showMine end,
								get = function(i) return unpack(i.handler.db.text.colorTime.mine30) end,
								set = function(i,v1,v2,v3,v4)
									local c = i.handler.db.text.colorTime.mine30
									c[1],c[2],c[3],c[4] = v1,v2,v3,v4
									i.handler:Apply(nil, "Text")
								end,
								order = 5117
							},
							othersLong = {
								type = "color",
								name = L.OPT_OTHERS_XS,
								hasAlpha = true,
								disabled = function(i) return not i.handler.db.text.showOthers end,
								get = function(i) return unpack(i.handler.db.text.colorTime.othersLong) end,
								set = function(i,v1,v2,v3,v4)
									local c = i.handler.db.text.colorTime.othersLong
									c[1],c[2],c[3],c[4] = v1,v2,v3,v4
									i.handler:Apply(nil, "Text")
								end,
								order = 5118
							},
							mineLong = {
								type = "color",
								name = L.OPT_MINE_XS,
								hasAlpha = true,
								disabled = function(i) return not i.handler.db.text.showMine end,
								get = function(i) return unpack(i.handler.db.text.colorTime.mineLong) end,
								set = function(i,v1,v2,v3,v4)
									local c = i.handler.db.text.colorTime.mineLong
									c[1],c[2],c[3],c[4] = v1,v2,v3,v4
									i.handler:Apply(nil, "Text")
								end,
								order = 5119
							}
						}
					}
				}
			}
		}
	end
	return sharedOptions
end -- get_shared_options()


--[[ MENU METHODS ]]--

function TrackerStyle.prototype:GetOptionsTable()
	if (not self.optionsTable) then
		self.optionsTable = {
			type = "group",
			handler = self,
			childGroups = "tab",
			args = get_shared_options()
		}
	end
	self.optionsTable.name = self.db.name
	return self.optionsTable
end -- GetOptionsTable()


--[[ INIT ]]--

Auracle:__trackerstyle(TrackerStyle, DB_DEFAULT_TRACKERSTYLE, DB_VALID_TRACKERSTYLE)

