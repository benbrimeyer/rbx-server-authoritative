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
--  A message queue with simulated network lag.
-- =============================================================================
local LagNetwork = {}
LagNetwork.__index = LagNetwork

function LagNetwork.new()
	return setmetatable({
		messages = {}
	}, LagNetwork)
end

function LagNetwork:send(lag_ms, message)
	table.insert(self.messages, {
		recv_ts = tick() + lag_ms,
		payload = message,
	})
end

function LagNetwork:receive()
	local now = tick()
	for i, message in ipairs(self.messages) do
		if (message.recv_ts <= now) then
			table.remove(self.messages, i)
			return message.payload
		end
	end
end

-- =============================================================================
--  The Client.
-- =============================================================================
local Client = {}
Client.__index = Client

function Client.new(canvas, status)
	return setmetatable({
		-- Local representation of the entities.
		entities = {};

		-- Input state.
		key_left = false;
		key_right = false;

		-- Simulated network connection.
		network = LagNetwork.new();
		server = nil;
		lag = 0;

		-- Unique ID of our entity. Assigned by Server on connection.
		entity_id = nil;

		-- Data needed for reconciliation.
		client_side_prediction = false;
		server_reconciliation = false;
		input_sequence_number = 0;
		pending_inputs = {};

		-- Entity interpolation toggle.
		entity_interpolation = true;

		-- UI.
		canvas = canvas;
		status = status;
	}, Client)
end

function Client:setUpdateRate(hz)
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

-- Update Client state.
function Client:update()
	-- Listen to the server.
	self:processServerMessages();

	if (self.entity_id == nil) then
	  return; -- Not connected yet.
	end

	-- Process inputs.
	self:processInputs();

	-- Interpolate other entities.
	if (self.entity_interpolation) then
	  self:interpolateEntities();
	end

	-- Render the World.
	renderWorld(self.canvas, self.entities);

	-- Show some info.
	local info = "Non-acknowledged inputs: " .. #self.pending_inputs;
	self.status.Text = info;
end

-- Get inputs and send them to the server.
-- If enabled, do client-side prediction.
function Client:processInputs()
	-- Compute delta time since last update.
	local now_ts = tick();
	local last_ts = self.last_ts or now_ts;
	local dt_sec = (now_ts - last_ts) / 1000.0;
	self.last_ts = now_ts;

	-- Package player's input.
	local input;
	if (self.key_right) then
		input = { press_time = dt_sec };
	elseif (self.key_left) then
		input = { press_time = -dt_sec };
	else
		-- Nothing interesting happened.
		return;
	end

	-- Send the input to the server.
	self.input_sequence_number = self.input_sequence_number + 1
	input.input_sequence_number = self.input_sequence_number;
	input.entity_id = self.entity_id;
	self.server.network:send(self.lag, input);

	-- Do client-side prediction.
	if (self.client_side_prediction) then
		if self.entities[self.entity_id] then
			self.entities[self.entity_id]:applyInput(input);
		end
	end

	-- Save this input for later reconciliation.
	table.insert(self.pending_inputs, input);
end

-- Process all messages from the server, i.e. world updates.
-- If enabled, do server reconciliation.
function Client:processServerMessages()
	while (true) do
		local message = self.network:receive();
		if (not message) then
			break;
		end

		-- World state is a list of entity states.
		for _, state in ipairs(message) do
			-- If this is the first time we see this entity, create a local representation.
			if (not self.entities[state.entity_id]) then
				local entity = Entity.new();
				entity.entity_id = state.entity_id;
				self.entities[state.entity_id] = entity;
			end

			local entity = self.entities[state.entity_id];

			if (state.entity_id == self.entity_id) then
				-- Received the authoritative position of this client's entity.
				entity.x = state.position;

				if (self.server_reconciliation) then
					-- Server Reconciliation. Re-apply all the inputs not yet processed by
					-- the server.
					local j = 1;
					while (j <= #self.pending_inputs) do
						local input = self.pending_inputs[j];
						if (input.input_sequence_number <= (state.last_processed_input or 0)) then
							-- Already processed. Its effect is already taken into account into the world update
							-- we just got, so we can drop it.
							table.remove(self.pending_inputs, j)
						else
							-- Not processed by the server yet. Re-apply it.
							entity:applyInput(input);
							j = j + 1;
						end
					end
				else
					-- Reconciliation is disabled, so drop all the saved inputs.
					self.pending_inputs = {};
				end
			else
				-- Received the position of an entity other than this client's.
				if (not self.entity_interpolation) then
					-- Entity interpolation is disabled - just accept the server's position.
					entity.x = state.position;
				else
					-- Add it to the position buffer.
					local timestamp = tick();
					table.insert(entity.position_buffer, {timestamp, state.position});
				end
			end
		end
	end
end

function Client:interpolateEntities()
	-- Compute render timestamp.
	local now = tick();
	local render_timestamp = now - (1 / server.update_rate);

	for _, entity in pairs(self.entities) do
		-- No point in interpolating this client's entity.
		if (entity.entity_id ~= self.entity_id) then
			-- Find the two authoritative positions surrounding the rendering timestamp.
			local buffer = entity.position_buffer;
			-- Drop older positions.
			while (#buffer >= 2 and buffer[2][1] <= render_timestamp) do
				table.remove(buffer, 1)
			end

			-- Interpolate between the two surrounding authoritative positions.
			if (#buffer >= 2 and buffer[1][1] <= render_timestamp and render_timestamp <= buffer[2][1]) then
				local x0 = buffer[1][2];
				local x1 = buffer[2][2];
				local t0 = buffer[1][1];
				local t1 = buffer[2][1];

				entity.x = x0 + (x1 - x0) * (render_timestamp - t0) / (t1 - t0);
			end
		end
	end
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