-- =============================================================================
--  An Entity in the world.
-- =============================================================================

--TODO: How much of this is redundant wrt ECS systems?

local Entity = {}
Entity.__index = Entity

function Entity.new()
	return setmetatable({
		x = 0,
		speed = 2000,
		position_buffer = {},
	}, Entity)
end

function Entity:applyInput(input)
	self.x = self.x + (input.press_time * self.speed)
end

return Entity