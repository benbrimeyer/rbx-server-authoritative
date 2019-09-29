local recs = require(game.ReplicatedStorage.Packages.recs)

return recs.defineComponent({
	name = "transform",
	generator = function()
		return {
			position = Vector3.new(0, 4.25, 0),
			pitch = 0,
			yaw = 0,
		}
	end,
})