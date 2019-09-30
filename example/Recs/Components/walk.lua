local recs = require(game.ReplicatedStorage.Packages.recs)

return recs.defineComponent({
	name = "walk",
	generator = function()
		return {
			speed = 1,
			moveX = 0,
			moveY = 0,
		}
	end,
})