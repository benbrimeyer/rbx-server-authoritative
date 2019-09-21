local RunService = game:GetService("RunService")

local UserInput = require(script.Parent.UserInput)
local FixedStepped = require(script.Parent.FixedStepped).config({
	signal = RunService.Heartbeat,
	timeStep = 1 / 3,
})
local Network = require(script.Parent.Network)
local Simulator = require(script.Parent.Simulator)

local clientServer = Instance.new("BindableEvent")
local serverClient = Instance.new("BindableEvent")
do --client
	local sequenceNumber = 0
	local myNetwork = Network.config({
		latency = 0.1,
		incoming = serverClient.Event,
		outgoing = function(...)
			sequenceNumber = sequenceNumber + 1
			clientServer:Fire("Player", sequenceNumber, ...)
		end,
	})

	UserInput.connect(function(inputObject)
		myNetwork.send(inputObject)
	end)

	myNetwork.connect(function(worldState)
		print("reconciling worldState:", worldState)
	end)
end

do --server
	local myNetwork = Network.config({
		latency = 0.1,
		incoming = clientServer.Event,
		outgoing = function(...)
			serverClient:Fire(...)
		end,
	})
	local simulator = Simulator.config({
		step = function(dt)

		end,
		applyInput = function(inputModel)

		end,
		makeState = function()
			return "hello world"
		end,
	})

	myNetwork.connect(function(player, sequenceNumber, inputObject)
		-- collects input for later simulation
		simulator.queue(player, sequenceNumber, inputObject)
	end)

	FixedStepped.connect(function(dt)
		-- simulates worldState from incoming input
		local worldState = simulator.update(dt)
		-- broadcasts worldState to clients
		myNetwork.send(worldState)
	end)
	FixedStepped.start()
end

return {}