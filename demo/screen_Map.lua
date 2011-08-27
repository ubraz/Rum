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
	----------- MAP VIEW -----------
	--------------------------------	
	self.mapView = native.newMapView( 20, 20, 280, 200 )
	self.mapView.isZoomEnabled = true
	self.mapView.isScrollEnabled = true
	self.mapView.isLocationUpdating = true
	self:insert(self.mapView)
	
	--------------------------------
	------- LOCATION BUTTONS -------
	--------------------------------	
	self.locationButtons = {}
	
	local onLocationRelease = function( event )
		local latitude, longitude = self.mapView:getAddressLocation( event.target.location )
		self.mapView:setCenter( latitude, longitude, true )
	end
	
	local createLocationButton = function( location )
		
		local index = #self.locationButtons + 1
		
		self.locationButtons[index] = ui.newButton
		{
			default = "images/buttonNav.png",
			over = "images/buttonNav_Over.png",
			onRelease = onLocationRelease,
			text = location,
			emboss = true,
			textColor = { 0, 0, 0, 255 }
		}
		self.locationButtons[index].location = location
		
		self.locationButtons[index].x = display.contentCenterX
		
		local yPos = 260
		
		if #self.locationButtons > 1 then
			yPos = self.locationButtons[index - 1].y + self.locationButtons[index].height
		end
		
		self.locationButtons[index].y = yPos
		
		self:insert( self.locationButtons[index] )
	end

	createLocationButton( "London" )
	createLocationButton( "Paris" )
	createLocationButton( "40.7143528, -74.0059731" )
		
	self.distanceText = display.newText(self, "", 0, 0, "Helvetica", 14)
	self.distanceText:setTextColour("black")
	self.distanceText.y = self.locationButtons[#self.locationButtons].y + self.locationButtons[#self.locationButtons].height / 2 + self.distanceText.contentHeight / 2
		
	local lat1, lon1 = self.mapView:getAddressLocation( "London" )
	local lat2, lon2 = self.mapView:getAddressLocation( "Paris" )
	
	pos1 = { latitude = lat1, longitude = lon1 }
	pos2 = { latitude = lat2, longitude = lon2 }

	local distance = math.gpsDistanceBetween(pos1, pos2)
	self.distanceText.text = "Distance from London to Paris: " .. math.floor( distance ) .. "km"
	self.distanceText.x = display.contentCenterX --math.floor( self.distanceText.contentWidth / 2 ) + 10
		
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