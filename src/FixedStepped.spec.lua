return function()
	local FixedStepped = require(script.Parent.FixedStepped)

	local signal = Instance.new("BindableEvent")
	local myStepped = FixedStepped.config({ signal = signal.Event, timeStep = 0.1 })

	local timesFired = 0
	myStepped.connect(function()
		timesFired = timesFired + 1
	end)
	myStepped.start()

	signal:Fire(1.1)
	-- expect(timesFired).to.equal(11)
end