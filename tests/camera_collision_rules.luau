local fs = require("@lune/fs")

local source = fs.readFile("src/client/Controllers/CameraController.luau")

assert(
    string.find(source, 'hit:GetAttribute("EverLeafCollisionProxy") == true', 1, true) ~= nil,
    "camera collision must recognize transparent EverLeaf collision proxies"
)
assert(
    string.find(source, "hit.CanCollide and (hit.Transparency < 0.95 or collisionProxy)", 1, true)
        ~= nil,
    "camera must pull in for physical proxies even when they are visually transparent"
)

print("camera collision rules tests passed")
