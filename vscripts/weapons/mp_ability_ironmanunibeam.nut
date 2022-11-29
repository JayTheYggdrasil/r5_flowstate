global function OnWeaponPrimaryAttack_Unibeam

bool function CanFire_Unibeam( entity weapon )
{
	#if SERVER
	entity player = weapon.GetOwner()
	//ApplyFX($"P_wpn_defender_charge", player)
	#endif
	
	if ( weapon.GetWeaponChargeFraction() < 1.0 )
	{		
		#if SERVER
		//entity player = weapon.GetOwner()
		
	
		//entity smokeTrailFX = StartParticleEffectOnEntityWithPos_ReturnEntity( player, GetParticleSystemIndex( $"P_wpn_defender_charge"), FX_PATTACH_ABSORIGIN_FOLLOW, player.LookupAttachment( "CHESTFOCUS" ), <0,0,0>, VectorToAngles( <0,0,-1> ) )
		//StartParticleEffectOnEntity( player, GetParticleSystemIndex( $"P_wpn_defender_charge"), FX_PATTACH_ABSORIGIN_FOLLOW, -1 )
		// EffectSetControlPointVector( smokeTrailFX, 1, <255,255,255> )
        // player.p.DEV_lastDroppedSurvivalWeaponProp = smokeTrailFX
		#endif
		return false}

	return true
}

var function OnWeaponPrimaryAttack_Unibeam( entity weapon, WeaponPrimaryAttackParams attackParams )
//By Colombia
{
	if ( !CanFire_Unibeam( weapon ) )
		return 0
		
	weapon.FireWeaponBullet( attackParams.pos + <0, 0, -40>, attackParams.dir, 1, weapon.GetWeaponDamageFlags() )
	
	#if SERVER
	entity player = weapon.GetOwner()
	StatusEffect_AddTimed( player, eStatusEffect.sonar_pulse_visuals, 1 , 3, 5 )
	//player.p.DEV_lastDroppedSurvivalWeaponProp.Destroy()
	#endif
	
	return weapon.GetWeaponSettingInt( eWeaponVar.ammo_min_to_fire )
}

