local MonsterConfig = require(script.Parent.MonsterConfig)

local definitions = {}
for enemyId, monster in MonsterConfig.All() do
    definitions[enemyId] = table.freeze({
        DisplayName = monster.DisplayName,
        MaxHealth = monster.MaxHealth,
        Reward = monster.Reward,
        RespawnSeconds = monster.RespawnTime,
        MonsterConfig = monster,
        AI = if monster.DetectionRange > 0
            then table.freeze({
                AggroRange = monster.DetectionRange,
                AttackRange = monster.AttackRange,
                AttackCooldown = monster.AttackCooldown,
                AttackWindup = monster.AttackWindup,
                MoveSpeed = monster.WalkSpeed,
                Damage = monster.Damage,
                DodgeChance = monster.DodgeChance,
                DodgeCooldown = monster.DodgeCooldown,
                DodgeDistance = monster.DodgeDistance,
                DodgePause = monster.DodgePause,
                LeashRange = monster.LeashRange,
                HitStun = monster.HitStun,
            })
            else nil,
    })
end

return table.freeze(definitions)
