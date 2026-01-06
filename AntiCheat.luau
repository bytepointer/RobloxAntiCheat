local AntiCheat = {}
AntiCheat.__index = AntiCheat

-- game teleports (cframe) will not work.
-- i will solve that in next update

-- i will make too 
-- some bypasses like hd admin
-- a remote trick to avoid remote debugging
-- ban action
-- webhook debug

-- defining some types

export type AntiCheatConfig = {
	maxSpeed: number,
	maxPositionChange: number,
	maxTimeInAir: number,
	causes: Object,
}

export type AntiCheatService = {
	initialize: (config: Object) -> AntiCheatService,
	run: (this: AntiCheatService) -> (),
	_config: AntiCheatConfig
}

export type Core = {
	check: {[string]: any},
	punish: (string, Object) -> ()
}

export type CoreContext = {
	player: Player,
	humanoidRoot: BasePart,
	storedTime: {[string]: number},
	storedVector: {[string]: Vector3},
	config: AntiCheatConfig
}

--[[core.punish(reason, {
	player = player,
	lastPosition = lastPosition,
	humanoidRoot = humanoidRoot,
	anchoredTime = anchoredTime
})--]]

--SERIVCES

local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

-- causes

-- next update make smth to change causes
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

-- utils

function copy(write, target)
	
	for key, value in pairs(target) do
		
		write[key] = value
	end
end

-- core

local core: Core = {
	check = {},
}

function core.check.noclip(data: Object)

	local detected = false

	local character = data.character
	local humanoidRoot = data.humanoidRoot
	local params = data.params

	local overlap = workspace:GetPartBoundsInBox(humanoidRoot.CFrame, Vector3.new(1,1,1), params)

	for _, part in ipairs(overlap) do
		if part.CanCollide == true then
			detected = true
		end
	end

	return detected
end

function core.punish(reason: string, ctx: CoreContext)

	local player = ctx.player
	local lastPosition = ctx.storedVector.lastPosition
	local humanoidRoot = ctx.humanoidRoot
	
	local cause = ctx.config.causes[reason]
	
	for _, action in ipairs(cause.action) do

		if action == "kick" then
			player:Kick(cause.message)
		elseif action == "back"  then
			humanoidRoot.Position = lastPosition
		elseif action == "anchor" then
			humanoidRoot.Anchored = true
			ctx.storedTime.lastAnchored = tick() 
		end
	end

	print("Punished!")
end

-- initialize anticheat class

function AntiCheat.initialize(config: Object) : AntiCheatService

	local causes = {}
	
	copy(causes, defaultCauses)
	
	for key, value in pairs(config.causes) do
		
		causes[key] = value
	end
	
	config.causes = causes
	
	local self = setmetatable({ _config = config }, AntiCheat)

	return self
end

-- run anti cheat

function AntiCheat:run()

	local config: AntiCheatConfig = self._config

	local maxSpeed = config.maxSpeed
	local maxPositionChange = config.maxPositionChange
	local maxTimeInAir = config.maxTimeInAir
	
	local causes = config.causes
	
	game.Players.PlayerAdded:Connect(function(player)

		-- ANTI SUSPECT MOVEMENT
		player.CharacterAdded:Connect(function(character)

			local humanoidRoot = character:WaitForChild("HumanoidRootPart")
			local humanoid = character:WaitForChild("Humanoid")
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Blacklist
			params.FilterDescendantsInstances = { character }

			local anchorTime = 3 -- just customizable in source because i did not viewed necessity to change it
			
			local bypass: boolean = false
			local initialized: boolean = false	
			
			local storedTime = {
				lastFloor = tick(),
				lastAnchored = 0,
			}
			
			local storedVector = {
				lastPosition = humanoidRoot.Position,
			}
			
			print("initialized")
			runService.Heartbeat:Connect(function()
				
				-- verifications before init
				if humanoid.Health <= 0 then return end

				if not initialized then 
					initialized = true
					print("DONE!")
					return
				end

				if storedTime.lastAnchored ~= 0 and tick() - storedTime.lastAnchored >= anchorTime then
					humanoidRoot.Anchored = false
					storedTime.lastAnchored = 0 -- changes to 0 because the player it is not anchored
				end
				
				-- local variables
				local humanoidState = humanoid:GetState()

				local positionDifference = humanoidRoot.Position - storedVector.lastPosition
				local deltaPositionXZ = Vector3.new(positionDifference.x, 0, positionDifference.z).Magnitude
				local deltaPositionY = positionDifference.y -- vertical distance

				local speed = humanoid.WalkSpeed

				-- HACKING FOUND
				local found = {}

				-- yes or not making smth
				local freefall: boolean = humanoidState == Enum.HumanoidStateType.Freefall
				local platformStanding: boolean = humanoidState == Enum.HumanoidStateType.PlatformStanding

				local climbing: boolean = humanoidState == Enum.HumanoidStateType.Climbing
				local swimming: boolean = humanoidState == Enum.HumanoidStateType.Swimming
				
				-- UPDATING LAST VARIABLES (e.x: lastFloor, falling)

				if humanoid.FloorMaterial ~= Enum.Material.Air or climbing or swimming then

					if bypass then bypass = false end

					storedTime.lastFloor = tick()
				end

				if deltaPositionY <= -1 and not bypass then
					bypass = true
				end

				-- ANTI NO CLIP

				if core.check.noclip({ character = character, humanoidRoot = humanoidRoot, params = params }) then
					table.insert(found, "noclip")	
				end

				-- ANTI FLOATING

				if humanoid.FloorMaterial == Enum.Material.Air and not bypass and tick() - storedTime.lastFloor >= maxTimeInAir and (freefall or platformStanding) then
					table.insert(found, "floating")
				end

				-- ANTI FLY
				if deltaPositionY >= maxPositionChange then
					table.insert(found, "fly")
				end


				-- ANTI TELEPORT
				if deltaPositionXZ >= maxPositionChange then
					table.insert(found, "teleport")
				end

				-- ANTI HIGH SPEED
				if speed >= maxSpeed then
					table.insert(found, "highSpeed")
				end

				-- RUNNING
	
				if #found > 0 then
					
					local context: CoreContext = {
						player = player,
						humanoidRoot = humanoidRoot,
						storedTime = storedTime,
						storedVector = storedVector,
						config = {
							causes = causes
						}
					}
					
					for _, reason in pairs(found) do
						core.punish(reason, context)
					end
					
					storedTime = context.storedTime
				end

				-- SETTING VARIABLES

				storedVector.lastPosition = humanoidRoot.Position

			end)
		end)
	end)
end

return AntiCheat
