local import = require(game:GetService("ReplicatedStorage").Source.import)
local rodash = import("Packages/rodash")

local server, player1, player2
local renderWorld

-- =============================================================================
--  An Entity in the world.
-- =============================================================================

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

-- =============================================================================
--  The Server.
-- =============================================================================
local Server = {}
Server.__index = Server

function Server.new(canvas, status)
	local self = setmetatable({
		-- Connected clients and their entities.
		clients = {};
		entities = {};

		-- Last processed input for each client.
		last_processed_input = {};

		-- Simulated network connection.
		network = LagNetwork.new();

		-- UI.
		canvas = canvas;
		status = status;
	}, Server)

	self:setUpdateRate(10);

	return self
end

function Server:connect(client)
	-- Give the Client enough data to identify itself.
	client.server = self;
	client.entity_id = #self.clients + 1;
	table.insert(self.clients, client);

	-- Create a new Entity for this Client.
	local entity = Entity.new();
	table.insert(self.entities, entity)
	entity.entity_id = client.entity_id;

	-- Set the initial state of the Entity (e.g. spawn point)
	local spawn_points = {4, 6};
	entity.x = spawn_points[client.entity_id];
end

function Server:setUpdateRate(hz)
	self.update_rate = hz

	if self.update_interval then
		self.update_interval:clear()
	end
	self.update_interval = rodash.setInterval(
		function()
			self:update()
		end,
		1 / self.update_rate
	);
end

function Server:update()
	self:processInputs()
	self:sendWorldState()
	renderWorld(self.canvas, self.entities)
end

-- Check whether this input seems to be valid (e.g. "make sense" according
-- to the physical rules of the World)
function Server:validateInput(input)
	if (math.abs(input.press_time) > 1/40) then
		return false;
	else
		return true;
	end
end

function Server:processInputs()
	-- Process all pending messages from clients.

	while (true) do
		local message = self.network:receive();
		if (not message) then
			break;
		end

		-- Update the state of the entity, based on its input.
		-- We just ignore inputs that don't look valid; this is what prevents clients from cheating.
		if (self:validateInput(message)) then
			local id = message.entity_id;
			self.entities[id]:applyInput(message);
			self.last_processed_input[id] = message.input_sequence_number;
		end
	end

	-- Show some info.
	local info = "Last acknowledged input: ";
	for i = 1, #self.clients do
		info = info .. "Player " .. i .. ": #" .. (self.last_processed_input[i] or 0) .. "   ";
	end
	self.status.Text = info;
end

-- Send the world state to all the connected clients.
function Server:sendWorldState()
	-- Gather the state of the world. In a real app, state could be filtered to avoid leaking data
	-- (e.g. position of invisible enemies).
	local world_state = {};
	local num_clients = #self.clients;
	for i = 1, num_clients do
		local entity = self.entities[i];
		table.insert(world_state, {
			entity_id = entity.entity_id,
			position = entity.x,
			last_processed_input = self.last_processed_input[i]
		});
	end

	-- Broadcast the state to all the clients.
	for i = 1, num_clients do
		local client = self.clients[i];
		client.network:send(client.lag, world_state);
	end
end

-- =============================================================================
--  Helpers.
-- =============================================================================
local element = function(id, scope)
	return (scope or game):FindFirstChild(id, true) or error("Could not find: " .. id);
end

-- Render all the entities in the given canvas.
renderWorld = function(canvas, entities)
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

-- =============================================================================
--  Get everything up and running.
-- =============================================================================

local function isNaN(number)
	return type(number) == "number" and number ~= number
end

local function parseInt(number)
	return math.floor(tonumber(number))
end

local updateNumberFromUI = function(old_value, element_id)
	local input = element(element_id);
	local new_value = parseInt(input.Value);
	if (isNaN(new_value)) then
	  new_value = old_value;
	end
	input.Value = new_value;
	return new_value;
end



local updatePlayerParameters = function(client, prefix)
	client.lag = updateNumberFromUI(player1.lag, prefix .. "_lag");

	local cb_prediction = element(prefix .. "_prediction");
	local cb_reconciliation = element(prefix .. "_reconciliation");

	-- Client Side Prediction disabled => disable Server Reconciliation.
	if (client.client_side_prediction and not cb_prediction.Value) then
		cb_reconciliation.Value = false;
	end

	-- Server Reconciliation enabled => enable Client Side Prediction.
	if (not client.server_reconciliation and cb_reconciliation.Value) then
		cb_prediction.Value = true;
	end

	client.client_side_prediction = cb_prediction.Value;
	client.server_reconciliation = cb_reconciliation.Value;

	client.entity_interpolation = element(prefix .. "_interpolation").Value;
end

-- Update simulation parameters from UI.
local updateParameters = function()
	updatePlayerParameters(player1, "player1");
	updatePlayerParameters(player2, "player2");
	server:setUpdateRate(updateNumberFromUI(server.update_rate, "server_fps"));
	return true;
end

-- When the player presses the arrow keys, set the corresponding flag in the client.
game:GetService("ContextActionService"):BindAction("keyboard", function(_, _, inputObject)
	local isKeyDown = (inputObject.UserInputState == Enum.UserInputState.Begin)
	if inputObject.KeyCode == Enum.KeyCode.D then
		player1.key_right = isKeyDown
	elseif inputObject.KeyCode == Enum.KeyCode.A then
		player1.key_left = isKeyDown
	elseif inputObject.KeyCode == Enum.KeyCode.L then
		player2.key_right = isKeyDown
	elseif inputObject.KeyCode == Enum.KeyCode.J then
		player2.key_left = isKeyDown
	end
end, false, Enum.UserInputType.Keyboard)

-- Setup a server, the player's client, and another player.
server = Server.new(element("server_canvas"), element("server_status"));

player1 = Client.new(element("player1_canvas"), element("player1_status"));
player1:setUpdateRate(50);

player2 = Client.new(element("player2_canvas"), element("player2_status"));
player2:setUpdateRate(50);


-- Connect the clients to the server.
server:connect(player1);
server:connect(player2);

-- Read initial parameters from the UI.
updateParameters();

return {}