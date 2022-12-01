//FLOWSTATE PROPHUNT
//Made by @CafeFPS (Retículo Endoplasmático#5955)

global function _GamemodeProphunt_Init
global function _RegisterLocationPROPHUNT
global function PROPHUNT_GiveAndManageRandomProp
global function returnPropBool
global function RunPROPHUNT
global function _OnPlayerConnectedPROPHUNT
global function _OnPlayerDiedPROPHUNT
global function ClientCommand_NextRoundPROPHUNT
global function helpMessagePROPHUNT

struct{
	float endTime = 0
	array<entity> playerSpawnedProps
	array<LocationSettings> locationSettings
	array<LocationSettings> locationsShuffled
	LocationSettings& selectedLocation
	int nextMapIndex = 0
	bool mapIndexChanged = true
	bool cantUseChangeProp = false
	bool InProgress = false
	entity ringBoundary
	entity ringBoundary_PreGame
	
	// Voting
    array<entity> votedPlayers // array of players that have already voted (bad var name idc)
    bool votingtime = false
    bool votestied = false
    array<int> mapVotes
    array<int> mapIds
    int mappicked = 0
	int currentRound = 1
} FS_PROPHUNT

void function _GamemodeProphunt_Init()
{
	AddCallback_OnClientConnected( void function(entity player) { 
		thread _OnPlayerConnectedPROPHUNT(player)
    })
	
	AddCallback_OnPlayerKilled( void function(entity victim, entity attacker, var damageInfo) {
        thread _OnPlayerDiedPROPHUNT(victim, attacker, damageInfo)
    })
	
	AddCallback_EntitiesDidLoad( _OnEntitiesDidLoadPROPHUNT )
	
	AddClientCommandCallback("next_round", ClientCommand_NextRoundPROPHUNT)
	AddClientCommandCallback("latency", ClientCommand_ShowLatency)
	AddClientCommandCallback("commands", ClientCommand_Help)
	AddClientCommandCallback("VoteForMap", ClientCommand_VoteForMap_PROPHUNT)
	
	PrecacheCustomMapsProps()
	
	thread RunPROPHUNT()	
}

void function _OnEntitiesDidLoadPROPHUNT()
{
	SpawnFlowstateLobbyProps()
	AddSpawnCallback("prop_dynamic", _OnPropDynamicSpawnedPROPHUNT)
}

void function _RegisterLocationPROPHUNT(LocationSettings locationSettings)
{
    FS_PROPHUNT.locationSettings.append(locationSettings)
}

void function _OnPropDynamicSpawnedPROPHUNT(entity prop)
{
    FS_PROPHUNT.playerSpawnedProps.append(prop)
}

const array<asset> prophuntAssetsWE =
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
array<LocationSettings> function shuffleLocationsArray(array<LocationSettings> arr)
// O(n) Durstenfeld / Knuth shuffle (https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle)
//By michae\l/#1125.
{
	int i;
	int j;
	int b;
	LocationSettings tmp;

	for (i = arr.len() - 1; i > 0; i--) {
		j = RandomIntRangeInclusive(1, i)
		tmp = arr[b]
		arr[b] = arr[j]
		arr[j] = tmp
	}

	return arr
}

void function RunPROPHUNT()
{
    SetGameState( eGameState.Playing )
	//FS_PROPHUNT.locationsShuffled = shuffleLocationsArray(FS_PROPHUNT.locationSettings)
	
    while(true)
	{
		ActualPROPHUNTLobby()
		ActualPROPHUNTGameLoop()
		WaitFrame()
	}
}

void function _OnPlayerConnectedPROPHUNT(entity player)
{
	while(IsDisconnected( player )) WaitFrame()

    if(!IsValid(player)) return

	//CreatePanelText( player, "Flowstate", "", <-19766, 2111, 6541>, <0, 180, 0>, false, 2 )
	printt("Flowstate DEBUG - New player connected.", player)
	if(FlowState_ForceCharacter())
	{
		CharSelect(player)
	}
	
	GivePassive(player, ePassives.PAS_PILOT_BLOOD)
	UpdatePlayerCounts()
	array<entity> IMCplayers = GetPlayerArrayOfTeam(TEAM_IMC)
	array<entity> MILITIAplayers = GetPlayerArrayOfTeam(TEAM_MILITIA)

	ItemFlavor playerCharacter = LoadoutSlot_GetItemFlavor( ToEHI( player ), Loadout_CharacterClass() )
	asset characterSetFile = CharacterClass_GetSetFile( playerCharacter )
	player.SetPlayerSettingsWithMods( characterSetFile, [] )
	SetPlayerSettings(player, PROPHUNT_SETTINGS)
	DoRespawnPlayer( player, null )
	Survival_SetInventoryEnabled( player, true )				
	player.SetPlayerNetInt( "respawnStatus", eRespawnStatus.NONE )
	player.SetPlayerNetBool( "pingEnabled", true )
	player.SetHealth( 100 )
	player.kv.solid = 6
	player.kv.CollisionGroup = TRACE_COLLISION_GROUP_PLAYER
	player.AllowMantle()
			
	switch(GetGameState())
    {
		case eGameState.WaitingForPlayers:
		case eGameState.MapVoting:
			if(!IsValid(player)) return
			
			printt("Flowstate DEBUG - Prophunt player connected mapvoting.", player)
			//player has a team assigned already, we need to fix it before spawn
			GiveTeamToProphuntPlayer(player)

			if (GetMapName() == "mp_rr_desertlands_64k_x_64k" || GetMapName() == "mp_rr_desertlands_64k_x_64k_nx")
			{
				player.SetOrigin(<-19459, 2127, 6404>)
			}
			else if(GetMapName() == "mp_rr_canyonlands_mu1" || GetMapName() == "mp_rr_canyonlands_mu1_night" || GetMapName() == "mp_rr_canyonlands_64k_x_64k")
			{
				player.SetOrigin(<-19459, 2127, 18404>)
			}

			player.SetThirdPersonShoulderModeOn()
			player.UnforceStand()
			player.UnfreezeControlsOnServer()
			break
		case eGameState.Playing: //wait round ends, set new player to spectate random player
			if(!IsValid(player)) return
			
			array<entity> playersON = GetPlayerArray_Alive()
			playersON.fastremovebyvalue( player )
			
			printt("Flowstate DEBUG - Prophunt player connected midround, setting spectator.", player)
			array<LocPair> prophuntSpawns = FS_PROPHUNT.selectedLocation.spawns
			player.SetOrigin(prophuntSpawns[RandomIntRangeInclusive(0,prophuntSpawns.len()-1)].origin)
			player.MakeInvisible()
			player.p.PROPHUNT_isSpectatorDiedMidRound = false
			
			SetTeam(player, 15 )
			
			player.SetPlayerNetInt( "spectatorTargetCount", GetPlayerArray().len() )
			player.SetObserverTarget( playersON[RandomIntRangeInclusive(0,playersON.len()-1)] )
			player.SetSpecReplayDelay( 2 )
			player.StartObserverMode( OBS_MODE_IN_EYE )
			Remote_CallFunction_NonReplay(player, "ServerCallback_KillReplayHud_Activate")
			player.p.isSpectating = true
			
			foreach(sPlayer in GetPlayerArray())
			{
				if(!IsValid(sPlayer)) continue
				
				if(sPlayer == player)
					Message(player, "FS PROPHUNT", "You'll spawn in the next round.", 10)
				else
					Message(player, "Player connected!", player.GetPlayerName() + " is in waiting room.", 5)
			}
			break
		default:
			break
	}
}

