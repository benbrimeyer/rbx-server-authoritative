local configWrapper = require(script.Parent.configWrapper)
local rodash = require(script.Parent.Parent.rodash)

local Entity = require(script.Parent.Entity)
local LagNetwork = require(script.Parent.LagNetwork)

local Server = {}
Server.__index = Server

function Server.new(options)
	local networkImpl = options.networkImpl or LagNetwork

	local self = setmetatable({
		-- Connected clients and their entities.
		clients = {};
		entities = {};

		-- Last processed input for each client.
		last_processed_input = {};

		-- Simulated network connection.
		network = networkImpl.new();

		options = options,
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

	-- TODO
	--renderWorld(self.canvas, self.entities)
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
			self:applyInputToEntity(message, self.entities[id])
			self.last_processed_input[id] = message.input_sequence_number;
		end
	end
end

function Server:applyInputToEntity(input, entity)
	local inputMap = self.options.inputMap
	for _, state in ipairs(input.state) do
		local bind = inputMap[state]
		bind(entity, input)
	end
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

return configWrapper(function(options)
	return function()
		return Server.new(options)
	end
end)