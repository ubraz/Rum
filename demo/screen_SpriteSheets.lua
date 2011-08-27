module(..., package.seeall)

local ui = require("ui")

function new()

	local self = display.newGroup()
		
	--------------------------------
	------------- BACK -------------
	--------------------------------
	self.back = display.newRect(self, 0, 0, display.contentWidth, display.contentHeight)
	self.back:setFillColor(colour.lightgrey)

	local sheet = sprite.newSpriteSheet( "images/tileset.png", 50, 85)
	
	local terrainSet = sprite.newSpriteSet(sheet, 1, 5)
	local itemSet = sprite.newSpriteSet(sheet, 6, 10)
	
	local terrain = {}
	local items = {}
	
	for i = 1, 5, 1 do
		terrain[i] = sprite.newSprite( terrainSet )
		terrain[i].currentFrame = math.random(1, 5)
		
		terrain[i].x = terrain[i].contentWidth * i
		terrain[i].y = 250
		
		self:insert(terrain[i])
		
		items[i] = sprite.newSprite( itemSet )
		items[i].currentFrame = math.random(1, 10)
		
		items[i].x = terrain[i].x
		items[i].y = terrain[i].y - terrain[i].contentHeight / 3
		
		self:insert(items[i])
	end

	--------------------------------
	---------- BACK BUTTON ---------
	--------------------------------	
	local onBackRelease = function( event )
		director:changeScene("screen_Main", "moveFromLeft")
	end
	
	self.backButton = ui.newButton
	{
		default = "images/buttonNav.png",
		over = "images/buttonNav_Over.png",
		onRelease = onBackRelease,
		text = "Back",
		emboss = true,
		textColor = { 0, 0, 0, 255 }
	}
	
	self.backButton.x = display.contentCenterX
	self.backButton.y = display.contentHeight - self.backButton.height / 2
	self:insert(self.backButton)
		
	return self

end