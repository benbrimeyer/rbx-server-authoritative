-- =============================================================================
--  A message queue with simulated network lag.
-- =============================================================================

local LagNetwork = {}
LagNetwork.__index = LagNetwork

function LagNetwork.new()
	return setmetatable({
		messages = {}
	}, LagNetwork)
end

function LagNetwork:send(lag_ms, message)
	table.insert(self.messages, {
		recv_ts = tick() + lag_ms,
		payload = message,
	})
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