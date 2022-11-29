// global function OnProjectileCollision_weapon_grenade_cryonade
global function OnProjectileExplode_cryonade

#if SERVER
global function Cryonade_DamagedPlayerOrNPC
#endif

const asset FX_EMP_BODY_HUMAN 				= $"P_emp_body_human"
const asset FX_EMP_BODY_TITAN 				= $"P_emp_body_titan"
const float EMP_SEVERITY_SLOWTURN 				= 0.35
const float EMP_SEVERITY_SLOWMOVE 				= 0.50
const EMP_GRENADE_BEAM_EFFECT 				= $"wpn_arc_cannon_beam"

// void function OnProjectileCollision_weapon_grenade_cryonade( entity projectile, vector pos, vector normal, entity hitEnt, int hitbox, bool isCritical )
// {
	// entity player = projectile.GetOwner()
	// if ( hitEnt == player )
		// return

	// table collisionParams =
	// {
		// pos = pos,
		// normal = normal,
		// hitEnt = hitEnt,
		// hitbox = hitbox
	// }

	// bool result = PlantStickyEntity( projectile, collisionParams )

	// if ( projectile.GrenadeHasIgnited() )
		// return

	// projectile.GrenadeIgnite()

	// #if SERVER
		// thread ArcCookSound( projectile )
	// #endif
// }

// void function ArcCookSound( entity projectile )
// {
	// projectile.EndSignal( "OnDestroy" )

	// string cookSound = expect string( projectile.ProjectileGetWeaponInfoFileKeyField( "sound_cook_warning" ) )
	// float ignitionTime = expect float( projectile.ProjectileGetWeaponInfoFileKeyField( "grenade_ignition_time" ) )

	// float stickTime = 0.2
	// wait stickTime  // let it make a stick sound before alarm starts

	// EmitSoundOnEntity( projectile, cookSound )
// }

void function OnProjectileExplode_cryonade( entity projectile )
{
printt("exploded")	
}

#if SERVER
void function Cryonade_DamagedPlayerOrNPC( entity ent, var damageInfo )
{
	ActualCryonade_DamagedPlayerOrNPC( ent, damageInfo, FX_EMP_BODY_HUMAN, FX_EMP_BODY_TITAN, EMP_SEVERITY_SLOWTURN, EMP_SEVERITY_SLOWMOVE )
}

void function ActualCryonade_DamagedPlayerOrNPC( entity ent, var damageInfo, asset humanFx, asset titanFx, float slowTurn, float slowMove )
{
	if ( !IsValid( ent ) )
		return

	if ( DamageInfo_GetCustomDamageType( damageInfo ) & DF_DOOMED_HEALTH_LOSS )
		return

	entity inflictor = DamageInfo_GetInflictor( damageInfo )
	if ( !IsValid( inflictor ) )
		return
	
	if(!ent.IsPlayer() || !ent.IsNPC()) return
	
	entity marker = StartParticleEffectInWorld_ReturnEntity( GetParticleSystemIndex( $"P_melee_ice" ), ent.GetOrigin(), ent.GetAngles())
	StatusEffect_AddTimed( ent, eStatusEffect.move_slow, 0.2, 2, 1 )

	// // Do electrical effect on this ent that everyone can see if they are a titan
	// string tag = ""
	// asset effect

	// if ( IsPilot( ent ) )
	// {
		// tag = "CHESTFOCUS"
		// effect = humanFx
	// }

	// ent.Signal( "ArcStunned" )

	// if ( tag != "" )
	// {
		// Assert( inflictor == DamageInfo_GetInflictor( damageInfo ) )
		// Assert( !(inflictor instanceof CEnvExplosion) )
		// if ( IsValid( inflictor ) )
		// {
			// float duration = EMP_GRENADE_PILOT_SCREEN_EFFECTS_DURATION_MAX
			// if ( inflictor instanceof CBaseGrenade )
			// {
				// vector entCenter   = ent.GetWorldSpaceCenter()
				// float dist         = Distance( DamageInfo_GetDamagePosition( damageInfo ), entCenter )
				// float damageRadius = inflictor.GetDamageRadius()
				// duration = GraphCapped( dist, damageRadius * 0.5, damageRadius, EMP_GRENADE_PILOT_SCREEN_EFFECTS_DURATION_MIN, EMP_GRENADE_PILOT_SCREEN_EFFECTS_DURATION_MAX )
			// }
			// thread EMP_FX( effect, ent, tag, duration )
		// }
	// }

	// if ( StatusEffect_GetSeverity( ent, eStatusEffect.destroyed_by_emp ) )
		// DamageInfo_SetDamage( damageInfo, ent.GetHealth() )

	// // Don't do arc beams to entities that are on the same team... except the owner or if the damage type is specified to ignore friendly fire protection.
	// entity attacker = DamageInfo_GetAttacker( damageInfo )
	// if ( IsValid( attacker ) && IsFriendlyTeam( attacker.GetTeam(), ent.GetTeam() ) && (attacker != ent) && !DamageIgnoresFriendlyFire( damageInfo ) )
		// return

	// if ( ent.IsPlayer() )
	// {
		// thread CryonadeGrenade_EffectsPlayer( ent, damageInfo )
	// }
}

void function CryonadeGrenade_EffectsPlayer( entity player, var damageInfo )
{
	player.Signal( "OnEMPPilotHit" )
	player.EndSignal( "OnEMPPilotHit" )

	if ( player.IsPhaseShifted() )
		return

	entity inflictor   = DamageInfo_GetInflictor( damageInfo )
	float dist         = Distance( DamageInfo_GetDamagePosition( damageInfo ), player.GetWorldSpaceCenter() )
	float damageRadius = 128
	if ( inflictor instanceof CBaseGrenade )
		damageRadius = inflictor.GetDamageRadius()
	float frac            = GraphCapped( dist, damageRadius * 0.5, damageRadius, 1.0, 0.0 )
	float strength        = EMP_GRENADE_PILOT_SCREEN_EFFECTS_MIN + ((EMP_GRENADE_PILOT_SCREEN_EFFECTS_MAX - EMP_GRENADE_PILOT_SCREEN_EFFECTS_MIN) * frac)
	float fadeoutDuration = EMP_GRENADE_PILOT_SCREEN_EFFECTS_FADE * frac
	float duration        = EMP_GRENADE_PILOT_SCREEN_EFFECTS_DURATION_MIN + ((EMP_GRENADE_PILOT_SCREEN_EFFECTS_DURATION_MAX - EMP_GRENADE_PILOT_SCREEN_EFFECTS_DURATION_MIN) * frac) - fadeoutDuration
	//vector origin = inflictor.GetOrigin()

	int dmgSource = DamageInfo_GetDamageSourceIdentifier( damageInfo )

	if ( IsCloaked( player ) )
				player.SetCloakFlicker( 0.5, duration )

	StatusEffect_AddTimed( player, eStatusEffect.emp, strength, duration, fadeoutDuration )
	GiveEMPStunStatusEffects( player, (duration + fadeoutDuration), fadeoutDuration )

	EmitSoundOnEntityOnlyToPlayer( player, player, "Arcstar_visualimpair" )
}
#endif