local recs = require(game.ReplicatedStorage.Packages.recs)

local function clampMagnitude(v3, max)
	return v3.magnitude > 0 and (v3.unit * math.min(v3.magnitude, max)) or v3
end

return function(core, logger)
	local collider = recs.System:extend("collider")

	function collider:step(input)
		for entityId, walk, motion in core:components("walk", "motion") do
			local clamp = clampMagnitude(walk.direction, walk.speed * input.press_time)

			motion.impulse = clamp
			walk.direction = Vector3.new()
		end
	end

	return collider
end