void function _OnPlayerDiedPROPHUNT(entity victim, entity attacker, var damageInfo)
{
	if(GetGameState() != eGameState.Playing) //FIXME!
	{	
		array<entity> playersON = GetPlayerArray_Alive()
		playersON.fastremovebyvalue( victim )
		if(playersON.len() == 0) return
		
		victim.SetObserverTarget( playersON[0] )
		victim.SetSpecReplayDelay( 2 + DEATHCAM_TIME_SHORT)
		victim.StartObserverMode( OBS_MODE_IN_EYE )
		victim.p.isSpectating = true
		Remote_CallFunction_NonReplay(victim, "ServerCallback_KillReplayHud_Activate")
		victim.p.PROPHUNT_isSpectatorDiedMidRound = true
		return
	}
	
	switch(GetGameState())
    {
		case eGameState.Playing:
			// Víctima
			void functionref() victimHandleFunc = void function() : (victim, attacker, damageInfo) 
			{
				if(!IsValid(victim) || !IsValid(attacker)) return

				victim.Hide()
				entity effect = StartParticleEffectInWorld_ReturnEntity( GetParticleSystemIndex($"P_ball_tick_exp_CP"), victim.GetOrigin(), <0, 0, 0> )
				EntFireByHandle( effect, "Kill", "", 2, null, null )

				wait DEATHCAM_TIME_SHORT
				
				if(!IsValid(victim) || !IsValid(attacker)) return

				array<entity> playersON = GetPlayerArray_Alive()
				playersON.fastremovebyvalue( victim )
		
				if(victim != attacker)
				{
					victim.SetObserverTarget( attacker )
					victim.SetSpecReplayDelay( 2 + DEATHCAM_TIME_SHORT)
					victim.StartObserverMode( OBS_MODE_IN_EYE )
					victim.p.isSpectating = true
					Remote_CallFunction_NonReplay(victim, "ServerCallback_KillReplayHud_Activate")
				} else 
				{
					victim.SetObserverTarget( playersON[0] )
					victim.SetSpecReplayDelay( 2 + DEATHCAM_TIME_SHORT)
					victim.StartObserverMode( OBS_MODE_IN_EYE )
					victim.p.isSpectating = true
					Remote_CallFunction_NonReplay(victim, "ServerCallback_KillReplayHud_Activate")
				}
			
				int invscore = victim.GetPlayerGameStat( PGS_DEATHS )
				invscore++
				victim.SetPlayerGameStat( PGS_DEATHS, invscore)
				//Add a death to the victim
				int invscore2 = victim.GetPlayerNetInt( "assists" )
				invscore2++
				victim.SetPlayerNetInt( "assists", invscore2 )
				
				victim.p.PROPHUNT_isSpectatorDiedMidRound = true
			}

			// Atacante
			void functionref() attackerHandleFunc = void function() : (victim, attacker, damageInfo)
			{
				if(!IsValid(victim) || !IsValid(attacker)) return

				if(IsValid(attacker) && attacker.IsPlayer() && IsAlive(attacker) && attacker != victim)
				{
					//DamageInfo_AddCustomDamageType( damageInfo, DF_KILLSHOT )
					thread EmitSoundOnEntityOnlyToPlayer( attacker, attacker, "flesh_bulletimpact_downedshot_1p_vs_3p" )
					
					WpnAutoReloadOnKill(attacker)
					
					GameRules_SetTeamScore(TEAM_IMC, GameRules_GetTeamScore(attacker.GetTeam()) + 1)
				}
				array<entity> teamMILITIAplayersalive = GetPlayerArrayOfTeam_Alive( TEAM_MILITIA )
				if ( teamMILITIAplayersalive.len() == 0 )
				{
					SetTdmStateToNextRound()		
				}
			}
			
			thread victimHandleFunc()
			thread attackerHandleFunc()
			break
		default:
			break
	}
	
	UpdatePlayerCounts()
	printt("Flowstate DEBUG - Prophunt player killed.", victim, " -by- ", attacker)
	
}

void function _HandleRespawnPROPHUNT(entity player)
{
	if(!IsValid(player)) return
	
	printt("Flowstate DEBUG - Tping prophunt player to Lobby.", player)

	if(FlowState_ForceCharacter())
	{
		CharSelect(player)
	}
	
	if(!IsAlive(player)) 
	{
		DecideRespawnPlayer(player, false)
	}
	
	if (GetMapName() == "mp_rr_desertlands_64k_x_64k" || GetMapName() == "mp_rr_desertlands_64k_x_64k_nx")
	{
		player.SetOrigin(<-19459, 2127, 6404>)
	}
	else if(GetMapName() == "mp_rr_canyonlands_mu1" || GetMapName() == "mp_rr_canyonlands_mu1_night" || GetMapName() == "mp_rr_canyonlands_64k_x_64k")
	{
		player.SetOrigin(<-19459, 2127, 18404>)
	}
	
	player.SetThirdPersonShoulderModeOn()
	Survival_SetInventoryEnabled( player, true )
	player.SetPlayerNetInt( "respawnStatus", eRespawnStatus.NONE )
	player.SetPlayerNetBool( "pingEnabled", true )
	player.SetHealth( 100 )
	TakeAllWeapons(player)
}

bool function returnPropBool()
{
	return FS_PROPHUNT.cantUseChangeProp
}

void function GiveTeamToProphuntPlayer(entity player)
{
	array<entity> IMCplayers = GetPlayerArrayOfTeam(TEAM_IMC)
	array<entity> MILITIAplayers = GetPlayerArrayOfTeam(TEAM_MILITIA)
	
	if(IMCplayers.len() > MILITIAplayers.len())
	{
		SetTeam(player, TEAM_MILITIA )
	} else if (MILITIAplayers.len() > IMCplayers.len())
	{
		SetTeam(player, TEAM_IMC )
	} else {
		switch(RandomIntRangeInclusive(0,1))
		{
			case 0:
				SetTeam(player, TEAM_IMC )
				break
			case 1:
				SetTeam(player, TEAM_MILITIA )
				break
		}
	}
	printt("Flowstate DEBUG - Giving team to player.", player, player.GetTeam())
}


void function EmitSoundOnSprintingProp()
{
	while(FS_PROPHUNT.InProgress)
	{
		array<entity> MILITIAplayers = GetPlayerArrayOfTeam(TEAM_MILITIA)
		foreach(player in MILITIAplayers)
		{
			if(!IsValid(player)) continue
			
			if(player.IsSprinting())
			{
				EmitSoundOnEntity( player, "husaria_sprint_default_3p" )
			} 
		}
		wait 0.2
	}
}

