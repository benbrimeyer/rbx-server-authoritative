local recs = require(game.ReplicatedStorage.Packages.recs)

return recs.defineComponent({
	name = "motion",
	generator = function()
		return {
			velocity = Vector3.new(0, 0, 0),
		}
	end,
})