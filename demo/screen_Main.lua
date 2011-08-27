module(..., package.seeall)

local ui = require("ui")

function new()

	local self = display.newGroup()
	
	--------------------------------
	------------- BACK -------------
	--------------------------------	
	self.back = display.newRect(self, 0, 0, display.contentWidth, display.contentHeight)
	self.back:setFillColor(colour.lightgrey)

	--------------------------------
	------------- TITLE ------------
	--------------------------------
	self.title = display.newText(self, "Rum Demo", 0, 0, "Helvetica-Bold", 24)
	self.title.x = display.contentCenterX
	self.title.y = self.title.contentHeight
	self.title:setTextColor("black")
	
	--------------------------------
	--------- NATIVE BUTTON --------
	--------------------------------	
	local onNativeButtonRelease = function( event )		
		director:changeScene("screen_Native", "moveFromRight")
	--	native.setActivityIndicator( true, function() director:changeScene("screen_Native", "moveFromRight") end )
	end
	
	self.nativeButton = ui.newButton
	{
		default = "images/buttonNav.png",
		over = "images/buttonNav_Over.png",
		onRelease = onNativeButtonRelease,
		text = "Native",
		emboss = true,
		textColor = { 0, 0, 0, 255 }
	}
	
	self.nativeButton.x = display.contentCenterX
	self.nativeButton.y = 100
	self:insert(self.nativeButton)

	--------------------------------
	------ BEHAVIOURS BUTTON -------
	--------------------------------	
	local onBehaviourButtonRelease = function( event )
		director:changeScene("screen_Behaviours", "moveFromRight")
	end
	
	self.behaviourButton = ui.newButton
	{
		default = "images/buttonNav.png",
		over = "images/buttonNav_Over.png",
		onRelease = onBehaviourButtonRelease,
		text = "Behaviours",
		emboss = true,
		textColor = { 0, 0, 0, 255 }
	}
	
	self.behaviourButton.x = display.contentCenterX
	self.behaviourButton.y = 160
	self:insert(self.behaviourButton)

	--------------------------------
	----- SPRITE SHEETS BUTTON -----
	--------------------------------	
	local onSpriteSheetsButtonRelease = function( event )
		director:changeScene("screen_SpriteSheets", "moveFromRight")
	end
	
	self.spriteSheetsButton = ui.newButton
	{
		default = "images/buttonNav.png",
		over = "images/buttonNav_Over.png",
		onRelease = onSpriteSheetsButtonRelease,
		text = "Sprite Sheets",
		emboss = true,
		textColor = { 0, 0, 0, 255 }
	}
	
	self.spriteSheetsButton.x = display.contentCenterX
	self.spriteSheetsButton.y = 220
	self:insert(self.spriteSheetsButton)
	
	--------------------------------
	----------- MAP BUTTON ---------
	--------------------------------	
	local onMapButtonRelease = function( event )
		director:changeScene("screen_Map", "moveFromRight")
	end
	
	self.mapButton = ui.newButton
	{
		default = "images/buttonNav.png",
		over = "images/buttonNav_Over.png",
		onRelease = onMapButtonRelease,
		text = "Maps",
		emboss = true,
		textColor = { 0, 0, 0, 255 }
	}
	
	self.mapButton.x = display.contentCenterX
	self.mapButton.y = 280
	self:insert(self.mapButton)
	
	--------------------------------
	---------- MISC BUTTON ---------
	--------------------------------	
	local onMiscButtonRelease = function( event )
		director:changeScene("screen_Misc", "moveFromRight")
	end
	
	self.miscButton = ui.newButton
	{
		default = "images/buttonNav.png",
		over = "images/buttonNav_Over.png",
		onRelease = onMiscButtonRelease,
		text = "Misc",
		emboss = true,
		textColor = { 0, 0, 0, 255 }
	}
	
	self.miscButton.x = display.contentCenterX
	self.miscButton.y = 340
	self:insert(self.miscButton)	

	return self
	
end