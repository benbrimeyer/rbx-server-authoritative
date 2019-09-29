local configWrapper = require(script.Parent.configWrapper)
local rodash = require(script.Parent.Parent.rodash)

local LagNetwork = require(script.Parent.LagNetwork)

local Client = {}
Client.__index = Client

function Client.new(options)
	local networkImpl = options.networkImpl or LagNetwork

	local self = setmetatable({
		-- Local representation of the entities.
		entities = {};
		position_buffer = {},

		-- Input state.
		inputState = {},

		-- Simulated network connection.
		network = networkImpl.new(options.address, options.lag);

		-- Unique ID of our entity. Assigned by Server on connection.
		entity_id = options.address;

		-- Data needed for reconciliation.
		input_sequence_number = 0;
		pending_inputs = {};

		options = options,

		onInput = Instance.new("BindableEvent"),
		onUpdate = Instance.new("BindableEvent"),

	}, Client)

	self:setUpdateRate(60)

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

function Client:look(pitch, yaw)
	self._look = { pitch = pitch, yaw = yaw }
end

function Client:applyInputToEntity(input, entity)
	local entityInput = self.options.entityInput
	for _, state in ipairs(input.state) do
		local bind = entityInput [state]
		bind(entity, input)
		self.onInput:Fire(input, 1/self.update_rate)
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
			self.onUpdate:Fire()
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
end

-- Get inputs and send them to the server.
-- If enabled, do client-side prediction.
function Client:processInputs()
	-- Compute delta time since last update.
	local now_ts = tick();
	local last_ts = self.last_ts or now_ts;
	local dt_sec = (now_ts - last_ts);
	self.last_ts = now_ts;

	-- Package player's input.
	local input;
	if (#self.inputState > 0) then
		input = {
			look = self._look,
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
	self.network:send("server", input);

	-- Do client-side prediction.
	self:applyInputToEntity(input, self.entity_id)

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
				--[[local entity = Entity.new();
				entity.entity_id = state.entity_id;
				self.entities[state.entity_id] = entity;]]
				self.options.entityInit(state.entity_id)
				self.position_buffer[state.entity_id] = {}
				self.entities[state.entity_id] = true
			end

			local entity_id = state.entity_id

			if (state.entity_id == self.entity_id) then
				-- Received the authoritative position of this client's entity.
				--entity.x = state.position;
				self.options.entityWrite(entity_id, state)

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
						self:applyInputToEntity(input, entity_id)
						j = j + 1;
					end
				end
			else
				-- Received the position of an entity other than this client's.
				-- Add it to the position buffer.
				local timestamp = tick();
				table.insert(self.position_buffer[entity_id], {timestamp = timestamp, state = state})
				--table.insert(entity.position_buffer, {timestamp, state.position});
			end
		end
	end
end

local lerp = function(renderTime, x0, x1, t0, t1)
	-- numbers/vector2/vector3
	return x0 + (x1 - x0) * (renderTime - t0) / (t1 - t0)
end

function Client:interpolateEntities()
	-- Compute render timestamp.
	local now = tick();
	local render_timestamp = now - (1 / self.options.server_update_rate);

	for entity_id, _ in pairs(self.entities) do
		-- No point in interpolating our own client's entity.
		if (entity_id ~= self.entity_id) then

			-- Find the two authoritative positions surrounding the rendering timestamp.
			self.position_buffer[entity_id] = self.position_buffer[entity_id] or {}
			local buffer = self.position_buffer[entity_id];
			-- Drop older positions.
			while (#buffer >= 2 and buffer[2].timestamp <= render_timestamp) do
				table.remove(buffer, 1)
			end

			-- Interpolate between the two surrounding authoritative positions.
			if (#buffer >= 2 and buffer[1].timestamp <= render_timestamp and render_timestamp <= buffer[2].timestamp) then
				local state0 = buffer[1].state;
				local state1 = buffer[2].state;
				local t0 = buffer[1].timestamp;
				local t1 = buffer[2].timestamp;

				local lerpedState = {}
				for property, value in pairs(state0) do
					if property ~= "entity_id" and property ~= "last_processed_input" then
						lerpedState[property] = lerp(render_timestamp, value, state1[property], t0, t1)
					end
				end

				self.options.entityWrite(entity_id, lerpedState)
			end
		end
	end
end

return configWrapper(function(options)
	return function()
		return Client.new(options)
	end
end)