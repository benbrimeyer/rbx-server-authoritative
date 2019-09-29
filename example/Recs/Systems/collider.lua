local recs = require(game.ReplicatedStorage.Packages.recs)


local function toWorldSpace(transform, direction)
	local angle = CFrame.Angles(0, math.rad(transform.yaw or 0), 0)

	return angle:VectorToWorldSpace(direction)
end


local function clampMagnitude(v3, max)
	return v3.magnitude > 0 and (v3.unit * math.min(v3.magnitude, max)) or v3
end

return function(core, logger)
	local collider = recs.System:extend("collider")

	function collider:step(input, dt)
		for entityId, walk, transform, motion in core:components("walk", "transform", "motion") do
			local moveX = walk.x * walk.speed
			local moveY = walk.y * walk.speed

			--local move = Vector3.new(moveX, 0, moveY)
			local move = clampMagnitude(Vector3.new(moveX, 0, moveY), walk.speed * input.press_time)

			local direction = toWorldSpace(transform, move)
			transform.position = transform.position + direction

			walk.x = 0
			walk.y = 0
		end
	end

	return collider
end
