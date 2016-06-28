
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

/* Gets the convars */
local duration = GetConVar("sv_taser_duration"):GetInt()
local dmg = GetConVar("sv_taser_dmg"):GetInt()
local tased = false

function SWEP:PrimaryAttack()
    if CLIENT then
        local trace = self.Owner:GetEyeTrace()
        if(IsFirstTimePredicted())then
            /* Used to draw the effects */
            local data = EffectData()
            data:SetOrigin(trace.HitPos)
            data:SetNormal(trace.HitNormal)
            data:SetMagnitude(1)
            data:SetScale(1)
            data:SetRadius(1)
            util.Effect("Sparks", data)
        end
    end

    /* Prevent the client from executing any more code */
    if CLIENT then return end
    self:SetNextPrimaryFire(CurTime() + 5)

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
    if ent:IsNPC() then return end

    local dist = trace.StartPos:Distance(trace.HitPos)
    if ent:IsPlayer() || ent:IsBot() then
        if ent:GetNWBool("IsBeingTased!") then return end
        if dist > 130 then return end

        /* This tells us if the player is already being tased */
        ent:SetNWBool("IsBeingTased!", true)

        ent:ViewPunch( Angle(-10, 0, 0))

        /* Used to create the ragdoll
        Note: This dosn't actually create a real ragdoll, the player will still be
        there, just not as a ragdoll */
        ent:CreateRagdoll()

        /* This is used to hide the player */
        ent:SetNoDraw(true)

        /* Freeze the player so they can't hit people while invisible */
        ent:Freeze(true)

        /* Apply damage from the taser (if enabled) */
        ent:TakeDamage(dmg, self.Owner, self)

        /* Get the ragdoll entity */
        local ragdoll = ent:GetRagdollEntity()

        if timer.Exists("TaserTimer") then timer.Destroy("TaserTimer") end
        timer.Simple(duration, function()
            /* Basically just remove everything we did to the player */
            ragdoll:Remove()
            ent:SetNoDraw(false)
            ent:Freeze(false)
            /* So we know that we aren't tased later on */
            ent:SetNWBool("IsBeingTased!", false)
        end)
    end
end
