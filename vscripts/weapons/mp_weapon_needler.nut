//By Retículo Endoplasmático#5955 (CaféDeColombiaFPS)

untyped

global function MpWeaponNeedler_Init
global function OnWeaponActivate_needler
global function OnWeaponDeactivate_needler
global function OnWeaponPrimaryAttack_needler
global function OnWeaponBulletHit_needler
// global function OnWeaponStartZoomIn_needler
// global function OnWeaponStartZoomOut_needler
global function OnProjectileCollision_needler

//Basic weapon stats
const float NEEDLER_DAMAGE = 6
const float NEEDLER_TIMETOEXPLODE = 2.3

//Custom particles
const asset NEEDLER_CUSTOMTRAIL = $"P_skydive_trail_CP"
const asset NEEDLER_EFFECTONEXPLODE = $"P_impact_exp_xo_shield_med_CP"
const asset NEEDLER_EFFECTONEXPLODE2 = $"P_plasma_exp_SM"


const AXE_FX_ATTACK_SWIPE_FP = $"P_wpn_bhaxe_swipe_FP"
const AXE_FX_ATTACK_SWIPE_3P = $"P_wpn_bhaxe_swipe_3P"

const asset KUNAI_FX_GLOW_FP = $"P_kunai_idle_FP"
const asset KUNAI_FX_GLOW_3P = $"P_kunai_idle_3P"

function MpWeaponNeedler_Init()
{
	PrecacheParticleSystem( NEEDLER_EFFECTONEXPLODE )
	PrecacheParticleSystem( NEEDLER_CUSTOMTRAIL )
	PrecacheParticleSystem( NEEDLER_EFFECTONEXPLODE2 )
	
	PrecacheParticleSystem( AXE_FX_ATTACK_SWIPE_FP ) 
	PrecacheParticleSystem( AXE_FX_ATTACK_SWIPE_3P ) 
	PrecacheParticleSystem( KUNAI_FX_GLOW_FP ) 
	PrecacheParticleSystem( KUNAI_FX_GLOW_3P ) 
	
	PrecacheParticleSystem( $"P_smartpistol_lockon_FP" )
	//PrecacheParticleSystem( $"wpn_arc_cannon_electricity_fp" )
	//PrecacheParticleSystem( $"wpn_arc_cannon_electricity" )
	PrecacheParticleSystem( $"wpn_mflash_snp_hmn_smoke_side" )
	PrecacheParticleSystem( $"wpn_mflash_snp_hmn_smoke_side_FP" )
	PrecacheParticleSystem( $"xo_spark_med" )
	PrecacheParticleSystem( $"P_smartpistol_lockon" )
	PrecacheParticleSystem( $"P_wat_hand_elec_CP" )
	PrecacheModel($"mdl/currency/crafting/currency_crafting_epic.rmdl")
}


#if SERVER || CLIENT
struct {
	bool onetime = false
	entity weapon
	entity lastent
	entity owner
} file
#endif 

void function OnWeaponActivate_needler( entity weapon )
{
	file.owner = weapon.GetWeaponOwner()
	
	weapon.PlayWeaponEffect( $"P_wat_hand_elec_CP" , $"P_wat_hand_elec_CP", "shell" )

	if ( !( "initialized" in weapon.s ) )
	{
		weapon.s.damageValue <- weapon.GetWeaponInfoFileKeyField( "damage_near_value" )
		SmartAmmo_SetAllowUnlockedFiring( weapon, true )
		SmartAmmo_SetUnlockAfterBurst( weapon, (SMART_AMMO_PLAYER_MAX_LOCKS > 1) )
		SmartAmmo_SetWarningIndicatorDelay( weapon, 0.0 )

		weapon.s.initialized <- true

#if SERVER
		weapon.s.lockStartTime <- Time()
		weapon.s.locking <- true
#endif
	}

#if SERVER
	weapon.s.locking = true
	weapon.s.lockStartTime = Time()
	
#endif
}

