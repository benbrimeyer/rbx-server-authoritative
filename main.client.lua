game.ReplicatedFirst:RemoveDefaultLoadingScreen()
game.ReplicatedStorage:WaitForChild("Packages")

local recs = require(game.ReplicatedStorage.Packages.recs)
local core = recs.Core.new()
core:registerComponent(recs.defineComponent({
	name = "transform",
	generator = function()
		return {
			x = 4,
			position_buffer = {},
			speed = 2000,
		}
	end,
}))

-- placeholder for interp
local position_buffer = {}
local engine = require(game.ReplicatedStorage.Packages.engine).config({
	-- TODO: Remove server_update_rate
	server_update_rate = 10,

	-- (Client/Server) Register inputs that modify and create entities
	inputMap = {
		move_left = function(entityId, input)
			local transform = core:getComponent(entityId, "transform")
			transform.x = transform.x + -(input.press_time * transform.speed)
		end,

		move_right = function(entityId, input)
			local transform = core:getComponent(entityId, "transform")
			transform.x = transform.x + (input.press_time * transform.speed)
		end
	},

	-- (Client/Server) Initialize entities here.
	entityInit = function(entityId)
		core:addComponent(entityId, "transform")
	end,

	-- (Server) Build snapshot of entity's worldState here.
	createWorldState = function(entityId)
		return {
			x = core:getComponent(entityId, "transform").x,
		}
	end,

	-- (Client) Received the authoritative position of this client's entity.
	sync = function(entityId, state)
		core:getComponent(entityId, "transform").x = state.x
	end,

	-- (Client) Object that handles interpolation
	-- TODO: Consider making this an object which can s.m.r.t interp whitelisted components
	interp = {
		addToBuffer = function(entityId, dataSet)
			table.insert(position_buffer[entityId], dataSet)
		end,

		invoke = function(entityId, render_timestamp)
			-- Find the two authoritative positions surrounding the rendering timestamp.
			position_buffer[entityId] = position_buffer[entityId] or {}
			local buffer = position_buffer[entityId];
			-- Drop older positions.
			while (#buffer >= 2 and buffer[2].timestamp <= render_timestamp) do
				table.remove(buffer, 1)
			end

			-- Interpolate between the two surrounding authoritative positions.
			if (#buffer >= 2 and buffer[1].timestamp <= render_timestamp and render_timestamp <= buffer[2].timestamp) then
				local x0 = buffer[1].state.x;
				local x1 = buffer[2].state.x;
				local t0 = buffer[1].timestamp;
				local t1 = buffer[2].timestamp;

				-- TODO: Should we mark certain properties/entities as translate-able to automate?
				core:getComponent(entityId, "transform").x = x0 + (x1 - x0) * (render_timestamp - t0) / (t1 - t0);
			end
		end,
	}
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