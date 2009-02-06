-- until the first release, every beta tag will increment MAJOR to 0.x,
-- since there is no presumption of backwards compatibility
local MAJOR,MINOR = "LibOOP-0.2",1
local LibOOP--[[,oldminor]] = LibStub:NewLibrary(MAJOR, MINOR)
if (not LibOOP) then return end -- already loaded, no upgrade necessary


--[[ INITIALIZATION ]]--

-- global functions
local assert,error,getmetatable,pairs,rawset,setmetatable,tostring,type = assert,error,getmetatable,pairs,rawset,setmetatable,tostring,type

-- utility tables
local weakKeys = { __mode = 'k' }
local weakVals = { __mode = 'v' }
--local weakTable = { __mode = 'kv' }

-- to prevent accidental fudging with the infrastructure tables
local DUMPKEY = "C8F210AB9B6A28EC"

-- define infrastructure table references
local ooSuper -- points to superclass of indexed class, or 'true' for base class
--local ooClassMeta -- points to metatable of indexed class
local ooProto -- points to prototype table of indexed class
--local ooProtoMeta -- points to metatable of prototype of indexed class
local ooObjectMeta -- points to metatable of objects of indexed class
local ooClassByProto -- points to class of indexed prototype, for <object>:GetClass()
local baseClass
local baseProto

-- load or allocate infrastructure tables
if (type(LibOOP.__dump_for_upgrade)=="function") then
	ooSuper,ooProto,ooObjectMeta,baseClass,baseProto = LibOOP:__dump_for_upgrade(DUMPKEY)
	ooClassByProto = {}
	for c,p in pairs(ooProto) do
		ooClassByProto[p] = c
	end
else
	ooSuper = {}
	ooProto = {}
	ooObjectMeta = {}
	ooClassByProto = {}
	
	baseClass = {}
	baseProto = {}
	ooSuper[baseClass] = true
	ooProto[baseClass] = baseProto
	--ooObjectMeta[baseClass] = nil -- not needed since baseClass is un-instantiatable
	--ooClassByProto[baseProto] = baseClass -- not needed since baseClass is un-instantiable
end

-- make infrastructure tables "weak", so they don't interfere with garbage collection of dead classes
setmetatable(ooSuper, weakKeys)
setmetatable(ooProto, weakKeys)
setmetatable(ooObjectMeta, weakKeys)
setmetatable(ooClassByProto, weakVals)


--[[ METAMETHODS ]]--

local function noop() end

local function class__call(class, ...)
	local cNew = class.New
	assert(type(cNew)=="function", "failed to instantiate using class-call, :New() is not a function")
	return cNew(class, ...)
end -- class__call()

local function class__newIndex(tbl, key, val)
	if (key == "GetSuperClass" or key == "SubClassOf" or key == "Super") then
		error("not allowed to redefine class method "..tostring(key))
	end
	rawset(tbl,key,val)
end -- class__newIndex()

local function proto__newIndex(tbl, key, val)
	if (key == "GetClass" or key == "InstanceOf" or key == "Super") then
		error("not allowed to redefine instance method "..tostring(key))
	end
	rawset(tbl,key,val)
end -- proto__newIndex()


--[[ CLASS METHODS ]]--
-- these assume that they will only be called on valid classes, but never on baseClass (except for <class>:Extend())

--- Defines a new subclass by extending this class.
-- The new subclass will inherit any properties and methods defined on this
-- class or any of its superclasses (including the base class), and will also
-- provide a "prototype" table on which properties and methods may be defined
-- that will be inherited by all objects of the class or its subclasses.
--
-- This method may be overridden.  An implementor overriding this method
-- must return the result of '''self:Super("Extend")''' in order to provide
-- the caller a usable subclass reference.  Returning "false" or raising an
-- error may suggest to the caller that this class should not be extended, but
-- Lua's flexibility makes strict restrictions impossible to enforce.  A
-- caller in doubt may verify that the returned value is a valid class
-- reference with, for example, '''LibOOP:SubClassOf(<return>)'''.
-- @name <class>:Extend
-- @return A table representing the newly created subclass.
function baseClass:Extend() -- overridable
	local newClassMeta = {
		__index = self,
		__newindex = class__newIndex,
		__call = class__call, -- can't just call class_New() because it might have been overridden
		__metatable = false
	}
	local newClass = setmetatable({}, newClassMeta)
	local newProtoMeta = {
		__index = ooProto[self],
		__newindex = proto__newIndex,
		__metatable = false
	}
	local newProto = setmetatable({}, newProtoMeta)
	local newObjectMeta = {
		__index = newProto,
		__newindex = proto__newIndex, -- no need to define a separate one yet
		__metatable = newProto
	}
	newClass.prototype = newProto
	ooSuper[newClass] = self
	ooProto[newClass] = newProto
	ooObjectMeta[newClass] = newObjectMeta
	ooClassByProto[newProto] = newClass
	return newClass
