game.ReplicatedFirst:RemoveDefaultLoadingScreen()
game.ReplicatedStorage:WaitForChild("Packages")

local rodash = require(game.ReplicatedStorage.Packages.rodash)
local recs = require(game.ReplicatedStorage.Packages.recs)
local recsBridge = require(game.ReplicatedStorage.Packages.recsBridge)

local renderSystem = require(script.Recs.Systems.render)
local colliderSystem = require(script.Recs.Systems.collider)

do -- player1
	local core = recs.Core.new()
	core:registerComponentsInInstance(script.Recs.Components)

	local engine = require(game.ReplicatedStorage.Packages.engine).config(rodash.merge(recsBridge(core), { address = 1, lag = 100/1000 }))
	local player1 = engine.client()

	local render = renderSystem(core, game:FindFirstChild("player1", true), true)
	local collider = colliderSystem(core, 'player1')
	core:registerSystem(render)
	core:registerSystem(collider)

	core:registerStepper(recs.event(player1.updated.Event, { collider }))


	render:init()
	local lastPitch = 0
	local lastYaw = 0
	local CAMERA_THRESHOLD = 0.0
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

do -- server
	local core = recs.Core.new()
	core:registerComponentsInInstance(script.Recs.Components)

	local engine = require(game.ReplicatedStorage.Packages.engine).config(rodash.merge(recsBridge(core), { address = "server", lag = 0 }))
	local server = engine.server()

	server:connect(1)
	--server:connect(2)

	local render = renderSystem(core, game:FindFirstChild("server", true))
	local collider = colliderSystem(core, 'server')
	core:registerSystem(render)
	core:registerSystem(collider)

	core:registerStepper(recs.event(server.updated.Event, { collider, render }))

	core:start()
end


print("Done")