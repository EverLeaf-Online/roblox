local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CombatHitboxMath = require(ReplicatedStorage.Shared.Math.CombatHitboxMath)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MonsterAttackHitboxMath = require(ReplicatedStorage.Shared.Math.MonsterAttackHitboxMath)

local MonsterAttackHitboxService = {}

local function getRoot(model)
    return model and model:FindFirstChild("HumanoidRootPart")
end

local function collectCharacterBodyParts(character)
    local parts = {}
    for _, descendant in character:GetDescendants() do
        if descendant:IsA("BasePart") and not descendant:FindFirstAncestorOfClass("Accessory") then
            table.insert(parts, descendant)
        end
    end
    return parts
end

local function hasLineOfSight(monster, targetCharacter, sourcePosition, targetPosition)
    local excluded = { monster }
    for _, player in Players:GetPlayers() do
        local character = player.Character
        if character and character ~= targetCharacter then
            table.insert(excluded, character)
        end
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = excluded
    params.IgnoreWater = true

    local delta = targetPosition - sourcePosition
    if delta.Magnitude <= 0.01 then
        return true
    end
    local result = Workspace:Raycast(sourcePosition, delta, params)
    return result == nil or result.Instance:IsDescendantOf(targetCharacter)
end

function MonsterAttackHitboxService.CanHitPlayer(monster, player, definition)
    if typeof(monster) ~= "Instance" or not monster:IsA("Model") or not monster.Parent then
        return false, "monster_unavailable"
    end
    if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then
        return false, "player_unavailable"
    end
    if type(definition) ~= "table" then
        return false, "invalid_definition"
    end

    local monsterRoot = getRoot(monster)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local targetRoot = getRoot(character)
    if
        not monsterRoot
        or not character
        or not humanoid
        or humanoid.Health <= 0
        or not targetRoot
    then
        return false, "target_unavailable"
    end

    local range = math.max(1, tonumber(definition.AttackRange) or 5)
    local depth = MonsterAttackHitboxMath.ResolveDepth(
        range,
        definition.AttackDepthSlack or GameConfig.Combat.MonsterAttackDepthSlack
    )
    local width = MonsterAttackHitboxMath.ResolveWidth(range, definition.AttackWidth, {
        WidthMultiplier = GameConfig.Combat.MonsterAttackHitboxWidthMultiplier,
        MinWidth = GameConfig.Combat.MonsterAttackHitboxMinWidth,
        MaxWidth = GameConfig.Combat.MonsterAttackHitboxMaxWidth,
    })
    local verticalRange = math.max(
        1,
        tonumber(definition.AttackVerticalRange) or GameConfig.Combat.MonsterAttackVerticalRange
    )
    local sizeX, sizeY, sizeZ = CombatHitboxMath.BoxSize(depth, width, verticalRange)
    local center = monsterRoot.CFrame * CFrame.new(0, 0, -(depth * 0.5))

    local bodyParts = collectCharacterBodyParts(character)
    if #bodyParts == 0 then
        return false, "target_unavailable"
    end
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = bodyParts
    params.MaxParts = math.min(32, #bodyParts)

    if #Workspace:GetPartBoundsInBox(center, Vector3.new(sizeX, sizeY, sizeZ), params) == 0 then
        return false, "outside_attack_hitbox"
    end

    local requireLineOfSight = definition.AttackRequireLineOfSight
    if requireLineOfSight == nil then
        requireLineOfSight = GameConfig.Combat.MonsterAttackRequireLineOfSight
    end
    if requireLineOfSight == true then
        local sourcePosition = monsterRoot.Position + Vector3.new(0, 1.5, 0)
        local targetPosition = targetRoot.Position + Vector3.new(0, 1, 0)
        if not hasLineOfSight(monster, character, sourcePosition, targetPosition) then
            return false, "blocked"
        end
    end

    return true
end

return MonsterAttackHitboxService
