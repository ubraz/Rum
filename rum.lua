-- Project: Rum
--
-- Version: 0.3
--
-- Author: Graham Ranson 
--
-- Support: www.monkeydeadstudios.com or www.grahamranson.co.uk
--
-- Copyright (C) 2011 MonkeyDead Studios Limited. All Rights Reserved.
--
-- Credits: Some code has been borrowed from other places such as the string and table functions, 
--			if I have failed to give proper credit please tell me so that I can add it.

----------------------------------------------------------------------------------------------------
----										CHANGES												----
----------------------------------------------------------------------------------------------------

-- 0.1 - Initial alpha release - 28/02/2011
--
-- 0.2 - 03/03/2011
--
--     	- Added system.isAndroid property - Will also be true if on Windows.
--
--	   	- Maps now work on Android / Windows using synchronous downloading.	
--
--     	- newSpriteSheetFromData() is no longer overridden for Retina graphics.
--
--		- display.newText() now makes Retina text automatically. Should work for buttons too.
--
--		- math.angleBetween() will now return 0 - 360 rather than 0 - 180 and -180 - 0.
--
--		- Added safe wrappers for OpenFeint in Simulator and Android.
--
--		- Temporarily removed the system.pathForFile checks before including Json and UI due
--			- to problems on hardware. If you don't want to use either of these things simply comment
--			- out the require statements just below these comments.
--
--		- Added in global "delete( path [, baseDirectory ] )" function for removing files. Simply wraps up os.remove.
--			- Can be used to delete saved data (as well as anything else)
--
--		- Added in basic Vector class - math.Vector:new(x, y) - with addition, subtraction, multiplication,
--			- division, length, comparisons and dot product. In theory.
--
--		- mapView:nearestAddress() now fires a mapAddress event.
--
--		- display.setDefault() can now accept "font" as a key to set the default font name.
--
--		- display.setDefault() can now accept "textSize" as a key to set the default text size.
--
--		- Reorganised the base functions to make them easier to manage and use.
--
--		- You will now need to change the "usingJson" and "usingUI" values in the preferences section
--		- depending on whether you are using Json.lua or ui.lua. This is because system.pathForFile
--		- doesn't seem to work the same way anymore on hardware as it does in the simulator.
--
-- 0.3 - 15/03/2011
--
--		- Added display.hideStatusBar()
--
--		- Added display.measureText() - pass in a string, font and size and get the pixel width of 
--		- the created text object. 
--
--		- Added display.newParagraph( parentGroup, text, width, font, size, align, lineHeight )
--		
--		- Added display.getAvailableColors()
--
--		- Added math.gpsDistanceBetween()
--
--		- Added system.isDevice property
--
--		- Removed a duplicated call in display.newGroup() - good catch Dewey!
--
----------------------------------------------------------------------------------------------------
----									MODULE DEFINITION										----
----------------------------------------------------------------------------------------------------

module(..., package.seeall)

----------------------------------------------------------------------------------------------------
----										PREFERENCES											----
----------------------------------------------------------------------------------------------------

-- Due to problems with system.pathForFile you will need to change these two settings depending on
-- whether you are using Json.lua and ui.lua
usingJson = true
usingUI = true

----------------------------------------------------------------------------------------------------
----									REQUIRED MODULES										----
----------------------------------------------------------------------------------------------------

if usingJson then
	Json = require('Json')
end

require('socket')
local http = require("socket.http")
local ltn12 = require("ltn12")

require("sprite")

if usingUI then
	ui = require("ui")
end

----------------------------------------------------------------------------------------------------
----								   		BASE FUNCTIONS										----
----------------------------------------------------------------------------------------------------

-- These are the unmodified base functions. If for any reason you wish to skip using a Rum
-- modification then simply call rum.base.section.functionName() i.e. rum.base.display.newText()

base = {}

base.display = {}
base.display.newGroup = display.newGroup
base.display.newImage = display.newImage
base.display.newImageRect = display.newImageRect
base.display.downloadRemoteImage = display.downloadRemoteImage
base.display.newText = display.newText
base.display.newLine = display.newLine
base.display.newRect = display.newRect
base.display.newRoundedRect = display.newRoundedRect
base.display.newCircle = display.newCircle
base.display.setDefault = display.setDefault

base.native = {}
base.native.newTextField = native.newTextField
base.native.newTextBox = native.newTextBox
base.native.showWebPopup = native.showWebPopup
base.native.cancelWebPopup = native.cancelWebPopup
base.native.newMapView = native.newMapView
base.native.setActivityIndicator = native.setActivityIndicator

base.system = {}
base.system.activate = system.activate

if sprite then
	base.sprite = {}
	base.sprite.newSprite = sprite.newSprite
	base.sprite.newSpriteSet = sprite.newSpriteSet
	base.sprite.newSpriteSheet = sprite.newSpriteSheet
	base.sprite.newSpriteSheetFromData = sprite.newSpriteSheetFromData
	base.sprite.addSprite = sprite.add
end

if ui then
	base.ui = {}
	base.ui.newButton = ui.newButton
	base.ui.newLabel = ui.newLabel
end

if openfeint then
	base.openfeint = {}
	base.openfeint.init = openfeint.init
	base.openfeint.launchDashboard = openfeint.launchDashboard
	base.openfeint.setHighScore = openfeint.setHighScore
	base.openfeint.unlockAchievement = openfeint.unlockAchievement
	base.openfeint.uploadBlob = openfeint.uploadBlob
	base.openfeint.downloadBlob = openfeint.downloadBlob
end

----------------------------------------------------------------------------------------------------
----									LOCALISED FUNCTIONS										----
----------------------------------------------------------------------------------------------------

local getInfo = system.getInfo
local getPreference = system.getPreference
local getLocalePreference = function(pref) return getPreference("locale", pref)  end

local getCurrentStage = display.getCurrentStage

local rad = math.rad
local deg = math.deg
local sqrt = math.sqrt
local atan = math.atan
local atan2 = math.atan2
local pi = math.pi
local twoPi = pi * 2
local random = math.random
local randomseed = math.randomseed
local floor = math.floor
local ceil = math.ceil
local sin = math.sin
local cos = math.cos
local acos = math.acos

local print = print
local type = type
local collectgarbage = collectgarbage

local time = os.time

local tableRemove = table.remove
local tableForEach = table.foreach

local pathForFile = system.pathForFile
local openFile = io.open
local closeFile = io.close
local ResourceDirectory = system.ResourceDirectory
local DocumentsDirectory = system.DocumentsDirectory
local TemporaryDirectory = system.TemporaryDirectory

randomseed( time() )

----------------------------------------------------------------------------------------------------
----								  	LOCAL PROPERTIES										----
----------------------------------------------------------------------------------------------------

local _objects = {}
local _enterFrameListenerAdded = false