end -- <class>:Extend()

--- Returns the superclass of this class.
-- Equivalent to '''LibOOP:GetSuperClass(<class>)'''.
--
-- This method may not be overridden.
-- @name <class>:GetSuperClass
-- @return A reference to the table representing the class' superclass, or false if the class has no superclass.
function baseClass:GetSuperClass() -- non-overridable
	local super = ooSuper[self]
	if (super == baseClass) then
		return false
	end
	return super
end -- <class>:GetSuperClass()

--- Instantiates (creates a new object of) this class.
-- The new object will inherit any properties and methods defined on this
-- class' or any superclass' prototype, including the methods "Clone",
-- "GetClass", "InstanceOf" and "Super" from the base prototype.
--
-- This method may be overridden, for example to implement a constructor.
-- An implementor overriding this method must return the result of
-- '''self:Super("New")''' in order to provide the caller a usable object
-- reference.  It is also permissible to return a reference to an existing
-- instance of the class, for example to implement a singleton pattern.
-- Returning "false" or raising an error may suggest to the caller that this
-- class should not be instantiated, but Lua's flexibility makes strict
-- restrictions impossible to enforce.  A caller in doubt may verify that the
-- returned value is a valid object reference with, for example,
-- '''LibOOP:InstanceOf(<return>)'''.
-- @name <class>:New
-- @return A table representing the newly created object.
function baseClass:New() -- overridable
	return setmetatable({}, ooObjectMeta[self])
end -- <class>:New()

--- Tests if this class extends a given superclass.
-- If "super" is omitted, this always returns true (when called on a LibOOP
-- class).  If "direct" is true, then "class" must extend "super" directly;
-- otherwise, it may also extend a subclass of "super".  Equivalent to
-- '''LibOOP:SubClassOf(<class>[, <super>[, <direct>]])'''.
--
-- This method may not be overridden.
-- @name <class>:SubClassOf
-- @param super (Optional) A class reference to test inheritence from.
-- @param direct (Optional) If true, tests only direct inheritence.
-- @return True if the class satisfies the specified inheritence profile, false otherwise.
function baseClass:SubClassOf(super, direct) -- non-overridable
	local cSuper = ooSuper[self]
	if (not super or cSuper == super) then
		return true
	elseif (direct or not ooSuper[super]) then
		return false
	elseif (self == super) then
		return true
	end
	cSuper = ooSuper[cSuper]
	while (cSuper and cSuper ~= super) do
		cSuper = ooSuper[cSuper]
	end
	return (cSuper == super)
end -- <class>:SubClassOf()

local class_Super_flag = {}
--- Calls the inherited version of the given method.
-- The method will be called like a normal class method, passing this class as
-- the implicit first argument "self" (even though the method was defined on a
-- superclass of this class).  However, the method will still have the scope
-- (and the variables in closure) with which it was defined, rather than that
-- of this class.
--
-- This method may not be overridden.
-- @name <class>:Super
-- @param method The name of the inherited method to be called, as a string.
-- @param ... (Optional) Any number of arguments to pass to the method.
-- @return All return values from the method.
function baseClass:Super(method, ...) -- non-overridable
	local super = ooSuper[self]
	local baseClass = baseClass
	local cMethod = self[method]
	while (super ~= baseClass and super[method] == cMethod) do
		super = ooSuper[super]
	end
	while (super ~= baseClass and class_Super_flag[super[method]]) do
		super = ooSuper[super]
	end
	local sMethod = super[method]
	assert(type(sMethod)=="function" and sMethod ~= cMethod, "failed to find inherited class method "..tostring(method))
	class_Super_flag[sMethod] = true
	local ret = sMethod(self, ...)
	class_Super_flag[sMethod] = nil
	return ret
