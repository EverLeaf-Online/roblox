local fs = require("@lune/fs")

local source = fs.readFile("src/client/Controllers/ReactUIController.luau")

for _, required in
    {
        "local UI_REFERENCE_SIZE = Vector2.new(1280, 720)",
        "scaledRoot.AnchorPoint = Vector2.new(0, 0)",
        "scaledRoot.Position = UDim2.fromOffset(0, 0)",
        "local scaledWidth = UI_REFERENCE_SIZE.X * scale",
        "local scaledHeight = UI_REFERENCE_SIZE.Y * scale",
        "local offsetX = math.max(0, (viewport.X - scaledWidth) * 0.5)",
        "local offsetY = math.max(0, (viewport.Y - scaledHeight) * 0.5)",
        "scaledRoot.Position = UDim2.fromOffset(math.floor(offsetX + 0.5), math.floor(offsetY + 0.5))",
    }
do
    assert(
        string.find(source, required, 1, true) ~= nil,
        "missing responsive HUD contract: " .. required
    )
end

assert(
    string.find(source, "scaledRoot.AnchorPoint = Vector2.new(0.5, 0.5)", 1, true) == nil,
    "fixed-size HUD root must not be centered with an unscaled AnchorPoint offset"
)
assert(
    string.find(source, "scaledRoot.Position = UDim2.fromScale(0.5, 0.5)", 1, true) == nil,
    "fixed-size HUD root must not use the old center-position pattern"
)

print("responsive UI layout rules tests passed")
