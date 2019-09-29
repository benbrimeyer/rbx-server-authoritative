return function(core)
	return {
		-- TODO: Remove server_update_rate
		-- Currently this is needed by the client to determine interpolation
		server_update_rate = 10,

		-- (Client/Server) Initialize entities here.
		entityInit = function(entityId)
			core:addComponent(entityId, "transform")
		end,

		-- (Client/Server) Build snapshot of entity's worldState here.
		entityRead = function(entityId)
			return {
				position = core:getComponent(entityId, "transform").position,
			}
		end,

		-- (Client) Received the authoritative position of this client's entity.
		entityWrite = function(entityId, state)
			core:getComponent(entityId, "transform").position = state.position
		end,

		-- (Client/Server) Register inputs that modify and create entities
		entityInput = {
			move_left = function(entityId, input)
				local transform = core:getComponent(entityId, "transform")
				transform.position = transform.position + Vector3.new(-(input.press_time * transform.speed), 0, 0)
			end,

			move_right = function(entityId, input)
				local transform = core:getComponent(entityId, "transform")
				transform.position = transform.position + Vector3.new((input.press_time * transform.speed), 0, 0)
			end,

			move_up = function(entityId, input)
				local transform = core:getComponent(entityId, "transform")
				transform.position = transform.position + Vector3.new(0, 0, -(input.press_time * transform.speed))
			end,

			move_down = function(entityId, input)
				local transform = core:getComponent(entityId, "transform")
				transform.position = transform.position + Vector3.new(0, 0, (input.press_time * transform.speed))
			end,
		},
	}
end