void function EmitWhistleOnProp()
{
	while(FS_PROPHUNT.InProgress)
	{
		wait 30 //40 s COD original value: 20.
		array<entity> MILITIAplayers = GetPlayerArrayOfTeam(TEAM_MILITIA)
		foreach(player in MILITIAplayers)
		{
			if(!IsValid(player)) continue
			
			EmitSoundOnEntity( player, "husaria_sprint_default_3p" )
			EmitSoundOnEntity( player, "concrete_bulletimpact_1p_vs_3p" )
			EmitSoundOnEntity( player, "husaria_sprint_default_3p" )
		}
	}
}

void function CheckForPlayersPlaying()
{
	while(FS_PROPHUNT.InProgress)
	{
		if(GetPlayerArray().len() == 1)
		{
			SetTdmStateToNextRound()
			foreach(player in GetPlayerArray())
			{
				if(!IsValid(player)) continue
				
				Message(player, "ATTENTION", "Not enough players. Round is ending.", 5)
			}
		}
		
	WaitFrame()	
	}
	
	printt("Flowstate DEBUG - Ending round cuz not enough players midround")
}

void function PropWatcher(entity prop, entity player)
{
	while(IsValid(player) && FS_PROPHUNT.InProgress && !player.p.PROPHUNT_DestroyProp) 
	{
		WaitFrame()
	}
	
	if(IsValid(prop))
		prop.Destroy()
}

void function DestroyPlayerPropsPROPHUNT()
{
    foreach(prop in FS_PROPHUNT.playerSpawnedProps)
    {
        if(!IsValid(prop)) continue
        
		prop.Destroy()
    }
    FS_PROPHUNT.playerSpawnedProps.clear()
}

void function PROPHUNT_GiveAndManageRandomProp(entity player, bool anglesornah = false)
{
	if(!IsValid(player)) return
	
	player.p.PROPHUNT_DestroyProp = true
	
	if(!anglesornah)
	{
		//WaitFrame()
		asset selectedModel = prophuntAssetsWE[RandomIntRangeInclusive(0,(prophuntAssetsWE.len()-1))]
		player.p.PROPHUNT_LastModel = selectedModel
		player.kv.solid = 6
		player.kv.CollisionGroup = TRACE_COLLISION_GROUP_PLAYER
		entity prop = CreatePropDynamic(selectedModel, player.GetOrigin(), player.GetAngles(), 6, -1)
		prop.kv.CollisionGroup = TRACE_COLLISION_GROUP_PLAYER
		prop.kv.solid = 6
		prop.SetDamageNotifications( true )
		prop.SetTakeDamageType( DAMAGE_YES )
		prop.AllowMantle()
		prop.SetCanBeMeleed( true )
		prop.SetBoundingBox( < -150, -75, 0 >, <150, 75, 100 >  )
		prop.SetMaxHealth( 100 )
		prop.SetHealth( 100 )
		prop.SetParent(player)
		AddEntityCallback_OnDamaged(prop, NotifyDamageOnProp)
		player.p.PROPHUNT_DestroyProp = false
		thread PropWatcher(prop, player) 
	} else
	{
		player.p.PROPHUNT_DestroyProp = true
		player.Show()
		player.SetBodyModelOverride( player.p.PROPHUNT_LastModel )
		player.SetArmsModelOverride( player.p.PROPHUNT_LastModel )
		Message(player, "prophunt", "Angles locked.", 1)
		player.kv.solid = SOLID_BBOX
		player.kv.CollisionGroup = TRACE_COLLISION_GROUP_PLAYER
		player.AllowMantle()
		player.SetDamageNotifications( true )
		player.SetTakeDamageType( DAMAGE_YES )
	}
}


void function PlayerwithLockedAngles_OnDamaged(entity ent, var damageInfo)
{
	entity attacker = DamageInfo_GetAttacker(damageInfo)
	float damage = DamageInfo_GetDamage( damageInfo )
	
	if(!IsValid(attacker) || !IsValid(ent)) return
		
	attacker.NotifyDidDamage
	(
		ent,
		DamageInfo_GetHitBox( damageInfo ),
		DamageInfo_GetDamagePosition( damageInfo ), 
		DamageInfo_GetCustomDamageType( damageInfo ),
		DamageInfo_GetDamage( damageInfo ),
		DamageInfo_GetDamageFlags( damageInfo ), 
		DamageInfo_GetHitGroup( damageInfo ),
		DamageInfo_GetWeapon( damageInfo ), 
		DamageInfo_GetDistFromAttackOrigin( damageInfo )
	)
	
	float NextHealth = ent.GetHealth() - DamageInfo_GetDamage( damageInfo )
	
	if (NextHealth > 0)
	{
		ent.SetHealth(NextHealth)
	} else
	{
		ent.SetTakeDamageType( DAMAGE_NO )
		int damageSourceId = DamageInfo_GetDamageSourceIdentifier( damageInfo )
		ent.Die( attacker, attacker, { damageSourceId = damageSourceId } )
		ent.kv.solid = 0
		// ent.SetOwner( attacker )
		// ent.kv.teamnumber = attacker.GetTeam()
	}
}

void function NotifyDamageOnProp(entity ent, var damageInfo)
{
//props health bleedthrough
	entity attacker = DamageInfo_GetAttacker(damageInfo)
	entity victim = ent.GetParent()
	float damage = DamageInfo_GetDamage( damageInfo )
	
	if(!IsValid(attacker) || !IsValid(victim) || !IsValid(ent)) return
		
	attacker.NotifyDidDamage
	(
		ent,
		DamageInfo_GetHitBox( damageInfo ),
		DamageInfo_GetDamagePosition( damageInfo ), 
		DamageInfo_GetCustomDamageType( damageInfo ),
		DamageInfo_GetDamage( damageInfo ),
		DamageInfo_GetDamageFlags( damageInfo ), 
		DamageInfo_GetHitGroup( damageInfo ),
		DamageInfo_GetWeapon( damageInfo ), 
		DamageInfo_GetDistFromAttackOrigin( damageInfo )
	)
	
	if(!IsAlive(victim)) return
	
	float playerNextHealth = ent.GetHealth() - DamageInfo_GetDamage( damageInfo )
	
	if (playerNextHealth > 0)
	{
		victim.SetHealth(playerNextHealth)
	} else 
	{
		int damageSourceId = DamageInfo_GetDamageSourceIdentifier( damageInfo )
		ent.ClearParent()
		victim.Die( attacker, attacker, { damageSourceId = damageSourceId } )
		ent.Destroy()
	}
}

