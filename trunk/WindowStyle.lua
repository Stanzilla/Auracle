local LibOOP
--@alpha@
LibOOP = LibStub("LibOOP-1.0-alpha",true)
--@end-alpha@
LibOOP = LibOOP or LibStub("LibOOP-1.0") or error("LibOOP not found")
local WindowStyle = LibOOP:Class()

--[[ CONSTANTS ]]--

local DB_DEFAULT_WINDOWSTYLE = {
	name = "Default",
	windowOpacity = 1.0,
	windowScale = 1.0,
	border = {
		show = true,
		texture = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 16,
		color = {0.5, 0.5, 0.5, 0.75}
	},
	background = {
		show = true,
		--texture = "Interface\\ChatFrame\\ChatFrameBackground",
		texture = "Interface\\DialogFrame\\UI-DialogBox-Background",
		--tileSize = 32,
		tileSize = 0,
		noScale = true,
		inset = 4,
		--color = {  0,   0,   0, 0.75}
		color = {  1,   1,   1, 0.75}
	},
	layout = {
		noScale = true,
		padding = 6,
		spacing = 2,
		trackerSize = 24
	}
}


--[[ INIT ]]--

Auracle:__windowstyle(WindowStyle, DB_DEFAULT_WINDOWSTYLE)

local LibSharedMedia = LibStub("LibSharedMedia-3.0")
local backdrop = {}
local insets = {}


--[[ CONSTRUCT & DESTRUCT ]]--

function WindowStyle:New(db)
	local obj = self:Super("New")
	obj.db = db
	return obj
end -- New()

function WindowStyle.prototype:Destroy()
	self.db = nil
end -- Destroy()


--[[ STYLE METHODS ]]--

function WindowStyle.prototype:GetBackdropTable()
	-- build config table
	local backdrop = backdrop
	wipe(backdrop)
	local sdbBorder = self.db.border
	if (sdbBorder.show) then
		backdrop.edgeFile = sdbBorder.texture
		backdrop.edgeSize = sdbBorder.edgeSize
	end
	local sdbBackground = self.db.background
	if (sdbBackground.show) then
		backdrop.bgFile = sdbBackground.texture
		if (sdbBackground.tileSize > 0) then
			backdrop.tile = true
			backdrop.tileSize = sdbBackground.tileSize
		else
			backdrop.tile = false
		end
		insets.left = sdbBackground.inset
		insets.right = sdbBackground.inset
		insets.top = sdbBackground.inset
		insets.bottom = sdbBackground.inset
		backdrop.insets = insets
	end
	return backdrop
end -- GetBackdropTable()


--[[ UPDATE METHODS ]]--

