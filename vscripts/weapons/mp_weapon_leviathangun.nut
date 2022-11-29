global function OnWeaponPrimaryAttack_leviathan
global function OnProjectileCollision_leviathan

struct
{
		float lastLevAnimCycleChosen = -1.0
		entity weapon
} file

int function FireGenericBoltWithDrop_New( entity weapon, WeaponPrimaryAttackParams attackParams, bool isPlayerFired )
{
	#if CLIENT
		if ( !weapon.ShouldPredictProjectiles() )
			return 1
	#endif // #if CLIENT

	weapon.EmitWeaponNpcSound( LOUD_WEAPON_AI_SOUND_RADIUS_MP, 0.2 )

	const float PROJ_SPEED_SCALE = 1
	const float PROJ_GRAVITY = 1
	int damageFlags = weapon.GetWeaponDamageFlags()
	WeaponFireBoltParams fireBoltParams
	fireBoltParams.pos = attackParams.pos
	fireBoltParams.dir = attackParams.dir
	fireBoltParams.speed = PROJ_SPEED_SCALE
	fireBoltParams.scriptTouchDamageType = damageFlags
	fireBoltParams.scriptExplosionDamageType = damageFlags
	fireBoltParams.clientPredicted = isPlayerFired
	fireBoltParams.additionalRandomSeed = 0
	entity bolt = weapon.FireWeaponBoltAndReturnEntity( fireBoltParams )
	if ( bolt != null )
	{
		 
		 // bolt.SetModel( $"mdl/Creatures/leviathan/leviathan_kingscanyon_animated.rmdl" )
		 // bolt.SetValueForModelKey( $"mdl/Creatures/leviathan/leviathan_kingscanyon_animated.rmdl" )
		 // bolt.kv.modelscale = 0.0050
		bolt.kv.gravity = PROJ_GRAVITY
		// bolt.kv.rendercolor = "0 0 0"
		// bolt.kv.renderamt = 0
		// bolt.kv.fadedist = 1
	}
	
	#if CLIENT
	Chroma_FiredWeapon( weapon )
	#endif


	return 1
}

var function OnWeaponPrimaryAttack_leviathan( entity weapon, WeaponPrimaryAttackParams attackParams)
{
	bool playerFired = true
	printt("Spawning Leviathan.")	
	file.weapon = weapon
	return FireGenericBoltWithDrop_New( weapon, attackParams, playerFired )
	// return 0
}


void function OnProjectileCollision_leviathan( entity projectile, vector pos, vector normal, entity hitEnt, int hitbox, bool isCritical )
{
	#if SERVER
	entity weapon = file.weapon
	
	
	// if (weapon.HasMod( "smallpets" )){
		
		printt("small levi pets")
		thread SmallLeviFollow(projectile)
	
	// } else if (weapon.HasMod( "smallroaming" )){
		
		// printt("small levi roaming")
		// thread SmallLeviRoaming(projectile)
		
	// } else {
		
		// printt("normal sized levi")
		// thread BigLeviPls(projectile)
	// }
	
	#endif
}
#if SERVER
void function BigLeviPls(entity projectile)
{
			
		
		vector origin = projectile.GetOrigin()
		entity owner = projectile.GetOwner()
			printt(owner)
		int team = owner.GetTeam()

		entity dummy = CreateFragDroneCan( team, origin, < 0, projectile.GetAngles().y, 0 > )
				SetSpawnOption_AISettings( dummy, "npc_frag_drone_throwable" )

		DispatchSpawn( dummy )
		
		vector ornull clampedPos = NavMesh_ClampPointForAIWithExtents( origin, dummy, < 20, 20, 36 > )
		if ( clampedPos != null )
				{
		expect vector( clampedPos )
		dummy.SetOrigin( clampedPos )
				}
		dummy.SetAngles( owner.GetAngles()*-1 )

		entity dummy2 = CreateEntity( "npc_dummie" )
		SetSpawnOption_AISettings( dummy2, "npc_leviathan" )
		dummy2.SetOrigin( dummy.GetOrigin() )
		dummy2.SetAngles( dummy.GetAngles() )
		DispatchSpawn( dummy2 )	
		dummy2.SetTitle("Levi")
		dummy2.SetParent(dummy)
		dummy.Hide()
				int followBehavior = GetDefaultNPCFollowBehavior( dummy )
								dummy.SetBossPlayer( owner )
					UpdateEnemyMemoryWithinRadius( dummy, 1000 )
		
		dummy.EnableNPCFlag( NPC_ALLOW_PATROL | NPC_ALLOW_INVESTIGATE )
			
		dummy.DisableBehavior( "Follow" )
}

void function SmallLeviRoaming(entity projectile)
{
	vector origin = projectile.GetOrigin()
	entity owner = gp()[0]
	int team = owner.GetTeam()

	entity dummy = CreateFragDroneCan( team, origin, < 0, projectile.GetAngles().y, 0 > )
			SetSpawnOption_AISettings( dummy, "npc_frag_drone_throwable" )

	DispatchSpawn( dummy )
	
	vector ornull clampedPos = NavMesh_ClampPointForAIWithExtents( origin, dummy, < 20, 20, 36 > )
		if ( clampedPos != null )
			{
	expect vector( clampedPos )
	dummy.SetOrigin( clampedPos )
			}
	dummy.SetAngles( owner.GetAngles()*-1 )
	
	entity dummy2 = CreateEntity( "npc_dummie" )
	SetSpawnOption_AISettings( dummy2, "npc_leviathan" )
	dummy2.SetOrigin( dummy.GetOrigin() )
	dummy2.SetAngles( dummy.GetAngles() )
	
	int random = RandomInt(2)
	
	if(random == 0)
	dummy2.kv.modelscale = 0.0045

	if(random == 1)
	dummy2.kv.modelscale = 0.0085

	if(random == 2)
	dummy2.kv.modelscale = 0.0100
	
	DispatchSpawn( dummy2 )	
	dummy2.SetTitle("Levi")
	dummy2.SetParent(dummy)
	dummy.Hide()
			int followBehavior = GetDefaultNPCFollowBehavior( dummy )
							dummy.SetBossPlayer( owner )
				UpdateEnemyMemoryWithinRadius( dummy, 500 )

			if ( IsSingleplayer() && IsAlive( owner ) )
			{
				dummy.InitFollowBehavior( owner, followBehavior )
				dummy.EnableBehavior( "Follow" )
			}
			else
			{
				dummy.EnableNPCFlag( NPC_ALLOW_PATROL | NPC_ALLOW_INVESTIGATE | NPC_NEW_ENEMY_FROM_SOUND )
			}
	thread WaitForEnemyNotification( dummy )
	thread LeviathanThink(dummy)
}