end -- <class>:Super()


--[[ OBJECT METHODS ]]--
-- these assume that they will only be called on valid objects, but never on instances of baseClass (which should not be instantiable)

--- Clones this object.
-- This is equivalent to calling this object's class' :New() method to create
-- a new instance of the class (using any provided arguments), and then
-- performing a shallow copy of this object's properties onto the clone.
--
-- This method may be overridden.  An implementor overriding this method must
-- return the result of '''self:Super("Clone", ...)''' or
-- '''(self:GetClass()):New(...)''' with appropriate arguments in order to
-- provide the caller a usable object reference.  Returning "false" or raising
-- an error may suggest to the caller that instances of this class should not
-- be cloned, but Lua's flexibility makes strict restrictions impossible to
-- enforce.  A caller in doubt may verify that the returned value is a valid
-- object reference with, for example, '''LibOOP:InstanceOf(<return>)'''.
-- @name <object>:Clone
-- @param ... (Optional) Any number of arguments to pass to the clone's constructor.
-- @return A table representing the newly created object.
function baseProto:Clone(...) -- overridable
	local class = ooClassByProto[getmetatable(self)]
	local newObj = class:New(...)
	for k,v in pairs(self) do
		newObj[k] = v
	end
	return newObj
end -- <object>:Clone()

--- Returns the class of this object.
-- Equivalent to '''LibOOP:GetClass(<object>)'''.
--
-- This method may not be overridden.
-- @name <object>:GetClass
-- @return A reference to the table representing the object's class.
function baseProto:GetClass() -- non-overridable
	return ooClassByProto[getmetatable(self)] or nil
end -- <object>:GetClass()

--- Tests if this object is an instance of a given class.
-- If "class" is omitted, this always returns true (when called on a LibOOP
-- class instance).  If "direct" is true, then "object" must be an instance of
-- "class" itself; otherwise, it may also be an instance of a subclass of
-- "class".  Equivalent to
-- '''LibOOP:InstanceOf(<object>[, <class>[, <direct>]])'''.
--
-- This method may not be overridden.
-- @name <object>:InstanceOf
-- @param class (Optional) A class reference to test instantiation from.
-- @param direct (Optional) If true, tests only direct inheritence.
-- @return True if the object satisfies the specified inheritence profile, false otherwise.
function baseProto:InstanceOf(class, direct) -- non-overridable
	local oClass = ooClassByProto[getmetatable(self)]
	if (not class or oClass == class) then
		return true
	elseif (direct or not ooSuper[class]) then
		return false
	end
	return baseClass.SubClassOf(oClass, class)
end -- <object>:InstanceOf()

local object_Super_flag = {}
--- Calls the inherited version of the given method.
-- The method will be called like a normal object method, passing this object
-- as the implicit first argument "self".  However, the method will still have
-- the scope (and the variables in closure) with which it was defined, rather
-- than that of this object's class or prototype.
--
-- This method may not be overridden.
-- @name <object>:Super
-- @param method The name of the inherited method to be called, as a string.
-- @param ... (Optional) Any number of arguments to pass to the method.
-- @return All return values from the method.
function baseProto:Super(method, ...) -- non-overridable
	local super = ooClassByProto[getmetatable(self)]
	local proto = ooProto[super]
	local oMethod = self[method]
	while (proto and proto[method] == oMethod) do
		super = ooSuper[super]
		proto = ooProto[super]
	end
	while (proto and object_Super_flag[proto[method]]) do
		super = ooSuper[super]
		proto = ooProto[super]
	end
	assert(proto, "failed to find inherited instance method "..tostring(method))
	local sMethod = proto[method]
	assert(type(sMethod)=="function" and sMethod ~= oMethod, "failed to find inherited instance method "..tostring(method))
	object_Super_flag[sMethod] = true
	local ret = sMethod(self, ...)
	object_Super_flag[sMethod] = nil
	return ret
end -- <object>:Super()


--[[ LIBRARY METHODS ]]--
-- these should accept and validate any input at all