void function ActualPROPHUNTLobby()
{
	DestroyPlayerPropsPROPHUNT()
	SetGameState(eGameState.MapVoting) //!FIXME
	SetFallTriggersStatus(true)
	if(GetMapName() == "mp_rr_desertlands_64k_x_64k" || GetMapName() == "mp_rr_desertlands_64k_x_64k_nx" || GetMapName() == "mp_rr_canyonlands_mu1" || GetMapName() == "mp_rr_canyonlands_mu1_night" || GetMapName() == "mp_rr_canyonlands_64k_x_64k")
	{
		thread CreateShipRoomFallTriggers()
	}
	printt("Flowstate DEBUG - Fall triggers created.")

	if (!FS_PROPHUNT.mapIndexChanged)
		{
			FS_PROPHUNT.nextMapIndex = ( FS_PROPHUNT.nextMapIndex + 1 ) % FS_PROPHUNT.locationSettings.len()
		}

	if (FlowState_LockPOI()) {
		FS_PROPHUNT.nextMapIndex = FlowState_LockedPOI()
	}
		
	FS_PROPHUNT.mapIndexChanged = false
	FS_PROPHUNT.selectedLocation = FS_PROPHUNT.locationSettings[ FS_PROPHUNT.mappicked ]
	printt("Flowstate DEBUG - Next location selected: ", FS_PROPHUNT.selectedLocation.name)
		
	if(FS_PROPHUNT.selectedLocation.name == "Skill trainer By CafeFPS")
	{
		DestroyPlayerPropsPROPHUNT()
		WaitFrame()
		thread SkillTrainerLoad()
		wait 1
		printt("Flowstate DEBUG - Skill trainer loading.")
	}
	
	foreach(player in GetPlayerArray())
	{
		if(!IsValid(player)) continue
		
		player.p.PROPHUNT_isSpectatorDiedMidRound = false
		player.p.PROPHUNT_Max3changes = 0
		player.p.PROPHUNT_DestroyProp = false
		player.UnforceStand()
		player.UnfreezeControlsOnServer()
		//Message(player, "FS PROPHUNT", "                Made by @CafeFPS. Game is starting.\n" + helpMessagePROPHUNT(), 10)
	}
	wait 2

	if(!GetCurrentPlaylistVarBool("flowstatePROPHUNTDebug", false ))
	{
		while(true)
		{
			array<entity> playersON = GetPlayerArray_Alive()
			if(playersON.len() > 1 )
			{
				foreach(player in GetPlayerArray())
				{
					if(!IsValid(player)) continue
		
					Message(player, "FS PROPHUNT", "We have enough players, starting now.", 5, "diag_ap_aiNotify_circleMoves10sec")
				}
				wait 5
				break
				
			} else {
				
				foreach(player in GetPlayerArray())
				{
					if(!IsValid(player)) continue
		
					Message(player, "FS PROPHUNT", "Waiting another player to start. Please wait.", 1)
				}
				wait 5			
			}
			WaitFrame()
		}
	}
	
	array<entity> IMCplayers = GetPlayerArrayOfTeam(TEAM_IMC)
	array<entity> MILITIAplayers = GetPlayerArrayOfTeam(TEAM_MILITIA)
	
	foreach(player in MILITIAplayers)
	{
		if(!IsValid(player)) continue
		
		Message(player, "ATTENTION", "            You're a prop. Teleporting in 5 seconds! \n Use your ULTIMATE to CHANGE PROP up to 3 times. ", 5)
	}
	wait 5
}

