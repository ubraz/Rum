-- Project: Rum
--
-- Date: 28-Feb-2011
--
-- Version: 0.1
--
-- File name: behaviourLibrary.lua
--
-- Author: Graham Ranson 
--
-- Support: www.monkeydeadstudios.com
--
-- Copyright (C) 2011 MonkeyDead Studios Limited. No Rights Reserved.

----------------------------------------------------------------------------------------------------
----										DESCRIPTION											----
----------------------------------------------------------------------------------------------------
----																							----
----	A 'Behaviour' is simply a function that takes a single argument, that being	the 		---- 
----	display object that the behaviour is being performed on.								----
----																							----
----	Behaviours are called once every frame and can be used for reusable functions across	----
----	objects i.e. followPlayer, pulsate, shootAtObject etc									----
----																							----
----	In this file are some examples of possible Behaviours, they are provided as-is and		----
----	aren't necessarily meant to be perfect examples so please take them with a pinch of		----
----	salt.																					----
----																							----																						----
----	If you have any suggestions for Behaviours that you have created yourself which you		----
----	wish to be included here for the benefit of the community please contact me at			----
----	graham.ranson@monkeydead.com and I will only be too happy to add them in.				----
----																							----
----------------------------------------------------------------------------------------------------

module(..., package.seeall)

--- Moves a display object based on its velocity.
-- @param object The display object that the behaviour is acting on.
move = function( object )
	if not object.velocity then
		object.velocity = { x = 5, y = 5 }
	end
	
	object:move( object.velocity.x, object.velocity.y )
	
end

--- Wraps a display object's position to keep it within screen bounds.
-- @param object The display object that the behaviour is acting on.
wrap = function( object )
		
	if object.x + ( object.width * 0.5 ) < 0 then
		object.x = display.contentWidth - ( object.width * 0.5 )
	elseif object.x - ( object.width * 0.5 ) > display.contentWidth then
		object.x = -object.width * 0.5
	elseif object.y + ( object.height * 0.5 ) < 0 then
		object.y = display.contentHeight - ( object.height * 0.5 )
	elseif object.y - ( object.height * 0.5 ) > display.contentHeight then
		object.y = -object.height * 0.5
	end
	
end

--- Causes a display object to bounce off the screen edges.
-- @param object The display object that the behaviour is acting on.
bounce = function( object )
	
	if object.x - ( object.width * 0.5 ) < 0 or object.x + ( object.width * 0.5 ) > display.contentWidth then
		object.velocity.x = -object.velocity.x
	elseif object.y - ( object.height * 0.5 ) < 0 or object.y + ( object.height * 0.5 ) > display.contentHeight then
		object.velocity.y = -object.velocity.y
	end
	
end

--- Rotates a display object 1 degree every frame.
-- @param object The display object that the behaviour is acting on.
rotate = function( object )
	object.rotation = object.rotation + 1
end

--- Causes a display object to randomly jump around the screen every 60 frames.
-- @param object The display object that the behaviour is acting on.
teleport = function( object )
	
	object.framesSinceLastJump = ( object.framesSinceLastJump or 0 ) + 1
	
	if object.framesSinceLastJump > 60 then
		object.framesSinceLastJump = 0
		
		object.x = math.random(0, display.contentWidth)
		object.y = math.random(0, display.contentHeight)
	end
	
end
