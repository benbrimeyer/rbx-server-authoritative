local configWrapper = require(script.Parent.configWrapper)
local rodash = require(script.Parent.Parent.rodash)

local Entity = require(script.Parent.Entity)
local LagNetwork = require(script.Parent.LagNetwork)

local renderWorld = require(script.Parent.renderWorld)

local Client = {}
Client.__index = Client

function Client.new(options)
	local networkImpl = options.networkImpl or LagNetwork

	local self = setmetatable({
		-- Local representation of the entities.
		entities = {};

		-- Input state.
		inputState = {},

		-- Simulated network connection.
		network = networkImpl.new();
		server = nil;
		lag = 0;

		-- Unique ID of our entity. Assigned by Server on connection.
		entity_id = nil;

		-- Data needed for reconciliation.
		input_sequence_number = 0;
		pending_inputs = {};

		options = options,

	}, Client)

	self:setUpdateRate(50)

	return self
end

function Client:input(name, isDown)
	if isDown then
		if not rodash.includes(self.inputState, name) then
			self.inputState = rodash.clone(self.inputState)
			table.insert(self.inputState, name)
		end
	else
		if rodash.includes(self.inputState, name) then
			self.inputState = rodash.without(self.inputState, name)
		end
	end
end

function Client:applyInputToEntity(input, entity)
	local inputMap = self.options.inputMap
	for _, state in ipairs(input.state) do
		local bind = inputMap[state]
		bind(entity, input)
	end
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
	self:interpolateEntities();

	-- TODO: Remove
	renderWorld(self.canvas, self.entities);
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
	if (#self.inputState > 0) then
		input = {
			state = self.inputState,
			press_time = dt_sec,
		};
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
	if self.entities[self.entity_id] then
		self:applyInputToEntity(input, self.entities[self.entity_id])
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
						self:applyInputToEntity(input, entity)
						j = j + 1;
					end
				end
			else
				-- Received the position of an entity other than this client's.
				-- Add it to the position buffer.
				local timestamp = tick();
				table.insert(entity.position_buffer, {timestamp, state.position});
			end
		end
	end
end

function Client:interpolateEntities()
	-- Compute render timestamp.
	local now = tick();
	local render_timestamp = now - (1 / self.options.server_update_rate);

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

				-- TODO: This is interpolating a function from inputMap
				-- Should we mark certain properties/entities as translate-able?
				entity.x = x0 + (x1 - x0) * (render_timestamp - t0) / (t1 - t0);
			end
		end
	end
end

return configWrapper(function(options)
	return function()
		return Client.new(options)
	end
end)