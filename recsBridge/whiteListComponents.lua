return function(core)
	return function(...)
		local listOfComponents = { ... }

		return {
			init = function(entityId)
				core:batchAddComponents(entityId, unpack(listOfComponents))
			end,

			read = function(entityId)
				local readValues = {}
				for _, component in ipairs(listOfComponents) do
					readValues[component] = core:getComponent(entityId, component)
				end

				return readValues
			end,

			write = function(entityId, state)
				for _, component in ipairs(listOfComponents) do
					local class = core:getComponent(entityId, component)
					for name, value in pairs(state[component]) do
						class[name] = value
					end
				end
			end,
		}
	end
end