local recs = require(game.ReplicatedStorage.Packages.recs)


local function toWorldSpace(transform, direction)
	local angle = CFrame.Angles(0, math.rad(transform.yaw or 0), 0)

	return angle:VectorToWorldSpace(direction)
end

local function clampMagnitude(v3, max)
	return v3.magnitude > 0 and (v3.unit * math.min(v3.magnitude, max)) or v3
end

return function(core, logger)
	local movement = recs.System:extend("movement")

	function movement:step()
		for entityId, walk, transform, motion in core:components("walk", "transform", "motion") do
			local moveX = walk.moveX * walk.speed
			local moveY = walk.moveY * walk.speed

			local move = Vector3.new(moveX, 0, moveY)
			local clampedMove = clampMagnitude(move, walk.speed)

			local direction = toWorldSpace(transform, clampedMove)
			motion.velocity = motion.velocity + direction

			walk.moveX = 0
			walk.moveY = 0
		end
	end

	return movement
end
