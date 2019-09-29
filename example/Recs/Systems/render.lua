local recs = require(game.ReplicatedStorage.Packages.recs)

return function(core, canvas, isLerped)
	local render = recs.System:extend("render")
	function render:init()
		-- helper function to find first child
		self.element = function(id, scope)
			return (scope or game):FindFirstChild(id, true) or error("Could not find: " .. id);
		end
	end
	function render:step()
		for entityId, transform in core:components("transform") do
			local player = self.element("Part" .. entityId, canvas)
			local goal = CFrame.new(transform.position)
				* CFrame.Angles(0, math.rad(transform.yaw or 0), 0)
				* CFrame.Angles(math.rad(transform.pitch or 0), 0, 0)

			if isLerped then
				player.CFrame = player.CFrame:Lerp(goal, 0.1)
			else
				player.CFrame = goal
			end
		end
	end

	return render
end