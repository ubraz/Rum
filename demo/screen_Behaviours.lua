module(..., package.seeall)

local behaviourLibrary = require("behaviourLibrary")

local ui = require("ui")

function new()

	local self = display.newGroup()
		
	self.behaviours = {}

	--------------------------------
	------------- BACK -------------
	--------------------------------
	self.back = display.newRect(self, 0, 0, display.contentWidth, display.contentHeight)
	self.back:setFillColor(colour.lightgrey)

	--------------------------------
	------------- TITLE ------------
	--------------------------------
	self.title = display.newText(self, "Tap a fish to select / deselect it", 0, 0, "Helvetica-Bold", 20)
	self.title.x = display.contentCenterX
	self.title.y = self.title.contentHeight
	self.title:setTextColor("#000000")
	
	--------------------------------
	------------ FISHIES  ----------
	--------------------------------
	local selectFish = function( fish )
		fish.isSelected = true
		
		self.selectedFish = fish
		
		for i = 1, #self.behaviours, 1 do
			
			local behaviour = self.behaviours[i]
			
			behaviour.removeButton.isVisible = fish:hasBehaviour( behaviour.callback )
			behaviour.addButton.isVisible = not behaviour.removeButton.isVisible
		end
		
		transition.to( fish, { time = 100, xScale = 1, yScale = 1 } )
	end
	
	local deselectFish = function( fish )
		fish.isSelected = false
		
		transition.to( fish, { time = 100, xScale = 0.7, yScale = 0.7 } )
	end
	
	local onFishTap = function( event )
		
		local fish = event.target
		local otherFish = fish.otherFish
		
		if fish.isSelected then
			deselectFish( fish )
			selectFish( self.blueFish )
		else
			deselectFish( otherFish )
			selectFish( fish )	
		end
		
	end
	
	self.redFish = display.newImage(self, "images/fish.small.red.png")
	self.redFish.x = display.contentCenterX - ( display.contentWidth / 4)
	self.redFish.y = self.redFish.height * 2
	self.redFish.xScale = 0.7
	self.redFish.yScale = 0.7
	self.redFish:addEventListener("tap", onFishTap)
	
	self.blueFish = display.newImage(self, "images/fish.small.blue.png")
	self.blueFish.x = display.contentCenterX + ( display.contentWidth / 4)
	self.blueFish.y = self.blueFish.height * 2	
	self.blueFish.xScale = 0.7
	self.blueFish.yScale = 0.7
	self.blueFish:addEventListener("tap", onFishTap)
	
	self.redFish.otherFish = self.blueFish
	self.blueFish.otherFish = self.redFish
	
	--------------------------------
	----------- BEHAVIOURS ---------
	--------------------------------	
	
	self.behaviours[#self.behaviours+1] = { name = "Move", description = "Moves the object every frame.", callback = behaviourLibrary.move }
	self.behaviours[#self.behaviours+1] = { name = "Wrap", description = "Wraps the object around the screen edges..", callback = behaviourLibrary.wrap }
	self.behaviours[#self.behaviours+1] = { name = "Bounce", description = "Bounces the object off the screen edges.", callback = behaviourLibrary.bounce }
	self.behaviours[#self.behaviours+1] = { name = "Rotate", description = "Rotates the object 1 degree every frame.", callback = behaviourLibrary.rotate }
	self.behaviours[#self.behaviours+1] = { name = "Teleport", description = "Randomly teleports around the screen.", callback = behaviourLibrary.teleport }
	
	for i = 1, #self.behaviours, 1 do
		
		local behaviour = self.behaviours[i]
		local previousBehaviour = self.behaviours[i-1]
		
		behaviour.nameTextObject = display.newText(self, behaviour.name, 0, 0, "Helvetica-Bold", 16)
		behaviour.nameTextObject.x = math.floor( behaviour.nameTextObject.contentWidth * 0.5 ) + 20
		behaviour.nameTextObject.y = ( previousBehaviour and previousBehaviour.nameTextObject.y + behaviour.nameTextObject.contentHeight * 2 ) or 150 
		behaviour.nameTextObject:setTextColor{ 0, 0, 0}
		
		behaviour.descriptionTextObject = display.newText(self, behaviour.description, 0, 0, "Helvetica", 12)
		behaviour.descriptionTextObject.x = math.floor( behaviour.descriptionTextObject.contentWidth * 0.5 ) + 20
		behaviour.descriptionTextObject.y = behaviour.nameTextObject.y + behaviour.descriptionTextObject.contentHeight
		behaviour.descriptionTextObject:setTextColor("#414141")
		
		behaviour.addButton = ui.newButton
		{
			default = "images/add-green.png",
			over = "images/add-green.png",
			onRelease = function() 
							if self.selectedFish then
								self.selectedFish:addBehaviour( behaviour.callback )
								behaviour.addButton.isVisible = false
								behaviour.removeButton.isVisible = true
							end
						end
		}
		
		behaviour.addButton.x = display.contentWidth - behaviour.addButton.width
		behaviour.addButton.y = behaviour.nameTextObject.y + behaviour.addButton.height * 0.3
		self:insert(behaviour.addButton)		
		

		behaviour.removeButton = ui.newButton
		{
			default = "images/remove-red.png",
			over = "images/remove-red.png",
			onRelease = function() 
			
							if self.selectedFish then
								self.selectedFish:removeBehaviour( behaviour.callback )
								behaviour.addButton.isVisible = true
								behaviour.removeButton.isVisible = false
							end
							
						end
		}
		
		behaviour.removeButton.x = behaviour.addButton.x
		behaviour.removeButton.y = behaviour.addButton.y
		behaviour.removeButton.isVisible = false
		self:insert(behaviour.removeButton)				
		
	end		
	
	--------------------------------
	---------- BACK BUTTON ---------
	--------------------------------	
	local onBackRelease = function( event )
	
		-- IMPORTANT! You must remember to call destroy on any objects that have Behaviours before removing them!
		self.redFish:destroy(true)
		self.blueFish:destroy(true)
		
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

	self.redFish:toFront()
	self.blueFish:toFront()

	return self

end