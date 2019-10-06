local recs = require(game.ReplicatedStorage.Packages.recs)

local cast = function(position)
	local hip = 4.25/2
	local ray = Ray.new(position, Vector3.new(0, -(hip + 0.2), 0))

	local hit, hitPosition, normal = workspace:FindPartOnRay(ray, workspace.render)
	local distanceFromGround = (position - hitPosition).magnitude

	return not not hit, normal * (hip - distanceFromGround)
end

return function(core, logger)
	local physics = recs.System:extend("physics")

	function physics:step(input)
		local dt = input.press_time

		for entityId, transform, motion in core:components("transform", "motion") do

			motion.acceleration = Vector3.new(0, -workspace.Gravity, 0) + motion.force
			motion.velocity = (motion.velocity + motion.acceleration * dt) * (1 - 0.5 * dt)
			local isGround, normal = cast(transform.position)
			if isGround then
				motion.acceleration = Vector3.new()
				motion.velocity = Vector3.new()
				motion.impulse = motion.impulse + (normal)
			end

			transform.position = transform.position + (motion.velocity * dt + motion.acceleration * (dt * dt * 0.5)) + motion.impulse
			motion.impulse = Vector3.new()

		end
	end

	return physics
end
