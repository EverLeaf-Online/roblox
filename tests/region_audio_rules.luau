local fs = require("@lune/fs")

local profiles = fs.readFile("src/shared/RegionAudioProfiles.luau")
local controller = fs.readFile("src/client/Controllers/RegionAudioController.luau")
local bootstrap = fs.readFile("src/client/bootstrap.client.luau")

for _, assetId in
    {
        "rbxassetid://1848017039",
        "rbxassetid://9112781510",
        "rbxassetid://9040092810",
        "rbxassetid://9112761348",
    }
do
    assert(
        string.find(profiles, assetId, 1, true) ~= nil,
        "missing approved Creator Store audio: " .. assetId
    )
end

assert(string.find(profiles, "lumenreach", 1, true) ~= nil, "Lumenreach audio profile missing")
assert(string.find(profiles, "brasshaven", 1, true) ~= nil, "Brasshaven audio profile missing")
assert(
    string.find(controller, "ProfileStore.Subscribe", 1, true) ~= nil,
    "region audio must react to profile/world changes"
)
assert(string.find(controller, "MusicVolume", 1, true) ~= nil, "music setting must control BGM")
assert(
    string.find(controller, "SfxVolume", 1, true) ~= nil,
    "SFX setting must control environmental ambience"
)
assert(
    string.find(controller, "CROSSFADE_SECONDS", 1, true) ~= nil,
    "region changes must crossfade rather than hard-cut"
)
assert(
    string.find(bootstrap, 'startController("RegionAudioController"', 1, true) ~= nil,
    "audio controller must start from client bootstrap"
)

print("region audio routing tests passed")
