require("rum")

vector1 = math.Vector:new(10, 10)
vector2 = math.Vector:new(5, 5)

director = require("director")

local group = display.newGroup()

display.setStatusBar( display.HiddenStatusBar ) 

local back = display.newRect(group, 0, 0, display.contentWidth, display.contentHeight)
back:setFillColor(0, 200, 0, 255)


local mainGroup = display.newGroup()
mainGroup:insert(director.directorView)	
director:changeScene("screen_Main")