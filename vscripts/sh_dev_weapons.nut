//

global function ShDevWeapons_Init
#if SERVER
global function DEV_ToggleAkimboWeapon
global function DEV_ToggleAkimboWeaponAlt
#endif


//////////////////////////
#if SERVER || CLIENT || UI
void function ShDevWeapons_Init()
{
	#if SERVER || CLIENT
		PrecacheWeapon( "mp_weapon_defender_sustained" )

		PrecacheWeapon( "melee_shadowsquad_hands" )
		PrecacheWeapon( "mp_weapon_shadow_squad_hands_primary" )
		
		PrecacheModel( $"mdl/humans/class/heavy/pilot_heavy_revenant.rmdl" )
		PrecacheModel( $"mdl/Weapons/arms/pov_pilot_heavy_revenant.rmdl" )
		PrecacheModel( $"mdl/Humans/class/medium/pilot_medium_loba.rmdl" )
		PrecacheModel( $"mdl/Weapons/arms/pov_pilot_medium_loba.rmdl" )
		PrecacheModel( $"mdl/humans/pilots/pilot_medium_reaper_m.rmdl" )
		PrecacheModel( $"mdl/humans/pilots/pov_pilot_medium_reaper_m.rmdl" )
		PrecacheModel( $"mdl/Humans/class/medium/pilot_medium_rampart.rmdl" )
		PrecacheModel( $"mdl/Weapons/arms/pov_pilot_medium_rampart.rmdl" )
		PrecacheModel( $"mdl/props/rampart_gum/rampart_bubblegum.rmdl" )
		PrecacheModel( $"mdl/props/loba_loot_stick/loba_loot_stick.rmdl" )
	#endif

}
#endif

#if SERVER

void function DEV_ToggleAkimboWeapon(entity player)
{
    if(!IsValid(player))
        return

    entity weapon = player.GetActiveWeapon( eActiveInventorySlot.mainHand )

    if(!IsValid(weapon))
        return

	if(player.GetNormalWeapon( GetDualPrimarySlotForWeapon( weapon ) ))
        TakeMatchingAkimboWeapon(weapon)
    else
        GiveMatchingAkimboWeapon(weapon, weapon.GetMods())
}

void function DEV_ToggleAkimboWeaponAlt(entity player)
{
    if(!IsValid(player))
        return

    array<entity> weapons = player.GetMainWeapons()

	if(weapons.len() < 2)
		return

	entity currentWeapon = player.GetActiveWeapon( eActiveInventorySlot.mainHand )
	entity otherWeapon = weapons[0] == currentWeapon ? weapons[1] : weapons[0]

	if(otherWeapon.GetWeaponClassName().find("melee") > 0)
		return
	if(currentWeapon.GetWeaponClassName().find("melee") > 0)
		return

	int dualslot = GetDualPrimarySlotForWeapon( currentWeapon )

	if(player.GetNormalWeapon( GetDualPrimarySlotForWeapon( currentWeapon ) ))
		player.TakeNormalWeaponByIndex( dualslot )
    else
		player.GiveWeapon( otherWeapon.GetWeaponClassName(), dualslot, otherWeapon.GetMods() )
}

int function GetDualPrimarySlotForWeapon( entity weapon )
{
	int slot = weapon.GetInventoryIndex()

	int dualslot = WEAPON_INVENTORY_SLOT_DUALPRIMARY_0
	if ( slot == 1 )
		dualslot = WEAPON_INVENTORY_SLOT_DUALPRIMARY_1
	else if ( slot == 2 )
		dualslot = WEAPON_INVENTORY_SLOT_DUALPRIMARY_2

	return dualslot
}

#endif
