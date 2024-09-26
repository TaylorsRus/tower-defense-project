local EntityManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage.Config

local AllEntities: { [number]: Entity } = {}
local AllComponents: any = require(Config.Components)

local NextID: number = 1

type Entity = {
	ID: number,
	Model: Model,
	Components: { [string]: Component },
}

type Component = { any }

function EntityManager.CreateEntity(Model: Model): Entity
	local EntityID: number = NextID
	local Entity: Entity = {
		ID = EntityID,
		Model = Model,
		Components = {},
	}

	NextID += 1
	AllEntities[EntityID] = Entity
	return Entity
end

function EntityManager.GetEntity(EntityID: number): Entity
	local Entity = AllEntities[EntityID]
	if not Entity then
		error("No entity associated with ID " .. tostring(EntityID))
	end
	return Entity
end

function EntityManager.GetAllEntities(): { [number]: Entity }
	return AllEntities
end

function EntityManager.RemoveEntity(EntityID: number)
	local Entity = EntityManager.GetEntity(EntityID)

	Entity.Model:Destroy()
	AllEntities[EntityID] = nil
end

function EntityManager.AddComponent(EntityID: number, Name: string, Value: any)
	local Entity = EntityManager.GetEntity(EntityID)
	local Component = AllComponents[Name]
	if Component == nil then
		error(Name .. " is not a valid component.")
	elseif Component and Value == nil then
		warn(`Value supplied to {Name} component is nil. Defaulting to {tostring(Component)}`)
	elseif Component and typeof(Value) ~= typeof(Component) then
		error(
			`{tostring(Value)} is not a valid value for component, expected value: {typeof(
				Component
			)}`
		)
	end

	Entity.Components[Name] = Value
end

function EntityManager.GetComponent(EntityID: number, Name: string): any
	local Entity = EntityManager.GetEntity(EntityID)
	local Value = Entity.Components[Name]
	if Value == nil then
		warn(`No component on entity, {tostring(EntityID)} named {Name}`)
	end

	return Value
end

function EntityManager.SetComponent(EntityID: number, Name: string, Value: any)
	local Entity = EntityManager.GetEntity(EntityID)
	local Component = EntityManager.GetComponent(EntityID, Name)
	if not Component then
		EntityManager.AddComponent(EntityID, Name, Value)
	else
		Entity.Components[Name] = Value
	end
end

function EntityManager.RemoveComponent(EntityID: number, Name: string)
	EntityManager.GetEntity(EntityID).Components[Name] = nil
end

return EntityManager
