local import = require(game:GetService("ReplicatedStorage").Packages.import)

import.setConfig({
	aliases = {
		Source = game.ReplicatedStorage.Source,
		Packages = game.ReplicatedStorage.Packages,
	}
})

return import