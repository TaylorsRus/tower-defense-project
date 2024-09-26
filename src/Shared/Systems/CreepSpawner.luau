local CreepSpawner = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage.Config
local Modules = ReplicatedStorage.Modules

local Units = ReplicatedStorage.Units
local CreepStorage = Units.Creeps

local EntitiesFolder = Workspace.Entities
local CreepsFolder = EntitiesFolder.Creeps

local PathFolder = Workspace.Path
local SpawnerFolder = PathFolder.Spawners
local NodesFolder = PathFolder.Nodes

local EntityManager = require(Modules.EntityManager)
local CreepTypes = require(Config.EntityTypes).Creep
local WaveData = require(Config.WaveData)

local WaveInProgress = false
local CurrentWave = 0
local TotalCreeps = 0

local CreepComponents = {
	UnitType = "Creep",
	NextNode = 0,
	Pathfinding = false,
}

local function CreateCreepEntity(Model)
	local Entity = EntityManager.CreateEntity(Model)
	for Name, Value in CreepComponents do
		EntityManager.AddComponent(Entity.ID, Name :: string, Value)
	end

	local Type = Model.Name
	local TypeComponents = CreepTypes[Type]
	if not TypeComponents then
		return
	end

	for Name, Value in TypeComponents do
		EntityManager.AddComponent(Entity.ID, Name, Value)
	end

	return Entity
end

local function LoadCreeps(Spawner: Model, SpawnerData: { [string]: any })
	for Type, Amount in SpawnerData.Creeps do
		local Model = CreepStorage:FindFirstChild(Type)
		if not Model then
			error(`Could not find model for creep {Type}`)
		end

		local SpawnPointReference = Spawner:FindFirstChild("SpawnPoint") :: BasePart
		local SpawnPoint = SpawnPointReference and SpawnPointReference.CFrame or Spawner:GetPivot()

		print(Amount)
		for Index = 1, Amount do
			task.wait(SpawnerData.Interval)

			local Clone = Model:Clone()
			Clone:PivotTo(SpawnPoint)
			Clone.Parent = CreepsFolder

			task.defer(CreateCreepEntity, Clone)
			script:SetAttribute("TotalCreeps", Index)
		end
	end
end

local function OnTotalCreepsChanged()
	TotalCreeps = script:GetAttribute("TotalCreeps")

	if TotalCreeps == 0 then
		print("Round ended!")
		task.wait(2)
		script:SetAttribute("CurrentWave", CurrentWave + 1)
	end
end

local function OnCurrentWaveChanged()
	CurrentWave = script:GetAttribute("CurrentWave")
	local CurrentWaveData = WaveData[CurrentWave]
	if not CurrentWaveData then
		CurrentWaveData = WaveData.Default
	end

	print(CurrentWaveData)
	for SpawnerName, SpawnerData in CurrentWaveData do
		local Spawner = SpawnerFolder:FindFirstChild(SpawnerName)
		if not Spawner then
			error(`Could not find spawner for wave {tostring(CurrentWave)}, {SpawnerName}`)
		end
		print(Spawner.Name)

		task.defer(LoadCreeps, Spawner, CurrentWaveData[Spawner.Name])
	end
end

function CreepSpawner.Init()
	if script:GetAttribute("CurrentWave") == nil then
		script:SetAttribute("CurrentWave", 0)
	end
	if script:GetAttribute("TotalCreeps") == nil then
		script:GetAttribute("TotalCreeps")
	end

	script:GetAttributeChangedSignal("CurrentWave"):Connect(OnCurrentWaveChanged)
	script:GetAttributeChangedSignal("TotalCreeps"):Connect(OnTotalCreepsChanged)
end

function CreepSpawner.Update(DeltaTime)
	if not WaveInProgress then
		WaveInProgress = true
		script:SetAttribute("CurrentWave", CurrentWave + 1)
	end

	for _, Entity in EntityManager.GetAllEntities() do
		local IsCreep = EntityManager.GetComponent(Entity.ID, "UnitType") == "Creep"
		local IsPathfinding = EntityManager.GetComponent(Entity.ID, "Pathfinding") == true
		if not IsCreep or IsPathfinding then
			continue
		end

		local NextNodeNumber = EntityManager.GetComponent(Entity.ID, "NextNode")
		if NextNodeNumber == nil or NextNodeNumber == 0 then
			EntityManager.SetComponent(Entity.ID, "NextNode", 1)
			NextNodeNumber = 1
		elseif NextNodeNumber > #NodesFolder:GetChildren() then
			script:SetAttribute("TotalCreeps", TotalCreeps - 1)
			EntityManager.RemoveEntity(Entity.ID)
			continue
		end

		local NextNode = NodesFolder:FindFirstChild(tostring(NextNodeNumber))
		if not NextNode then
			warn("Couldn't find next node.")
		end

		local PotentialHumanoid = Entity.Model:FindFirstChildOfClass("Humanoid")
		local Humanoid = nil
		if not PotentialHumanoid then
			Humanoid = Instance.new("Humanoid")
			Humanoid.Parent = Entity.Model
		else
			Humanoid = PotentialHumanoid
		end

		Humanoid.MoveToFinished:Once(function()
			EntityManager.SetComponent(Entity.ID, "NextNode", NextNodeNumber + 1)
			EntityManager.SetComponent(Entity.ID, "Pathfinding", false)
		end)
		Humanoid:MoveTo(NextNode.Position, NextNode)
		EntityManager.SetComponent(Entity.ID, "Pathfinding", true)
	end
end

return CreepSpawner
