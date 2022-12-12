//FLOWSTATE PROPHUNT
//Made by @CafeFPS (Retículo Endoplasmático#5955)

// AyeZee#6969 -- Ctf voting phase to work off
// everyone else -- advice

global function GamemodeProphuntShared_Init
global function RegisterLocationPROPHUNT

global const int PROPHUNT_CHANGE_PROP_USAGE_LIMIT = 5
global const int PROPHUNT_FLASH_BANG_RADIUS = 600
global const int PROPHUNT_DECOYS_USAGE_LIMIT = 5
global const int PROPHUNT_FLASH_BANG_USAGE_LIMIT = 5
global const int PROPHUNT_WHISTLE_RADIUS = 2000
global const int PROPHUNT_WHISTLE_TIMER = 25
global const int PROPHUNT_TELEPORT_ATTACKERS_DELAY = 30 //hiding props time too
global const int PROPHUNT_ATTACKERS_ABILITY_COOLDOWN = 60

global array<asset> prophuntAssets = []

void function GamemodeProphuntShared_Init()
{
    switch(GetMapName())
    {
	    case "mp_rr_canyonlands_mu1":

		prophuntAssets = [
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
			//nuevos
			$"mdl/containers/slumcity_oxygen_bag_large_01_b.rmdl",
			$"mdl/containers/slumcity_oxygen_tank_blue.rmdl",
			$"mdl/containers/barrel.rmdl",
			$"mdl/containers/container_medium_tanks_blue.rmdl",
			$"mdl/containers/underbelly_cargo_container_128_red_02.rmdl",
			$"mdl/containers/underbelly_cargo_container_128_blue_02.rmdl",
			$"mdl/containers/pelican_case_large.rmdl",
			$"mdl/containers/box_med_cardboard_03.rmdl",
			$"mdl/furniture/couch_suede_brown_01.rmdl",
			$"mdl/colony/farmland_crate_md_80x64x72_01.rmdl",
			$"mdl/colony/farmland_crate_md_80x64x72_03.rmdl",
			$"mdl/industrial/vending_machine_02.rmdl",
			$"mdl/angel_city/jersey_barrier_large_02.rmdl",
			$"mdl/angel_city/vending_machine.rmdl"
			
		]
		
		// RegisterLocationPROPHUNT(
            // NewLocationSettings(
                // "Hillside Outspot",
                // [
                    // NewLocPair(<-19300, 4678, 3230>, <0, -100, 0>),
                    // NewLocPair(<-16763, 4465, 3020>, <1, 18, 0>),
                    // NewLocPair(<-20153, 1127, 3060>, <11, 170, 0>),
					// NewLocPair(<-16787, 3540, 3075>, <0, 86, 0>),
					// NewLocPair(<-19026, 3749, 4460>, <0, 2, 0>)
                // ],
                // <0, 0, 3000>,$"rui/flowstatelocations/hillside"
            // )
        // )
		
		// RegisterLocationPROPHUNT(
            // NewLocationSettings(
                // "Gaunlet",
                // [
                    // NewLocPair(<-21271, -15275, 2781>, <0, 90, 0>),
                    // NewLocPair(<-22952, -13304, 2718>, <0, 5, 0>),
                    // NewLocPair(<-22467, -9567, 2949>, <0, -85, 0>),
                    // NewLocPair(<-18494, -10427, 2825>, <0, -155, 0>),
					// NewLocPair(<-22590, -7534, 3103>, <0, 0, 0>)
                // ],
                // <0, 0, 4000>,$"rui/flowstatelocations/gaunlet"
            // )
        // )
		
		RegisterLocationPROPHUNT(
            NewLocationSettings(
                "Relay",
                [
                    NewLocPair(<26420, 31700, 4790>, <0, -90, 0>),
                    NewLocPair(<29260, 26245, 4210>, <0, 45, 0>),
                    NewLocPair(<29255, 24360, 4210>, <0, 0, 0>),
                    NewLocPair(<24445, 28970, 4340>, <0, -90, 0>),
                    NewLocPair(<27735, 27880, 4370>, <0, 180, 0>),
                    NewLocPair(<25325, 25725, 4270>, <0, 0, 0>),
                    NewLocPair(<27675, 25745, 4370>, <0, 0, 0>),
                    NewLocPair(<24375, 27050, 4325>, <0, 180, 0>),
                    NewLocPair(<24000, 23650, 4050>, <0, 135, 0>),
                    NewLocPair(<23935, 22080, 4200>, <0, 15, 0>)
                ],
                <0, 0, 3000>,$"rui/flowstatelocations/relay"
            )
        )
		
        RegisterLocationPROPHUNT(
            NewLocationSettings(
                "Slum Lakes",
                [
                    NewLocPair(<-20060, 23800, 2655>, <0, 110, 0>),
                    NewLocPair(<-20245, 24475, 2810>, <0, -160, 0>),
                    NewLocPair(<-25650, 22025, 2270>, <0, 20, 0>),
                    NewLocPair(<-25550, 21635, 2590>, <0, 20, 0>),
                    NewLocPair(<-25030, 24670, 2410>, <0, -75, 0>),
                    NewLocPair(<-23125, 25320, 2410>, <0, -20, 0>),
                    NewLocPair(<-21925, 21120, 2390>, <0, 180, 0>)
                ],
                <0, 0, 3000>,$"rui/flowstatelocations/slumlakes"
            )
        )
		
		RegisterLocationPROPHUNT(
            NewLocationSettings(
                "Swamps",
                [
                    NewLocPair(<37886, -4012, 3300>, <0, 167, 0>),
                    NewLocPair(<34392, -5974, 3017>, <0, 51, 0>),
                    NewLocPair(<29457, -2989, 2895>, <0, -17, 0>),
                    NewLocPair(<34582, 2300, 2998>, <0, -92, 0>),
					NewLocPair(<35757, 3256, 3290>, <0, -90, 0>),
                    NewLocPair(<36422, 3109, 3500>, <0, -165, 0>),
                    NewLocPair(<34965, 1718, 3529>, <0, 45, 0>),
                    NewLocPair(<32654, -1552, 3228>, <0, -90, 0>)

                ],
                <0, 0, 3000>,$"rui/flowstatelocations/swamps"
            )
        )
	
        RegisterLocationPROPHUNT(
            NewLocationSettings(
                "Water Treatment",
                [
                    NewLocPair(<5583, -30000, 3070>, <0, 0, 0>),
                    NewLocPair(<7544, -29035, 3061>, <0, 130, 0>),
                    NewLocPair(<10091, -30000, 3070>, <0, 180, 0>),
                    NewLocPair(<8487, -28838, 3061>, <0, -45, 0>)
                ],
                <0, 0, 3000>,$"rui/flowstatelocations/watert"
            )
        )
		
        RegisterLocationPROPHUNT(
            NewLocationSettings(
                "Airbase",
                [
                    NewLocPair(<-24140, -4510, 2583>, <0, 90, 0>),
                    NewLocPair(<-28675, 612, 2600>, <0, 18, 0>),
                    NewLocPair(<-24688, 1316, 2583>, <0, 180, 0>),
                    NewLocPair(<-26492, -5197, 2574>, <0, 50, 0>)
                ],
                <0, 0, 3000>,$"rui/flowstatelocations/airbase"
            )
        )
	    break

	    case "mp_rr_desertlands_64k_x_64k_nx":		
	    case "mp_rr_desertlands_64k_x_64k":
		
		prophuntAssets = [
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
			//nuevos
			$"mdl/containers/slumcity_oxygen_bag_large_01_b.rmdl",
			$"mdl/containers/slumcity_oxygen_tank_blue.rmdl",
			$"mdl/containers/barrel.rmdl",
			$"mdl/containers/container_medium_tanks_blue.rmdl",
			$"mdl/containers/underbelly_cargo_container_128_red_02.rmdl",
			$"mdl/containers/underbelly_cargo_container_128_blue_02.rmdl",
			$"mdl/containers/pelican_case_large.rmdl",
			$"mdl/containers/box_med_cardboard_03.rmdl",
			$"mdl/furniture/couch_suede_brown_01.rmdl",
			$"mdl/colony/farmland_crate_md_80x64x72_01.rmdl",
			$"mdl/colony/farmland_crate_md_80x64x72_03.rmdl",
			$"mdl/industrial/vending_machine_02.rmdl",
			$"mdl/angel_city/jersey_barrier_large_02.rmdl",
			$"mdl/angel_city/vending_machine.rmdl"
			
		]
		
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
		// RegisterLocationPROPHUNT(
				// NewLocationSettings(
					// "Skill trainer By CafeFPS",
					// [
						// NewLocPair(<15008, 30040, -680>, <20, 50, 0>),
						// NewLocPair(<19265, 30022, -680>, <11, 132, 0>),
						// NewLocPair(<19267, 33522, -680>, <10, -138, 0>),
						// NewLocPair(<14995, 33566, -680>, <16, -45, 0>)
					// ],
					// <0, 0, 3000>,$"rui/flowstatelocations/skilltrainer"
				// )
			// )
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
			
		RegisterLocationPROPHUNT(
					NewLocationSettings(
						"Overlook",
						[
							NewLocPair(<32774, 6031, -3239>, <0, 117, 0>),
							NewLocPair(<28381, 8963, -3224>, <0, 48, 0>),
							NewLocPair(<26327, 11857, -2477>, <0, -43, 0>),
							NewLocPair(<27303, 14528, -3047>, <0, -42, 0>)
						],
						<0, 0, 2000>,$"rui/flowstatelocations/overlook"
					)
				)

		RegisterLocationPROPHUNT(
					NewLocationSettings(
						"Little Town",
						[
							NewLocPair(<22857, 3449, -4050>, <0, -157, 0>),
							NewLocPair(<19559, 232, -4035>, <0, 33, 0>),
							NewLocPair(<19400, 4384, -4027>, <0, -35, 0>)
						],
						<0, 0, 2000>,$"rui/flowstatelocations/littletown"
					)
				)

		RegisterLocationPROPHUNT(
				NewLocationSettings(
					"Little Town 2",
					[
						NewLocPair(<-27219, -24393, -4497>, <0, 87, 0>),
						NewLocPair(<-26483, -28042, -4209>, <0, 122, 0>),
						NewLocPair(<-25174, -26091, -4550>, <0, 177, 0>),
						NewLocPair(<-29512, -25863, -4462>, <0, 3, 0>),
						NewLocPair(<-28380, -28984, -4102>, <0, 54, 0>)
					],
					<0, 0, 2000>,$"rui/flowstatelocations/littletown2"
				)
			)
		break
	}
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