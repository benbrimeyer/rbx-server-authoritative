local function new(options)
	assert(options.applyInput)
	assert(options.step)
	assert(options.makeState)

	local inputArray = {}

	return {
		update = function(dt)
			for _, inputModel in ipairs(inputArray) do
				options.applyInput(inputModel)
				options.step(dt)
			end
			inputArray = {}

			return options.makeState()
		end,

		queue = function(player, sequenceNumber, inputObject)
			table.insert(inputArray, {
				player = player,
				sequenceNumber = sequenceNumber,
				inputObject = inputObject,
			})
		end,
	}
end

return {
	config = function(options)
		return new(options)
	end,
}