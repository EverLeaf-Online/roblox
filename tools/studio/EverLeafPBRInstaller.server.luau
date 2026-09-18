local MaterialService = game:GetService("MaterialService")

local TARGET_GAME_ID = 10766525835

local MATERIALS = {
    ForestGround = {
        BaseMaterial = Enum.Material.Grass,
        ColorMap = "rbxassetid://107344079410100",
        NormalMap = "rbxassetid://120186366475714",
        RoughnessMap = "rbxassetid://140381828962512",
        StudsPerTile = 14,
        OverrideMaterial = Enum.Material.Grass,
    },
    MossyRock = {
        BaseMaterial = Enum.Material.Rock,
        ColorMap = "rbxassetid://101823683881386",
        NormalMap = "rbxassetid://96893029091015",
        RoughnessMap = "rbxassetid://84185533532288",
        StudsPerTile = 10,
        OverrideMaterial = Enum.Material.Rock,
    },
    MossWood = {
        BaseMaterial = Enum.Material.WoodPlanks,
        ColorMap = "rbxassetid://77089458184667",
        NormalMap = "rbxassetid://120659903163403",
        RoughnessMap = "rbxassetid://100854560520124",
        StudsPerTile = 8,
    },
    WoodChipPath = {
        BaseMaterial = Enum.Material.Ground,
        ColorMap = "rbxassetid://104765563977781",
        NormalMap = "rbxassetid://130811469027211",
        RoughnessMap = "rbxassetid://115321092703074",
        StudsPerTile = 12,
        OverrideMaterial = Enum.Material.Ground,
    },
    WoodStonePathway = {
        BaseMaterial = Enum.Material.Cobblestone,
        ColorMap = "rbxassetid://139474808529273",
        NormalMap = "rbxassetid://70914826798460",
        RoughnessMap = "rbxassetid://94534825378988",
        StudsPerTile = 10,
    },
}

local function isTargetExperience()
    return game.GameId == TARGET_GAME_ID
end

local function matchesDefinition(instance, definition)
    if not instance:IsA("MaterialVariant") then
        return false
    end

    return instance.BaseMaterial == definition.BaseMaterial
        and instance.ColorMap == definition.ColorMap
        and instance.NormalMap == definition.NormalMap
        and instance.RoughnessMap == definition.RoughnessMap
end

local function clearOverride(name, definition)
    if not definition.OverrideMaterial then
        return
    end

    local ok, current = pcall(function()
        return MaterialService:GetBaseMaterialOverride(definition.OverrideMaterial)
    end)
    if ok and current == name then
        local cleared, err = pcall(function()
            MaterialService:SetBaseMaterialOverride(definition.OverrideMaterial, "")
        end)
        if not cleared then
            warn(
                string.format(
                    "[EverLeaf PBR] Failed to clear %s override in foreign experience: %s",
                    name,
                    tostring(err)
                )
            )
        end
    end
end

local function cleanupForeignExperience()
    if isTargetExperience() then
        return 0
    end

    local removed = 0
    for name, definition in MATERIALS do
        local existing = MaterialService:FindFirstChild(name)
        if existing and matchesDefinition(existing, definition) then
            clearOverride(name, definition)
            existing:Destroy()
            removed += 1
        end
    end

    if removed > 0 then
        print(
            string.format(
                "[EverLeaf PBR] Removed %d EverLeaf MaterialVariants from non-EverLeaf experience %d.",
                removed,
                game.GameId
            )
        )
    end

    return removed
end

local function install()
    if not isTargetExperience() then
        cleanupForeignExperience()
        warn(
            string.format(
                "[EverLeaf PBR] Refusing to install materials outside EverLeaf Online (expected game %d, current game %d).",
                TARGET_GAME_ID,
                game.GameId
            )
        )
        return false
    end

    local installed = 0

    for name, definition in MATERIALS do
        local ok, err = pcall(function()
            local existing = MaterialService:FindFirstChild(name)
            if existing and not existing:IsA("MaterialVariant") then
                existing:Destroy()
                existing = nil
            end

            local variant = existing or Instance.new("MaterialVariant")
            variant.Name = name
            variant.BaseMaterial = definition.BaseMaterial
            variant.ColorMap = definition.ColorMap
            variant.NormalMap = definition.NormalMap
            variant.RoughnessMap = definition.RoughnessMap
            variant.MetalnessMap = ""
            variant.StudsPerTile = definition.StudsPerTile
            variant.MaterialPattern = Enum.MaterialPattern.Organic
            variant.Parent = MaterialService

            if definition.OverrideMaterial then
                MaterialService:SetBaseMaterialOverride(definition.OverrideMaterial, name)
            end
        end)

        if ok then
            installed += 1
        else
            warn(string.format("[EverLeaf PBR] Failed to author %s: %s", name, tostring(err)))
        end
    end

    print(string.format("[EverLeaf PBR] Installed/refreshed %d PBR MaterialVariants.", installed))
    return installed == 5
end

local toolbar = plugin:CreateToolbar("EverLeaf")
local button = toolbar:CreateButton(
    "Refresh PBR Materials",
    "Create or refresh EverLeaf Poly Haven MaterialVariants",
    "rbxassetid://4458901886"
)
button.ClickableWhenViewportHidden = true
button.Click:Connect(install)

-- Local Studio plugins are global. Never author EverLeaf materials into unrelated places.
-- Clean only variants whose maps exactly match this plugin's known EverLeaf definitions.
task.defer(function()
    if isTargetExperience() then
        install()
    else
        cleanupForeignExperience()
    end
end)
