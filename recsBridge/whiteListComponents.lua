local rodash = require(game.ReplicatedStorage.Packages.rodash)

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
			map[name] = array
		end

		return {
			init = function(entityId)
				core:batchAddComponents(entityId, unpack(args))
			end,

			read = function(entityId)
				local readValues = {}
				for component, propertyList in pairs(map) do
					for _, propertyName in ipairs(propertyList) do
						readValues[propertyName] = core:getComponent(entityId, component)[propertyName]
					end
				end

				return readValues
			end,

			write = function(entityId, state)
				for component, propertyList in pairs(map) do
					for _, propertyName in ipairs(propertyList) do
						core:getComponent(entityId, component)[propertyName] = state[propertyName]
					end
				end
			end,
		}
	end
end