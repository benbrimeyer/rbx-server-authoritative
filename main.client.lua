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
			y = 0,
			position_buffer = {},
			speed = 16,
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

		self.lastPos = Vector3.new()
	end
	function render:step()
		for entityId, transform in core:components("transform") do
			local player = self.element("partplayer" .. entityId, canvas)
			player.Position = player.Position:lerp(Vector3.new(transform.x, 4.25, transform.y), 0.1)
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
	--core:registerStepper(recs.event(game:GetService("RunService").RenderStepped, { render }))

	render:init()
	game:GetService("RunService"):BindToRenderStep("temp", Enum.RenderPriority.Camera.Value - 1, function(dt)
		render:step(dt)
	end)


	core:start()

	-- We don't care or want to know how consumers process input,
	-- as long as they give us valid input's defined from the inputMap
	game:GetService("ContextActionService"):BindAction("keyboard", function(_, _, inputObject)
		local isKeyDown = (inputObject.UserInputState == Enum.UserInputState.Begin)
		if inputObject.KeyCode == Enum.KeyCode.D then
			player1:input("move_right", isKeyDown)
		elseif inputObject.KeyCode == Enum.KeyCode.A then
			player1:input("move_left", isKeyDown)
		elseif inputObject.KeyCode == Enum.KeyCode.W then
			player1:input("move_up", isKeyDown)
		elseif inputObject.KeyCode == Enum.KeyCode.S then
			player1:input("move_down", isKeyDown)
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
	--core:registerStepper(recs.event(game:GetService("RunService").RenderStepped, { render }))

	core:start()

end


print("Done")