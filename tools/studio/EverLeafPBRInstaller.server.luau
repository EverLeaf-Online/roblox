local MaterialService = game:GetService("MaterialService")
local RunService = game:GetService("RunService")

local MATERIALS = {
    ForestGround = {
        BaseMaterial = Enum.Material.Grass,
        ColorMap = "rbxassetid://107344079410100",
        NormalMap = "rbxassetid://120186366475714",
        RoughnessMap = "rbxassetid://140381828962512",
        StudsPerTile = 14,
        OverrideProperty = "GrassName",
    },
    MossyRock = {
        BaseMaterial = Enum.Material.Rock,
        ColorMap = "rbxassetid://101823683881386",
        NormalMap = "rbxassetid://96893029091015",
        RoughnessMap = "rbxassetid://84185533532288",
        StudsPerTile = 10,
        OverrideProperty = "RockName",
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
        OverrideProperty = "GroundName",
    },
    WoodStonePathway = {
        BaseMaterial = Enum.Material.Cobblestone,
        ColorMap = "rbxassetid://139474808529273",
        NormalMap = "rbxassetid://70914826798460",
        RoughnessMap = "rbxassetid://94534825378988",
        StudsPerTile = 10,
    },
}

local function install()
    if RunService:IsRunning() then
        warn("[EverLeaf PBR] Stop Play mode before installing materials.")
        return false
    end

    for name, definition in MATERIALS do
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

        if definition.OverrideProperty then
            MaterialService[definition.OverrideProperty] = name
        end
    end

    print("[EverLeaf PBR] Installed/refreshed 5 PBR MaterialVariants.")
    return true
end

local toolbar = plugin:CreateToolbar("EverLeaf")
local button = toolbar:CreateButton(
    "Refresh PBR Materials",
    "Create or refresh EverLeaf Poly Haven MaterialVariants",
    "rbxassetid://4458901886"
)
button.ClickableWhenViewportHidden = true
button.Click:Connect(install)

-- Refresh automatically whenever the plugin loads in edit mode.
task.defer(install)
