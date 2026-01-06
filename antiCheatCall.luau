local AntiCheat = require(script.Parent.AntiCheat)

-- causes example

local causes = {
  noclip = {
    message="You got caught using noclip",
    action= { "kick" }
  }
}

-- keys options { noclip, teleport, fly, floating, highSpeed

local config = {
	maxSpeed = 50,
	maxPositionChange = 10,
	maxTimeInAir = 1,
	causes = causes
}

local antiCheat = AntiCheat.initialize(config)
antiCheat:run()

--[[
DEFAULT CAUSES
local defaultCauses  = {
	floating = {
		message="Floating in air detected!",
		action= { "kick" }
	},
	noclip = {
		message="User is noclipping",
		action={ "back", "anchor"}
	},
	fly = {
		message="User is flying",
		action= { "back" }
	},
	teleport = {
		message="Teleport Detected!",
		action= { "back" }
	},
	highSpeed = {
		message="High Speed Detected",
		action= { "kick" }
	}
}
]]--
