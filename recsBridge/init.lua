return function(core)
	local whiteListComponents = require(script.whiteListComponents)(core)
	local whitelist = whiteListComponents("transform", "motion", "walk")

	return {
		-- TODO: Remove server_update_rate
		-- Currently this is needed by the client to determine interpolation
		server_update_rate = 10,

		-- (Client/Server) Initialize entities here.
		entityInit = whitelist.init,

		-- (Client/Server) Build snapshot of entity's worldState here.
		entityRead = whitelist.read,

		-- (Client) Received the authoritative position of this client's entity.
		--[[entityWrite = function(entityId, state)
			core:getComponent(entityId, "transform").position = state.position
			core:getComponent(entityId, "transform").pitch = state.pitch
			core:getComponent(entityId, "transform").yaw = state.yaw
		end,]]
		entityWrite = whitelist.write,

		-- (Client/Server) Register inputs that modify and create entities
		entityInput = {
			move_left = function(entityId, input)
				local walk = core:getComponent(entityId, "walk")
				walk.moveDirection = walk.moveDirection + Vector3.new(-(input.press_time), 0, 0)
			end,

			move_right = function(entityId, input)
				local transform = core:getComponent(entityId, "transform")
				local normalizedDirection = Vector3.new((input.press_time * transform.speed), 0, 0)
				transform.position = transform.position + toWorldSpace(transform, normalizedDirection)
			end,

			move_up = function(entityId, input)
				local transform = core:getComponent(entityId, "transform")
				local normalizedDirection = Vector3.new(0, 0, -(input.press_time * transform.speed))
				transform.position = transform.position + toWorldSpace(transform, normalizedDirection)
			end,

			move_down = function(entityId, input)
				local transform = core:getComponent(entityId, "transform")
				local normalizedDirection = Vector3.new(0, 0, (input.press_time * transform.speed))
				transform.position = transform.position + toWorldSpace(transform, normalizedDirection)
			end,

			look = function(entityId, input)
				local transform = core:getComponent(entityId, "transform")
				transform.pitch = input.look.pitch
				transform.yaw = input.look.yaw
			end
		},
	}
end