-- Thanks go to Frank S for the creation of this colour list - https://github.com/franks42/colors-rgb.lua/blob/master/colors-rgb.lua
_G["colour"] = 
{
	aliceblue = {240, 248, 255},
	antiquewhite = {250, 235, 215},
	aqua = { 0, 255, 255},
	aquamarine = {127, 255, 212},
	azure = {240, 255, 255},
	beige = {245, 245, 220},
	bisque = {255, 228, 196},
	black = { 0, 0, 0},
	blanchedalmond = {255, 235, 205},
	blue = { 0, 0, 255},
	blueviolet = {138, 43, 226},
	brown = {165, 42, 42},
	burlywood = {222, 184, 135},
	cadetblue = { 95, 158, 160},
	chartreuse = {127, 255, 0},
	chocolate = {210, 105, 30},
	coral = {255, 127, 80},
	cornflowerblue = {100, 149, 237},
	cornsilk = {255, 248, 220},
	crimson = {220, 20, 60},
	cyan = { 0, 255, 255},
	darkblue = { 0, 0, 139},
	darkcyan = { 0, 139, 139},
	darkgoldenrod = {184, 134, 11},
	darkgray = {169, 169, 169},
	darkgreen = { 0, 100, 0},
	darkgrey = {169, 169, 169},
	darkkhaki = {189, 183, 107},
	darkmagenta = {139, 0, 139},
	darkolivegreen = { 85, 107, 47},
	darkorange = {255, 140, 0},
	darkorchid = {153, 50, 204},
	darkred = {139, 0, 0},
	darksalmon = {233, 150, 122},
	darkseagreen = {143, 188, 143},
	darkslateblue = { 72, 61, 139},
	darkslategray = { 47, 79, 79},
	darkslategrey = { 47, 79, 79},
	darkturquoise = { 0, 206, 209},
	darkviolet = {148, 0, 211},
	deeppink = {255, 20, 147},
	deepskyblue = { 0, 191, 255},
	dimgray = {105, 105, 105},
	dimgrey = {105, 105, 105},
	dodgerblue = { 30, 144, 255},
	firebrick = {178, 34, 34},
	floralwhite = {255, 250, 240},
	forestgreen = { 34, 139, 34},
	fuchsia = {255, 0, 255},
	gainsboro = {220, 220, 220},
	ghostwhite = {248, 248, 255},
	gold = {255, 215, 0},
	goldenrod = {218, 165, 32},
	gray = {128, 128, 128},
	grey = {128, 128, 128},
	green = { 0, 128, 0},
	greenyellow = {173, 255, 47},
	honeydew = {240, 255, 240},
	hotpink = {255, 105, 180},
	indianred = {205, 92, 92},
	indigo = { 75, 0, 130},
	ivory = {255, 255, 240},
	khaki = {240, 230, 140},
	lavender = {230, 230, 250},
	lavenderblush = {255, 240, 245},
	lawngreen = {124, 252, 0},
	lemonchiffon = {255, 250, 205},
	lightblue = {173, 216, 230},
	lightcoral = {240, 128, 128},
	lightcyan = {224, 255, 255},
	lightgoldenrodyellow = {250, 250, 210},
	lightgray = {211, 211, 211},
	lightgreen = {144, 238, 144},
	lightgrey = {211, 211, 211},
	lightpink = {255, 182, 193},
	lightsalmon = {255, 160, 122},
	lightseagreen = { 32, 178, 170},
	lightskyblue = {135, 206, 250},
	lightslategray = {119, 136, 153},
	lightslategrey = {119, 136, 153},
	lightsteelblue = {176, 196, 222},
	lightyellow = {255, 255, 224},
	lime = { 0, 255, 0},
	limegreen = { 50, 205, 50},
	linen = {250, 240, 230},
	magenta = {255, 0, 255},
	maroon = {128, 0, 0},
	mediumaquamarine = {102, 205, 170},
	mediumblue = { 0, 0, 205},
	mediumorchid = {186, 85, 211},
	mediumpurple = {147, 112, 219},
	mediumseagreen = { 60, 179, 113},
	mediumslateblue = {123, 104, 238},
	mediumspringgreen = { 0, 250, 154},
	mediumturquoise = { 72, 209, 204},
	mediumvioletred = {199, 21, 133},
	midnightblue = { 25, 25, 112},
	mintcream = {245, 255, 250},
	mistyrose = {255, 228, 225},
	moccasin = {255, 228, 181},
	navajowhite = {255, 222, 173},
	navy = { 0, 0, 128},
	oldlace = {253, 245, 230},
	olive = {128, 128, 0},
	olivedrab = {107, 142, 35},
	orange = {255, 165, 0},
	orangered = {255, 69, 0},
	orchid = {218, 112, 214},
	palegoldenrod = {238, 232, 170},
	palegreen = {152, 251, 152},
	paleturquoise = {175, 238, 238},
	palevioletred = {219, 112, 147},
	papayawhip = {255, 239, 213},
	peachpuff = {255, 218, 185},
	peru = {205, 133, 63},
	pink = {255, 192, 203},
	plum = {221, 160, 221},
	powderblue = {176, 224, 230},
	purple = {128, 0, 128},
	red = {255, 0, 0},
	rosybrown = {188, 143, 143},
	royalblue = { 65, 105, 225},
	saddlebrown = {139, 69, 19},
	salmon = {250, 128, 114},
	sandybrown = {244, 164, 96},
	seagreen = { 46, 139, 87},
	seashell = {255, 245, 238},
	sienna = {160, 82, 45},
	silver = {192, 192, 192},
	skyblue = {135, 206, 235},
	slateblue = {106, 90, 205},
	slategray = {112, 128, 144},
	slategrey = {112, 128, 144},
	snow = {255, 250, 250},
	springgreen = { 0, 255, 127},
	steelblue = { 70, 130, 180},
	tan = {210, 180, 140},
	teal = { 0, 128, 128},
	thistle = {216, 191, 216},
	tomato = {255, 99, 71},
	transparent = {0, 0, 0, 0},
	turquoise = { 64, 224, 208},
	violet = {238, 130, 238},
	wheat = {245, 222, 179},
	white = {255, 255, 255},
	whitesmoke = {245, 245, 245},
	yellow = {255, 255, 0},
	yellowgreen = {154, 205, 50}
}
_G["colour"].toRGB = function( colour ) 

	if type( colour ) == "string" then
		local colour = _G.colour[name] or _G.colour.white
		return colour[1], colour[2], colour[3]
	elseif type( colour ) == "table" then
		return colour[1], colour[2], colour[3]
	end
	
end

_G["color"] = _G["colour"] -- Quick alternative for our friends across the pond.

----------------------------------------------------------------------------------------------------
----								  	LOCAL METHODS											----
----------------------------------------------------------------------------------------------------

local onUpdate = function( event )
	
	for i = 1, #_objects, 1 do
		
		if _objects[i]._behaviours then
			
			for j = 1, #_objects[i]._behaviours, 1 do
				
				if _objects[i]._behaviours[j].isActive then
					_objects[i]._behaviours[j].callback( _objects[i] )
				end
				
			end
			
		end
		
	end

end

local function hexToBinary(str)

	local hex2bin = 
	{
		["0"] = "0000",
		["1"] = "0001",
		["2"] = "0010",
		["3"] = "0011",
		["4"] = "0100",
		["5"] = "0101",
		["6"] = "0110",
		["7"] = "0111",
		["8"] = "1000",
		["9"] = "1001",
		["a"] = "1010",
        ["b"] = "1011",
        ["c"] = "1100",
        ["d"] = "1101",
        ["e"] = "1110",
        ["f"] = "1111"
	}

	local ret = ""
	local i = 0

	for i in string.gfind(str, ".") do
		i = string.lower(i)

		ret = ret..hex2bin[i]

	end

	return ret
end

function binaryToDecimal(str)

	local num = 0
	local ex = string.len(str) - 1
	local l = 0

	l = ex + 1
	for i = 1, l do
		b = string.sub(str, i, i)
		if b == "1" then
			num = num + 2^ex
		end
		ex = ex - 1
	end

	return string.format("%u", num)

end

function hexToDecimal(str)

	local str = hexToBinary(str)

	return binaryToDecimal(str)

end


local getColourFromName = function( name )
	
	name = name:lower()
	
	local colour = _G["colour"][name] or { 255, 255, 255 }
	
	if not colour[4] then
		colour[4] = 255
	end
	
	return colour
end

local getColourFromHex = function( hex )

	hex = hex:lower()

	local colour = {}
	
	if hex:len() == 6 or hex:len() == 8 then
		colour[1] = string.sub(hex, 1, 2)
		colour[2] = string.sub(hex, 3, 4)
		colour[3] = string.sub(hex, 5, 6)	
		
		if hex:len() == 8 then
			colour[4] = string.sub(hex, 7, 8)	
		end	

		for i = 1, #colour, 1 do
			colour[i] = hexToDecimal(colour[i])
		end
		
	end
	
	for i = 1, #colour, 1 do
		colour[i] = tonumber(colour[i])
	end
	
	return colour
end

local getColourFromString = function( s )

	local firstLetter = string.sub(s, 1, 1)
	
	if firstLetter == "#" then
		return getColourFromHex( string.sub( s, 2 ) ) 
	else
		return getColourFromName( s ) 
	end
end

