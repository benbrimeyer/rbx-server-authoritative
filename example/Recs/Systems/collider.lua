local recs = require(game.ReplicatedStorage.Packages.recs)

return function(core, logger)
	local collider = recs.System:extend("collider")

	function collider:step()
		for entityId, transform, motion in core:components("transform", "motion") do
			print(logger, "collider:", entityId)
		end
	end

	return collider
end
