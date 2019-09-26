-- Temporary file for visualization

local element = function(id, scope)
	return (scope or game):FindFirstChild(id, true) or error("Could not find: " .. id);
end

return function(canvas, entities)
	local colors = {BrickColor.new("Bright blue").Color, BrickColor.new("Bright red").Color};

	local canvasWidth = canvas.AbsoluteSize.X
	local canvasHeight = canvas.AbsoluteSize.Y

	for _, entity in ipairs(entities) do
		-- Compute size and position.
		local radius = canvasHeight*0.9/2;
		local x = (entity.x / 10.0)*canvasWidth;
		local color = colors[entity.entity_id]

		-- Draw the entity.
		local ball = element("ball" .. entity.entity_id, canvas)
		ball.AnchorPoint = Vector2.new(0, 0.5)
		ball.Position = UDim2.new(0, x, 0.5, 0)
		ball.Size = UDim2.new(0, radius, 0, radius)
		ball.BackgroundColor3 = color
	end
end