function WindowStyle.prototype:Apply(window, method)
	method = method or "Style"
	if (window) then
		window["Update"..method](window)
	else
		for i,window in pairs(Auracle.windows) do
			if (window.style == self) then
				window["Update"..method](window)
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
				func = function(i) Auracle:RemoveWindowStyle(i.handler) end,
				order = 10
			},
			copy = {
				type = "execute",
				name = "Copy",
				func = function(i) Auracle:CopyWindowStyle(i.handler) end,
				order = 11
			},
			name = {
				type = "input",
				name = "Name",
				width = "double",
				disabled = function(i) return i.handler.db.name == "Default" end,
				get = function(i) return i.handler.db.name end,
				set = function(i,v) Auracle:RenameWindowStyle(i.handler, v) end,
				validate = function(i,v)
					if (i.handler.db.name == "Default") then
						return "You cannot rename the Default style"
					end
					v = strtrim(v)
					if (v == "") then
						return "Every style needs a name"
					elseif (Auracle.windowStyles[v] and Auracle.windowStyles[v] ~= i.handler) then
						return "Every style name must be unique"
					end
					return true
				end,
				order = 12
			},
			windowOpacity = {
				type = "range",
				name = "Window Opacity",
				width = "double",
				min = 0.0,
				max = 1.0,
				step = 0.01,
				get = function(i) return i.handler.db.windowOpacity end,
				set = function(i,v)
					i.handler.db.windowOpacity = v
					i.handler:Apply(nil, "Backdrop")
				end,
				order = 13
			},
			windowScale = {
				type = "range",
				name = "Window Scale",
				width = "double",
				min = 0.5,
				max = 2.0,
				step = 0.01,
				get = function(i) return i.handler.db.windowScale end,
				set = function(i,v)
					i.handler.db.windowScale = v
					i.handler:Apply(nil, "Layout")
				end,
				order = 14
			}
		}
	},
	border = {
		type = "group",
		name = "Border",
		order = 2,
		args = {
			show = {
				type = "toggle",
				name = "Show",
				width = "full",
				get = function(i) return i.handler.db.border.show end,
				set = function(i,v)
					i.handler.db.border.show = v
					i.handler:Apply(nil, "Backdrop")
				end,
				order = 20
			},
			texture = {
				type = "select",
				dialogControl = "LSM30_Border",
				name = "Texture",
				values = AceGUIWidgetLSMlists.border,
				disabled = function(i) return not i.handler.db.border.show end,
				get = function(i)
					for key,data in pairs(AceGUIWidgetLSMlists.border) do
						if (data == i.handler.db.border.texture) then return key end
					end
					return "None"
				end,
				set = function(i,v)
					i.handler.db.border.texture = LibSharedMedia:Fetch("border", v)
					i.handler:Apply(nil, "Backdrop")
				end,
				order = 21
			},
			color = {
				type = "color",
				name = "Color",
				width = "half",
				hasAlpha = true,
				disabled = function(i) return not i.handler.db.border.show end,
				get = function(i) return unpack(i.handler.db.border.color) end,
				set = function(i,v1,v2,v3,v4)
					local c = i.handler.db.border.color
					c[1],c[2],c[3],c[4] = v1,v2,v3,v4
					i.handler:Apply(nil, "Backdrop")
				end,
				order = 22
			},
			edgeSize = {
				type = "range",
				name = "Corner Size",
				width = "double",
				min = 1,
				max = 32,
				step = 1,
				disabled = function(i) return not i.handler.db.border.show end,
				get = function(i) return i.handler.db.border.edgeSize end,
				set = function(i,v)
					i.handler.db.border.edgeSize = v
					i.handler:Apply(nil, "Backdrop")
				end,
				order = 23
			}
		}
	},
	background = {
		type = "group",
		name = "Background",
		order = 3,
		args = {
			show = {
				type = "toggle",
				name = "Show",
				width = "full",
				get = function(i) return i.handler.db.background.show end,
				set = function(i,v)
					i.handler.db.background.show = v
					i.handler:Apply(nil, "Backdrop")
				end,
				order = 30
			},
			texture = {
				type = "select",
				dialogControl = "LSM30_Background",
				name = "Texture",
				values = AceGUIWidgetLSMlists.background,
				disabled = function(i) return not i.handler.db.background.show end,
				get = function(i)
					for key,data in pairs(AceGUIWidgetLSMlists.background) do
						if (data == i.handler.db.background.texture) then return key end
					end
					return "None"
				end,
				set = function(i,v)
					i.handler.db.background.texture = LibSharedMedia:Fetch("background", v)
					i.handler:Apply(nil, "Backdrop")
				end,
				order = 31
			},
			color = {
				type = "color",
				name = "Color",
				width = "half",
				hasAlpha = true,
				disabled = function(i) return not i.handler.db.background.show end,
				get = function(i) return unpack(i.handler.db.background.color) end,
				set = function(i,v1,v2,v3,v4)
					local c = i.handler.db.background.color
					c[1],c[2],c[3],c[4] = v1,v2,v3,v4
					i.handler:Apply(nil, "Backdrop")
				end,
				order = 32
			},
			tileSize = {
				type = "range",
				name = "Tile Size",
				desc = "0 to disable background tiling",
				width = "double",
				min = 0,
				max = 32,
				step = 4,
				disabled = function(i) return not i.handler.db.background.show end,
				get = function(i) return i.handler.db.background.tileSize end,
				set = function(i,v)
					i.handler.db.background.tileSize = v
					i.handler:Apply(nil, "Backdrop")
				end,
				order = 32
			},
			noScale = {
				type = "toggle",
				name = "Don't scale inset",
				desc = "Apply inset in pixels, by canceling out the effective scale",
				width = "full",
				disabled = function(i) return not i.handler.db.background.show end,
				get = function(i) return i.handler.db.background.noScale end,
				set = function(i,v)
					i.handler.db.background.noScale = v
					i.handler:Apply(nil, "Backdrop")
				end,
				order = 33
			},
			inset = {
				type = "range",
				name = "Inset",
				width = "double",
				min = 0,
				max = 16,
				step = 1,
				disabled = function(i) return not i.handler.db.background.show end,
				get = function(i) return i.handler.db.background.inset end,
				set = function(i,v)
					i.handler.db.background.inset = v
					i.handler:Apply(nil, "Backdrop")
				end,
				order = 34
			}
		}
	},
	layout = {
		type = "group",
		name = "Layout",
		order = 4,
		args = {
			noScale = {
				type = "toggle",
				name = "Don't scale padding and spacing",
				desc = "Apply padding and spacing in pixels, by canceling out the effective scale",
				width = "full",
				get = function(i) return i.handler.db.layout.noScale end,
				set = function(i,v)
					i.handler.db.layout.noScale = v
					i.handler:Apply(nil, "Layout")
				end,
				order = 40
			},
			padding = {
				type = "range",
				name = "Padding",
				desc = "The distance between trackers and the window border",
				width = "double",
				min = 0,
				max = 16,
				step = 1,
				get = function(i) return i.handler.db.layout.padding end,
				set = function(i,v)
					i.handler.db.layout.padding = v
					i.handler:Apply(nil, "Layout")
				end,
				order = 41
			},
			spacing = {
				type = "range",
				name = "Spacing",
				desc = "The distance between each tracker",
				width = "double",
				min = 0,
				max = 16,
				step = 1,
				get = function(i) return i.handler.db.layout.spacing end,
				set = function(i,v)
					i.handler.db.layout.spacing = v
					i.handler:Apply(nil, "Layout")
				end,
				order = 42
			},
			trackerSize = {
				type = "range",
				name = "Tracker Size",
				width = "double",
				min = 8,
				max = 64,
				step = 1,
				get = function(i) return i.handler.db.layout.trackerSize end,
				set = function(i,v)
					i.handler.db.layout.trackerSize = v
					i.handler:Apply(nil, "Layout")
				end,
				order = 43
			},
--[[ TODO
			mode = {
			},
			origin = {
			},
			order = {
			},
--]]
		}
	}
}


--[[ MENU METHODS ]]--

function WindowStyle.prototype:GetOptionsTable()
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

