global function OnProjectileCollision_jumppadsweapon

const float JUMP_PAD_ANGLE_LIMIT = 0.70

void function OnProjectileCollision_jumppadsweapon( entity projectile, vector pos, vector normal, entity hitEnt, int hitbox, bool isCritical )
{
	#if SERVER
	thread OnJumpPadPlanted(projectile, normal, hitEnt)
	#endif
}

#if SERVER
int i = 0
void function OnJumpPadPlanted( entity projectile, vector normal, entity hitEnt )
{
	i++
	printt(i)
	string gameMode = GameRules_GetGameMode()
	entity owner = projectile.GetOwner()

	if( !IsValid( owner ) )
	{
		projectile.Destroy()
		return
	}

	vector origin = projectile.GetOrigin()

	vector forward = AnglesToForward( projectile.proj.savedAngles )
	vector surfaceAngles = AnglesOnSurface( normal, forward )

	entity oldParent = projectile.GetParent()
	projectile.ClearParent()

	origin = projectile.GetOrigin()
	asset model = $"mdl/props/octane_jump_pad/octane_jump_pad.rmdl"
	
	//Use NoDispatchSpawn so that we can setup the entity before spawning it in the game world
	entity newProjectile = CreatePropDynamic_NoDispatchSpawn( model, origin, surfaceAngles, SOLID_VPHYSICS )

	newProjectile.RemoveFromAllRealms()
	newProjectile.AddToOtherEntitysRealms( projectile )
	projectile.Destroy()
	newProjectile.kv.solid = 6
	newProjectile.kv.fadedist = 30000
	newProjectile.SetTakeDamageType( DAMAGE_NO )			
	newProjectile.SetOwner( owner )

	//Dispatch the spawn after our settings are done
	DispatchSpawn( newProjectile )
	newProjectile.EndSignal( "OnDestroy" )

	EmitSoundOnEntity( newProjectile, "JumpPad_Deploy_Unpack" )
	thread PlayAnim( newProjectile, "prop_octane_jump_pad_deploy")

	JumpPadsWeaponJumppad_CreatedCallback( newProjectile )
}
#endif