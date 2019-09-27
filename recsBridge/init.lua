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
				x = core:getComponent(entityId, "transform").x,
				y = core:getComponent(entityId, "transform").y,
			}
		end,

		-- (Client) Received the authoritative position of this client's entity.
		entityWrite = function(entityId, state)
			core:getComponent(entityId, "transform").x = state.x
			core:getComponent(entityId, "transform").y = state.y
		end,

		-- (Client/Server) Register inputs that modify and create entities
		entityInput = {
			move_left = function(entityId, input)
				local transform = core:getComponent(entityId, "transform")
				transform.x = transform.x + -(input.press_time * transform.speed)
			end,

			move_right = function(entityId, input)
				local transform = core:getComponent(entityId, "transform")
				transform.x = transform.x + (input.press_time * transform.speed)
			end,

			move_up = function(entityId, input)
				local transform = core:getComponent(entityId, "transform")
				transform.y = transform.y + -(input.press_time * transform.speed)
			end,

			move_down = function(entityId, input)
				local transform = core:getComponent(entityId, "transform")
				transform.y = transform.y + (input.press_time * transform.speed)
			end,
		},
	}
end