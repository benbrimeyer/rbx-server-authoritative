-- Short utility function binding a constructor function
-- to a config function.

return function(constructor)
	return {
		config = function(options)
			return constructor(options)
		end,
	}
end