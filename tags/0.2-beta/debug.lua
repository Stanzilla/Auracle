__auracle_debug_table = false
do
	local flag = {}
	__auracle_debug_table = function(tbl, recurse, indent, indentWith)
		if (flag[tbl]) then return "{recursion}" end
		flag[tbl] = 1
		if (not indent) then indent = 0 end
		if (not indentWith) then indentWith = "  " end
		local s = ""
		for k,v in pairs(tbl) do
			s = s..strrep(indentWith, indent)..tostring(k).." = "
			if (recurse and type(v) == "table") then
				s = s.."{\n"..__auracle_debug_table(v, true, indent+1, indentWith)..strrep(indentWith, indent).."}\n"
			else
				s = s..tostring(v).."\n"
			end
		end
		flag[tbl] = nil
		return s
	end -- __auracle_debug_table()
end

__auracle_debug_array = false
do
	local flag = {}
	__auracle_debug_array = function(tbl, recurse, indent, indentWith)
		if (flag[tbl]) then return "{recursion}" end
		flag[tbl] = 1
		if (not indent) then indent = 0 end
		if (not indentWith) then indentWith = "  " end
		local s = ""
		for n,v in ipairs(tbl) do
			s = s..strrep(indentWith, indent)..tostring(n)..": "
			if (recurse and type(v) == "table") then
				s = s.."{\n"
				if (recurse == "table") then
					s = s..__auracle_debug_table(v, true, indent+1, indentWith)
				else
					s = s..__auracle_debug_array(v, true, indent+1, indentWith)
				end
				s = s..strrep(indentWith, indent).."}\n"
			else
				s = s..tostring(v).."\n"
			end
		end
		flag[tbl] = nil
		return s
	end -- __auracle_debug_array()
end

__auracle_debug_call = function(func, ...)
	local s = ""
	local i,n = 1,select('#',...)
	while i <= n do
		a = select(i,...)
		i = i + 1
		if (type(a)=="table") then
			s = s..",{ --"..tostring(a).."\n"..__auracle_debug_table(a,false,1,"  ").."}"
		else
			s = s..","..tostring(a)
		end
	end
	print(func.."("..strsub(s,2)..")")
end -- __auracle_debug_call()

