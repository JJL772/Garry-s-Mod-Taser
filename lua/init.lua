
/* As much as I don't want to... */
resource.AddFile("sound/weapons/taser.wav")

function CleanUpTaserCrap(victim, inflictor, attacker)
    victim:SetNWBool("IsBeingTased!", false)
end
hook.Add("PlayerDeath", "FJFJFJFFJFJFJ", CleanUpTaserCrap)

function InitTaserCrap(ply)
    ply:SetNWBool("IsBeingTased!", false)
end
hook.Add("PlayerInitialSpawn", "LDLLSLDLSLD", InitTaserCrap)
