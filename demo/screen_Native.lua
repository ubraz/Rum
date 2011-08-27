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
	---------- TEXT FIELD ----------
	--------------------------------	
	self.textField = native.newTextField(20, 20, 280, 36)
	self:insert(self.textField)
	
	--------------------------------
	----------- TEXT BOX -----------
	--------------------------------	
	self.textBox = native.newTextBox(20, 70, 280, 120)
	self:insert(self.textBox)
	
	local onTouchTap = function( event )
		native.setKeyboardFocus( nil )
	end
	
	Runtime:addEventListener( "touch", onTouchTap )
	Runtime:addEventListener( "tap", onTouchTap )
	
	--------------------------------
	----------- MAP VIEW -----------
	--------------------------------	
	self.mapView = native.newMapView( 20, 210, 280, 100 )
	self.mapView.isZoomEnabled = true
	self.mapView.isScrollEnabled = true
	self.mapView.isLocationUpdating = true
	self:insert(self.mapView)
	
	local latitude, longitude = self.mapView:getAddressLocation( "oxford, uk" )
	self.mapView:setCenter( latitude, longitude, true )
	
	--------------------------------
	----------- WEB POPUP ----------
	--------------------------------		
	native.showWebPopup( 20, 330, 280, 80, "http://www.google.com", nil )

	--------------------------------
	---------- BACK BUTTON ---------
	--------------------------------	
	local onBackRelease = function( event )
		native.cancelWebPopup()
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
		
	--------------------------------
	------------ CLEAN UP ----------
	--------------------------------	
	function clean()
		Runtime:removeEventListener( "touch", onTouchTap )
		Runtime:removeEventListener( "tap", onTouchTap )
	end
	
	native.setActivityIndicator( false )
	

	
	return self

end