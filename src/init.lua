local configWrapper = require(script.configWrapper)

return configWrapper(function(options)
	return {
		client = require(script.Client).config(options),
		server = require(script.Server).config(options),
	}
end)