void function ActualPROPHUNTGameLoop()
{
	SetTdmStateToInProgress()
	printt("Flowstate DEBUG - tdmState is eTDMState.IN_PROGRESS Starting round.")
	if( GetBestPlayer() != null )
		SetChampion( GetBestPlayer() )

	SurvivalCommentary_ResetAllData()
	float endTime = Time() + GetCurrentPlaylistVarFloat("flowstatePROPHUNTLimitTime", 300 )
	
	array<entity> IMCplayers = GetPlayerArrayOfTeam(TEAM_IMC)
	array<entity> MILITIAplayers = GetPlayerArrayOfTeam(TEAM_MILITIA)

	array<LocPair> prophuntSpawns = FS_PROPHUNT.selectedLocation.spawns

	FS_PROPHUNT.cantUseChangeProp = false
	FS_PROPHUNT.InProgress = true
	thread EmitSoundOnSprintingProp()
	
	ResetMapVotes()
	FS_PROPHUNT.ringBoundary_PreGame = CreateRing_PreGame(FS_PROPHUNT.selectedLocation)
	SetGameState( eGameState.Playing )
	printt("Flowstate DEBUG - Tping props team.")
	foreach(player in GetPlayerArray())
	{
		if(!IsValid(player)) continue
		
		//try{TakePassive(player, ePassives.PAS_PILOT_BLOOD)}catch(e420){}
		//Inventory_SetPlayerEquipment(player, WHITE_SHIELD, "armor") //props dont like shields FX
		ClearInvincible(player)
		player.p.playerDamageDealt = 0.0
		if(player.GetTeam() == TEAM_MILITIA)
		{
			vector lastPosForCoolParticles = player.GetOrigin()
			vector lastAngForCoolParticles = player.GetAngles()
			StartParticleEffectInWorld( GetParticleSystemIndex( $"P_impact_shieldbreaker_sparks" ), lastPosForCoolParticles, lastAngForCoolParticles )
			StartParticleEffectInWorld( GetParticleSystemIndex( $"P_impact_shieldbreaker_sparks" ), lastPosForCoolParticles, lastAngForCoolParticles )
			EmitSoundOnEntityOnlyToPlayer( player, player, "PhaseGate_Enter_1p" )
			EmitSoundOnEntityExceptToPlayer( player, player, "PhaseGate_Enter_3p" )
			player.SetOrigin(prophuntSpawns[RandomIntRangeInclusive(0,prophuntSpawns.len()-1)].origin)
			asset selectedModel = prophuntAssetsWE[RandomIntRangeInclusive(0,(prophuntAssetsWE.len()-1))]
			player.p.PROPHUNT_LastModel = selectedModel
			player.kv.solid = 6
			player.kv.CollisionGroup = TRACE_COLLISION_GROUP_PLAYER
			player.Hide()
			entity prop = CreatePropDynamic(selectedModel, player.GetOrigin(), player.GetAngles(), 6, -1)
			prop.kv.solid = 6
			prop.kv.CollisionGroup = TRACE_COLLISION_GROUP_PLAYER
			prop.AllowMantle()
			prop.SetDamageNotifications( true )
			prop.SetTakeDamageType( DAMAGE_YES )
			prop.SetMaxHealth( 100 )	
			prop.SetHealth( 100 )
			prop.SetParent(player)
			
			AddEntityCallback_OnDamaged(prop, NotifyDamageOnProp)
			
			player.p.PROPHUNT_DestroyProp = false
			
			thread PropWatcher(prop, player) //destroys prop on end round and restores player model.
			
			player.SetThirdPersonShoulderModeOn()
			player.TakeOffhandWeapon(OFFHAND_TACTICAL)
			player.TakeOffhandWeapon(OFFHAND_ULTIMATE)
			player.GiveOffhandWeapon("mp_ability_heal", OFFHAND_TACTICAL)
			player.GiveOffhandWeapon("mp_ability_phase_walk", OFFHAND_ULTIMATE)
			DeployAndEnableWeapons(player)
		} else if(player.GetTeam() == TEAM_IMC)
		{
			Message(player, "PROPS ARE HIDING", "Teleporting in 25 seconds.", 10)
		}

	wait 0.2
	}
		
	if(!GetCurrentPlaylistVarBool("flowstatePROPHUNTDebug", false ))
	{
		wait 25
	} else
	{
		wait 2
	}
	
	foreach(player in GetPlayerArray())
	{
		if(!IsValid(player)) continue
		
		if(player.GetTeam() == TEAM_IMC)
			ScreenFade( player, 0, 0, 0, 255, 4.0, 1, FFADE_OUT | FFADE_PURGE )
	}
	wait 4
	
	SetFallTriggersStatus(false)

	FS_PROPHUNT.cantUseChangeProp = true
	printt("Flowstate DEBUG - Tping attackers team.")
	
	foreach(player in IMCplayers)
	{
		if(!IsValid(player)) continue
		
		//Inventory_SetPlayerEquipment(player, WHITE_SHIELD, "armor")
		ClearInvincible(player)
		EmitSoundOnEntityOnlyToPlayer( player, player, "PhaseGate_Enter_1p" )
		EmitSoundOnEntityExceptToPlayer( player, player, "PhaseGate_Enter_3p" )
		player.SetOrigin(prophuntSpawns[RandomIntRangeInclusive(0,prophuntSpawns.len()-1)].origin)
		player.kv.solid = 6
		player.kv.CollisionGroup = TRACE_COLLISION_GROUP_PLAYER
		player.SetThirdPersonShoulderModeOff()
		string pri = GetCurrentPlaylistVarString("flowstatePROPHUNTweapon1", "~~none~~")
		string sec = GetCurrentPlaylistVarString("flowstatePROPHUNTweapon2", "~~none~~")
		player.TakeNormalWeaponByIndexNow( WEAPON_INVENTORY_SLOT_PRIMARY_0 )
		player.GiveWeapon( pri, WEAPON_INVENTORY_SLOT_PRIMARY_0, [] )
		player.TakeNormalWeaponByIndexNow( WEAPON_INVENTORY_SLOT_PRIMARY_1 )
		player.GiveWeapon( sec, WEAPON_INVENTORY_SLOT_PRIMARY_1, [] )
		player.TakeOffhandWeapon(OFFHAND_TACTICAL)
		player.GiveOffhandWeapon("mp_ability_heal", OFFHAND_TACTICAL)
		//if a player punch a prop, he/she will crash. This is a workaround. Colombia
		//player.GiveWeapon( "mp_weapon_melee_survival", WEAPON_INVENTORY_SLOT_PRIMARY_2, [] )
		//player.GiveOffhandWeapon( "melee_data_knife", OFFHAND_MELEE, [] )
		DeployAndEnableWeapons(player)
	}
	
	FS_PROPHUNT.ringBoundary_PreGame.Destroy()
	FS_PROPHUNT.ringBoundary = CreateRingBoundary_PropHunt(FS_PROPHUNT.selectedLocation)
	
	foreach(player in GetPlayerArray())
	{
		if(!IsValid(player)) continue
		
		if (player.GetTeam() == TEAM_MILITIA)
		{
			Message(player, "ATTENTION", "The attackers have arrived. Use your ULTIMATE to PLACE PROP (lock angles).", 20, "Survival_UI_Ultimate_Ready")
		}
		else if (player.GetTeam() == TEAM_IMC)
		{
			array<entity> MILITIAplayersAlive = GetPlayerArrayOfTeam_Alive(TEAM_MILITIA)
			Message(player, "ATTENTION", "Kill the props. Props alive: " + MILITIAplayersAlive.len(), 20)
		}			
	}
	
	if(!GetCurrentPlaylistVarBool("flowstatePROPHUNTDebug", false ))
		thread CheckForPlayersPlaying()
	
	thread EmitWhistleOnProp()

	while( Time() <= endTime )
		{
			if(Time() == endTime-120)
			{
				foreach(player in GetPlayerArray())
				{
					if(!IsValid(player)) continue
					
					array<entity> MILITIAplayersAlive = GetPlayerArrayOfTeam_Alive(TEAM_MILITIA)
					Message(player,"2 MINUTES REMAINING!", "Props alive: " + MILITIAplayersAlive.len(), 5)
				}
			}
			if(Time() == endTime-60)
			{
				foreach(player in GetPlayerArray())
				{
					if(!IsValid(player)) continue
					
					array<entity> MILITIAplayersAlive = GetPlayerArrayOfTeam_Alive(TEAM_MILITIA)
					Message(player,"1 MINUTE REMAINING!", "Props alive: " + MILITIAplayersAlive.len(), 5, "diag_ap_aiNotify_circleMoves60sec")
				}
			}
			if(Time() == endTime-30)
			{
				foreach(player in GetPlayerArray())
				{
					if(!IsValid(player)) continue
					
					array<entity> MILITIAplayersAlive = GetPlayerArrayOfTeam_Alive(TEAM_MILITIA)
					Message(player,"30 SECONDS REMAINING!", "Props alive: " + MILITIAplayersAlive.len(), 5, "diag_ap_aiNotify_circleMoves30sec")
				}
			}
			if(Time() == endTime-10)
			{
				foreach(player in GetPlayerArray())
				{
					if(!IsValid(player)) continue
					
					array<entity> MILITIAplayersAlive = GetPlayerArrayOfTeam_Alive(TEAM_MILITIA)
					Message(player,"10 SECONDS REMAINING!",  "Props alive: " + MILITIAplayersAlive.len(), 5, "diag_ap_aiNotify_circleMoves10sec")
				}
			}
			if(GetTDMState() == 1)//eTDMState.NEXT_ROUND_NOW)
			{
				printt("Flowstate DEBUG - tdmState is eTDMState.NEXT_ROUND_NOW Loop ended.")
				break
			}
			WaitFrame()	
		}
	FS_PROPHUNT.InProgress = false
	array<entity> MILITIAplayersAlive = GetPlayerArrayOfTeam_Alive(TEAM_MILITIA)	
	if(MILITIAplayersAlive.len() > 0){
		foreach(player in GetPlayerArray())
		{
			if(!IsValid(player)) continue
			
			Message(player, "PROPS TEAM WIN", "Props alive: " + MILITIAplayersAlive.len() + ". \n Swapping teams.", 5, "diag_ap_aiNotify_winnerFound")
			player.SetThirdPersonShoulderModeOn()
			HolsterAndDisableWeapons(player)
		}
	} else {
		foreach(player in GetPlayerArray())
		{
			if(!IsValid(player)) continue
			
			Message(player, "ATTACKERS TEAM WIN", "All props are dead. \n Swapping teams.", 5, "diag_ap_aiNotify_winnerFound")
			player.SetThirdPersonShoulderModeOn()	
			HolsterAndDisableWeapons(player)		
		}	
	}
	
	thread SendScoreboardToClient()

	wait 7
	SetGameState(eGameState.MapVoting)
	UpdatePlayerCounts()
	FS_PROPHUNT.ringBoundary.Destroy()
	SetDeathFieldParams( <0,0,0>, 100000, 0, 90000, 99999 )
	printt("Flowstate DEBUG - Prophunt round finished Swapping teams.")
	foreach( player in GetPlayerArray() )
	{
		if( !IsValid( player ) ) continue
		RemoveCinematicFlag( player, CE_FLAG_HIDE_MAIN_HUD | CE_FLAG_EXECUTION )
		player.SetThirdPersonShoulderModeOff()	
		player.FreezeControlsOnServer()
	}
	
	int TeamWon = 69
	
	if(GetPlayerArray().len() == 1)
		TeamWon = gp()[0].GetTeam() //DEBUG VALUE
	
	if(IsValid(GetBestPlayer()))
		TeamWon = GetBestPlayer().GetTeam()
	

	// Only do voting for maps with multi locations
	// if ( FS_PROPHUNT.locationSettings.len() >= NUMBER_OF_MAP_SLOTS_FSDM )
	// {

		// for each player, open the vote menu and set it to the winning team screen
		foreach( player in GetPlayerArray() )
		{
			if( !IsValid( player ) )
				continue
			
			Remote_CallFunction_Replay(player, "ServerCallback_FSDM_OpenVotingPhase", true)
			Remote_CallFunction_Replay(player, "ServerCallback_FSDM_ChampionScreenHandle", true, TeamWon, 0)
			Remote_CallFunction_Replay(player, "ServerCallback_FSDM_SetScreen", eFSDMScreen.WinnerScreen, TeamWon, eFSDMScreen.NotUsed, eFSDMScreen.NotUsed)
		}
		
		
		thread function() : ()
		{
			for( int i = 0; i < NUMBER_OF_MAP_SLOTS_FSDM; ++i )
			{
				while( true )
				{
					// Get a random location id from the available locations
					int randomId = RandomIntRange(0, FS_PROPHUNT.locationSettings.len())

					// If the map already isnt picked for voting then append it to the array, otherwise keep looping till it finds one that isnt picked yet
					if( !FS_PROPHUNT.mapIds.contains( randomId ) )
					{
						FS_PROPHUNT.mapIds.append( randomId )
						break
					}
				}
			}
		}()
		
		wait 7

		foreach( player in GetPlayerArray() )
		{
			if( !IsValid( player ) )
				continue
			
			Remote_CallFunction_NonReplay(player, "ServerCallback_FSDM_CoolCamera")
			Remote_CallFunction_Replay(player, "ServerCallback_FSDM_SetScreen", eFSDMScreen.ScoreboardUI, TeamWon, eFSDMScreen.NotUsed, eFSDMScreen.NotUsed)
			EmitSoundOnEntityOnlyToPlayer(player, player, "UI_Menu_RoundSummary_Results")
		}
		
		wait 7
	
		// Set voting to be allowed
		FS_PROPHUNT.votingtime = true

		// For each player, set voting screen and update maps that are picked for voting
		foreach( player in GetPlayerArray() )
		{
			if( !IsValid( player ) )
				continue
			
			Remote_CallFunction_Replay(player, "ServerCallback_FSDM_UpdateVotingMaps", FS_PROPHUNT.mapIds[0], FS_PROPHUNT.mapIds[1], FS_PROPHUNT.mapIds[2], FS_PROPHUNT.mapIds[3])
			Remote_CallFunction_Replay(player, "ServerCallback_FSDM_SetScreen", eFSDMScreen.VoteScreen, eFSDMScreen.NotUsed, eFSDMScreen.NotUsed, eFSDMScreen.NotUsed)
		}

		wait 16

		FS_PROPHUNT.votestied = false
		bool anyVotes = false

		// Make voting not allowed
		FS_PROPHUNT.votingtime = false

		// See if there was any votes in the first place
		foreach( int votes in FS_PROPHUNT.mapVotes )
		{
			if( votes > 0 )
			{
				anyVotes = true
				break
			}
		}

		if ( anyVotes )
		{
			// store the highest vote count for any of the maps
			int highestVoteCount = -1

			// store the last map id of the map that has the highest vote count
			int highestVoteId = -1

			// store map ids of all the maps with the highest vote count
			array<int> mapsWithHighestVoteCount


			for(int i = 0; i < NUMBER_OF_MAP_SLOTS_FSDM; ++i)
			{
				int votes = FS_PROPHUNT.mapVotes[i]
				if( votes > highestVoteCount )
				{
					highestVoteCount = votes
					highestVoteId = FS_PROPHUNT.mapIds[i]

					// we have a new highest, so clear the array
					mapsWithHighestVoteCount.clear()
					mapsWithHighestVoteCount.append(FS_PROPHUNT.mapIds[i])
				}
				else if( votes == highestVoteCount ) // if this map also has the highest vote count, add it to the array
				{
					mapsWithHighestVoteCount.append(FS_PROPHUNT.mapIds[i])
				}
			}

			// if there are multiple maps with the highest vote count then it's a tie
			if( mapsWithHighestVoteCount.len() > 1 )
			{
				FS_PROPHUNT.votestied = true
			}
			else // else pick the map with the highest vote count
			{
				// Set the vote screen for each player to show the chosen location
				foreach( player in GetPlayerArray() )
				{
					if( !IsValid( player ) )
						continue

					Remote_CallFunction_Replay(player, "ServerCallback_FSDM_SetScreen", eFSDMScreen.SelectedScreen, eFSDMScreen.NotUsed, highestVoteId, eFSDMScreen.NotUsed)
				}

				// Set the location to the location that won
				FS_PROPHUNT.mappicked = highestVoteId
			}

			if ( FS_PROPHUNT.votestied )
			{
				foreach( player in GetPlayerArray() )
				{
					if( !IsValid( player ) )
						continue

					Remote_CallFunction_Replay(player, "ServerCallback_FSDM_SetScreen", eFSDMScreen.TiedScreen, eFSDMScreen.NotUsed, 42069, eFSDMScreen.NotUsed)
				}

				mapsWithHighestVoteCount.randomize()
				waitthread RandomizeTiedLocations(mapsWithHighestVoteCount)
			}
		}
		else // No one voted so pick random map
		{
			// Pick a random location id from the aviable locations
			FS_PROPHUNT.mappicked = RandomIntRange(0, FS_PROPHUNT.locationSettings.len() - 1)

			// Set the vote screen for each player to show the chosen location
			foreach( player in GetPlayerArray() )
			{
				if( !IsValid( player ) )
					continue

				Remote_CallFunction_Replay(player, "ServerCallback_FSDM_SetScreen", eFSDMScreen.SelectedScreen, eFSDMScreen.NotUsed, FS_PROPHUNT.mappicked, eFSDMScreen.NotUsed)
			}
		}

		//wait for timing
		wait 5

		// Close the votemenu for each player
		foreach( player in GetPlayerArray() )
		{
			if( !IsValid( player ) )
				continue
			
			ScreenCoverTransition_Player(player, Time() + 1)
			Remote_CallFunction_Replay(player, "ServerCallback_FSDM_OpenVotingPhase", false)
		}
	wait 2
	// }
	
    // Clear players the voted for next voting
    FS_PROPHUNT.votedPlayers.clear()

    // Clear mapids for next voting
    FS_PROPHUNT.mapIds.clear()	
	
	// if( FS_PROPHUNT.currentRound == Flowstate_AutoChangeLevelRounds() && Flowstate_EnableAutoChangeLevel() )
	// {
		// // foreach( player in GetPlayerArray() )
			// // Message( player, "We have reached the round to change levels.", "Total Round: " + FS_PROPHUNT.currentRound, 6.0 )

		// foreach( player in GetPlayerArray() )
			// Message( player, "Server clean up incoming", "Don't leave. Server is going to reload to avoid lag.", 6.0 )

		// wait 6.0

		// GameRules_ChangeMap( GetMapName(), GameRules_GetGameMode() )
	// }

	foreach( player in GetPlayerArray() )
	{
		if( !IsValid( player ) ) continue
		
		ClearInvincible( player )
		player.UnfreezeControlsOnServer()
	}

	FS_PROPHUNT.currentRound++
	
	foreach(player in GetPlayerArray())
	{	
		if(!IsValid(player)) continue
			
		HandlePlayerTeam(player)
	}
}

