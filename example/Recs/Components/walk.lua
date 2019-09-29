local recs = require(game.ReplicatedStorage.Packages.recs)

return recs.defineComponent({
	name = "walk",
	generator = function()
		return {
			speed = 50,
			direction = Vector3.new(0, 0, 0),
			offset = Vector3.new(0, 0, 0),
			x = 0,
			y = 0,
		}
	end,
})