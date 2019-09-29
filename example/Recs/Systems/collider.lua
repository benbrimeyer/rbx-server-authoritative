local recs = require(game.ReplicatedStorage.Packages.recs)

local function toWorldSpace(transform, direction)
	local angle = CFrame.Angles(0, math.rad(transform.yaw or 0), 0)

	return angle:VectorToWorldSpace(direction)
end

return function(core)
	local collider = recs.System:extend("collider")

	function collider:step()
		for entityId, transform, motion in core:components("walk", "transform", "motion") do
			print(entityId, motion)
		end
	end

	return collider
end
