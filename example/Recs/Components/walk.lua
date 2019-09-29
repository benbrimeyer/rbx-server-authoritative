local recs = require(game.ReplicatedStorage.Packages.recs)

return recs.defineComponent({
	name = "walk",
	generator = function()
		return {
			speed = 16,
			moveDirection = Vector3.new(0, 0, 0),
		}
	end,
})