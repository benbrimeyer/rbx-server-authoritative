local rodash = require(game.ReplicatedStorage.Packages.rodash)

return function(core)

	return {
		-- TODO: Remove server_update_rate
		-- Currently this is needed by the client to determine interpolation
		server_update_rate = 10,

		-- (Client/Server) Initialize entities here.
		entityInit = function(entityId)
			core:addComponent(entityId, "transform")
			core:addComponent(entityId, "motion")
			core:addComponent(entityId, "walk")
		end,

		-- (Client/Server) Build snapshot of entity's worldState here.
		entityRead = function(entityId)
			return {
				position = core:getComponent(entityId, "transform").position,
				pitch = core:getComponent(entityId, "transform").pitch,
				yaw = core:getComponent(entityId, "transform").yaw,

				x = core:getComponent(entityId, "walk").x,
				y = core:getComponent(entityId, "walk").y,
			}
		end,

		-- (Client) Received the authoritative position of this client's entity.
		entityWrite = function(entityId, state)
			core:getComponent(entityId, "transform").position = state.position
			core:getComponent(entityId, "transform").pitch = state.pitch
			core:getComponent(entityId, "transform").yaw = state.yaw

			core:getComponent(entityId, "walk").x = state.x
			core:getComponent(entityId, "walk").y = state.y
		end,

		-- (Client/Server) Register inputs that modify and create entities
		entityInput = {
			move_left = function(entityId, input)
				local walk = core:getComponent(entityId, "walk")
				walk.x = walk.x + -(input.press_time)
			end,

			move_right = function(entityId, input)
				local walk = core:getComponent(entityId, "walk")
				walk.x = walk.x + (input.press_time)
			end,

			move_up = function(entityId, input)
				local walk = core:getComponent(entityId, "walk")
				walk.y = walk.y + -(input.press_time)
			end,

			move_down = function(entityId, input)
				local walk = core:getComponent(entityId, "walk")
				walk.y = walk.y + (input.press_time)
			end,

			look = function(entityId, input)
				local transform = core:getComponent(entityId, "transform")
				transform.pitch = input.look.pitch
				transform.yaw = input.look.yaw
			end
		},
	}
end