void function OnWeaponDeactivate_needler( entity weapon )
{
	weapon.StopWeaponEffect( $"P_smartpistol_lockon_FP", $"P_smartpistol_lockon" )
}

var function OnWeaponPrimaryAttack_needler( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	int damageFlags = weapon.GetWeaponDamageFlags()
	file.weapon = weapon

	//return SmartAmmo_FireWeapon( weapon, attackParams, damageFlags, damageFlags )
	return SmartAmmo_FireNeedler( weapon, attackParams, damageFlags, damageFlags )
}

void function OnWeaponBulletHit_needler( entity weapon, WeaponBulletHitParams hitParams )
{
	#if SERVER
	entity hitEnt = hitParams.hitEnt
	
    #endif
}

void function OnProjectileCollision_needler( entity projectile, vector pos, vector normal, entity hitEnt, int hitbox, bool isCritical )
//By Retículo Endoplasmático#5955 (CaféDeColombiaFPS)
{
	#if SERVER
	if(hitEnt.IsNPC()){
		hitEnt.ai.needles++
		printt("saving needle for ai - Total needles: " + hitEnt.ai.needles)
		
		if(CoinFlip()){
		entity model = CreatePropDynamic( $"mdl/currency/crafting/currency_crafting_epic.rmdl", hitEnt.GetOrigin(), <RandomIntRangeInclusive(-180,180), RandomIntRangeInclusive(-180,180), RandomIntRangeInclusive(-180,180)> )
		
		model.SetParent(hitEnt, "CHESTFOCUS")
		model.kv.modelscale = RandomFloatRange(0.6,0.8)
		model.SetOrigin(model.GetOrigin() + <RandomIntRangeInclusive(-5,5), RandomIntRangeInclusive(-5,5), RandomIntRangeInclusive(-20,10)>)
		hitEnt.ai.proplist.append(model)}
		
	} else if (hitEnt.IsPlayer())
	{
		hitEnt.p.needles++
		printt("saving needle for player - Total needles: " + hitEnt.ai.needles)	
	}
	#endif
	
	#if CLIENT
	if(hitEnt.IsNPC()){
		hitEnt.ai.needles++
		printt("saving needle for ai - Total needles: " + hitEnt.ai.needles)
	} else if (hitEnt.IsPlayer())
	{
		hitEnt.p.needles++
		printt("saving needle for player - Total needles: " + hitEnt.ai.needles)	
	}
	#endif
	
	#if SERVER || CLIENT
	thread delayeddamage(hitEnt)	
	#endif

}


