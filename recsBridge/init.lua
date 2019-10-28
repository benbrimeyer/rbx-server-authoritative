local rodash = require(game.ReplicatedStorage.Packages.rodash)

return function(core)
	local whiteListComponents = require(script.whiteListComponents)(core)
	local whiteList = whiteListComponents("walk", "transform", "motion")

	return {
		-- TODO: Remove server_update_rate
		-- Currently this is needed by the client to determine interpolation
		server_update_rate = 10,

		-- (Client/Server) Initialize entities here.
		entityInit = whiteList.init,

		-- (Client/Server) Build snapshot of entity's worldState here.
		entityRead = whiteList.read,

		-- (Client) Received the authoritative position of this client's entity.
		entityWrite = whiteList.write,

		-- (Client/Server) Register inputs that modify and create entities
		entityInput = {
			move_left = function(entityId, input)
				local walk = core:getComponent(entityId, "walk")
				walk.moveX = walk.moveX + -(input.press_time)
			end,

			move_right = function(entityId, input)
				local walk = core:getComponent(entityId, "walk")
				walk.moveX = walk.moveX + (input.press_time)
			end,

			move_up = function(entityId, input)
				local walk = core:getComponent(entityId, "walk")
				walk.moveY = walk.moveY + -(input.press_time)
			end,

			move_down = function(entityId, input)
				local walk = core:getComponent(entityId, "walk")
				walk.moveY = walk.moveY + (input.press_time)
			end,

			jump = function(entityId, input)
				local walk = core:getComponent(entityId, "walk")
				if walk.canJump then
					walk.jump = true
					walk.airTime = -0.25
				end
			end,

			look = function(entityId, input)
				local transform = core:getComponent(entityId, "transform")
				if not transform then
					return
				end

				transform.pitch = input.look.pitch
				transform.yaw = input.look.yaw
			end,

			dash = function(entityId, input)
				local transform = core:getComponent(entityId, "transform")
				local motion = core:getComponent(entityId, "motion")

				motion.force = (CFrame.new(transform.position)
					* CFrame.Angles(0, math.rad(transform.yaw or 0), 0)).lookVector * 1000
			end,
		},
	}
end