--- Defines a new class.
-- The new class will inherit the methods "New", "Extend", "GetSuperClass",
-- "SubClassOf" and "Super" from the base class, and will also provide a
-- "prototype" table on which properties and methods may be defined that will
-- be inherited by all objects of the class or its subclasses.
-- @name LibOOP:Class
-- @return A table representing the newly created class.
function LibOOP:Class()
	return baseClass:Extend()
end -- Class()

--- Determines if the given reference is an object, and returns its class.
-- If the argument is a valid LibOOP class instance, this is equivalent to
-- '''<object>:GetClass()'''.
-- @name LibOOP:GetClass
-- @param object A (potential) object reference to get the class of.
-- @return A reference to the table representing the object's class, or nil if called on a non-object.
function LibOOP:GetClass(object)
	if (type(object) ~= "table") then
		return nil
	end
	return baseProto.GetClass(object)
end -- GetClass()

--- Determines if the given reference is a class, and returns its superclass.
-- If the argument is a valid LibOOP class, this is equivalent to
-- '''<class>:GetSuperClass()'''.
-- @name LibOOP:GetSuperClass
-- @param class A (potential) class reference to get the superclass of.
-- @return A reference to the table representing the class' superclass, false if the class has no superclass, or nil if called on a non-class.
function LibOOP:GetSuperClass(class)
	if (not ooSuper[class]) then
		return nil
	end
	return baseClass.GetSuperClass(class)
end -- GetSuperClass()

--- Determines if the given reference is an instance of a given class.
-- If "class" is omitted, this returns true if "object" is a valid LibOOP
-- class instance.  If "class" is provided and "direct" is true, then "object
-- must be an instance of "class" itself; otherwise, it may also be an
-- instance of a subclass of "class".  If "object" is a valid LibOOP class
-- instance, this is equivalent to
-- '''<object>:InstanceOf(<class>[, <direct>])'''.
-- @name LibOOP:InstanceOf
-- @param object A (potential) object reference to test the inheritance of.
-- @param class (Optional) A class reference to test instantiation from.
-- @param direct (Optional) If true, tests only direct inheritence.
-- @return True if the object satisfies the specified inheritence profile, false if it doesn't, or nil if called on a non-object.
function LibOOP:InstanceOf(object, class, direct)
	if (type(object) ~= "table" or not ooClassByProto[getmetatable(object)]) then
		return nil
	end
	return baseProto.InstanceOf(object, class, direct)
end -- InstanceOf()

--- Determines if the given reference is a subclass of a given superclass.
-- If "super" is omitted, this returns true if "class" is a valid LibOOP
-- class.  If "super" is provided and "direct" is true, then "class" must
-- extend "super" directly; otherwise, it may also extend a subclass of
-- "super".  If "class" is a valid LibOOP class, this is equivalent to
-- '''<class>:SubClassOf(<super>[, <direct>])'''.
-- @name LibOOP:SubClassOf
-- @param class A (potential) class reference to test the inheritance of.
-- @param super (Optional) A class reference to test inheritence from.
-- @param direct (Optional) If true, tests only direct inheritence.
-- @return True if the class satisfies the specified inheritence profile, false if it doesn't, or nil if called on a non-class.
function LibOOP:SubClassOf(class, super, direct)
	if (not ooSuper[class]) then
		return nil
	end
	return baseClass.SubClassOf(class, super, direct)
end -- SubClassOf()

--- Calls the inherited version of the given method.
-- If the reference is a class or object, this is equivalent to
-- '''<ref>:Super(method[, ...])'''; otherwise, this does nothing and returns
-- nothing.
-- @name LibOOP:Super
-- @param ref A class or object reference on which to operate.
-- @param method The name of the inherited method to be called, as a string.
-- @param ... (Optional) Any number of arguments to pass to the method.
-- @return All return values from the method.
function LibOOP:Super(ref, method, ...)
	local ptr = noop
	if (ooSuper[ref]) then
		ptr = baseClass.Super
	elseif (type(ref)=="table" and ooClassByProto[getmetatable(ref)]) then
		ptr = baseProto.Super
	end
	return ptr(ref, method, ...)
end -- Super()

-- undocumented, for internal use only!
function LibOOP:__dump_for_upgrade(key)
	assert(key==DUMPKEY, "invalid call to runtime-upgrade handler")
	return ooSuper,ooProto,ooObjectMeta,baseClass,baseProto
end -- __dump_for_upgrade()
