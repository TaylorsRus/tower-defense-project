local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SystemsFolder = ReplicatedStorage:WaitForChild("Systems")

local LoadedSystems = {}

for _, System in SystemsFolder:GetChildren() do
	if not System:IsA("ModuleScript") then
		continue
	end

	local LoadedSystem = require(System) :: any
	if LoadedSystem.Init then
		LoadedSystem.Init()
	end
	table.insert(LoadedSystems, LoadedSystem)
end

RunService.Heartbeat:Connect(function(DeltaTime)
	for _, System in LoadedSystems do
		if System.Update then
			System.Update(DeltaTime)
		end
	end
end)
