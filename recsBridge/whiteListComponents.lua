return function(core)
	return function(...)
		local args = { ... }

		local map = {}
		for _, name in ipairs(args) do
			local component = core:getComponentClass(name)
			local default = component._create()
			local array = {}
			for property, _ in pairs(default) do
				table.insert(array, property)
			end
			map[component] = array
		end

		return {
			init = function(entityId)
				core:batchAddComponents(entityId, unpack(args))
			end,

			read = function(entityId)
				local readValues = {}
				for component, propertyList in pairs(map) do
					readValues[propertyList] = core:getComponent(entityId, component)[propertyList]
				end

				return readValues
			end,

			write = function(entityId, state)
				for component, propertyList in pairs(map) do
					core:getComponent(entityId, component)[propertyList] = state[propertyList]
				end
			end,
		}
	end
end