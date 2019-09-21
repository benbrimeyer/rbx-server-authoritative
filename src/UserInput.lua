local ContextActionService = game:GetService("ContextActionService")

local BindableEvent = Instance.new("BindableEvent")

ContextActionService:BindAction("keyboard", function(_, _, inputObject)
	BindableEvent:Fire(inputObject)
end, false, Enum.UserInputType.Keyboard)

return {
	connect = function(func)
		return BindableEvent.Event:Connect(func)
	end,
}