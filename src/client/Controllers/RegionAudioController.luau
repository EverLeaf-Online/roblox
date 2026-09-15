local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local ProfileStore = require(script.Parent.Parent.State.ProfileStore)
local RegionAudioProfiles = require(ReplicatedStorage.Shared.RegionAudioProfiles)

local RegionAudioController = {}

local CROSSFADE_SECONDS = 2.25
local currentRegionId = nil
local musicIndex = 1
local ambienceIndex = 1
local musicSounds = {}
local ambienceSounds = {}
local activeTweens = {}

local function clampVolume(value)
    return math.clamp(tonumber(value) or 1, 0, 1)
end

local function ensureSound(name)
    local existing = SoundService:FindFirstChild(name)
    if existing and existing:IsA("Sound") then
        existing:Stop()
        existing.Volume = 0
        existing.Looped = true
        return existing
    end
    if existing then
        existing:Destroy()
    end

    local sound = Instance.new("Sound")
    sound.Name = name
    sound.Looped = true
    sound.Volume = 0
    sound.Parent = SoundService
    return sound
end

local function setupChannels()
    musicSounds[1] = ensureSound("EverLeafRegionMusicA")
    musicSounds[2] = ensureSound("EverLeafRegionMusicB")
    ambienceSounds[1] = ensureSound("EverLeafRegionAmbienceA")
    ambienceSounds[2] = ensureSound("EverLeafRegionAmbienceB")
end

local function cancelTweens()
    for _, tween in activeTweens do
        pcall(function()
            tween:Cancel()
        end)
    end
    table.clear(activeTweens)
end

local function tweenVolume(sound, volume)
    local tween = TweenService:Create(
        sound,
        TweenInfo.new(CROSSFADE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Volume = math.max(0, volume) }
    )
    table.insert(activeTweens, tween)
    tween:Play()
    return tween
end

local function regionFromSnapshot(snapshot)
    local world = type(snapshot) == "table" and snapshot.World or nil
    local regionId = type(world) == "table" and world.RegionId or nil
    return type(regionId) == "string" and regionId or nil
end

local function userVolumes(snapshot)
    local settings = type(snapshot) == "table" and snapshot.Settings or nil
    if type(settings) ~= "table" then
        return 1, 1
    end
    return clampVolume(settings.MusicVolume), clampVolume(settings.SfxVolume)
end

local function profileFor(regionId)
    local profile = regionId and RegionAudioProfiles[regionId] or nil
    return type(profile) == "table" and profile or nil
end

local function stopInactiveAfterFade(sound)
    task.delay(CROSSFADE_SECONDS + 0.05, function()
        if sound.Parent and sound.Volume <= 0.001 then
            sound:Stop()
            sound.TimePosition = 0
        end
    end)
end

local function switchChannel(channels, activeIndex, track, userVolume)
    local current = channels[activeIndex]
    local nextIndex = if activeIndex == 1 then 2 else 1
    local nextSound = channels[nextIndex]

    tweenVolume(current, 0)
    stopInactiveAfterFade(current)

    if type(track) ~= "table" or type(track.AssetId) ~= "string" or track.AssetId == "" then
        tweenVolume(nextSound, 0)
        stopInactiveAfterFade(nextSound)
        return nextIndex
    end

    nextSound:Stop()
    nextSound.SoundId = track.AssetId
    nextSound.TimePosition = 0
    nextSound.Volume = 0
    nextSound.Looped = true
    nextSound:Play()
    tweenVolume(nextSound, math.max(0, tonumber(track.BaseVolume) or 0) * userVolume)
    return nextIndex
end

local function retargetVolumes(profile, musicVolume, sfxVolume)
    local music = profile and profile.Music or nil
    local ambience = profile and profile.Ambience or nil

    local activeMusic = musicSounds[musicIndex]
    local activeAmbience = ambienceSounds[ambienceIndex]
    if activeMusic then
        tweenVolume(activeMusic, (tonumber(music and music.BaseVolume) or 0) * musicVolume)
    end
    if activeAmbience then
        tweenVolume(activeAmbience, (tonumber(ambience and ambience.BaseVolume) or 0) * sfxVolume)
    end
end

local function applySnapshot(snapshot)
    local regionId = regionFromSnapshot(snapshot)
    local profile = profileFor(regionId)
    local musicVolume, sfxVolume = userVolumes(snapshot)

    cancelTweens()
    if regionId ~= currentRegionId then
        currentRegionId = regionId
        musicIndex = switchChannel(musicSounds, musicIndex, profile and profile.Music, musicVolume)
        ambienceIndex =
            switchChannel(ambienceSounds, ambienceIndex, profile and profile.Ambience, sfxVolume)
        return
    end

    retargetVolumes(profile, musicVolume, sfxVolume)
end

function RegionAudioController.Start()
    setupChannels()
    ProfileStore.Subscribe(applySnapshot)
end

return RegionAudioController