// purpose: display the UI for randomization of tied maps at the end of voting
void function RandomizeTiedLocations(array<int> maps)
{
    bool donerandomizing = false
    int randomizeammount = RandomIntRange(50, 75)
    int i = 0
    int mapslength = maps.len()
    int currentmapindex = 0
    int selectedamp = 0

    while (!donerandomizing)
    {
        // If currentmapindex is out of range set to 0
        if (currentmapindex >= mapslength)
            currentmapindex = 0

        // Update Randomizer ui for each player
        foreach( player in GetPlayerArray() )
        {
            if( !IsValid( player ) )
                continue

            Remote_CallFunction_Replay(player, "ServerCallback_FSDM_SetScreen", eFSDMScreen.TiedScreen, 69, maps[currentmapindex], 0)
        }

        // stop randomizing once the randomize ammount is done
        if (i >= randomizeammount)
        {
            donerandomizing = true
            selectedamp = currentmapindex
        }

        i++
        currentmapindex++

        if (i >= randomizeammount - 15 && i < randomizeammount - 5) // slow down voting randomizer speed
        {
            wait 0.15
        }
        else if (i >= randomizeammount - 5) // slow down voting randomizer speed
        {
            wait 0.25
        }
        else // default voting randomizer speed
        {
            wait 0.05
        }
    }

    // Show final selected map
    foreach( player in GetPlayerArray() )
    {
        if( !IsValid( player ) )
            continue

        Remote_CallFunction_Replay(player, "ServerCallback_FSDM_SetScreen", eFSDMScreen.TiedScreen, 69, maps[selectedamp], 1)
    }

    // Pause on selected map for a sec for visuals
    wait 0.5

    // Procede to final location picked screen
    foreach( player in GetPlayerArray() )
    {
        if( !IsValid( player ) )
            continue

        Remote_CallFunction_Replay(player, "ServerCallback_FSDM_SetScreen", eFSDMScreen.SelectedScreen, 69, maps[selectedamp], eFSDMScreen.NotUsed)
    }

    // Set selected location on server
    FS_PROPHUNT.mappicked = maps[selectedamp]
}

