game.ReplicatedFirst:RemoveDefaultLoadingScreen()
game.ReplicatedStorage:WaitForChild("Packages")

local rodash = require(game.ReplicatedStorage.Packages.rodash)
local recs = require(game.ReplicatedStorage.Packages.recs)
local recsBridge = require(game.ReplicatedStorage.Packages.recsBridge)

local transformComponent = recs.defineComponent({
	name = "transform",
	generator = function()
		return {
			x = 4,
			position_buffer = {},
			speed = 2000,
		}
	end,
})

local renderSystem = function(core, canvas)
	local render = recs.System:extend("render")
	function render:init()
		-- helper function to find first child
		self.element = function(id, scope)
			return (scope or game):FindFirstChild(id, true) or error("Could not find: " .. id);
		end
	end
	function render:step(dt)
		local colors = {BrickColor.new("Bright blue").Color, BrickColor.new("Bright red").Color};

		local canvasWidth = canvas.AbsoluteSize.X
		local canvasHeight = canvas.AbsoluteSize.Y

		for entityId, transform in core:components("transform") do
			-- Compute size and position.
			local radius = canvasHeight*0.9/2;
			local x = (transform.x / 10.0)*canvasWidth;
			local color = colors[entityId]

			-- Draw the entity.
			local ball = self.element("ball" .. entityId, canvas)
			ball.AnchorPoint = Vector2.new(0, 0.5)
			ball.Position = UDim2.new(0, x, 0.5, 0)
			ball.Size = UDim2.new(0, radius, 0, radius)
			ball.BackgroundColor3 = color
		end
	end

	return render
end

do -- player1
	local core = recs.Core.new()
	core:registerComponent(transformComponent)

	local engine = require(game.ReplicatedStorage.Packages.engine).config(rodash.merge(recsBridge(core), { address = 1, lag = 0 }))
	local player1 = engine.client()

	local render = renderSystem(core, game:FindFirstChild("player1_canvas", true))
	core:registerSystem(render)
	core:registerStepper(recs.event(game:GetService("RunService").RenderStepped, { render }))

	core:start()

	-- We don't care or want to know how consumers process input,
	-- as long as they give us valid input's defined from the inputMap
	game:GetService("ContextActionService"):BindAction("keyboard", function(_, _, inputObject)
		local isKeyDown = (inputObject.UserInputState == Enum.UserInputState.Begin)
		if inputObject.KeyCode == Enum.KeyCode.D then
			player1:input("move_right", isKeyDown)
		elseif inputObject.KeyCode == Enum.KeyCode.A then
			player1:input("move_left", isKeyDown)
		end
	end, false, Enum.UserInputType.Keyboard)
end

do -- server
	local core = recs.Core.new()
	core:registerComponent(transformComponent)

	local engine = require(game.ReplicatedStorage.Packages.engine).config(rodash.merge(recsBridge(core), { address = "server", lag = 0 }))
	local server = engine.server()

	server:connect(1)

	local render = renderSystem(core, game:FindFirstChild("server_canvas", true))
	core:registerSystem(render)
	core:registerStepper(recs.event(game:GetService("RunService").RenderStepped, { render }))

	core:start()

end


print("Done")