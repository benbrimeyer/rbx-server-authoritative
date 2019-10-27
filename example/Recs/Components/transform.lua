local recs = require(game.ReplicatedStorage.Packages.recs)

return recs.defineComponent({
	name = "transform",
	generator = function()
		return {
			--position = Vector3.new(0, 14.25, 0),
			position = Vector3.new(47.6515808, 150.729645, -257.969055),
			pitch = 0,
			yaw = 0,
		}
	end,
})