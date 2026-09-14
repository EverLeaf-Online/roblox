local Players = game:GetService("Players")

local RateLimiterService = {}
local buckets = {}

local function getBucket(player, key, capacity)
    local playerBuckets = buckets[player]
    if not playerBuckets then
        playerBuckets = {}
        buckets[player] = playerBuckets
    end

    local bucket = playerBuckets[key]
    if not bucket then
        bucket = {
            Tokens = capacity,
            UpdatedAt = os.clock(),
        }
        playerBuckets[key] = bucket
    end
    return bucket
end

function RateLimiterService.Allow(player, key, capacity, refillPerSecond, cost)
    cost = cost or 1
    local bucket = getBucket(player, key, capacity)
    local now = os.clock()
    local elapsed = math.max(0, now - bucket.UpdatedAt)
    bucket.UpdatedAt = now
    bucket.Tokens = math.min(capacity, bucket.Tokens + elapsed * refillPerSecond)

    if bucket.Tokens < cost then
        return false
    end
    bucket.Tokens -= cost
    return true
end

Players.PlayerRemoving:Connect(function(player)
    buckets[player] = nil
end)

return RateLimiterService
