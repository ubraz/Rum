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
	------------ COLOURS -----------
	--------------------------------
	self.coloursTitle = display.newText(self, "Colours", 0, 0, "Helvetica-Bold", 18)
	self.coloursTitle.x = display.contentCenterX
	self.coloursTitle.y = 20
	self.coloursTitle:setTextColor("black")
		
	local onColourButtonRelease = function( event )
		self.coloursTitle:setTextColor(event.target.colour)
	end
	
	self.colourButtons = {}
	
	self.colourButtons[1] = ui.newButton
	{
		default = "images/buttonSmall.png",
		over = "images/buttonSmall_Over.png",
		onRelease = onColourButtonRelease,
		text = "red",
		emboss = true,
		textColor = { 0, 0, 0, 255 }
	}
	
	self.colourButtons[1].x = self.colourButtons[1].width / 2 + 10
	self.colourButtons[1].y = self.colourButtons[1].height * 1.5 - 20
	self.colourButtons[1].colour = "red"
	self:insert(self.colourButtons[1])
	
	self.colourButtons[2] = ui.newButton
	{
		default = "images/buttonSmall.png",
		over = "images/buttonSmall_Over.png",
		onRelease = onColourButtonRelease,
		text = "color.lime",
		emboss = true,
		textColor = { 0, 0, 0, 255 }
	}
	
	self.colourButtons[2].x = self.colourButtons[1].x + self.colourButtons[1].width 
	self.colourButtons[2].y = self.colourButtons[1].y
	self.colourButtons[2].colour = colour.green
	self:insert(self.colourButtons[2])	

	self.colourButtons[3] = ui.newButton
	{
		default = "images/buttonSmall.png",
		over = "images/buttonSmall_Over.png",
		onRelease = onColourButtonRelease,
		text = "{0, 0, 255}",
		emboss = true,
		textColor = { 0, 0, 0, 255 }
	}
	
	self.colourButtons[3].x = self.colourButtons[1].x
	self.colourButtons[3].y = self.colourButtons[1].y + self.colourButtons[1].height
	self.colourButtons[3].colour = { 0, 0, 255 }
	self:insert(self.colourButtons[3])	
	
	self.colourButtons[4] = ui.newButton
	{
		default = "images/buttonSmall.png",
		over = "images/buttonSmall_Over.png",
		onRelease = onColourButtonRelease,
		text = "#FF0AC2",
		emboss = true,
		textColor = { 0, 0, 0, 255 }
	}
	
	self.colourButtons[4].x = self.colourButtons[2].x
	self.colourButtons[4].y = self.colourButtons[3].y
	self.colourButtons[4].colour = "#FF0AC2"
	self:insert(self.colourButtons[4])	
	
	--------------------------------
	---------- DATA SAVING ---------
	--------------------------------
	self.dataSavingTitle = display.newText(self, "Data Saving", 0, 0, "Helvetica-Bold", 18)
	self.dataSavingTitle.x = display.contentCenterX
	self.dataSavingTitle.y = 170
	self.dataSavingTitle:setTextColor(color.black)
	

	---------- GLOBAL ----------
	self.dataSavingGlobalTitle = display.newText(self, "Global: Saved for when the app is running", 0, 0, "Helvetica", 14)
	self.dataSavingGlobalTitle.x = display.contentCenterX
	self.dataSavingGlobalTitle.y = self.dataSavingTitle.y + self.dataSavingGlobalTitle.contentHeight + 10
	self.dataSavingGlobalTitle:setTextColor(color.black)
	
	-- Load up the pre-existing score variable or 0 if one hasn't already been saved
	local score = loadVariable("score") or 0
	
	local onIncreaseScoreButtonRelease = function( event )
		
		-- Increase the score
		score = score + 1
		
		-- Save the variable back out
		saveVariable("score", score)
		
		-- Update the text
		self.dataSavingScoreText.text = "Score: " .. score
	end

	local onDecreaseScoreButtonRelease = function( event )
		
		-- Decrease the score
		score = score - 1
		
		-- Save the variable back out
		saveVariable("score", score)
		
		-- Update the text
		self.dataSavingScoreText.text = "Score: " .. score
	end

	
	self.dataSavingScoreText = display.newText(self, "Score: " .. score, 0, 0, "Helvetica-Bold", 14)
	self.dataSavingScoreText.x = display.contentCenterX 
	self.dataSavingScoreText.y = self.dataSavingGlobalTitle.y + self.dataSavingScoreText.contentHeight * 1.1
	self.dataSavingScoreText:setTextColor(color.black)
	
	self.minusButton = ui.newButton
	{
		default = "images/remove-red.png",
		over = "images/remove-red.png",
		onRelease = onDecreaseScoreButtonRelease
	}
	
	self.minusButton.x = self.dataSavingTitle.x - self.dataSavingTitle.contentWidth / 2
	self.minusButton.y = self.dataSavingScoreText.y
	self:insert(self.minusButton)	
	
	self.plusButton = ui.newButton
	{
		default = "images/add-green.png",
		over = "images/add-green.png",
		onRelease = onIncreaseScoreButtonRelease
	}
	
	self.plusButton.x = self.dataSavingScoreText.x + self.dataSavingScoreText.contentWidth / 2 + self.plusButton.width
	self.plusButton.y = self.minusButton.y 
	self:insert(self.plusButton)	
	

	---------- FILE ----------
	
	local difficulties = { "Easy", "Medium", "Hard", "Extreme" }
	-- Load up the pre-existing difficulty variable or 1 if one hasn't already been saved
	local difficulty = load("difficulty.txt") or 1

	-- If we have loaded up the difficulty variable then it is a table, so get the first element
	if type(difficulty) == "table" then
		difficulty = difficulty[1]
	end
	
	self.dataSavingFileTitle = display.newText(self, "File: Saved for when the app is restarted", 0, 0, "Helvetica", 14)
	self.dataSavingFileTitle.x = display.contentCenterX
	self.dataSavingFileTitle.y = self.plusButton.y + self.plusButton.height
	self.dataSavingFileTitle:setTextColor(color.black)
	
	self.dataSavingDifficultyText = display.newText(self, "Difficulty: " .. difficulties[difficulty], 0, 0, "Helvetica-Bold", 14)
	self.dataSavingDifficultyText.x = display.contentCenterX 
	self.dataSavingDifficultyText.y = self.dataSavingFileTitle.y + self.dataSavingDifficultyText.contentHeight * 1.1
	self.dataSavingDifficultyText:setTextColor(color.black)
	
	local onIncreaseDifficultyButtonRelease = function( event )
		
		-- Increase the difficulty
		difficulty = difficulty + 1
				
		-- Cap the difficulty		
		if difficulty > #difficulties then
			difficulty = #difficulties
		end
		
		-- Save the variable back out, adding the squiggly brackets creates a single element table
		save( { difficulty } , "difficulty.txt")
		
		-- Update the text
		self.dataSavingDifficultyText.text = "Difficulty: " .. difficulties[difficulty]
	end

	local onDecreaseDifficultyButtonRelease = function( event )
		
		-- Decrease the difficulty
		difficulty = difficulty - 1
		
		-- Cap the difficulty
		if difficulty < 1 then
			difficulty = 1
		end
		
		-- Save the variable back out, adding the squiggly brackets creates a single element table
		save( { difficulty } , "difficulty.txt")
		
		-- Update the text
		self.dataSavingDifficultyText.text = "Difficulty: " .. difficulties[difficulty]
	end
	
	self.previousButton = ui.newButton
	{
		default = "images/arrow-button.png",
		over = "images/arrow-button-over.png",
		onRelease = onDecreaseDifficultyButtonRelease
	}
	
	self.previousButton.xScale = -1
	self.previousButton.x = self.minusButton.x - self.previousButton.width 
	self.previousButton.y = self.dataSavingDifficultyText.y
	self:insert(self.previousButton)	
	
	self.nextButton = ui.newButton
	{
		default = "images/arrow-button.png",
		over = "images/arrow-button-over.png",
		onRelease = onIncreaseDifficultyButtonRelease
	}
	
	self.nextButton.x = self.plusButton.x + self.nextButton.width
	self.nextButton.y = self.previousButton.y 
	self:insert(self.nextButton)	
	
	--------------------------------
	-------- OBJECT HELPERS --------
	--------------------------------
	self.objectHelpersTitle = display.newText(self, "Object Helpers", 0, 0, "Helvetica-Bold", 18)
	self.objectHelpersTitle.x = display.contentCenterX
	self.objectHelpersTitle.y = 300
	self.objectHelpersTitle:setTextColor(color.black)
	
	self.objectHelpersDescription = display.newText(self, "Touch somewhere to see distance and angle.", 0, 0, "Helvetica", 14)
	self.objectHelpersDescription.x = display.contentCenterX
	self.objectHelpersDescription.y = self.objectHelpersTitle.y + self.objectHelpersDescription.contentHeight
	self.objectHelpersDescription:setTextColor(color.grey)
	
	self.angleText = display.newText(self, "Angle: ", 0, 0, "Helvetica", 12)
	self.angleText.x = display.contentCenterX - self.angleText.contentWidth * 2
	self.angleText.y = self.objectHelpersDescription.y + self.angleText.contentHeight
	self.angleText:setTextColor(color.grey)

	self.distanceText = display.newText(self, "Distance: ", 0, 0, "Helvetica", 12)
	self.distanceText.x = display.contentCenterX + self.distanceText.width * 2
	self.distanceText.y = self.objectHelpersDescription.y + self.distanceText.contentHeight
	self.distanceText:setTextColor(color.grey)
	
	self.arrow = display.newImage(self, "images/arrow.png")
	self.arrow.x = display.contentCenterX
	self.arrow.y = self.objectHelpersDescription.y + self.arrow.height
	
	local onTouch = function( event )
		
		self.arrow:rotateTo( event )
	
		self.angleText.text = "Angle: " .. math.floor(self.arrow.rotation)
		self.angleText.x = math.floor( self.angleText.contentWidth / 2 ) + 40
		
		self.distanceText.text = "Distance: " .. math.floor( self.arrow:getDistanceTo(event) )
		self.distanceText.x = math.floor( self.distanceText.contentWidth / 2 ) + 200
	end
	
	Runtime:addEventListener("touch", onTouch)
	
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
		
	function clean()
		Runtime:removeEventListener("touch", onTouch)
	end
	
	return self

end