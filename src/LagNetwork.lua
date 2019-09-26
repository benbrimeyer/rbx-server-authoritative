-- =============================================================================
--  A message queue with simulated network lag.
-- =============================================================================

-- TODO: Convert to use lua Signals
local event = Instance.new("BindableEvent")

local LagNetwork = {}
LagNetwork.__index = LagNetwork

function LagNetwork.new(address, lag)
	local self = setmetatable({
		lag = lag,
		messages = {},
	}, LagNetwork)

	event.Event:Connect(function(incomingAddress, message)
		if address ~= incomingAddress then
			return
		end

		table.insert(self.messages, {
			recv_ts = tick() + lag,
			payload = message,
		})
	end)

	return self
end

function LagNetwork:send(address, message)
	delay(self.lag, function()
		event:Fire(address, message)
	end)
end

function LagNetwork:receive()
	local now = tick()
	for i, message in ipairs(self.messages) do
		if (message.recv_ts <= now) then
			table.remove(self.messages, i)
			return message.payload
		end
	end
end

return LagNetwork