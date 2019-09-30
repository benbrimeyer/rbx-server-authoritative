local recs = require(game.ReplicatedStorage.Packages.recs)

return function(core, logger)
	local collider = recs.System:extend("collider")

	function collider:step()
		for entityId, transform, motion in core:components("transform", "motion") do
			transform.position = transform.position + motion.velocity
			motion.velocity = Vector3.new()
		end
	end

	return collider
end
