global function OnProjectileCollision_ziplinesweapon

void function OnProjectileCollision_ziplinesweapon( entity projectile, vector pos, vector normal, entity hitEnt, int hitbox, bool isCritical )
{
	#if SERVER
	vector startPos = gp()[0].GetOrigin()
	vector endPos = projectile.GetOrigin()
	bool pathfinder_model = true
	bool lifeline_rope = false
	string selected_cable_mat
    const asset PATHFINDER_ZIP_MODEL = $"mdl/props/pathfinder_zipline/pathfinder_zipline.rmdl"

    if(!lifeline_rope) 
    { selected_cable_mat = "cable/zipline.vmt" } else 
    { selected_cable_mat = "models/cable/drone_medic_cable" }

    // define zipline entities
    entity zipline_start = CreateEntity( "zipline" )
	entity ent_model_start 
    entity zipline_end = CreateEntity( "zipline_end" )
	entity ent_model_end

    // set zipline properties
    zipline_start.kv.Material = selected_cable_mat
    zipline_start.kv.ZiplineAutoDetachDistance = "160"
	zipline_end.kv.ZiplineAutoDetachDistance = "160"

    // check if pathfinder model is needed
    if (!pathfinder_model)
    {
        zipline_start.SetOrigin( startPos ) ; zipline_end.SetOrigin( endPos ) // set zipline start and end positions
    } else{
        ent_model_start = CreateFRProp( PATHFINDER_ZIP_MODEL, startPos, <0,0,0>, true, 50000) // create pathfinder models
		zipline_start.SetParent( ent_model_start, "ATTACH_TOP_ROPE", false, 0.0 )
        ent_model_end = CreateFRProp( PATHFINDER_ZIP_MODEL, endPos, AnglesOnSurface(normal, -AnglesToRight(gp()[0].EyeAngles())), true, 50000)
		zipline_end.SetParent( ent_model_end, "ATTACH_TOP_ROPE", false, 0.0 )
    }
	ent_model_start.Anim_PlayOnly( "prop_pathfinder_zipline_release" )
	EmitSoundOnEntity( ent_model_start, "pathfinder_zipline_expand" )
	
    zipline_start.LinkToEnt( zipline_end ) // linking the zipline entities
	zipline_start.Zipline_WakeUp()
    DispatchSpawn( zipline_start )
	DispatchSpawn( zipline_end )
	ent_model_end.SetParent(hitEnt)
	projectile.Destroy()
	#endif
}