local LibOOP
--@alpha@
LibOOP = LibStub("LibOOP-1.0-alpha",true)
--@end-alpha@
LibOOP = LibOOP or LibStub("LibOOP-1.0") or error("LibOOP not found")
local TrackerStyle = LibOOP:Class()

--[[ CONSTANTS ]]--

local DB_DEFAULT_TRACKERSTYLE = {
	name = "Default",
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
		sizeMult       = 0.66,
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
}
local S_5     = {                         others="others5",     mine="mine5"     }
local S_10    = {                         others="others10",    mine="mine10"    }
local S_20    = {                         others="others20",    mine="mine20"    }
local S_30    = {                         others="others30",    mine="mine30"    }
local S_40    = {                         others="others40",    mine="mine40"    }
local S_60    = {                         others="others60",    mine="mine60"    }
local S_80    = {                         others="others80",    mine="mine80"    }
local S_100   = {                         others="others100",   mine="mine100"   }
local S_LONG  = {                         others="othersLong",  mine="mineLong"  }


--[[ INIT ]]--

Auracle:__trackerstyle(TrackerStyle, DB_DEFAULT_TRACKERSTYLE)

local LibSharedMedia = LibStub("LibSharedMedia-3.0")


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

local sharedOptions = {
	style = {
		type = "group",
		name = "Style",
		order = 1,
		args = {
			delete = {
				type = "execute",
				name = "Delete",
				disabled = function(i) return i.handler.db.name == "Default" end,
				func = function(i) Auracle:RemoveTrackerStyle(i.handler) end,
				order = 10
			},
			copy = {
				type = "execute",
				name = "Copy",
				func = function(i) Auracle:CopyTrackerStyle(i.handler) end,
				order = 11
			},
			name = {
				type = "input",
				name = "Name",
				width = "double",
				disabled = function(i) return i.handler.db.name == "Default" end,
				get = function(i) return i.handler.db.name end,
				set = function(i,v) Auracle:RenameTrackerStyle(i.handler, v) end,
				validate = function(i,v)
					if (i.handler.db.name == "Default") then
						return "You cannot rename the Default style"
					end
					v = strtrim(v)
					if (v == "") then
						return "Every style needs a name"
					elseif (Auracle.trackerStyles[v] and Auracle.trackerStyles[v] ~= i.handler) then
						return "Every style name must be unique"
					end
					return true
				end,
				order = 12
			}
		}
	},
	border = {
		type = "group",
		name = "Border",
		order = 2,
		args = {
			noScale = {
				type = "toggle",
				name = "Don't scale border",
				desc = "Apply border size in pixels, by canceling out the effective scale",
				width = "double",
				get = function(i) return i.handler.db.border.noScale end,
				set = function(i,v)
					i.handler.db.border.noScale = v
					i.handler:Apply(nil, "Border")
				end,
				order = 20
			},
			showMissing = {
				type = "toggle",
				name = "Show when Missing",
				width = "full",
				get = function(i) return i.handler.db.border.showMissing end,
				set = function(i,v)
					i.handler.db.border.showMissing = v
					i.handler:Apply(nil, "Border")
				end,
				order = 21
			},
			sizeMissing = {
				type = "range",
				name = "Size when Missing",
				min = 1,
				max = 8,
				step = 1,
				disabled = function(i) return not i.handler.db.border.showMissing end,
				get = function(i) return i.handler.db.border.sizeMissing end,
				set = function(i,v)
					i.handler.db.border.sizeMissing = v
					i.handler:Apply(nil, "Border")
				end,
				order = 22
			},
			colorMissing = {
				type = "color",
				name = "Color when Missing",
				hasAlpha = true,
				disabled = function(i) return not i.handler.db.border.showMissing end,
				get = function(i) return unpack(i.handler.db.border.colorMissing) end,
				set = function(i,v1,v2,v3,v4)
					local c = i.handler.db.border.colorMissing
					c[1],c[2],c[3],c[4] = v1,v2,v3,v4
					i.handler:Apply(nil, "Border")
				end,
				order = 23
			},
			showOthers = {
				type = "toggle",
				name = "Show when Other's",
				width = "full",
				get = function(i) return i.handler.db.border.showOthers end,
				set = function(i,v)
					i.handler.db.border.showOthers = v
					i.handler:Apply(nil, "Border")
				end,
				order = 24
			},
			sizeOthers = {
				type = "range",
				name = "Size when Other's",
				min = 1,
				max = 8,
				step = 1,
				disabled = function(i) return not i.handler.db.border.showOthers end,
				get = function(i) return i.handler.db.border.sizeOthers end,
				set = function(i,v)
					i.handler.db.border.sizeOthers = v
					i.handler:Apply(nil, "Border")
				end,
				order = 25
			},
			colorOthers = {
				type = "color",
				name = "Color when Other's",
				hasAlpha = true,
				disabled = function(i) return not i.handler.db.border.showOthers end,
				get = function(i) return unpack(i.handler.db.border.colorOthers) end,
				set = function(i,v1,v2,v3,v4)
					local c = i.handler.db.border.colorOthers
					c[1],c[2],c[3],c[4] = v1,v2,v3,v4
					i.handler:Apply(nil, "Border")
				end,
				order = 26
			},
			showMine = {
				type = "toggle",
				name = "Show when Mine",
				width = "full",
				get = function(i) return i.handler.db.border.showMine end,
				set = function(i,v)
					i.handler.db.border.showMine = v
					i.handler:Apply(nil, "Border")
				end,
				order = 27
			},
			sizeMine = {
				type = "range",
				name = "Size when Mine",
				min = 1,
				max = 8,
				step = 1,
				disabled = function(i) return not i.handler.db.border.showMine end,
				get = function(i) return i.handler.db.border.sizeMine end,
				set = function(i,v)
					i.handler.db.border.sizeMine = v
					i.handler:Apply(nil, "Border")
				end,
				order = 28
			},
			colorMine = {
				type = "color",
				name = "Color when Mine",
				hasAlpha = true,
				disabled = function(i) return not i.handler.db.border.showMine end,
				get = function(i) return unpack(i.handler.db.border.colorMine) end,
				set = function(i,v1,v2,v3,v4)
					local c = i.handler.db.border.colorMine
					c[1],c[2],c[3],c[4] = v1,v2,v3,v4
					i.handler:Apply(nil, "Border")
				end,
				order = 29
			}
		}
	},
	icon = {
		type = "group",
		name = "Icon",
		order = 3,
		args = {
			zoom = {
				type = "toggle",
				name = "Zoom Icon",
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
				name = "Show when Missing",
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
				name = "Gray when Missing",
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
				name = "Tint when Missing",
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
				name = "Show when Other's",
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
				name = "Gray when Other's",
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
				name = "Tint when Other's",
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
				name = "Show when Mine",
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
				name = "Gray when Mine",
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
				name = "Tint when Mine",
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
		name = "Spiral",
		order = 4,
		args = {
			showOthers = {
				type = "toggle",
				name = "Show when Other's",
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
				name = "Show when Mine",
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
				name = "Block External Cooldown",
				width = "full",
				desc = "Prevent CooldownCount and OmniCC from adding timer text to the cooldown",
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
		name = "Text",
		order = 5,
		args = {
--[[
			font = { -- TODO: LibSharedMedia
				type = "input",
				name = "Font",
				get = function(i) return i.handler.db.text.font end,
				set = function(i,v)
					i.handler.db.text.font = v
					i.handler:Apply(nil, "Font")
				end,
				order = 50
			},
--]]
			font = {
				type = "select",
				dialogControl = "LSM30_Font",
				name = "Font",
				values = AceGUIWidgetLSMlists.font,
				get = function(i)
					for key,data in pairs(AceGUIWidgetLSMlists.font) do
						if (data == i.handler.db.text.font) then return key end
					end
					return "None"
				end,
				set = function(i,v)
					i.handler.db.text.font = LibSharedMedia:Fetch("font", v)
					i.handler:Apply(nil, "Font")
				end,
				order = 50
			},
			outline = {
				type = "select",
				name = "Outline",
				values = {
					[""] = "none",
					OUTLINE = "thin",
					THICKOUTLINE = "thick"
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
				name = "Relative size",
				desc = "Effective font size is (relativeSize * trackerSize) + staticSize",
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
				name = "Static size",
				desc = "Effective font size is (relativeSize * trackerSize) + staticSize",
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
				name = "Smooth-Fade Colors",
width = "full",
				desc = "When coloring based on time, fade smoothly between each marker",
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
				name = "Smooth-Fade Rate",
				desc = "The interval at which the smooth-fade color will be updated; lower settings may impact performance",
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
				name = "Show when Missing",
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
				name = "Color when Missing",
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
				name = "Show when Other's",
				width = "full",
				get = function(i) return i.handler.db.text.showOthers end,
				set = function(i,v)
					i.handler.db.text.showOthers = v
					i.handler:Apply(nil, "Text")
				end,
				order = 58
			},
			showMine = {
				type = "toggle",
				name = "Show when Mine",
				width = "full",
				get = function(i) return i.handler.db.text.showMine end,
				set = function(i,v)
					i.handler.db.text.showMine = v
					i.handler:Apply(nil, "Text")
				end,
				order = 59
			},
			colorRel = {
				type = "group",
				name = "Relative Colors",
				inline = true,
				order = 510,
				args = {
					others20 = {
						type = "color",
						name = "Other's 0-20%",
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
						name = "Mine 0-20%",
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
						name = "Other's 20-40%",
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
						name = "Mine 20-40%",
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
						name = "Other's 40-60%",
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
						name = "Mine 40-60%",
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
						name = "Other's 60-80%",
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
						name = "Mine 60-80%",
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
						name = "Other's 80-100%",
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
						name = "Mine 80-100%",
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
				name = "Colors by Time",
				inline = true,
				order = 511,
				args = {
					others5 = {
						type = "color",
						name = "Other's 0-5s",
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
						name = "Mine 0-5s",
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
						name = "Other's 5-10s",
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
						name = "Mine 5-10s",
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
						name = "Other's 10-20s",
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
						name = "Mine 10-20s",
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
						name = "Other's 20-30s",
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
						name = "Mine 20-30s",
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
						name = "Other's 30s+",
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
						name = "Mine 30s+",
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


--[[ MENU METHODS ]]--

function TrackerStyle.prototype:GetOptionsTable()
	if (not self.optionsTable) then
		self.optionsTable = {
			type = "group",
			handler = self,
			childGroups = "tab",
			args = sharedOptions
		}
	end
	self.optionsTable.name = self.db.name
	return self.optionsTable
end -- GetOptionsTable()