local addGroupObjectHelperMethods = function( object )
	
	object.baseInsert = object.insert
	
	--[[
	function object:insert( ... )
		
		local args = {...}
		local index = 0
		local resetTransform = nil
		
		if type( args[#args] ) == "boolean" then 
			index = 1
			resetTransform = args[#args] 
		end
		
		if type( args[2]) == "number" then 
			
			for i = 3, #args - index, 1 do 
				self:baseInsert( args[2], args[i], resetTransform) 
			end
			
    	else
   
    		for i = 2, #args - index, 1 do
    			self:baseInsert(args[i], resetTransform)
    		end
    		
    	end
		 
		self:baseInsert( ... )
		
	end
	--]]
	
	return object
end

local addGenericObjectHelperMethods = function( object )

	if object then

		_objects[#_objects + 1] = object
		
		--- Move the object by the specified amounts.
		-- @param x The amount to move the object along the X axis.
		-- @param y The amount to move the object along the Y axis.
		function object:move( x, y )
			self.x = self.x + (x or 0)
			self.y = self.y + (y or 0)
		end

		--- Sets the position of the object.
		-- @param x The new X position.
		-- @param y The new Y position.
		function object:setPosition( x, y )
			self.x = x or self.x
			self.y = y or self.y
		end
		
		--- Gets the distance between this object and another position.
		-- @param position A table (can be a display object or touch/tap event) containing an X and Y value.
		-- @return The distance between the two positions.
		function object:getDistanceTo( position )
			return math.distanceBetween( self, position )
		end	
	
		--- Gets the angle between this object and another position.
		-- @param position A table (can be a display object or touch/tap event) containing an X and Y value.
		-- @return The angle between the two positions.	
		function object:getAngleTo( position )
			return math.angleBetween( self, position )
		end	
		
		--- Rotates this object to point at another position.
		-- @param position A table (can be a display object or touch/tap event) containing an X and Y value.	
		function object:rotateTo( position )
			self.rotation = self:getAngleTo( position )
		end
		
		--- Gets a behaviour from the object.
		-- @param callback The callback function of the behaviour.
		-- @return The behaviour or nil if none found.
		function object:getBehaviour( callback )
			
			if not self._behaviours then
				return false
			end
			
			for i = 1, #self._behaviours, 1 do
				
				if self._behaviours[i].callback == callback then
									
					return self._behaviours[i]
					
				end
				
			end
			
			return nil
			
		end
		
		--- Pauses a behaviour on the object.
		-- @param callback The callback function of the behaviour.
		-- @return True if the behaviour was paused, false and a reason if it wasn't.
		function object:pauseBehaviour( callback )
			
			if not self:hasBehaviour( callback ) then
				return false, "Object does not have behaviour"
			end
			
			local behaviour = self:getBehaviour( callback )
			
			if behaviour then
				behaviour.isActive = false
				return true
			end
			
		end
		
		--- Resumes a behaviour on the object.
		-- @param callback The callback function of the behaviour.
		-- @return True if the behaviour was resumed, false and a reason if it wasn't.		
		function object:resumeBehaviour( callback )
		
			if not self:hasBehaviour( callback ) then
				return false, "Object does not have behaviour"
			end
			
			local behaviour = self:getBehaviour( callback )
			
			if behaviour then
				behaviour.isActive = true
				return true
			end
			
		end
		
		--- Checks if the object has a behaviour.
		-- @param callback The callback function of the behaviour.
		-- @return True if the object has the behaviour, false if it doesn't.	
		function object:hasBehaviour( callback )
			
			if not self._behaviours then
				return false
			end
			
			return self:getBehaviour( callback ) ~= nil
			
		end
		
		--- Removes a behaviour from the object.
		-- @param callback The callback function of the behaviour.
		-- @return True if the behaviour was removed, false and a reason if it wasn't.			
		function object:removeBehaviour( callback )
			
			if not self:hasBehaviour( callback ) then
				return false, "Object does not have behaviour"
			end
				
			for i = 1, #self._behaviours, 1 do
				
				if self._behaviours[i].callback == callback then
					table.remove( self._behaviours, i )
					
					return true
					
				end
				
			end
			
			return false, "Behaviour not found on object"
			
		end
	
		--- Adds a behaviour to the object.
		-- @param callback The callback function of the behaviour.
		-- @return True if the behaviour was added, false and a reason if it wasn't.		
		function object:addBehaviour( callback )
			
			if callback and type( callback ) == "function" then
		
				if self:hasBehaviour( callback ) then
					return false
				end
		
				if not _enterFrameListenerAdded then	
					Runtime:addEventListener( "enterFrame", onUpdate )
					_enterFrameListenerAdded = true
				end
				
				if not self._behaviours then
					self._behaviours = {}
				end
				
				self._behaviours[#self._behaviours + 1] = { callback = callback, isActive = true }
				
				return true
			end
		
			return false, "Param 'callback' must be of type 'function'"
		end
				
		--- Destroys the object. You still need to call object:removeSelf() like normal AFTER this.
		-- @param collectGarbage True if garbage should be collected after the destruction.		
		function object:destroy( collectGarbage )
		
			local removeObject = function() 
				
				local removeFromTable = function( index )
				
					if _objects[index] == self then
						tableRemove( _objects, index )
					end
					
				end
				
				self._behaviours = nil
				
				tableForEach( _objects, removeFromTable )
				
				if collectGarbage then
					timer.performWithDelay(1, function() collectgarbage("collect") end , 1) 
				end

			end
			
			removeObject()

		end
			
	end

	return object
end

local addLineObjectHelperMethods = function( object )
	
	object.baseSetColor = object.setColor
	
	--- Sets the colour of the line.
	-- @param rOrColour Either the value of the red component of the colour, a table containing rgb[a] eg {50, 205, 50}, a named colour eg "limegreen" / colour.limegreen, or a hex value eg "#32CD32"
	-- @param g The value of the green component of the colour.
	-- @param b The value of the blue component of the colour.
	-- @param a The value of the alpha component of the colour.
	function object:setColor( rOrColour, g, b, a )

		if rOrColour and type(rOrColour) == "number" then
			self:baseSetColor( rOrColour, g, b, a or 255)
		elseif rOrColour and type(rOrColour) == "table" then
			self:setColor( rOrColour[1], rOrColour[2], rOrColour[3], rOrColour[4] or 255 )
		elseif rOrColour and type(rOrColour) == "string" then
			self:setColor( getColourFromString( rOrColour ) )
		end
	
	end
	
	return object
	
end

local addVectorObjectHelperMethods = function( object )

	object.baseSetFillColor = object.setFillColor
	object.baseSetStrokeColor = object.setStrokeColor
	
	--- Sets the fill colour of the shape.
	-- @param rOrColour Either the value of the red component of the colour, a table containing rgb[a] eg {50, 205, 50}, a named colour eg "limegreen" / colour.limegreen, or a hex value eg "#32CD32"
	-- @param g The value of the green component of the colour.
	-- @param b The value of the blue component of the colour.
	-- @param a The value of the alpha component of the colour.
	function object:setFillColor( rOrColour, g, b, a )

		if rOrColour and type(rOrColour) == "number" then
			self:baseSetFillColor( rOrColour, g, b, a or 255)
		elseif rOrColour and type(rOrColour) == "table" then
			self:setFillColor( rOrColour[1], rOrColour[2], rOrColour[3], rOrColour[4] or 255 )
		elseif rOrColour and type(rOrColour) == "string" then
			self:setFillColor( getColourFromString( rOrColour ) )
		end
	
	end
	
	object.setFillColour = object.setFillColor
	
	--- Sets the stroke colour of the shape.
	-- @param rOrColour Either the value of the red component of the colour, a table containing rgb[a] eg {50, 205, 50}, a named colour eg "limegreen" / colour.limegreen, or a hex value eg "#32CD32"
	-- @param g The value of the green component of the colour.
	-- @param b The value of the blue component of the colour.
	-- @param a The value of the alpha component of the colour.
	function object:setStrokeColor( rOrColour, g, b, a )

		if rOrColour and type(rOrColour) == "number" then
			self:baseSetStrokeColor( rOrColour, g, b, a or 255)
		elseif rOrColour and type(rOrColour) == "table" then
			self:baseSetStrokeColor( rOrColour[1], rOrColour[2], rOrColour[3], rOrColour[4] or 255 )
		elseif rOrColour and type(rOrColour) == "string" then
			self:baseSetStrokeColor( getColourFromString( rOrColour ) )
		end
	
	end
	
	object.setStrokeColour = object.setStrokeColor
	
	return object
end

local addTextObjectHelperMethods = function( object )

	object.baseSetTextColor = object.setTextColor

	--- Sets the colour of the text.
	-- @param rOrColour Either the value of the red component of the colour, a table containing rgb[a] eg {50, 205, 50}, a named colour eg "limegreen" / colour.limegreen, or a hex value eg "#32CD32"
	-- @param g The value of the green component of the colour.
	-- @param b The value of the blue component of the colour.
	-- @param a The value of the alpha component of the colour.
	function object:setTextColor( rOrColour, g, b, a )

		if rOrColour and type(rOrColour) == "number" then
			self:baseSetTextColor( rOrColour, g, b, a or 255)
		elseif rOrColour and type(rOrColour) == "table" then
			self:setTextColor( rOrColour[1], rOrColour[2], rOrColour[3], rOrColour[4] or 255 )
		elseif rOrColour and type(rOrColour) == "string" then
			self:setTextColor( getColourFromString( rOrColour ) )
		end
	
	end
	
	object.setTextColour = object.setTextColor
	
	return object
end

----------------------------------------------------------------------------------------------------
----									PUBLIC METHODS											----
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
----									NEW PROPERTIES											----
----------------------------------------------------------------------------------------------------

system.environment = getInfo("environment")
system.isSimulator = system.environment == "simulator"
system.isDevice = not system.isSimulator
system.deviceID = getInfo("deviceID")
system.deviceName = getInfo("name")
system.deviceModel = getInfo("model")
system.platformName = getInfo("platformName")
system.isAndroid = ( system.platformName == "Android" or system.platformName == "Win" )
system.platformVersion = getInfo("platformVersion")
system.build = getInfo("build")
system.version = getInfo("version")
system.language = getPreference("ui", "language")
system.locale = { country = getLocalePreference("country"), identifier = getLocalePreference("identifier") , language = getLocalePreference("language")  }

registeredVariables = {}

----------------------------------------------------------------------------------------------------
----									NEW METHODS												----
----------------------------------------------------------------------------------------------------

--~~~~~~~~~~~~~~~~~~~~--
--~~      GLOBAL	~~--
--~~~~~~~~~~~~~~~~~~~~--

--- Just a quick alternative to make sure it is always Rum time.
_G.Rumtime = _G.Runtime

--- Makes everything fly.
_G.makeItFly = function()
	print("I'm sorry, Dave. I'm afraid I can't do that.")
end

--- Sets (or creates) a global variable.
-- @param name The name of the variable.
-- @param value The value of the variable.
_G.saveVariable = function( name, value )

	if not registeredVariables then
		registeredVariables = {}
	end
	
	registeredVariables[name] = value
	
end

--- Gets a global variable.
-- @param name The name of the variable.
-- @return The value of the variable or nil if not found.
_G.loadVariable = function( name )

	if not registeredVariables then
		return
	end
	
	return registeredVariables[name]
end

_G.save = function( data, path )
	if data and type(data) == "table" then
		table.save( data, path )
	end
end

_G.load = function( path )
	return table.load( path )
end

_G.delete = function( path, baseDirectory )

	if baseDirectory and baseDirectory == ResourceDirectory then
		return false, "Deleting files from the ResourceDirectory is not allowed."
	end
	
	path = system.pathForFile( path, baseDirectory or DocumentsDirectory )
	
	return os.remove( path )
end

--~~~~~~~~~~~~~~~~~~~~--
--~~      DISPLAY	~~--
--~~~~~~~~~~~~~~~~~~~~--

display.hideStatusBar = function()
	display.setStatusBar( display.HiddenStatusBar ) 
end

--- Measure the width of a string.
-- @param text The text to measure.
-- @param font The font to use.
-- @param size The size of the font.
-- @return The width in pixels.
display.measureText = function( text, font, size )
	
	local textObject = display.newText( text, 0, 0, font, size )
	
	local width = textObject.contentWidth
	
	textObject:removeSelf()
	textObject = nil
	
	return width
	
end

--- Create a new wrapped paragraph.
-- @param parentGroup The parent group. Optional.
-- @param text The text to use.
-- @param width Maximum width, in pixels, of the paragraph.
-- @param font The font to use.
-- @param size The size of the font.
-- @param align The paragraph alignment. Optional, defaults to "centre". Can be "left", "right" or "centre"/"center".
-- @param lineHeight The size of each line. Optional, default to the pixel height of the line.
-- @return The new paragraph object.
display.newParagraph = function( parentGroup, text, width, font, size, align, lineHeight )
	
	-- If the first argument is actually the text then move them all up one
	if type( parentGroup ) == "string" then
		parentGroup, text, width, font, size, align, lineHeight = display.getCurrentStage(), parentGroup, text, width, font, size, align
	end
		
	-- Create the paragraph object
	local self = display.newGroup()
	
	self.maxWidth = width
		
	local alignLine = function( line, align  )
	
		if not align then
			align = "centre"
		end
		
		align = string.lower(align)
		
		if align and align == "centre" or align == "center" then
			-- Default so at present do nothing
		elseif align and align == "left" then	
			line.x = math.floor(line.contentWidth / 2)	
		elseif align and align == "right" then
			line.x = -math.floor(line.contentWidth / 2)
		end
		
	end
	
	local setText = function( text, font, size, align, lineHeight )

		-- Split the text into words
		local words = text:split(" ")
		
		-- Create the first empty line
		local line = display.newText( self, "", 0, 0, font, size)
		
		local word = nil
		
		-- Loop through all the words
		for i = 1, #words, 1 do
			
			word = words[i]
			
			if display.measureText(line.text .. " " .. word .. " ", font, size) >= self.maxWidth then
			
				if not lineHeight or type(lineHeight) == "string" then
					lineHeight = line.contentHeight
				end
				
				line = display.newText( self, " " .. word, 0, lineHeight * self.numChildren, font, size)
				
				alignLine( line, align )
				
			else
				line.text = line.text .. " " .. word
				
				alignLine( line, align )
	
			end
			
		end
	
	end
	
	--- Sets the colour of the text.
	-- @param rOrColour Either the value of the red component of the colour, a table containing rgb[a] eg {50, 205, 50}, a named colour eg "limegreen" / colour.limegreen, or a hex value eg "#32CD32"
	-- @param g The value of the green component of the colour.
	-- @param b The value of the blue component of the colour.
	-- @param a The value of the alpha component of the colour.
	function self:setTextColor( rOrColour, g, b, a )

		for i = 1, self.numChildren, 1 do

			if self[i]["setTextColor"] then
				self[i]:setTextColor( rOrColour, g, b, a )
			end
		end
	
	end
	
	self.setTextColour = self.setTextColor
	
	--- Align the paragraph.
	-- @param align The type of alignment. "left", "right" or "centre"/"center".
	function self:setTextAlignment( align )
		
		for i = 1, self.numChildren, 1 do
			alignLine( self[i], align )
		end
		
	end
	
	setText( text, font, size, align, lineHeight )
	
	if parentGroup and parentGroup.insert then
		parentGroup:insert( self )
	end
	
	return addGenericObjectHelperMethods( self )
end

display.getAvailableColors = function()
	return _G.colour
end
display.getAvailableColours = display.getAvailableColors

--~~~~~~~~~~~~~~~~~~~~--
--~~      SYSTEM	~~--
--~~~~~~~~~~~~~~~~~~~~--

--- Gets the amount of texture memory being used.
-- @return The memory usage in bytes.
system.getTextureMemoryUsed = function()
	return getInfo("textureMemoryUsed")
end

--- Checks if there is an internet connection.
-- @param Url to check with. Do not include protocol. Optional, default is www.google.com
-- @return True if yes, false if not.
system.verifyInternetConnection = function( url )

 	local connection = socket.connect(  url or "www.google.com", 80)
 	
    if connection == nil then
        return false
    end
    
    connection:close()
    
    return true
end

--~~~~~~~~~~~~~~~~~~~~--
--~~      MATH		~~--
--~~~~~~~~~~~~~~~~~~~~--

math.gpsDistanceBetween = function ( pos1, pos2, radians )

	local earthRadius = 6371
	
	local lat1 = rad( pos1.latitude )
	local lon1 = rad( pos1.longitude )
	local lat2 = rad( pos2.latitude )
	local lon2 = rad( pos2.longitude )
	
	local distance = acos( sin ( lat1 ) * sin ( lat2 ) + cos( lat1 ) * cos ( lat2 ) * cos( lon2 - lon1 ) ) * earthRadius;
                  
	return distance
end

--- Gets the distance between two positions.
-- @param pos1 First position. Table containing X and Y values.
-- @param pos2 Second position. Table containing X and Y values.
-- @return distance The distance between the two positions.
math.distanceBetween = function ( pos1, pos2 )

	if not pos1 or not pos2 then
		return
	end
	
	if not pos1.x or not pos1.y or not pos2.x or not pos2.y then
		return
	end
	 
	local factor = { x = pos2.x - pos1.x, y = pos2.y - pos1.y }

	return sqrt( ( factor.x * factor.x ) + ( factor.y * factor.y ) )

end

--- Gets the angle between two positions.
-- @param pos1 First position. Table containing X and Y values.
-- @param pos2 Second position. Table containing X and Y values.
-- @param radians If true then convert the angle to radians.
-- @return angle The angle between the two positions.
math.angleBetween = function ( pos1, pos2, radians )

	if not pos1 or not pos2 then
		return
	end
	
	if not pos1.x or not pos1.y or not pos2.x or not pos2.y then
		return
	end

	local distance = { x = pos2.x - pos1.x, y = pos2.y - pos1.y }

	if distance then

		local angleBetween = atan( distance.y / distance.x ) --+ rad( 90 )
	
	     if ( pos1.x < pos2.x ) then 
			angleBetween = angleBetween + rad( 90 ) 
		else 
			angleBetween = angleBetween + rad( 270 ) 
		end		
		
		if angleBetween == pi or angleBetween == pi2 then
  			angleBetween = angleBetween - rad( 180 )
		end

		if not radians then
			angleBetween = deg( angleBetween )
		end
		
		return angleBetween
	
	end

	return nil
end

math.Vector = {}

function math.Vector:add(v) 
	
	if type(v) == "number" then
	
		local newVector = math.Vector:new(self.x + v, self.y + v)
		
		--self.x = newVector.x
		--self.y = newVector.y
		
		return newVector
		
	elseif type(v) == "table" then
	
		local newVector = math.Vector:new(self.x + v.x, self.y + v.y) 
		
		self.x = newVector.x
		self.y = newVector.y
		
		return newVector
	end
	
end

function math.Vector:subtract(v) 

	if type(v) == "number" then
	
		local newVector = math.Vector:new(self.x - v, self.y - v)
		
		--self.x = newVector.x
		--self.y = newVector.y
		
		return newVector
		
	elseif type(v) == "table" then
	
		local newVector = math.Vector:new(self.x - v.x, self.y - v.y) 
		
		self.x = newVector.x
		self.y = newVector.y
		
		return newVector
	end
	
end

function math.Vector:toString()
	return "X:" .. self.x .. " Y:" .. self.y
end

function math.Vector:multiply(v) 

	if type(v) == "number" then
	
		local newVector = math.Vector:new(self.x * v, self.y * v)
		
		--self.x = newVector.x
		--self.y = newVector.y
		
		return newVector
		
	elseif type(v) == "table" then
	
		local newVector = math.Vector:new(self.x * v.x, self.y * v.y) 
		
		self.x = newVector.x
		self.y = newVector.y
		
		return newVector
	end
	
end

function math.Vector:divide(v) 

	if type(v) == "number" then
	
		local newVector = math.Vector:new(self.x / v, self.y / v)
		
		--self.x = newVector.x
		--self.y = newVector.y
		
		return newVector
		
	elseif type(v) == "table" then
	
		local newVector = math.Vector:new(self.x / v.x, self.y / v.y) 
		
		self.x = newVector.x
		self.y = newVector.y
		
		return newVector
	end
	
end

function math.Vector:compare(v)
	if self.x == v.x and self.y == v.y then
		return true
	else
		return false
	end
end

function math.Vector:lessThan(v)
	if self.x < v.x and self.y < v.y then
		return true
	else
		return false
	end
end

function math.Vector:lessThanOrEqualTo(v)
	if self.x <= v.x and self.y <= v.y then
		return true
	else
		return false
	end
end

function math.Vector:lengthSquared()
	return ( self.x * self.x ) + ( self.y * self.y )
end

function math.Vector:length()
	return sqrt( self:lengthSquared() )
end
	
function math.Vector:dot( vector )
	return ( self.x * vector.x ) + ( self.y * vector.y )
end

function math.Vector:negate()
	self.x = -self.x
	self.y = -self.y
end

math.Vector_mt = 
	{ 
		__index = math.Vector,
		__add = math.Vector.add,
		__sub = math.Vector.subtract, 
		__tostring = math.Vector.toString,
		__mul = math.Vector.multiply, 
		__div = math.Vector.divide, 
		__eq = math.Vector.compare,
		__lt = math.Vector.lessThan,
		__le = math.Vector.lessThanOrEqualTo--,
		--__len = Vector.length
	}

function math.Vector:new( x, y )
	
	local self = {}
	
	setmetatable( self, math.Vector_mt )
	
	self.x = x
	self.y = y
	
	return self
end

--~~~~~~~~~~~~~~~~~~~~--
--~~     TABLE		~~--
--~~~~~~~~~~~~~~~~~~~~--

--- Converts a table into a string.
-- @param t Table to convert.
-- @param indent Indentation amount. Optional.
-- @return string The converted string.
function table.toString( t, indent )

    local str = "" 

    if(indent == nil) then 
        indent = 0 
    end 

    -- Check the type 
    if(type(t) == "string") then 
        str = str .. (" "):rep(indent) .. t .. "\n" 
    elseif(type(t) == "number") then 
        str = str .. (" "):rep(indent) .. t .. "\n" 
    elseif(type(t) == "boolean") then 
        if(self == true) then 
            str = str .. "true" 
        else 
            str = str .. "false" 
        end 
    elseif(type(t) == "table") then 
        local i, v 
        for i, v in pairs(t) do 
            -- Check for a table in a table 
            if(type(v) == "table") then 
                str = str .. (" "):rep(indent) .. i .. ":\n" 
                str = str .. table.toString(v, indent + 2) 
            else 
                str = str .. (" "):rep(indent) .. i .. ": " .. table.toString(v, 0) 
            end 
        end 
    else 
        print("Error: unknown data type: %s", type(t)) 
    end 

    return str 
end

--- Prints out a table to the Console.
-- @param t Table to convert.
-- @param indent Indentation amount. Optional.
function table.print( t, indent )
	print( table.toString( t, indent ) )
end

--- Loads a table in from a Json file.
-- @param path Relative path to the file.
-- @param baseDirectory Base directory to load the file from. Optional, default is system.DocumentsDirectory.
function table.load( path, baseDirectory)

	if not Json then
	
		print("Error: Json.lua is required to load in a table. Get it from here - http://www.chipmunkav.com/downloads/Json.lua") 
	
		return
	end
	
	local path = pathForFile( path, baseDirectory or DocumentsDirectory )

	file = openFile( path, "r" )
	
	if file then
		
    	local table = Json.Decode( file:read( "*a" ) ) 

    	closeFile( file )

		return table
		
	else
		return nil
	end
	
end

--- Saves a table out to a Json file.
-- @param t The table to save.
-- @param path Relative path to the file.
-- @param baseDirectory Base directory to load the file from. Optional, default is system.DocumentsDirectory. Can not be system.ResourceDirectory.
function table.save( t, path, baseDirectory )

	if not Json then
	
		print("Error: Json.lua is required to load in a table. Get it from here - http://www.chipmunkav.com/downloads/Json.lua") 

		return
	end
		
	baseDirectory = baseDirectory or DocumentsDirectory
	
	if baseDirectory == ResourceDirectory then
		baseDirectory = DocumentsDirectory
	end

	local path = pathForFile( path, baseDirectory )

	local file = openFile( path, "w" )
	
	file:write( Json.Encode(t) )
	
    closeFile( file )
	
end

--- Finds a string in a table.
-- Borrowed from here - http://otfans.net/threads/112204-table.find-(matching-isInArray)?s=c063868c4d60d86e6495bc5683ef7209
-- @param t The table to search.
-- @param v String to search for.
-- @param c Optional setting for the search, "NOCASE", "PATTERN" or "PATTERN_NOCASE"
-- @return The index of the found element or false if not found.
function table.find( t, v, c )

	local noCase = "NOCASE"
	local pattern = "PATTERN"
	local patternNoCase = "PATTERN_NOCASE"
 
    if type(t) == "table" and v then 
        v = (c==noCase or c==patternNoCase) and v:lower() or v 
        for k, val in pairs(t) do 
            val = (c==noCase or c==patternNoCase) and val:lower() or val
            if (c==pattern or c==patternNoCase) and val:find(v) or v == val then 
                return k
            end 
        end 
    end 

    return false 

end

--~~~~~~~~~~~~~~~~~~~~--
--~~     STRING		~~--
--~~~~~~~~~~~~~~~~~~~~--

--- Converts a string to title case.
-- @param str The string to convert.
-- @return The converted string.
function string.titlecase( str )

	local function tchelper(first, rest)
		return first:upper()..rest:lower()
	end
	
	return str:gsub("(%a)([%w_']*)", tchelper)
end



--- URL Encodes a string.
-- @param str The string to encode.
-- @return The encoded string.
function string.encode( str )

  if str then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w ])", function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  
  return str	
  
end

--- URL Encodes a string into UTF8 format.
-- Borrowed from here - http://otfans.net/threads/150806-Some-functions?s=c063868c4d60d86e6495bc5683ef7209
-- @param str The string to encode.
-- @return The encoded string.
function string.encodeUTF8( str )
	
	local encodedStr = string.gsub(str, "([^ %w])", function (s) return "&#"..s:byte()..";" end)
	
    return encodedStr
end

--- URL Decodes a string from UTF8 format.
-- Borrowed from here - http://otfans.net/threads/150806-Some-functions?s=c063868c4d60d86e6495bc5683ef7209
-- @param str The string to decode.
-- @return The decoded string.
function string.decodeUTF8( str )

	local decodedStr = string.gsub(str, "&#(%d+);", function(s) return s:char() end)
	
    return decodedStr 
end

--- Splits a string.
-- @param str The string to split.
-- @param delim The delimiter to split on.
-- @return A table of all split elements.
function string.split(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

----------------------------------------------------------------------------------------------------
----								  OVERRIDDEN METHODS										----
----------------------------------------------------------------------------------------------------

--[[
system.activate = function( item, extraParam )
	
	base.activate( item )
	
	if item == "multitouch" and extraParam then
		
		local onGlobalTouch = function( event )
	
				local removeTouchObjects = function()
				
					if mainTouchObject and mainTouchObject["removeSelf"] then
						_G.mainTouchObject:removeSelf()
						_G.mainTouchObject = nil
					end
		
					if secondTouchObject and secondTouchObject["removeSelf"] then
						_G.secondTouchObject:removeSelf()
						_G.secondTouchObject = nil
					end
		
				end
				
				local createSecondEvent = function( event )
				
					local newEvent = {}
					
					newEvent.x = display.contentWidth - event.x
					newEvent.y = display.contentHeight - event.y
					newEvent.phase = event.phase
					newEvent.name = event.name
					newEvent.isFake = true
					newEvent.id = 2
					
					return newEvent
					
				end
				
				local fireEvents = function( events )
					
					for i = 1, #events, 1 do 
						
						local event = events[i]
						
						event.id = i
						event.isFake = true
						
						-- Fire global event
						Runtime:dispatchEvent( event )

						for i = 1, #_objects, 1 do
							
							local object = _objects[i]
							local bounds = object.contentBounds
							
							if object then
							
								if not bounds and object.width then
									bounds = {}
									bounds.xMin = object.x - ( ( object.contentWidth or object.width ) * 0.5 )
									bounds.xMax = object.x + ( ( object.contentWidth or object.width ) * 0.5 )
									bounds.yMin = object.y - ( ( object.contentHeight or object.height ) * 0.5 )
									bounds.yMax = object.y + ( ( object.contentHeight or object.height ) * 0.5 )
								end
								
								if bounds then
									if event.x > bounds.xMin and event.x < bounds.xMax then
										if event.y > bounds.yMin and event.y < bounds.yMax then
											event.target = object
											object:dispatchEvent( event )
										end
									end
								end
								
							end
						end
					end
				end
				
			if not event.isFake then
			
				if event.phase == "began" then
					
					local createTouchObject = function( x, y )
						
						local object = display.newCircle( x, y, 20 )
	
						object:setFillColor("slategrey")
						object.alpha = 0.7
						object.strokeWidth = 1
						object:setStrokeColor("black")
					
						return object
						
					end
					
					removeTouchObjects()
					
					_G.mainTouchObject = createTouchObject( event.x, event.y )
					
					local secondEvent = createSecondEvent( event )				
					_G.secondTouchObject = createTouchObject( secondEvent.x, secondEvent.y )
					
					fireEvents{ event, secondEvent }
					
					_G.secondTouchObject.parent:insert( _G.secondTouchObject )
					_G.mainTouchObject.parent:insert( _G.mainTouchObject )
					
					event.name = "tap"
					secondEvent.name = "tap"
					fireEvents{ event, secondEvent }
					
				elseif event.phase == "moved" then
					
					_G.mainTouchObject:setPosition(event.x, event.y)
					
					local secondEvent = createSecondEvent( event )
					fireEvents{ event, secondEvent }
					_G.secondTouchObject:setPosition( secondEvent.x, secondEvent.y )
					
					_G.secondTouchObject.parent:insert( _G.secondTouchObject )
					_G.mainTouchObject.parent:insert( _G.mainTouchObject )
					
				elseif event.phase == "ended" then
					
					local secondEvent = createSecondEvent( event )
					fireEvents{ event, secondEvent }
					
					removeTouchObjects()
					
				end
			end			
			
			
		end
		
		if system.isSimulator then
			Runtime:addEventListener( "touch", onGlobalTouch )
		end
		
		print("With Rum it does :-)")
		
	end
		
end
--]]

display.setDefault = function( key, rOrColour, g, b, a )
	
	if key == "font" and type(rOrColour) == "string" then
		_G.defaultFont = rOrColour
	elseif key == "textSize" and type(rOrColour) == "number"  then
		_G.defaultTextSize = rOrColour
	else
	
		local colour = {}
	
		if rOrColour and type(rOrColour) == "number" then
			colour = { rOrColour, g, b, a or 255 }
		elseif rOrColour and type(rOrColour) == "table" then
			colour = { rOrColour[1], rOrColour[2], rOrColour[3], rOrColour[4] or 255 }
		elseif rOrColour and type(rOrColour) == "string" then		
			colour = getColourFromString( rOrColour ) 
		end
	
		base.display.setDefault( key, colour[1], colour[2], colour[3], colour[4] )  
	end
	
end

display.newGroup = function() 
	local obj = addGenericObjectHelperMethods( base.display.newGroup() )
	return addGroupObjectHelperMethods( obj )
end

display.newLine = function( ... )
	local obj = addLineObjectHelperMethods( base.display.newLine( ... ) )
	return addGenericObjectHelperMethods( obj )
end

display.newCircle = function( ... )
	local obj = addVectorObjectHelperMethods( base.display.newCircle( ... ) )
	return addGenericObjectHelperMethods( obj )
end

display.newRect = function( ... )
	local obj = addVectorObjectHelperMethods( base.display.newRect( ... ) )
	return addGenericObjectHelperMethods( obj )
end

display.newRoundedRect = function( ...  ) 
	local obj = addVectorObjectHelperMethods( base.display.newRoundedRect( ... ) )
	return addGenericObjectHelperMethods( obj )
end

display.newImage = function( ... ) 
	return addGenericObjectHelperMethods( base.display.newImage( ... ) )
end

display.newImageRect = function( ... ) 
	return addGenericObjectHelperMethods( base.display.newImageRect( ... ) )
end

--- Creates a retina-ready text object with its top-left corner at (left, top).
-- @param parentGroup display group in which to insert the text. Optional.
-- @param string Text to display.
-- @param left Left position of the object.
-- @param top Top position of the object.
-- @param font Name of the font to use.
-- @param size Font size in pixels.
-- @return The text object.
display.newText = function( parentGroup, string, left, top, font, size ) 
		
	local isRetina = ( display.contentScaleX == 0.5 )	
	local newText
	alignment = "right"
	
	if type(parentGroup) == "table" then
	
		if isRetina then size = ( size or _G.defaultTextSize or 16 ) * 2 end
		
		if not font then
			size = _G.defaultTextSize	
			font = _G.defaultFont	
		elseif type(font) == "number" then
			size = font
			font = _G.defaultFont			
		end
		
		newText = base.display.newText( parentGroup, string, left, top, font, size ) 
		
	elseif type(parentGroup) == "string" then

		if isRetina then 
			font = ( font or _G.defaultTextSize or 16 ) * 2 
		end
		
		newText = base.display.newText( parentGroup, string, left, top or _G.defaultFont, font or _G.defaultTextSize )

	end

	if isRetina then 
		newText.xScale = 0.5 
		newText.yScale = 0.5   
	end

	newText = addGenericObjectHelperMethods( newText )
	
	return addTextObjectHelperMethods( newText )
end

--- Creates a simulator-safe text field.
-- @param left Left position of the object.
-- @param top Top position of the object.
-- @param width Width of the object.
-- @param height Height of the object.
-- @param listener Listener function to respond to keyboard events. Optional.
-- @return The textfield object.
native.newTextField = function( left, top, width, height, listener )

	if system.isSimulator then

		local group = display.newGroup()
	
		local rect = display.newRoundedRect(group, left, top, width, height, 8 )
		rect:setFillColor(colour.transparent)
		rect.strokeWidth = 2
		rect:setStrokeColor(colour.grey)
		
		local shadow = display.newRoundedRect(group, left + 2, top + 2, width - 3, height - 3, 6 )
		shadow:setFillColor(color.white)
		shadow.strokeWidth = 2
		shadow:setStrokeColor(227, 227, 227, 240)
		
		local text = display.newText( group, "Text Field", 0, 0, "Helvetica-Bold", 15)
		text:setTextColor(color.black)
		text.x = rect.x + text.width / 2 - text.width / 2
		text.y = rect.y
		
		rect.parent:insert(rect)
		
		return group
		
	else
		return base.native.newTextField( left, top, width, height, listener )
	end
	
end

--- Creates a simulator-safe text box.
-- @param left Left position of the object.
-- @param top Top position of the object.
-- @param width Width of the object.
-- @param height Height of the object.
-- @return The textfield object.
native.newTextBox = function( left, top, width, height )

	if system.isSimulator then	
		
		local group = display.newGroup()
	
		local rect = display.newRect(group, left, top, width, height )
		rect:setFillColor(colour.transparent)
		rect.strokeWidth = 2
		rect:setStrokeColor(colour.grey)
		
		local shadow = display.newRect(group, left + 2, top + 2, width - 3, height - 3 )
		shadow:setFillColor(color.white)
		shadow.strokeWidth = 2
		shadow:setStrokeColor(227, 227, 227, 240)
		
		local text = display.newText( group, "Text Box", 0, 0, "Helvetica-Bold", 15)
		text:setTextColor(color.black)
		text.x = rect.x + text.width / 2 - text.width / 2
		text.y = rect.y
		
		rect.parent:insert(rect)
		
		return group
		
	else
		return base.native.newTextBox( left, top, width, height )
	end
	
end

--- Dismisses the current web popup.
-- @return True if web pop-up was displaying prior to the call, false if not.
native.cancelWebPopup = function()

	if system.isSimulator then
		
		if rumWebPopup then
			rumWebPopup:removeSelf()
			rumWebPopup = nil
			
			return true
		end
		
		return false
		
	else
		return base.native.cancelWebPopup() 
	end
end

--- Creates a simulator-safe text box.
-- @param x Left position of the popup.
-- @param y Top position of the popup.
-- @param width Width of the popup.
-- @param height Height of the popup.
-- @param url Url for the popup
-- @param options Options table containing additional paramaters for the popup. Optional.
native.showWebPopup = function( x, y, width, height, url, options )
	
	if system.isSimulator then
		
		if type(x) == "string" then
			url = x
			x = 0
			y = 0
			width = display.contentWidth
			height = display.contentHeight
		end
		
		-- Force only one web view at a time.
		native.cancelWebPopup()
		
		rumWebPopup = display.newGroup()
		
		local rect = display.newRect( rumWebPopup, x, y, width, height )
		rect:setFillColor(colour.white)
		rect.strokeWidth = 1
		rect:setStrokeColor(colour.black)

		local text = display.newText( rumWebPopup, "Web Popup", 0, 0, "Helvetica-Bold", 15)
		text:setTextColor(colour.black)
		text.x = rect.x + text.width / 2 - text.width / 2
		text.y = rect.y
		
	else
	
		if type(x) == "string" then
			base.native.showWebPopup( x, options )
		else
			base.native.showWebPopup( x, y, width, height, url, options )
		end

	end
	
end

native.newMapView = function( left, top, width, height )
	
	local map = nil
	
	if system.isSimulator then
		
		map = display.newGroup()
		
		map.baseRemoveSelf = map.removeSelf
		
		local rect = display.newRect( map, left, top, width, height )
		rect:setFillColor(color.white)
		rect.strokeWidth = 1
		rect:setStrokeColor(colour.black)

		local text = display.newText( map, "Map View", 0, 0, "Helvetica-Bold", 15)
		text:setTextColor(colour.black)
		text.x = rect.x + text.width / 2 - text.width / 2
		text.y = rect.y
		
		local getMapImage = function( self, latitude, longitude, visible )
		
			if latitude and longitude then 
				
				local function networkListener( event )
					if ( event.isError ) then
						print ( "Network error - map download failed" )
					else	
						
						if self.image then
							self.image:removeSelf()
							self.image = nil
						end
						
						self.image = event.target
						self.parent:insert(self.image)
						event.target.x = ( left + self.width / 2 ) - 1
						event.target.y = ( top + self.height / 2 ) - 1
					end
				end
				 
				local server = "http://maps.google.com/maps/api/staticmap?"
				
				local url = server

				url = url .. "center=" .. latitude .. "," .. longitude
				
				if visible then
					
				
					local regionString = ""
						
					for i = 1, #visible, 1 do
						regionString = regionString .. visible[i][1] .. "," .. visible[i][2] .. string.encode("|")
					end
						
					url = url .. "&visible="  .. regionString
					
				else
					url = url .. "&zoom=" .. (self.zoom or 14)
				end
				
				url = url .. "&size=" .. self.width .. "x" .. self.height
				url = url .. "&format=png32"
				url = url .. "&maptype=" .. (self.mapType or "standard")
				url = url .. "&sensor=true"
				
				
				local mapFileName = os.time() .. ".png"
				
				if system.isAndroid then 
			
					local path = system.pathForFile( mapFileName, system.TemporaryDirectory )
					local imageFile = io.open( path, "w+b" ) 

					http.request{
						url = url, 
						sink = ltn12.sink.file( imageFile ),
					}
					
						if self.image then
							self.image:removeSelf()
							self.image = nil
						end
						
						self.image = display.newImage(self.parent, mapFileName, system.TemporaryDirectory, 0, 0 )
				
						self.image.x = ( left + self.width / 2 ) - 1
						self.image.y = ( top + self.height / 2 ) - 1
					
				else
					display.loadRemoteImage( url, "GET", networkListener, mapFileName, system.TemporaryDirectory, 0, 0)
				end
		
				self.center = { latitude = latitude, longitude = longitude }
							
			end
			
		end
				
		function map:getAddressLocation(address)
			
			if Json then
			
				local url = "http://maps.googleapis.com/maps/api/geocode/json?address=" .. string.encode(address) .. "&sensor=true"
				
				local response = {}

				local b, c, h = http.request {  
					url=url,
					sink = ltn12.sink.table( response )
				}
				
				if response then
			
					local data = Json.Decode(table.concat(response,''))
					
					
					if data then
					
						if data["results"] then
							
							if data["results"][1] then
					
								if data["results"][1].geometry then
								
								--	table.print(data["results"][1].geometry)
								
									if data["results"][1].geometry["location"] then
										
										local location = data["results"][1].geometry["location"]
										
										return location["lat"], location["lng"]	
							
									end
								end
								
							end
						end
					
					end
					
				end
				
			else
				return 51.50015, -0.12624 -- OXFORD BABY!
			end
		
		end
		
		function map:getUserLocation()

			local location = {}

			location.latitude = 37.448485
			location.longitude = -122.158911
			location.altitude = 0
			location.accuracy = 50
			location.time = os.time()
			location.speed = -1
			location.direction = -1
			location.isUpdating = false
			
			return location
			
		end		
		
		function map:setRegion( latitude, longitude, latitudeSpan, longitudeSpan, isAnimated )
					
			if latitude and longitude and latitudeSpan and longitudeSpan then
				
				local visible = {}
				
				visible[1] = { latitude - ( latitudeSpan / 2 ), longitude - ( longitudeSpan / 2 ) }
				visible[2] = { latitude + ( latitudeSpan / 2 ), longitude + ( longitudeSpan / 2 ) }
				
				getMapImage( self, latitude, longitude, visible )		
			end
			
		end		
		
		function map:setCenter( latitude, longitude, isAnimated )					
			getMapImage( self, latitude, longitude )		
		end		
		
		function map:addMarker( latitude, longitude )
			print("map:addMarker() is currently unsupported by Rum. Sorry :-(")
		end	
		
		function map:removeAllMarkers()
			print("map:removeAllMarkers() is currently unsupported by Rum. Sorry :-(")
		end					
		
		function map:nearestAddress( latitude, longitude )
			
			if latitude and longitude then
				if Json then
				
					local url = "http://maps.googleapis.com/maps/api/geocode/json?latlng=" .. latitude .. "," .. longitude .. "&sensor=true"
					
					local response = {}
	
					local b, c, h = http.request {  
						url=url,
						sink = ltn12.sink.table( response )
					}
					
					if response then
				
						local data = Json.Decode(table.concat(response,''))
						
						if data then
						
							if data["results"] then
								if data["results"][1] then
								
									local address = {}
									
									for i = 1, #data["results"][1]["address_components"], 1 do
										
										local item = data["results"][1]["address_components"][i]
								
										local detail = item["long_name"]
										
										if item.types[1] == "street_number" then
											address.streetDetail = detail
										elseif item.types[1] == "route" then
											address.street = detail
										elseif item.types[1] == "locality" then
											address.city = detail
										elseif item.types[1] == "administrative_area_level_3" then
										
										elseif item.types[1] == "administrative_area_level_2" then
										
										elseif item.types[1] == "administrative_area_level_1" then
											address.region = detail
										elseif item.types[1] == "country" then
											address.country = detail
										elseif item.types[1] == "postal_code" or item.types[1] == "postal_code_prefix" then
											address.postalCode = detail
										end
									end
									
									local event = { name = "mapAddress" } 
											
									for key, value in pairs(address) do
										event[key] = value
									end
									
									Runtime:dispatchEvent(event)
									
									event.target = self
									self:dispatchEvent(event)
								end
							end
						
						end
					end
				end
			end				
		
		end			
		
		function map:removeSelf()
			
			if self.image then
			
				if self.image["removeSelf"] then
					self.image:removeSelf()
				end
				
				self.image = nil
			end
			
			self:baseRemoveSelf()
		end
		
	else
		map = base.native.newMapView( left, top, width, height )
	end
	
	return addGenericObjectHelperMethods( map )
	
end

--- Shows / hides the native activity indicator.
-- @param visible True to show, false to hide.
-- @param listener Optional listener function to call when the indicator is shown.
native.setActivityIndicator = function( visible, listener )

	if visible then
		
		base.native.setActivityIndicator( true )
		
		if listener and type(listener) == "function" then
			timer.performWithDelay(1, listener, 1 )
		end
		
	else
		base.native.setActivityIndicator( false )
	end
end

if sprite then

	sprite.add = function( spriteSet, sequenceName, startFrame, frameCount, time, loopParam )
	
		local usingRetinaSource = false
		
		if type( spriteSet ) == "table" then
			usingRetinaSource = spriteSet.isRetina
			spriteSet = spriteSet.set
		end
		
		return base.sprite.addSprite( spriteSet, sequenceName, startFrame, frameCount, time, loopParam )
	end
	
	local getRetinaFilename = function( filename, baseDirectory )
		
		local usingRetinaSource = false
		
		if display.contentScaleX == 0.5 then 
			
			local splitFilename = {}
			local pattern = string.format("([^%s]+)", ".")
			filename:gsub(pattern, function(c) splitFilename[#splitFilename+1] = c end)
			
			if #splitFilename == 2 then
				splitFilename[1] = splitFilename[1] .. "@2x"
			end
			
			local newFilename = table.concat(splitFilename, ".")
			
			local baseDir = ResourceDirectory
			
			if baseDirectory and type( baseDirectory ) == "userdata" then
				baseDir = baseDirectory
			end
		
			local path = pathForFile( newFilename, baseDir )
			
			if path then
				filename = newFilename
				usingRetinaSource = true
			end

		end
		
		return filename, usingRetinaSource
		
	end
	
	sprite.newSpriteSheet = function( spriteSheetFile, baseDirectory, frameWidth, frameHeight )
			
		local usingRetinaSource = false
			
		if display.contentScaleX == 0.5 then
			
			spriteSheetFile, usingRetinaSource = getRetinaFilename( spriteSheetFile, baseDirectory )
			
			if usingRetinaSource then
				
				if type(baseDirectory) == "userdata" then
					frameWidth = frameWidth * 2
					frameHeight = frameHeight * 2
				elseif type(baseDirectory) == "number" then
					baseDirectory = baseDirectory * 2
					frameWidth = frameWidth * 2
				end
			end
			
		end
		
		local spriteSheet = base.sprite.newSpriteSheet( spriteSheetFile, baseDirectory, frameWidth, frameHeight )
	
		if usingRetinaSource then
			return { sheet = spriteSheet, isRetina = true }
		else
			return spriteSheet
		end
		
	end
	
	sprite.newSpriteSet = function( spriteSheet, startFrame, frameCount )
		
		local usingRetinaSource = false
		
		if type( spriteSheet ) == "table" then
			usingRetinaSource = spriteSheet.isRetina
			spriteSheet = spriteSheet.sheet
		end
		
		local spriteSet = base.sprite.newSpriteSet( spriteSheet, startFrame, frameCount )
		
		if usingRetinaSource then
			return { set = spriteSet, isRetina = true }
		else
			return spriteSet
		end
	
	end

--[[
	sprite.newSpriteSheetFromData = function( spriteSheetImageFile, baseDirectory, coordinateData )
		
		local usingRetinaSource = false
		
		spriteSheetImageFile, usingRetinaSource = getRetinaFilename( spriteSheetImageFile, baseDirectory )
		
		if type( baseDirectory ) == "table" then
			coordinateData = baseDirectory
		end
		
		local spriteSheet = base.sprite.newSpriteSheetFromData( spriteSheetImageFile, baseDirectory, coordinateData )
		
		if usingRetinaSource then
			return { sheet = spriteSheet, isRetina = true }
		else
			return spriteSheet
		end
		
	end
--]]

	sprite.newSprite = function( spriteSet )
		
		local usingRetinaSource = false
		
		if type( spriteSet ) == "table" then
			usingRetinaSource = spriteSet.isRetina
			spriteSet = spriteSet.set
		end
	
		local newInstance = addGenericObjectHelperMethods( base.sprite.newSprite( spriteSet ) )
	
		if display.contentScaleX == 0.5 and usingRetinaSource then
			newInstance.xScale = 0.5
			newInstance.yScale = 0.5
		end
	
		return newInstance
	end

end

if ui then

	ui.newButton = function( params )
	
		local button = addGenericObjectHelperMethods( base.ui.newButton( params ) )
	
		local textItems = {}
		
		if button.text then textItems[#textItems + 1] = button.text end
		if button.shadow then textItems[#textItems + 1] = button.shadow end
		if button.highlight then textItems[#textItems + 1] = button.highlight end
		
		for i = 1, #textItems, 1 do
			textItems[i].xScale = display.contentScaleX
			textItems[i].yScale = display.contentScaleY
		end
		
		return button
	end
	
	ui.newLabel = function( params )
		
		local label = addGenericObjectHelperMethods( base.ui.newLabel( params ) )
		
		label = addTextObjectHelperMethods( label )
		
		return label
		
	end
	
end

if openfeint then

	openfeint.init = function( ... )
	
		if system.isSimulator or system.isAndroid then
			print("OpenFeint is not currently supported in the Simulator or on Android Devices.")
		else
			base.openfeint.init( ... )
		end
		
	end
	
	openfeint.launchDashboard = function( ... )
	
		if system.isSimulator or system.isAndroid then
			print("OpenFeint is not currently supported in the Simulator or on Android Devices.")
		else
			base.openfeint.launchDashboard( ... )
		end
		
	end
	
	openfeint.setHighScore = function( ... )
	
		if system.isSimulator or system.isAndroid then
			print("OpenFeint is not currently supported in the Simulator or on Android Devices.")
		else
			base.openfeint.setHighScore( ... )
		end
		
	end
	
	openfeint.unlockAchievement = function( ... )
	
		if system.isSimulator or system.isAndroid then
			print("OpenFeint is not currently supported in the Simulator or on Android Devices.")
		else
			base.openfeint.unlockAchievement( ... )
		end
		
	end
	
	openfeint.uploadBlob = function( ... )
	
		if system.isSimulator or system.isAndroid then
			print("OpenFeint is not currently supported in the Simulator or on Android Devices.")
		else
			base.openfeint.uploadBlob( ... )
		end
		
	end	
	
	openfeint.downloadBlob = function( ... )
	
		if system.isSimulator or system.isAndroid then
			print("OpenFeint is not currently supported in the Simulator or on Android Devices.")
		else
			base.openfeint.downloadBlob( ... )
		end
		
	end		
end