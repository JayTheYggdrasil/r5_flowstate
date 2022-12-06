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
global const int PROPHUNT_WHISTLE_RADIUS = 1500
global const int PROPHUNT_WHISTLE_TIMER = 30
global int PROPHUNT_TELEPORT_ATTACKERS_DELAY = 15

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
					NewLocPair(<11407, 6778, -4295>, <0, 88, 0>),
					NewLocPair(<11973, 4158, -4220>, <0, 82, 0>),
					NewLocPair(<9956, 3435, -4239>, <0, 0, 0>),
					NewLocPair(<9038, 3800, -4120>, <0, -88, 0>),
					NewLocPair(<7933, 6692, -4250>, <0, 76, 0>),
					NewLocPair(<8990, 5380, -4250>, <0, 145, 0>),
					NewLocPair(<8200, 5463, -3815>, <0, 0, 0>),
					NewLocPair(<9789, 5363, -3480>, <0, 174, 0>),
					NewLocPair(<9448, 5804, -4000>, <0, 0, 0>),
					NewLocPair(<8135, 4087, -4233>, <0, 90, 0>),
					NewLocPair(<9761, 5980, -4250>, <0, 135, 0>),
					NewLocPair(<11393, 5477, -4289>, <0, 90, 0>),
					NewLocPair(<12027, 7121, -4290>, <0, -120, 0>),
					NewLocPair(<8105, 6156, -4300>, <0, -45, 0>),
					NewLocPair(<9420, 5528, -4236>, <0, 90, 0>),
					NewLocPair(<8277, 6304, -3940>, <0, 0, 0>),
					NewLocPair(<8186, 5513, -3828>, <0, 0, 0>),
					NewLocPair(<8243, 4537, -4235>, <-13, 32, 0>),
					NewLocPair(<11700, 6207, -4435>, <-10, 90, 0>),
					NewLocPair(<11181, 5862, -3900>, <0, -180, 0>),
					NewLocPair(<9043, 5866, -4171>, <0, 90, 0>),
					NewLocPair(<11210, 4164, -4235>, <0, 90, 0>),
					NewLocPair(<12775, 4446, -4235>, <0, 150, 0>),
					NewLocPair(<9012, 5386, -4242>, <0, 90, 0>)
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