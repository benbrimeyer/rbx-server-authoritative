local function createObject(incomingSignal, timeStep)
	print("new incoming:", timeStep)
	local outgoingSignal = Instance.new("BindableEvent")
	local connection = nil

	local function start()
		if connection then
			return
		end
		local fixedDelta = timeStep
		local accumulator = 0

		connection = incomingSignal:Connect(function(frameTime)
			accumulator = accumulator + frameTime
			while accumulator >= fixedDelta do
				outgoingSignal:Fire(fixedDelta)
				accumulator = accumulator - fixedDelta
			end
		end)
	end

	local function stop()
		if connection then
			connection:Disconnect()
		end
	end

	local function connect(func)
		return outgoingSignal.Event:Connect(func)
	end

	return {
		connect = connect,
		start = start,
		stop = stop,
	}
end

return {
	config = function(options)
		local signal = options.signal
		local timeStep = options.timeStep or 0.1
		return createObject(signal, timeStep)
	end
}
