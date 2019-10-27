local recs = require(game.ReplicatedStorage.Packages.recs)

return recs.defineComponent({
	name = "walk",
	generator = function()
		return {
			speed = 16,
			jump = false,
			airTime = 0.25,
			canJump = false,
			--velocity = Vector3.new(),
			direction = Vector3.new(),
			moveX = 0,
			moveY = 0,
		}
	end,
})