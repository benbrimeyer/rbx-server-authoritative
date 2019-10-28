local recs = require(game.ReplicatedStorage.Packages.recs)
local debug = require(game.ReplicatedStorage.Packages.debug)

local function safeUnit(v)
	if v.magnitude > 0 then
		return v.unit
	end

	return Vector3.new()
end

local cast = function(position, direction, bias)
	local hip = 4.25/2 + 0.2
	local ray = Ray.new(position + safeUnit(bias), safeUnit(direction) * hip)

	local hit, hitPosition, normal = workspace:FindPartOnRay(ray, workspace.render)
	local distanceFromGround = (position - hitPosition).magnitude

	return not not hit, normal * (hip - distanceFromGround)
end

return function(core, logger)
	local physics = recs.System:extend("physics")

	function physics:step(input)
		local dt = input.press_time

		for entityId, transform, motion in core:components("transform", "motion") do
			local friction = Vector3.new()
			if motion.velocity2.magnitude > 0.02 then
				friction = -motion.velocity2 * 0.3
			end
			motion.acceleration = motion.force

			motion.velocity2 = ((motion.velocity2 + motion.acceleration * dt) * (1 - 0.98 * dt)) + friction
			transform.position = transform.position + (motion.velocity2 * dt + motion.acceleration * (dt * dt * 0.5)) + motion.impulse

			motion.impulse = Vector3.new()
			motion.force = Vector3.new()
		end
	end

	return physics
end
