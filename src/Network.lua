return {
	config = function(options)
		local incoming = options.incoming
		local outgoing = options.outgoing

		return {
			connect = function(func)
				return incoming:Connect(func)
			end,
			send = function(...)
				local args = {...}
				coroutine.wrap(function()
					if options.latency then
						wait(options.latency)
					end
					outgoing(unpack(args))
				end)()
			end,
		}
	end,
}