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

return function(core)
	local physics = recs.System:extend("physics")

	function physics:step(input)
		local dt = input.press_time

		for entityId, transform, motion in core:components("transform", "motion") do

			motion.acceleration = Vector3.new(0, -100, 0) + motion.force
			motion.velocity = (motion.velocity + motion.acceleration * dt) * (1 - 0.5 * dt)
			local isGround, normal = cast(transform.position, motion.acceleration, motion.impulse)
			if isGround then
				motion.acceleration = Vector3.new()
				motion.velocity = Vector3.new()
				motion.impulse = motion.impulse + (normal)
			end

			transform.position = transform.position + (motion.velocity * dt + motion.acceleration * (dt * dt * 0.5)) + motion.impulse
			motion.impulse = Vector3.new()
			motion.force = Vector3.new()

		end
	end

	return physics
end