void function ResetMapVotes()
{
    FS_PROPHUNT.mapVotes.clear()
    FS_PROPHUNT.mapVotes.resize( NUMBER_OF_MAP_SLOTS_FSDM )
}

void function HandlePlayerTeam(entity player)
{
	if(!IsValid(player)) return
	
	player.Show()
	printt(player, player.GetTeam())
	//for connected players midround
	if( player.GetTeam() == 15 && !player.p.PROPHUNT_isSpectatorDiedMidRound)
	{
		player.p.isSpectating = false
		player.SetPlayerNetInt( "spectatorTargetCount", 0 )
	    player.SetSpecReplayDelay( 0 )
		player.SetObserverTarget( null )
        player.StopObserverMode()
		Remote_CallFunction_NonReplay(player, "ServerCallback_KillReplayHud_Deactivate")
		TakeAllWeapons(player)
		player.SetThirdPersonShoulderModeOn()
		player.MakeVisible()
		GiveTeamToProphuntPlayer(player)
		WaitFrame()
		if(!IsValid(player)) return
		
		_HandleRespawnPROPHUNT(player)
		player.UnforceStand()
		player.UnfreezeControlsOnServer()
		
	//for ded players midround
	} else if ( player.p.PROPHUNT_isSpectatorDiedMidRound)
	{
		player.p.isSpectating = false
		player.SetPlayerNetInt( "spectatorTargetCount", 0 )
	    player.SetSpecReplayDelay( 0 )
		player.SetObserverTarget( null )
        player.StopObserverMode()
		Remote_CallFunction_NonReplay(player, "ServerCallback_KillReplayHud_Deactivate")
		if(player.GetTeam() == TEAM_IMC){
			TakeAllWeapons(player)
			player.SetThirdPersonShoulderModeOn()
			SetTeam(player, TEAM_MILITIA )
			WaitFrame()
			if(!IsValid(player)) return
			
			_HandleRespawnPROPHUNT(player)
			player.MakeVisible()
			player.UnforceStand()
			player.UnfreezeControlsOnServer()
		} else if(player.GetTeam() == TEAM_MILITIA){
			TakeAllWeapons(player)
			player.SetThirdPersonShoulderModeOn()
			SetTeam(player, TEAM_IMC )
			WaitFrame()
			if(!IsValid(player)) return
			
			_HandleRespawnPROPHUNT(player)
			player.MakeVisible()
			player.UnforceStand()
			player.UnfreezeControlsOnServer()
		}
	} else 
	{
	//for alive players swap teams
		if(player.GetTeam() == TEAM_IMC){
				TakeAllWeapons(player)
				player.SetThirdPersonShoulderModeOn()
				SetTeam(player, TEAM_MILITIA )
				WaitFrame()
				if(!IsValid(player)) return
				
				_HandleRespawnPROPHUNT(player)
				player.MakeVisible()
				player.UnforceStand()
				player.UnfreezeControlsOnServer()
		
		} else if(player.GetTeam() == TEAM_MILITIA){
				TakeAllWeapons(player)
				player.SetThirdPersonShoulderModeOn()
				SetTeam(player, TEAM_IMC )
				WaitFrame()
				if(!IsValid(player)) return
				
				_HandleRespawnPROPHUNT(player)
				player.MakeVisible()
				player.UnforceStand()
				player.UnfreezeControlsOnServer()
		}
	}	
}


entity function CreateRing_PreGame(LocationSettings location)
{
    array<LocPair> spawns = location.spawns

    vector ringCenter
    foreach( spawn in spawns )
    {
        ringCenter += spawn.origin
    }

    ringCenter /= spawns.len()

    float ringRadius = 0

    foreach( LocPair spawn in spawns )
    {
        if( Distance( spawn.origin, ringCenter ) > ringRadius )
            ringRadius = Distance(spawn.origin, ringCenter)
    }

    ringRadius += GetCurrentPlaylistVarFloat("ring_radius_padding", 800)
	//We watch the ring fx with this entity in the threads
	entity circle = CreateEntity( "prop_script" )
	circle.SetValueForModelKey( $"mdl/fx/ar_survival_radius_1x100.rmdl" )
	circle.kv.fadedist = -1
	circle.kv.modelscale = ringRadius
	circle.kv.renderamt = 255
	circle.kv.rendercolor = FlowState_RingColor()
	circle.kv.solid = 0
	circle.kv.VisibilityFlags = ENTITY_VISIBLE_TO_EVERYONE
	circle.SetOrigin( ringCenter )
	circle.SetAngles( <0, 0, 0> )
	circle.NotSolid()

	DispatchSpawn(circle)
	return circle
}

