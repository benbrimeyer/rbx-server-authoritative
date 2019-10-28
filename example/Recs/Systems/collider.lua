local WALK_HEIGHT = 2.0
local GRAVITY = 9.81 * 20
local WALL_PADDING = 2.25

local recs = require(game.ReplicatedStorage.Packages.recs)

local function clampMagnitude(v3, max)
	return v3.magnitude > 0 and (v3.unit * math.min(v3.magnitude, max)) or v3
end

-- default is incase of something???
local function normalize(vec)
	local default = Vector3.new()
	local unit = vec.unit

	if unit.X ~= unit.X then --NANANANANANANNANAN
		return default
	else
		return unit
	end
end

local getGround = require(script.Parent.Parent.getGround).getGround
local getWall = require(script.Parent.Parent.getGround).getWall

return function(core, logger)
	local collider = recs.System:extend("collider")

	function collider:step(input)
		for entityId, walk, transform in core:components("walk", "transform") do
			local dt = input.press_time
			local moveVector = walk.direction.magnitude > 0 and walk.direction.unit or Vector3.new() --self.velocity.magnitude > 0 and self.velocity.unit or Vector3.new()--clampMagnitude(walk.direction, walk.speed * input.press_time)
			local movePosition = transform.position
			local jumpRequest = walk.jump
			local airTime = walk.airTime

			-- collision casting and what not
			local hitGround, groundPos, groundNormal, groundVelocity, groundFriction = getGround(movePosition, moveVector)
			local horizontalVelocity = (moveVector * walk.speed) + (groundVelocity)
			local verticalVelocity = Vector3.new()

			-- floor detection
			if hitGround and (movePosition - groundPos).magnitude < WALK_HEIGHT and not jumpRequest then
				local rawPower = (movePosition - groundPos).magnitude/WALK_HEIGHT
				local power = (1 - math.min(rawPower, 1))^2

				verticalVelocity = verticalVelocity + Vector3.new(0, GRAVITY * power, 0)
				walk.airTime = 0
			else
				verticalVelocity = verticalVelocity - Vector3.new(0, GRAVITY * airTime, 0)
				if hitGround == nil then
					walk.airTime = airTime + dt
				end
			end

			-- jump stuff
			if airTime >= 0 then
				walk.jump = false
			end

			walk.canJump = walk.airTime == 0 --hitGround ~= nil


			-- ground friction & velocity combining
			--local lastFlat = walk.velocity * Vector3.new(1, 0, 1)
			--walk.velocity = lastFlat:Lerp(horizontalVelocity, groundFriction) + verticalVelocity

			local lastFlat = walk.velocity * Vector3.new(1, 0, 1)
			walk.velocity = lastFlat:Lerp(horizontalVelocity, groundFriction) + verticalVelocity
			--self.velocity = horizontalVelocity + verticalVelocity


			-- wall detection and defelection and what not
			do
				if verticalVelocity.Y > 0 then
					local castDirection = normalize(verticalVelocity, walk.velocity)
					local hitWall, wallPos, wallNormal = getWall(movePosition, castDirection)

					if hitWall and (movePosition - wallPos).magnitude < 0.5 then
						walk.airTime = 0
						walk.velocity = walk.velocity + (wallNormal * wallNormal:Dot(-walk.velocity))
					end
				end
			end

			do
				local castDirection = normalize(horizontalVelocity, walk.velocity)
				local hitWall, wallPos, wallNormal = getWall(movePosition, castDirection)

				if hitWall and (movePosition - wallPos).magnitude < WALL_PADDING then
					walk.velocity = walk.velocity + (wallNormal * wallNormal:Dot(-walk.velocity))
				end
			end

			-- position stuff (raycast his change in the future?)
			transform.position = movePosition + (walk.velocity * dt)
			walk.jump = false
			walk.direction = Vector3.new()
		end
	end

	return collider
end
