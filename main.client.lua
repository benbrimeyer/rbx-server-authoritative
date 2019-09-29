game.ReplicatedFirst:RemoveDefaultLoadingScreen()
game.ReplicatedStorage:WaitForChild("Packages")

local rodash = require(game.ReplicatedStorage.Packages.rodash)
local recs = require(game.ReplicatedStorage.Packages.recs)
local recsBridge = require(game.ReplicatedStorage.Packages.recsBridge)

local transformComponent = recs.defineComponent({
	name = "transform",
	generator = function()
		return {
			position = Vector3.new(0, 4.25, 0),
			speed = 16,
		}
	end,
})

local renderSystem = function(core, canvas, isLerped)
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

do -- player1
	local core = recs.Core.new()
	core:registerComponent(transformComponent)

	local engine = require(game.ReplicatedStorage.Packages.engine).config(rodash.merge(recsBridge(core), { address = 1, lag = 0 }))
	local player1 = engine.client()

	local render = renderSystem(core, game:FindFirstChild("player1", true), true)
	core:registerSystem(render)
	--core:registerStepper(recs.event(game:GetService("RunService").RenderStepped, { render }))

	render:init()
	local lastPitch = 0
	local lastYaw = 0
	local CAMERA_THRESHOLD = 0.1
	game:GetService("RunService"):BindToRenderStep("temp", Enum.RenderPriority.Camera.Value - 1, function(dt)
		local x, y = workspace.CurrentCamera.CFrame:ToOrientation()
		local pitch, yaw = math.deg(x), math.deg(y)
		if math.abs(lastPitch - pitch) > CAMERA_THRESHOLD or math.abs(lastYaw - yaw) > CAMERA_THRESHOLD then
			lastPitch = pitch
			lastYaw = yaw
			player1:look(pitch, yaw)
			player1:input("look", true)
		else
			player1:input("look", false)
		end

		render:step(dt)
	end)


	core:start()

	-- We don't care or want to know how consumers process input,
	-- as long as they give us valid input's defined from the inputMap
	game:GetService("ContextActionService"):BindAction("keyboard_player1", function(_, _, inputObject)
		local isKeyDown = (inputObject.UserInputState == Enum.UserInputState.Begin)
		if inputObject.KeyCode == Enum.KeyCode.D then
			player1:input("move_right", isKeyDown)
		elseif inputObject.KeyCode == Enum.KeyCode.A then
			player1:input("move_left", isKeyDown)
		elseif inputObject.KeyCode == Enum.KeyCode.W then
			player1:input("move_up", isKeyDown)
		elseif inputObject.KeyCode == Enum.KeyCode.S then
			player1:input("move_down", isKeyDown)
		else
			return Enum.ContextActionResult.Pass
		end
	end, false, Enum.UserInputType.Keyboard)
end

do -- player2
	local core = recs.Core.new()
	core:registerComponent(transformComponent)

	local engine = require(game.ReplicatedStorage.Packages.engine).config(rodash.merge(recsBridge(core), { address = 2, lag = 100/1000 }))
	local player2 = engine.client()

	local render = renderSystem(core, game:FindFirstChild("player2", true), true)
	core:registerSystem(render)
	--core:registerStepper(recs.event(game:GetService("RunService").RenderStepped, { render }))

	render:init()
	game:GetService("RunService"):BindToRenderStep("temp", Enum.RenderPriority.Camera.Value - 1, function(dt)
		render:step(dt)
	end)


	core:start()

	-- We don't care or want to know how consumers process input,
	-- as long as they give us valid input's defined from the inputMap
	game:GetService("ContextActionService"):BindAction("keyboard_player2", function(_, _, inputObject)
		local isKeyDown = (inputObject.UserInputState == Enum.UserInputState.Begin)
		if inputObject.KeyCode == Enum.KeyCode.K then
			player2:input("move_right", isKeyDown)
		elseif inputObject.KeyCode == Enum.KeyCode.H then
			player2:input("move_left", isKeyDown)
		elseif inputObject.KeyCode == Enum.KeyCode.U then
			player2:input("move_up", isKeyDown)
		elseif inputObject.KeyCode == Enum.KeyCode.J then
			player2:input("move_down", isKeyDown)
		else
			return Enum.ContextActionResult.Pass
		end
	end, false, Enum.UserInputType.Keyboard)
end

do -- server
	local core = recs.Core.new()
	core:registerComponent(transformComponent)

	local engine = require(game.ReplicatedStorage.Packages.engine).config(rodash.merge(recsBridge(core), { address = "server", lag = 0 }))
	local server = engine.server()

	server:connect(1)
	server:connect(2)

	local render = renderSystem(core, game:FindFirstChild("server", true))
	core:registerSystem(render)
	core:registerStepper(recs.event(game:GetService("RunService").RenderStepped, { render }))

	core:start()

end


print("Done")