entity function CreateRingBoundary_PropHunt(LocationSettings location)
{
    array<LocPair> spawns = location.spawns

    vector ringCenter
    foreach( spawn in spawns )
    {
        ringCenter += spawn.origin
    }

    ringCenter /= spawns.len()

    float ringRadius = 0

    foreach( LocPair spawn in spawns )
    {
        if( Distance( spawn.origin, ringCenter ) > ringRadius )
            ringRadius = Distance(spawn.origin, ringCenter)
    }

    ringRadius += GetCurrentPlaylistVarFloat("ring_radius_padding", 800)
	//We watch the ring fx with this entity in the threads
	entity circle = CreateEntity( "prop_script" )
	circle.SetValueForModelKey( $"mdl/fx/ar_survival_radius_1x100.rmdl" )
	circle.kv.fadedist = -1
	circle.kv.modelscale = ringRadius
	circle.kv.renderamt = 255
	circle.kv.rendercolor = FlowState_RingColor()
	circle.kv.solid = 0
	circle.kv.VisibilityFlags = ENTITY_VISIBLE_TO_EVERYONE
	circle.SetOrigin( ringCenter )
	circle.SetAngles( <0, 0, 0> )
	circle.NotSolid()
	circle.DisableHibernation()
    circle.Minimap_SetObjectScale( min(ringRadius / SURVIVAL_MINIMAP_RING_SCALE, 1) )
    circle.Minimap_SetAlignUpright( true )
    circle.Minimap_SetZOrder( 2 )
    circle.Minimap_SetClampToEdge( true )
    circle.Minimap_SetCustomState( eMinimapObject_prop_script.OBJECTIVE_AREA )
	SetTargetName( circle, "hotZone" )
	DispatchSpawn(circle)

    foreach ( player in GetPlayerArray() )
    {
        circle.Minimap_AlwaysShow( 0, player )
    }

	SetDeathFieldParams( ringCenter, ringRadius, ringRadius, 90000, 99999 ) // This function from the API allows client to read ringRadius from server so we can use visual effects in shared function. Colombia

	//Audio thread for ring
	foreach(sPlayer in GetPlayerArray())
		thread AudioThread(circle, sPlayer, ringRadius)

	//Damage thread for ring
	thread RingDamage(circle, ringRadius)

    return circle
}

void function AudioThread(entity circle, entity player, float radius)
{
	EndSignal(player, "OnDestroy")
	entity audio
	string soundToPlay = "Survival_Circle_Edge_Small"
	OnThreadEnd(
		function() : ( soundToPlay, audio)
		{

			if(IsValid(audio)) audio.Destroy()
		}
	)
	audio = CreateScriptMover()
	audio.SetOrigin( circle.GetOrigin() )
	audio.SetAngles( <0, 0, 0> )
	EmitSoundOnEntity( audio, soundToPlay )

	while(IsValid(circle)){
		if(!IsValid(player)) continue
		vector fwdToPlayer   = Normalize( <player.GetOrigin().x, player.GetOrigin().y, 0> - <circle.GetOrigin().x, circle.GetOrigin().y, 0> )
		vector circleEdgePos = circle.GetOrigin() + (fwdToPlayer * radius)
		circleEdgePos.z = player.EyePosition().z
		if ( fabs( circleEdgePos.x ) < 61000 && fabs( circleEdgePos.y ) < 61000 && fabs( circleEdgePos.z ) < 61000 )
		{
			audio.SetOrigin( circleEdgePos )
		}
		WaitFrame()
	}

	StopSoundOnEntity(audio, soundToPlay)
}

void function RingDamage( entity circle, float currentRadius)
{
	WaitFrame()
	const float DAMAGE_CHECK_STEP_TIME = 1.5

	while ( IsValid(circle) )
	{
		foreach ( player in GetPlayerArray_Alive() )
		{
			if ( player.IsPhaseShifted() )
				continue

			float playerDist = Distance2D( player.GetOrigin(), circle.GetOrigin() )
			if ( playerDist > currentRadius )
			{
				Remote_CallFunction_Replay( player, "ServerCallback_PlayerTookDamage", 0, 0, 0, 0, DF_BYPASS_SHIELD | DF_DOOMED_HEALTH_LOSS, eDamageSourceId.deathField, null )
				player.TakeDamage( int( Deathmatch_GetOOBDamagePercent() / 100 * float( player.GetMaxHealth() ) ), null, null, { scriptType = DF_BYPASS_SHIELD | DF_DOOMED_HEALTH_LOSS, damageSourceId = eDamageSourceId.deathField } )
			}
		}
		wait DAMAGE_CHECK_STEP_TIME
	}
}


bool function ClientCommand_NextRoundPROPHUNT(entity player, array<string> args)
{
	if(player.GetPlayerName() == FlowState_Hoster() || player.GetPlayerName() == FlowState_Admin1() || player.GetPlayerName() == FlowState_Admin2() || player.GetPlayerName() == FlowState_Admin3() || player.GetPlayerName() == FlowState_Admin4()) 
	{
		if (args.len()) {
			int mapIndex = int(args[0])
			FS_PROPHUNT.nextMapIndex = (((mapIndex >= 0 ) && (mapIndex < FS_PROPHUNT.locationSettings.len())) ? mapIndex : RandomIntRangeInclusive(0, FS_PROPHUNT.locationSettings.len() - 1))
			FS_PROPHUNT.mapIndexChanged = true

			string now = args[0]
			if (now == "now")
			{
			   SetTdmStateToNextRound()
			   FS_PROPHUNT.mapIndexChanged = false
			   FS_PROPHUNT.InProgress = false
			}
			
			if(args.len() > 1){
				now = args[1]
				if (now == "now")
				{
				   SetTdmStateToNextRound()
				   FS_PROPHUNT.InProgress = false
				}
			}
		}
	}
	else {
		return false
	}
	
	return true
}

string function helpMessagePROPHUNT()
//by michae\l/#1125
{
	return " Use your ULTIMATE to CHANGE PROP up to 3 times. \n Use your ULTIMATE to LOCK ANGLES as attackers arrive. "
}

bool function ClientCommand_VoteForMap_PROPHUNT(entity player, array<string> args)
{
    // don't allow multiple votes
    if ( FS_PROPHUNT.votedPlayers.contains( player ) )
        return false

    // dont allow votes if its not voting time
    if ( !FS_PROPHUNT.votingtime )
        return false

    // get map id from args
    int mapid = args[0].tointeger()

    // reject map ids that are outside of the range
    if ( mapid >= NUMBER_OF_MAP_SLOTS_FSDM || mapid < 0 )
        return false

    // add a vote for selected maps
    FS_PROPHUNT.mapVotes[mapid]++

    // update current amount of votes for each map
    foreach( p in GetPlayerArray() )
    {
        if( !IsValid( p ) )
            continue

        Remote_CallFunction_Replay(p, "ServerCallback_FSDM_UpdateMapVotesClient", FS_PROPHUNT.mapVotes[0], FS_PROPHUNT.mapVotes[1], FS_PROPHUNT.mapVotes[2], FS_PROPHUNT.mapVotes[3])
    }

    // append player to the list of players the voted so they cant vote again
    FS_PROPHUNT.votedPlayers.append(player)

    return true
}