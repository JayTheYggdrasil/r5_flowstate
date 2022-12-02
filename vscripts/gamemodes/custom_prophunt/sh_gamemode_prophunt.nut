//FLOWSTATE PROPHUNT
//Made by @CafeFPS (Retículo Endoplasmático#5955)

// AyeZee#6969 -- Ctf voting phase to work off
// everyone else -- advice

global function GamemodeProphuntShared_Init
global function RegisterLocationPROPHUNT

global const int PROPHUNT_CHANGE_PROP_USAGE_LIMIT = 3
global const int PROPHUNT_FLASH_BANG_RADIUS = 300
global const int PROPHUNT_DECOYS_USAGE_LIMIT = 4
global const int PROPHUNT_FLASH_BANG_USAGE_LIMIT = 3

global const array<asset> prophuntAssetsWE =
[
	$"mdl/barriers/concrete/concrete_barrier_01.rmdl",
	$"mdl/vehicles_r5/land/msc_truck_samson_v2/veh_land_msc_truck_samson_v2.rmdl",
	$"mdl/angel_city/vending_machine.rmdl",
	$"mdl/utilities/power_gen1.rmdl",
	$"mdl/angel_city/box_small_02.rmdl",
	$"mdl/colony/antenna_05_colony.rmdl",
	$"mdl/garbage/trash_bin_single_wtrash_Blue.rmdl",
	$"mdl/angel_city/box_small_01.rmdl",
	$"mdl/garbage/dumpster_dirty_open_a_02.rmdl",
	$"mdl/containers/slumcity_oxygen_tank_red.rmdl",
	$"mdl/containers/box_shrinkwrapped.rmdl",
	$"mdl/colony/farmland_fridge_01.rmdl",
	$"mdl/furniture/chair_beanbag_01.rmdl",
	$"mdl/colony/farmland_crate_plastic_01_red.rmdl",
	$"mdl/IMC_base/generator_IMC_01.rmdl",
	$"mdl/garbage/trash_can_metal_02_b.rmdl",
	$"mdl/garbage/trash_bin_single_wtrash.rmdl"
]

void function GamemodeProphuntShared_Init()
{
	RegisterLocationPROPHUNT(
			NewLocationSettings(
				"TTV Building",
				[
					NewLocPair(<8779, 5154, -4092>, <0, 90, 0>),
					NewLocPair(<9351,6319,-4095>, <0, -120, 0>),
					NewLocPair(<10462,6128,-4163>, <0, -45, 0>),
					NewLocPair(<9635,4868,-4073>, <0, -135, 0>)
				],
				<0, 0, 3000>,$"rui/flowstatelocations/ttvbuilding"
			)
		)
	RegisterLocationPROPHUNT(
			NewLocationSettings(
				"Skill trainer By CafeFPS",
				[
					NewLocPair(<15008, 30040, -680>, <20, 50, 0>),
					NewLocPair(<19265, 30022, -680>, <11, 132, 0>),
					NewLocPair(<19267, 33522, -680>, <10, -138, 0>),
					NewLocPair(<14995, 33566, -680>, <16, -45, 0>)
				],
				<0, 0, 3000>,$"rui/flowstatelocations/skilltrainer"
			)
		)
	RegisterLocationPROPHUNT(
			NewLocationSettings(
				"TTV Building 2",
				[
					NewLocPair(<1313, 4450, -2990>, <0, 50, 0>),
					NewLocPair(<2300, 6571, -4490>, <0, -96, 0>),
					NewLocPair(<2617, 4668, -4250>, <0, 85, 0>),
					NewLocPair(<1200, 4471, -4150>, <0, 50, 0>)
				],
				<0, 0, 2000>,$"rui/flowstatelocations/ttvbuilding2"
			)
		)

	RegisterLocationPROPHUNT(
			NewLocationSettings(
				"Train yard",
				[
					NewLocPair(<-11956,3021,-2988>, <0, 87, 0>),
					NewLocPair(<-13829,2836,-3037>, <0, 122, 0>),
					NewLocPair(<-12883,4502,-3340>, <0, 177, 0>),
					NewLocPair(<-11412,3692,-3405>, <0, 3, 0>),
					NewLocPair(<-14930,2065,-3140>, <0, 3, 0>)
				],
				<0, 0, 2000>,$"rui/flowstatelocations/trainyard"
			)
		)

}

void function RegisterLocationPROPHUNT(LocationSettings locationSettings)
{
    #if SERVER
    _RegisterLocationPROPHUNT(locationSettings)
    #endif
	
	#if CLIENT
    Cl_RegisterLocation(locationSettings)
    #endif

}