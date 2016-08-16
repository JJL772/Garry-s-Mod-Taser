
AddCSLuaFile()

SWEP.ViewModel = Model( "models/weapons/v_pistol.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_pistol.mdl" )

SWEP.Author                 = "JJl77"
SWEP.Contact                = "Steam"
SWEP.Purpose                = "Use to temporarily disable enemies"

SWEP.Primary.ClipSize		= 1
SWEP.Primary.DefaultClip	= 256
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "256"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo			= "none"

SWEP.Category =             "JJ's SWEPs"

SWEP.PrintName	= "Taser"

SWEP.Slot		= 5
SWEP.SlotPos	= 1
SWEP.Base = "weapon_base"
SWEP.DrawAmmo		= false
SWEP.DrawCrosshair	= true
SWEP.Spawnable		= true

SWEP.ShootSound = Sound( "weapons/taser.wav" )

/* Creates the convars and sets their default value */
CreateConVar("sv_taser_dmg", "0", 0, "Determines how much damage the taser will do to players")
CreateConVar("sv_taser_duration", "15", 0, "The duration of the taser's effects. Default: 15 seconds")
CreateConVar("sv_taser_distance", "256", 0, "The effective distance the taser can be used at. Default: 256 units (16 feet)")
CreateConVar("sv_taser_firerate", "5", 0, "How long the player has to wait until the taser can be used again. Default: 5 seconds")
CreateConVar("cl_taser_sparksize", "2", FCVAR_CLIENTDLL, "How large the sparks produced by the taser are. Default: 2")
CreateConVar("sv_taser_screen_fade", "1", FCVAR_REPLICATED, "Determines if the screen will fade when a player gets tased. Default: true")

/* Gets the convars */
local duration = GetConVar("sv_taser_duration"):GetInt()
local dmg = GetConVar("sv_taser_dmg"):GetInt()
local tased = false
local taser_distance = GetConVar("sv_taser_distance"):GetInt()
local taser_firerate = GetConVar("sv_taser_firerate"):GetInt()
local screenfade = GetConVar("sv_taser_screen_fade"):GetBool()

function SWEP:PrimaryAttack()
    if CLIENT then
        local trace = self.Owner:GetEyeTrace()
        local distance = GetConVar("sv_taser_distance"):GetInt()
        local sparksize = GetConVar("cl_taser_sparksize"):GetInt()
        if(IsFirstTimePredicted())then
            if(trace.StartPos:Distance(trace.HitPos) > taser_distance) then return end
            /* Used to draw the effects */
            local data = EffectData()
            data:SetOrigin(trace.HitPos)
            data:SetNormal(trace.HitNormal)
            data:SetMagnitude(1.3)
            data:SetScale(sparksize)
            data:SetRadius(1.2)
            util.Effect("Sparks", data)
        end
    end

    /* Prevent the client from executing any more code */
    if CLIENT then return end
    self:SetNextPrimaryFire(CurTime() + taser_firerate)
    /* Emit the shooting sound */
    self.Owner:EmitSound(Sound("weapons/taser.wav"))

    /* Play the animations... */
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.Owner:SetAnimation(PLAYER_ATTACK1)

    /* To get the entity, we need to do an eye trace */
    local trace = self.Owner:GetEyeTrace()
    local ent = trace.Entity

    /* We don't want these entities to be used */
    if ent:IsWorld() then return end

    local dist = trace.StartPos:Distance(trace.HitPos)
    if ent:IsNPC() then
        /* Basic NPC support, its still very clunky and is very basic */
        if ent:GetNWBool("IsBeingTased!") then return end
        if dist > taser_distance then return end
        ent:SetNWBool("IsBeingTased!", true)
        local weapon = ent:GetActiveWeapon()
        ent:TakeDamage(dmg, self.Owner, self)
        weapon:SetNextPrimaryFire(CurTime() + duration)
        local ragdoll = ents.Create("prop_ragdoll")
        ragdoll:SetPos(ent:GetPos())
        ragdoll:SetAngles(ent:GetAngles())
        ragdoll:SetModel(ent:GetModel())
        ragdoll:SetVelocity(ent:GetVelocity())
        ragdoll:Spawn()
        ragdoll:Activate()
        ent:SetParent(ragdoll)
        ent:SetNoDraw(true)
        timer.Simple(duration, function()
            ent:SetParent()
            ent:Spawn()
            local pos = ragdoll:GetPos()
            pos.z = pos.z + 10
            ent:SetPos(pos)
            ragdoll:Remove()
            weapon:SetNextPrimaryFire(CurTime())
            ent:SetNoDraw(false)
            ent:SetNWBool("IsBeingTased!", false)
        end)
    end

    if ent:IsNPC() then return end

    if ent:IsPlayer() || ent:IsBot() then
        if ent:GetNWBool("IsBeingTased!") then return end
        if dist >  taser_distance then return end

        local weapon = ent:GetActiveWeapon()

        /* This tells us if the player is already being tased */
        ent:SetNWBool("IsBeingTased!", true)

        /* Adds some more fun stuff ;) */
        ent:ViewPunch( Angle(-10, 0, 0))

        ent:PrintMessage(HUD_PRINTTALK, "You have been tased, you will be disabled temporarily")

        /* Apply damage from the taser (if enabled) */
        ent:TakeDamage(dmg, self.Owner, self)

        /* In reality, you'd drop your weapon when you get tased */
        ent:DropWeapon(ent:GetActiveWeapon())

        /* This will ensure the player can't shoot their weapon when they're tased */
        weapon:SetNextPrimaryFire(CurTime() + duration)

        /* Cosmetic-ish effects */
        ent:EmitSound(Sound("player/pl_pain" .. math.random(5, 7) .. ".wav"))

        /* So they can't see their viewmodel */
        ent:DrawViewModel(false)

        /* Create the ragdoll and set the properties */
        local ragdoll = ents.Create("prop_ragdoll")
        ragdoll:SetPos(ent:GetPos())
        ragdoll:SetAngles(ent:GetAngles())
        ragdoll:SetModel(ent:GetModel())
        ragdoll:SetVelocity(ent:GetVelocity())
        ragdoll:Spawn()
        ragdoll:Activate()

        /* This is so the player will be in the same place as the ragdoll */
        ent:SetParent(ragdoll)

        /* There are some problems with dropping weapons that can cause some unsightly
        visuals so fade the screen to hide them */
        ent:ScreenFade(SCREENFADE.IN, Color(230, 230, 230), 0.7, 1.4)

        /* Spectate mode allows the player to see themselves in third person */
        ent:Spectate(OBS_MODE_CHASE)
        ent:SpectateEntity(ragdoll)

        if timer.Exists("TaserTimer") then timer.Destroy("TaserTimer") end
        timer.Simple(duration, function()

            /* Unspectate so they can function normally again */
            ent:UnSpectate()
            ent:SetParent()

            /* Forces the player to spawn */
            ent:Spawn()

            local pos = ragdoll:GetPos()

            /* Add 10 to the z coord so we dont end up in the ground */
            pos.z = pos.z + 10
            ent:SetPos(pos)

            /* Remove the ragdoll */
            ragdoll:Remove()

            /* Allow the viewmodel to be drawn */
            ent:DrawViewModel(true)

            /* Allow them to fire again */
            weapon:SetNextPrimaryFire(CurTime())

            /* So we know that we aren't tased later on */
            ent:SetNWBool("IsBeingTased!", false)
        end)
    end
end
