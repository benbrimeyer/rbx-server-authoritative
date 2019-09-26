game.ReplicatedFirst:RemoveDefaultLoadingScreen()
game.ReplicatedStorage:WaitForChild("Packages")

local engine = require(game.ReplicatedStorage.Packages.engine).config({
	-- inputMap allows consumers to register inputs that
	-- modify and create entities
	inputMap = {
		move_left = function(entity, input)
			entity.x = entity.x + -(input.press_time * entity.speed)
		end,

		move_right = function(entity, input)
			entity.x = entity.x + (input.press_time * entity.speed)
		end
	},

	server_update_rate = 10,
})

local player1 = engine.client()

local server = engine.server()
server:connect(player1);

-- TODO: Remove
player1.canvas = game:FindFirstChild("player1_canvas", true)
server.canvas = game:FindFirstChild("server_canvas", true)

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

print("Done")