void function delayeddamage(entity hitEnt)
//By Retículo Endoplasmático#5955 (CaféDeColombiaFPS)
{

	float damagetodeal

	if(hitEnt.IsNPC() && hitEnt.ai.ongoingneedlesexplode){
		return
	} else if (hitEnt.IsPlayer() && hitEnt.p.ongoingneedlesexplode)
	{
		return
	}

	if(hitEnt.IsNPC()){
		hitEnt.ai.ongoingneedlesexplode = true
			#if SERVER 
			// local colorVec = Vector( 238, 255, 0 )
			// entity cpoint = CreateEntity( "info_placement_helper" )
			// SetTargetName( cpoint, UniqueString( "pickup_controlpoint" ) )
			// DispatchSpawn( cpoint )
			// cpoint.SetOrigin( colorVec )
			// entity glowFX = PlayFXWithControlPoint( $"P_ar_titan_droppoint", hitEnt.GetOrigin(), cpoint, -1, null, null, C_PLAYFX_LOOP )
			
			entity env_sprite = CreateEntity( "env_sprite" )
			env_sprite.SetScriptName( UniqueString( "molotov_sprite" ) )
			env_sprite.kv.rendermode = 5
			env_sprite.kv.origin = hitEnt.GetOrigin()
			env_sprite.kv.angles = <0, 0, 0>
			env_sprite.kv.fadedist = -1
			env_sprite.kv.rendercolor = "97 50 168"
			env_sprite.kv.renderamt = 255
			env_sprite.kv.framerate = "10.0"
			env_sprite.SetValueForModelKey( $"sprites/glow_05.vmt" )
			env_sprite.kv.scale = string( 0.17 )
			env_sprite.kv.spawnflags = 1
			env_sprite.kv.GlowProxySize = 15.0
			env_sprite.kv.HDRColorScale = 15.0
			DispatchSpawn( env_sprite )
			
			env_sprite.SetParent(hitEnt, "CHESTFOCUS")
			hitEnt.ai.particleonbody = env_sprite
			#endif
			
	} else if (hitEnt.IsPlayer())
	{
		hitEnt.p.ongoingneedlesexplode = true
			#if SERVER 
			entity env_sprite = CreateEntity( "env_sprite" )
			env_sprite.SetScriptName( UniqueString( "molotov_sprite" ) )
			env_sprite.kv.rendermode = 5
			env_sprite.kv.origin = hitEnt.GetOrigin()
			env_sprite.kv.angles = <0, 0, 0>
			env_sprite.kv.fadedist = -1
			env_sprite.kv.rendercolor = "97 50 168"
			env_sprite.kv.renderamt = 255
			env_sprite.kv.framerate = "10.0"
			env_sprite.SetValueForModelKey( $"sprites/glow_05.vmt" )
			env_sprite.kv.scale = string( 0.17 )
			env_sprite.kv.spawnflags = 1
			env_sprite.kv.GlowProxySize = 15.0
			env_sprite.kv.HDRColorScale = 15.0
			DispatchSpawn( env_sprite )
			
			env_sprite.SetParent(hitEnt, "CHESTFOCUS")
			hitEnt.p.particleonbody = env_sprite
			#endif
	}
	
	wait NEEDLER_TIMETOEXPLODE

	if(!IsValid(hitEnt)) return
	
	if(hitEnt.IsNPC()){
		damagetodeal = hitEnt.ai.needles*NEEDLER_DAMAGE

		#if SERVER 
		EmitSoundOnEntity( hitEnt, "spectre_arm_explode" )

		hitEnt.TakeDamage( damagetodeal, file.owner, null, { scriptType = DF_BYPASS_SHIELD | DF_DOOMED_HEALTH_LOSS, damageSourceId = eDamageSourceId.deathField } )
		
		// for(int i=0; i<4; i++){
			
		// int bodyFX = GetParticleSystemIndex( NEEDLER_EFFECTONEXPLODE )
		// int attachID = hitEnt.LookupAttachment( "ref" ) // TEMP
		// int trailFXHandle = StartParticleEffectOnEntity( hitEnt, bodyFX, FX_PATTACH_POINT_FOLLOW, attachID )
		
		//EffectSetControlPointVector( trail, 1, color )
		
		entity trailFXHandle = StartParticleEffectInWorld_ReturnEntity(GetParticleSystemIndex( NEEDLER_EFFECTONEXPLODE ), hitEnt.GetOrigin(), <RandomIntRangeInclusive(-180,180), RandomIntRangeInclusive(-180,180), RandomIntRangeInclusive(-180,180)>)
		trailFXHandle.SetParent(hitEnt, "CHESTFOCUS")
		trailFXHandle.SetOrigin(trailFXHandle.GetOrigin() + <RandomIntRangeInclusive(-5,5), RandomIntRangeInclusive(-5,5), RandomIntRangeInclusive(-20,10)>)
		trailFXHandle.SetAngles(<RandomIntRangeInclusive(-180,180), RandomIntRangeInclusive(-180,180), RandomIntRangeInclusive(-180,180)>)
		EffectSetControlPointVector( trailFXHandle, 1, <97, 50, 168> )
		
		entity trailFXHandle2 = StartParticleEffectInWorld_ReturnEntity(GetParticleSystemIndex( NEEDLER_EFFECTONEXPLODE2 ), hitEnt.GetOrigin(), <RandomIntRangeInclusive(-180,180), RandomIntRangeInclusive(-180,180), RandomIntRangeInclusive(-180,180)>)
		trailFXHandle2.SetParent(hitEnt, "CHESTFOCUS")
		trailFXHandle2.SetOrigin(trailFXHandle.GetOrigin() + <RandomIntRangeInclusive(-5,5), RandomIntRangeInclusive(-5,5), RandomIntRangeInclusive(-20,10)>)
		trailFXHandle2.SetAngles(<RandomIntRangeInclusive(-180,180), RandomIntRangeInclusive(-180,180), RandomIntRangeInclusive(-180,180)>)
		EffectSetControlPointVector( trailFXHandle2, 1, <97, 50, 168> )
		// }
		
		if(IsValid(hitEnt.ai.particleonbody)) hitEnt.ai.particleonbody.Destroy()
		
		foreach(needle in hitEnt.ai.proplist){
				if(IsValid(needle))needle.Destroy()}
		
		#endif
		printt("dealing delayed damage ai - Total damage: " + damagetodeal)
		hitEnt.ai.needles = 0
		

	} else if (hitEnt.IsPlayer())
	{
		damagetodeal = hitEnt.p.needles*NEEDLER_DAMAGE

		#if SERVER 
		hitEnt.TakeDamage( damagetodeal, file.owner, null, { scriptType = DF_BYPASS_SHIELD | DF_DOOMED_HEALTH_LOSS, damageSourceId = eDamageSourceId.deathField } )
				
		// for(int i=0; i<4; i++){
		entity trailFXHandle = StartParticleEffectInWorld_ReturnEntity(GetParticleSystemIndex( NEEDLER_EFFECTONEXPLODE ), hitEnt.GetOrigin(), <RandomIntRangeInclusive(-180,180), RandomIntRangeInclusive(-180,180), RandomIntRangeInclusive(-180,180)>)
		trailFXHandle.SetParent(hitEnt, "CHESTFOCUS")
		trailFXHandle.SetOrigin(trailFXHandle.GetOrigin() + <RandomIntRangeInclusive(-5,5), RandomIntRangeInclusive(-5,5), RandomIntRangeInclusive(-20,10)>)
		trailFXHandle.SetAngles(<RandomIntRangeInclusive(-180,180), RandomIntRangeInclusive(-180,180), RandomIntRangeInclusive(-180,180)>)
		// }
		
		if(IsValid(hitEnt.p.particleonbody)) hitEnt.p.particleonbody.Destroy()
		
		foreach(needle in hitEnt.p.proplist){
				if(IsValid(needle))needle.Destroy()}
		
		#endif
		printt("dealing delayed damage player - Total damage: " + damagetodeal)
		hitEnt.p.needles = 0
	}
	

	if(hitEnt.IsNPC()){
		hitEnt.ai.ongoingneedlesexplode = false
	} else if (hitEnt.IsPlayer())
	{
		hitEnt.p.ongoingneedlesexplode = false
	}
}

// void function ArcCannon_Start( entity weapon )
// {
	// if ( !IsPilot( weapon.GetWeaponOwner() ) )
	// {
		// weapon.PlayWeaponEffectNoCull( $"wpn_arc_cannon_electricity_fp", $"wpn_arc_cannon_electricity", "muzzle_flash" )
		// weapon.EmitWeaponSound( "arc_cannon_charged_loop" )
	// }
	// else
	// {
		// weapon.EmitWeaponSound_1p3p( "Arc_Rifle_charged_Loop_1P", "Arc_Rifle_charged_Loop_3P" )
	// }
// }

// void function OnWeaponStartZoomIn_needler( entity weapon )
// {

	// if ( !weapon.HasMod( "ads_smaller_lock_on" ) )
	// {
		// array<string> mods = weapon.GetMods()
		// mods.append( "ads_smaller_lock_on" )
		// weapon.SetMods( mods )
	// }
// }

// void function OnWeaponStartZoomOut_needler( entity weapon )
// {
	// if ( weapon.HasMod( "ads_smaller_lock_on" ) )
	// {
		// array<string> mods = weapon.GetMods()
		// mods.fastremovebyvalue( "ads_smaller_lock_on" )
		// weapon.SetMods( mods )
	// }

// }