void function SmallLeviFollow(entity projectile)
{
	vector origin = projectile.GetOrigin()
	entity owner = gp()[0]
	int team = owner.GetTeam()

	// entity dummy = CreateFragDroneCan( team, origin, < 0, projectile.GetAngles().y, 0 > )
			// SetSpawnOption_AISettings( dummy, "npc_frag_drone_throwable" )

	// DispatchSpawn( dummy )
	
	// vector ornull clampedPos = NavMesh_ClampPointForAIWithExtents( origin, dummy, < 20, 20, 36 > )
		// if ( clampedPos != null )
			// {
	// expect vector( clampedPos )
	// dummy.SetOrigin( clampedPos )
			// }
	// dummy.SetAngles( owner.GetAngles()*-1 )
	
	entity dummy2 = CreateEntity( "npc_spider" )
	SetSpawnOption_AISettings( dummy2, "npc_spider" )
	 DispatchSpawn( dummy2 )
		vector ornull clampedPos = NavMesh_ClampPointForAIWithExtents( origin, dummy2, < 20, 20, 36 > )
		if ( clampedPos != null )
			{
	expect vector( clampedPos )
	dummy2.SetOrigin( clampedPos )
			} else {
				dummy2.SetOrigin( projectile.GetOrigin() )
			}
	dummy2.SetAngles( projectile.GetAngles() )
	


			 // int followBehavior = GetDefaultNPCFollowBehavior( dummy2 )
							 // dummy2.SetBossPlayer( owner )
			
				 // dummy2.InitFollowBehavior( owner, followBehavior )
				 // dummy2.EnableBehavior( "Follow" )
dummy2.DisableBehavior( "Follow" )
dummy2.DisableNPCFlag( NPC_ALLOW_PATROL | NPC_ALLOW_INVESTIGATE | NPC_NEW_ENEMY_FROM_SOUND )
dummy2.SetEnemyLKP( owner, owner.GetOrigin())

	// thread LeviathanThink(dummy)
}

void function WaitForEnemyNotification( entity drone )
{
	drone.EndSignal( "OnDeath" )

	entity owner
	entity currentTarget

	while ( true )
	{
		//----------------------------------
		// Get owner and current enemy
		//----------------------------------
		currentTarget = drone.GetEnemy()
		owner = drone.GetFollowTarget()

		//----------------------------------
		// Free roam if owner is dead or HasEnemy
		//----------------------------------
		if ( !IsAlive( owner ) || currentTarget != null )
		{
			drone.DisableBehavior( "Follow" )
		}
		else
		{
			drone.ClearEnemy()
			drone.EnableBehavior( "Follow" )
		}

		wait 0.25
	}

}


void function LeviathanThink( entity leviathan )
{
	leviathan.EndSignal( "OnDestroy" )

	OnThreadEnd(
		function () : ( leviathan )
		{
			if ( IsValid( leviathan ) )
			{
				leviathan.Destroy()
			}
		}
	)

	leviathan.Anim_Play( "ACT_IDLE"  )

	int count = 0
	int liftCount = RandomIntRange( 3, 10 )

	// Prevent rare bug where leviathan anims sync up
	const float CYCLE_BUFFER_DIST = 0.3
	Assert( CYCLE_BUFFER_DIST < 0.5, "Warning! Impossible to get second leviathan random animation cycle if cycle buffer distance is 0.5 or greater!" )

	float randCycle
	if ( file.lastLevAnimCycleChosen < 0 )
		randCycle = RandomFloat( 1.0 )
	else
	{
		// Get the range that remains when the full buffer range is subtracted, then roll within that range.
		// Add that roll to the buffer top end (last chosen val + buffer), use modulo to clamp within 0 - 1
		float randomRoll = RandomFloat( 1.0 - ( CYCLE_BUFFER_DIST * 2 ) )
		float adjustedRandCycle = ( file.lastLevAnimCycleChosen + CYCLE_BUFFER_DIST + randomRoll ) % 1.0
		randCycle = adjustedRandCycle
	}

	file.lastLevAnimCycleChosen = randCycle

	leviathan.SetCycle( randCycle )
	WaitForever()

	while ( 1 )
	{

		if ( count < liftCount )
		{
			if ( CoinFlip() )
				waitthread PlayAnim( leviathan, "lev_idle_lookup_noloop_kingscanyon_preview" )
			else
				waitthread PlayAnim( leviathan, "lev_idle_noloop_kingscanyon_preview_0" )
			count++
		}
		else
		{
			waitthread PlayAnim( leviathan, "lev_idle_lookup_noloop_kingscanyon_preview" )
			count = 0
			liftCount = RandomIntRange( 3, 10 )
		}
	}

}
#endif
