local recs = require(game.ReplicatedStorage.Packages.recs)


local function toWorldSpace(transform, direction)
	local angle = CFrame.Angles(0, math.rad(transform.yaw or 0), 0)

	return angle:VectorToWorldSpace(direction)
end

return function(core, logger)
	local movement = recs.System:extend("movement")

	function movement:step()
		for entityId, walk, transform in core:components("walk", "transform") do
			local moveX = walk.moveX * walk.speed
			local moveY = walk.moveY * walk.speed

			local move = Vector3.new(moveX, 0, moveY)

			walk.direction = toWorldSpace(transform, move)
			walk.moveX = 0
			walk.moveY = 0
		end
	end

	return movement
end
