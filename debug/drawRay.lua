local Debris = game:GetService("Debris")

return function(Ray, Life, Color, Parent)
	Life = Life or 2
	Parent = Parent or workspace.Terrain
	Color = Color or BrickColor.new("Bright red").Color

	local NewPart = Instance.new("CylinderHandleAdornment", Parent)


	NewPart.Height = Ray.Direction.magnitude

	local Center = Ray.Origin + Ray.Direction/2

	NewPart.AlwaysOnTop = false
	NewPart.CFrame = CFrame.new(Center, Center + Ray.Direction)
	NewPart.Color3 = Color
	NewPart.Radius = 0.06
	NewPart.Transparency = 0.5
	NewPart.Adornee = workspace.Terrain

	Debris:AddItem(NewPart, Life)
	return NewPart
end