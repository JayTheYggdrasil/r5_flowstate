//FLOWSTATE PROPHUNT
//Made by @CafeFPS (Retículo Endoplasmático#5955)

// AyeZee#6969 -- Ctf voting phase to work off
// everyone else -- advice

global function _GamemodeProphunt_Init
global function _RegisterLocationPROPHUNT
global function _OnPlayerConnectedPROPHUNT
global function _OnPlayerDiedPROPHUNT
global function PROPHUNT_StartGameThread
global function returnPropBool

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
    array<entity> votedPlayers
    bool votingtime = false
    bool votestied = false
    array<int> mapVotes
    array<int> mapIds
    int mappicked = 0
	int currentRound = 1
	
	int maxvotesallowedforTeams = -1
	
	int requestsforIMC = -1
	int requestsforMILITIA = -1	
} FS_PROPHUNT

void function _GamemodeProphunt_Init()
{
	SetConVarInt("sv_quota_stringCmdsPerSecond", 100)
	
	if(GetCurrentPlaylistVarBool("enable_global_chat", true))
		SetConVarBool("sv_forceChatToTeamOnly", false)
	else
		SetConVarBool("sv_forceChatToTeamOnly", true)
	
	SurvivalFreefall_Init() //Enables freefall/skydive
	
	RegisterSignal("DestroyProp")
	
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
	AddClientCommandCallback("EmitWhistle", ClientCommand_PROPHUNT_EmitWhistle)
	AddClientCommandCallback("AskForTeam", ClientCommand_PROPHUNT_AskForTeam)

	PrecacheCustomMapsProps()
	
	foreach(prop in prophuntAssetsWE)
		PrecacheModel(prop)
	
	PrecacheParticleSystem($"P_impact_exp_xo_shield_med_CP")
	PrecacheParticleSystem($"P_plasma_exp_SM")
	PrecacheModel($"mdl/fx/ar_edge_sphere_512.rmdl")
	PrecacheParticleSystem($"P_smokescreen_FD")
	thread PROPHUNT_StartGameThread()	
}

void function _OnEntitiesDidLoadPROPHUNT()
{
	SpawnFlowstateLobbyProps()
	AddSpawnCallback("prop_dynamic", _OnPropDynamicSpawnedPROPHUNT) //it should be after spawn lobby props so they won't be deleted
}

void function _RegisterLocationPROPHUNT(LocationSettings locationSettings)
{
    FS_PROPHUNT.locationSettings.append(locationSettings)
}

void function _OnPropDynamicSpawnedPROPHUNT(entity prop)
{
    FS_PROPHUNT.playerSpawnedProps.append(prop)
}

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

void function PROPHUNT_StartGameThread()
{
    WaitForGameState(eGameState.Playing)
	
    while(true)
	{
		PROPHUNT_Lobby()
		PROPHUNT_GameLoop()
		WaitFrame()
	}
}

void function PROPHUNT_CharSelect( entity player)
//By Retículo Endoplasmático#5955 (CaféDeColombiaFPS)//
{
	if(FlowState_ForceCharacter())
	{
		ItemFlavor PersonajeEscogido = GetAllCharacters()[FlowState_ChosenCharacter()]
		CharacterSelect_AssignCharacter( ToEHI( player ), PersonajeEscogido )		
	}
	else
	{
		ItemFlavor PersonajeEscogido = GetAllCharacters()[RandomInt(9)]
		CharacterSelect_AssignCharacter( ToEHI( player ), PersonajeEscogido )		
	}
	TakeAllWeapons(player)
}

void function _OnPlayerConnectedPROPHUNT(entity player)
{
	while(IsDisconnected( player )) WaitFrame()

    if(!IsValid(player)) return

	CreatePanelText( player, "Flowstate", "", <-19766, 2111, 6541>, <0, 180, 0>, false, 2 )
	
	if(FlowState_ForceCharacter())
	{
		PROPHUNT_CharSelect(player)
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
	Survival_SetInventoryEnabled( player, false )				
	player.SetPlayerNetInt( "respawnStatus", eRespawnStatus.NONE )
	player.SetPlayerNetBool( "pingEnabled", true )
	player.SetHealth( 100 )
	Inventory_SetPlayerEquipment(player, "armor_pickup_lv2", "armor")
	player.SetShieldHealth( 75 )
	player.kv.solid = 6
	player.kv.CollisionGroup = TRACE_COLLISION_GROUP_PLAYER
	player.kv.fadedist = 999999
	player.AllowMantle()
			
	switch(GetGameState())
    {
		case eGameState.WaitingForPlayers:
		case eGameState.MapVoting:
			if(!IsValid(player)) return
			
			//printt("Flowstate DEBUG - Prophunt player connected mapvoting.", player)
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
			
			player.p.isSpectating = true
			
			array<entity> playersON = GetPlayerArray_Alive()
			playersON.fastremovebyvalue( player )
			
			printt("Flowstate DEBUG - Prophunt player connected midround, setting spectator.", player)
			array<LocPair> prophuntSpawns = FS_PROPHUNT.selectedLocation.spawns
			player.SetOrigin(prophuntSpawns[RandomIntRangeInclusive(0,prophuntSpawns.len()-1)].origin)
			player.MakeInvisible()
			player.p.PROPHUNT_isSpectatorDiedMidRound = false
			player.MovementDisable()
			SetTeam(player, 15 )
			
			foreach(availablePlayers in playersON)
			{
				if(!IsValid(availablePlayers) || IsValid(availablePlayers) && !IsAlive(availablePlayers) || IsValid(availablePlayers) && availablePlayers.p.isSpectating)
					playersON.fastremovebyvalue( availablePlayers )
			}
			
			if(playersON.len() == 0) 
			{
				thread SetSpectatorAnotherTry(player)
				return
			}
			entity specTarget = playersON.getrandom()
			if( IsValid( specTarget ) && ShouldSetObserverTarget( specTarget ))
			{
				player.SetPlayerNetInt( "spectatorTargetCount", GetPlayerArray_Alive().len() )
				player.SetObserverTarget( specTarget )
				player.SetSpecReplayDelay( 2 )
				player.StartObserverMode( OBS_MODE_IN_EYE )
				Remote_CallFunction_NonReplay(player, "ServerCallback_KillReplayHud_Activate")
			} else
			{
				thread SetSpectatorAnotherTry(player)
			}
			break
		default:
			break
	}
}

void function SetSpectatorAnotherTry(entity player)
{
	wait 3
	if(!FS_PROPHUNT.InProgress || !IsValid(player) || GetPlayerArray_Alive().len() == 0) 
	{
		Message(player, "FS PROPHUNT", "You will spawn next round")
		return
	}
	array<entity> playersON = GetPlayerArray_Alive()
	
	foreach(availablePlayers in playersON)
	{
		if(!IsValid(availablePlayers) || IsValid(availablePlayers) && !IsAlive(availablePlayers) || IsValid(availablePlayers) && availablePlayers.p.isSpectating)
			playersON.fastremovebyvalue( availablePlayers )
	}
	
	if(playersON.len() == 0) 
	{
		Message(player, "FS PROPHUNT", "You will spawn next round")
		return
	}
	
	entity specTarget = playersON.getrandom()
	if( IsValid( specTarget ) && ShouldSetObserverTarget( specTarget ))
	{
		player.SetPlayerNetInt( "spectatorTargetCount", GetPlayerArray_Alive().len() )
		player.SetObserverTarget( specTarget )
		player.SetSpecReplayDelay( 2 )
		player.StartObserverMode( OBS_MODE_IN_EYE )
		Remote_CallFunction_NonReplay(player, "ServerCallback_KillReplayHud_Activate")
	} else {
		Message(player, "FS PROPHUNT", "You will spawn next round")
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
				} else if (GetPlayerArray_Alive().len() > 0)
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
							
				RemoveButtonPressedPlayerInputCallback( victim, IN_ATTACK, ClientCommand_ChangeProp )
				RemoveButtonPressedPlayerInputCallback( victim, IN_ZOOM, ClientCommand_LockAngles )
				RemoveButtonPressedPlayerInputCallback( victim, IN_ZOOM_TOGGLE, ClientCommand_LockAngles ) //fix for the weirdos using ads toggle
				RemoveButtonPressedPlayerInputCallback( victim, IN_MELEE, ClientCommand_CreatePropDecoy )
				RemoveButtonPressedPlayerInputCallback( victim, IN_OFFHAND4, ClientCommand_EmitFlashBangToNearbyPlayers )
				//RemoveButtonPressedPlayerInputCallback( victim, IN_RELOAD, ClientCommand_MatchSlope )
				Remote_CallFunction_NonReplay(victim, "Minimap_DisableDraw_Internal")
				Remote_CallFunction_NonReplay(victim, "PROPHUNT_RemoveControlsUI")
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
	//printt("Flowstate DEBUG - Prophunt player killed.", victim, " -by- ", attacker)
	
}

void function _HandleRespawnPROPHUNT(entity player)
{
	if(!IsValid(player)) return
	
	//printt("Flowstate DEBUG - Tping prophunt player to Lobby.", player)

	if(FlowState_ForceCharacter())
	{
		PROPHUNT_CharSelect(player)
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
	
	ItemFlavor playerCharacter = LoadoutSlot_GetItemFlavor( ToEHI( player ), Loadout_CharacterClass() )
	asset characterSetFile = CharacterClass_GetSetFile( playerCharacter )
	player.SetPlayerSettingsWithMods( characterSetFile, [] )
	SetPlayerSettings(player, PROPHUNT_SETTINGS)
	
	if(IsValid(player.p.PROPHUNT_LastPropEntity))
		player.p.PROPHUNT_LastPropEntity.Destroy()
	
	player.SetThirdPersonShoulderModeOn()
	Survival_SetInventoryEnabled( player, false )
	player.SetPlayerNetInt( "respawnStatus", eRespawnStatus.NONE )
	player.SetPlayerNetBool( "pingEnabled", true )
	Inventory_SetPlayerEquipment(player, "armor_pickup_lv2", "armor")
	player.SetShieldHealth( 75 )
	player.SetHealth( 100 )
	player.kv.solid = 6
	player.kv.CollisionGroup = TRACE_COLLISION_GROUP_PLAYER
	player.kv.fadedist = 999999
	player.AllowMantle()
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
	
	if(player.p.teamasked != -1)
	{
		switch(player.p.teamasked)
		{
			case 0:
				SetTeam(player, TEAM_IMC )
				break
			case 1:
				SetTeam(player, TEAM_MILITIA )
				break
			default:
			break
		}
		
		return
	}
	
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
	//printt("Flowstate DEBUG - Giving team to player.", player, player.GetTeam())
}

void function StartHuntersAbilityTimer()
{
	float endTime = Time() + PROPHUNT_ATTACKERS_ABILITY_COOLDOWN
	
	OnThreadEnd(
	function() : ()
	{
		if(GetGameState() == eGameState.Playing)
		{
			array<entity> IMCplayers = GetPlayerArrayOfTeam_Alive(TEAM_IMC)
			foreach(player in IMCplayers)
			{
				if(!IsValid(player)) continue
				AddButtonPressedPlayerInputCallback( player, IN_OFFHAND4, ClientCommand_hunters_ForceChangeProp )
				Remote_CallFunction_NonReplay( player, "EnableHuntersAbility")
			}
		}
	})
	
	while( Time() <= endTime && GetGameState() == eGameState.Playing)
	{
		if( Time() == (endTime-5) )
		{
			foreach(player in GetPlayerArrayOfTeam_Alive(TEAM_MILITIA))
			{
				if(!IsValid(player)) continue
				
				Remote_CallFunction_NonReplay( player, "PROPHUNT_CustomHint", 12)
			}
		}
		
		WaitFrame()
	}
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
	
	//printt("Flowstate DEBUG - Ending round cuz not enough players midround")
}

void function PropWatcher(entity prop, entity player)
{
	EndSignal(player, "OnDeath")
	EndSignal(player, "DestroyProp")
	
	OnThreadEnd(
	function() : ( prop)
	{
		if(IsValid(prop))
			prop.Destroy()
	})
	
	while(IsValid(player) && FS_PROPHUNT.InProgress )
		WaitFrame()
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

void function PROPHUNT_GiveAndManageProp(entity player, bool giveOldProp = false, bool forcelockedangles = false)
{
	if(!IsValid(player)) return
	
	if(!forcelockedangles)
		Signal(player, "DestroyProp")

	asset selectedModel
	if(giveOldProp)
		selectedModel = player.p.PROPHUNT_LastModel
	else
	{
		int modelindex = RandomIntRangeInclusive(0,(prophuntAssetsWE.len()-1))
		while(modelindex == player.p.PROPHUNT_LastModelIndex) //remove me
		{
			modelindex = RandomIntRangeInclusive(0,(prophuntAssetsWE.len()-1))
			WaitFrame()
		}
		player.p.PROPHUNT_LastModelIndex = modelindex
		selectedModel = prophuntAssetsWE[modelindex]
		player.p.PROPHUNT_LastModel = selectedModel
	}
	
	if(forcelockedangles)
	{
		player.SetBodyModelOverride( selectedModel )
		player.SetArmsModelOverride( selectedModel )
		
		if(IsValid(player.p.PROPHUNT_LastPropEntity))
			player.p.PROPHUNT_LastPropEntity.SetModel( selectedModel )
		player.p.PROPHUNT_LastModel = selectedModel

		player.p.PROPHUNT_AreAnglesLocked = true
		return
	}

	entity prop = CreatePropDynamic(selectedModel, player.GetOrigin(), player.GetAngles(), 6, -1)
	player.p.PROPHUNT_LastPropEntity = prop
	prop.kv.CollisionGroup = TRACE_COLLISION_GROUP_PLAYER
	prop.kv.solid = 6
	prop.kv.fadedist = 999999
	
	prop.SetTakeDamageType( DAMAGE_YES )
	prop.AllowMantle()
	prop.SetCanBeMeleed( true )
	prop.SetMaxHealth( 100 )
	prop.SetHealth( player.GetHealth() )
	prop.SetParent(player)
	
	prop.SetPassDamageToParent(true)
	
	thread PropWatcher(prop, player) 
}

void function PROPHUNT_Lobby()
{
	DestroyPlayerPropsPROPHUNT()
	SetGameState(eGameState.MapVoting) //!FIXME
	SetFallTriggersStatus(true)
	if(GetMapName() == "mp_rr_desertlands_64k_x_64k" || GetMapName() == "mp_rr_desertlands_64k_x_64k_nx" || GetMapName() == "mp_rr_canyonlands_mu1" || GetMapName() == "mp_rr_canyonlands_mu1_night" || GetMapName() == "mp_rr_canyonlands_64k_x_64k")
	{
		thread CreateShipRoomFallTriggers()
	}
	//printt("Flowstate DEBUG - Fall triggers created.")

	if (!FS_PROPHUNT.mapIndexChanged)
		{
			FS_PROPHUNT.nextMapIndex = ( FS_PROPHUNT.nextMapIndex + 1 ) % FS_PROPHUNT.locationSettings.len()
		}

	if (FlowState_LockPOI()) {
		FS_PROPHUNT.nextMapIndex = FlowState_LockedPOI()
	}
		
	FS_PROPHUNT.mapIndexChanged = false
	FS_PROPHUNT.selectedLocation = FS_PROPHUNT.locationSettings[ FS_PROPHUNT.mappicked ]
	//printt("Flowstate DEBUG - Next location selected: ", FS_PROPHUNT.selectedLocation.name)
		
	if(FS_PROPHUNT.selectedLocation.name == "Skill trainer By CafeFPS")
	{
		DestroyPlayerPropsPROPHUNT()
		WaitFrame()
		thread SkillTrainerLoad()
		wait 1
		//printt("Flowstate DEBUG - Skill trainer loading.")
	}
	
	foreach(player in GetPlayerArray())
	{
		if(!IsValid(player)) continue
		
		player.p.PROPHUNT_isSpectatorDiedMidRound = false
		player.UnforceStand()
		player.UnfreezeControlsOnServer()
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
		
					// Remote_CallFunction_NonReplay( player, "PROPHUNT_CustomHint", 8)
				}
				wait 5
				// break
				
			} else {
				
				foreach(player in GetPlayerArray())
				{
					if(!IsValid(player)) continue
		
					Remote_CallFunction_NonReplay( player, "PROPHUNT_CustomHint", 9)
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
		
		Remote_CallFunction_NonReplay( player, "PROPHUNT_CustomHint", 10)
	}
	wait 5
}

void function PROPHUNT_GameLoop()
{
	SetTdmStateToInProgress()
	//printt("Flowstate DEBUG - tdmState is eTDMState.IN_PROGRESS Starting round.")

	SurvivalCommentary_ResetAllData()
	FS_PROPHUNT.endTime = Time() + GetCurrentPlaylistVarFloat("flowstatePROPHUNTLimitTime", 300 )
	
	array<entity> IMCplayers = GetPlayerArrayOfTeam(TEAM_IMC)
	array<entity> MILITIAplayers = GetPlayerArrayOfTeam(TEAM_MILITIA)

	array<LocPair> prophuntSpawns = FS_PROPHUNT.selectedLocation.spawns

	FS_PROPHUNT.cantUseChangeProp = false
	FS_PROPHUNT.InProgress = true
	//thread EmitSoundOnSprintingProp()
	
	FS_PROPHUNT.ringBoundary_PreGame = CreateRing_PreGame(FS_PROPHUNT.selectedLocation)
	SetGameState( eGameState.Playing )
	//printt("Flowstate DEBUG - Tping props team.")
	foreach(player in GetPlayerArray())
	{
		if(!IsValid(player)) continue
		
		//try{TakePassive(player, ePassives.PAS_PILOT_BLOOD)}catch(e420){}
		//Inventory_SetPlayerEquipment(player, WHITE_SHIELD, "armor") //props dont like shields FX
		ClearInvincible( player )
		
		player.p.playerDamageDealt = 0.0
		if(player.GetTeam() == TEAM_MILITIA)
		{
			
			Remote_CallFunction_NonReplay(player, "PROPHUNT_EnableControlsUI", false)

			AddButtonPressedPlayerInputCallback( player, IN_ATTACK, ClientCommand_ChangeProp )
			AddButtonPressedPlayerInputCallback( player, IN_ZOOM, ClientCommand_LockAngles )
			AddButtonPressedPlayerInputCallback( player, IN_ZOOM_TOGGLE, ClientCommand_LockAngles ) //fix for the weirdos using ads toggle
			AddButtonPressedPlayerInputCallback( player, IN_MELEE, ClientCommand_CreatePropDecoy )
			AddButtonPressedPlayerInputCallback( player, IN_OFFHAND4, ClientCommand_EmitFlashBangToNearbyPlayers )
			//AddButtonPressedPlayerInputCallback( player, IN_RELOAD, ClientCommand_MatchSlope )
			
			vector lastPosForCoolParticles = player.GetOrigin()
			vector lastAngForCoolParticles = player.GetAngles()
			StartParticleEffectInWorld( GetParticleSystemIndex( $"P_impact_shieldbreaker_sparks" ), lastPosForCoolParticles, lastAngForCoolParticles )
			StartParticleEffectInWorld( GetParticleSystemIndex( $"P_impact_shieldbreaker_sparks" ), lastPosForCoolParticles, lastAngForCoolParticles )
			EmitSoundOnEntityOnlyToPlayer( player, player, "PhaseGate_Enter_1p" )
			EmitSoundOnEntityExceptToPlayer( player, player, "PhaseGate_Enter_3p" )
			player.SetOrigin(prophuntSpawns[RandomIntRangeInclusive(0,prophuntSpawns.len()-1)].origin)
			int modelindex = RandomIntRangeInclusive(0,(prophuntAssetsWE.len()-1))
			player.p.PROPHUNT_LastModelIndex = modelindex
			asset selectedModel = prophuntAssetsWE[modelindex]
			player.p.PROPHUNT_LastModel = selectedModel
			
			player.kv.solid = 0
			player.kv.CollisionGroup = TRACE_COLLISION_GROUP_PLAYER
			
			player.kv.fadedist = 999999
			player.AllowMantle()
			player.Hide()
			
			entity prop = CreatePropDynamic(selectedModel, player.GetOrigin(), player.GetAngles(), 6, -1)
			prop.SetParent(player)
			prop.kv.solid = 6
			
			player.p.PROPHUNT_LastPropEntity = prop
			prop.kv.CollisionGroup = TRACE_COLLISION_GROUP_PLAYER
			prop.kv.fadedist = 999999
			prop.AllowMantle()
			prop.SetDamageNotifications( true )
			prop.SetTakeDamageType( DAMAGE_YES )
			prop.SetMaxHealth( 100 )
			prop.SetHealth( player.GetHealth() )
			
			prop.SetPassDamageToParent(true)
			
			thread PropWatcher(prop, player) //destroys prop on end round and restores player model.
			
			player.SetThirdPersonShoulderModeOn()
			player.TakeOffhandWeapon(OFFHAND_TACTICAL)
			player.TakeOffhandWeapon(OFFHAND_ULTIMATE)
			player.GiveOffhandWeapon("mp_ability_heal", OFFHAND_TACTICAL)
			player.GiveOffhandWeapon("mp_weapon_flashbang_fakeultimate", OFFHAND_ULTIMATE)
			//player.GiveOffhandWeapon("mp_ability_phase_walk", OFFHAND_ULTIMATE)
			player.TakeOffhandWeapon( OFFHAND_EQUIPMENT )
			player.GiveOffhandWeapon( "mp_ability_emote_projector", OFFHAND_EQUIPMENT )
			DeployAndEnableWeapons(player)
			
			Remote_CallFunction_NonReplay(player, "Minimap_DisableDraw_Internal")
			Remote_CallFunction_NonReplay(player, "PROPHUNT_StartMiscTimer", true)
			wait 0.2
		} else if(player.GetTeam() == TEAM_IMC)
		{
			Remote_CallFunction_NonReplay(player, "PROPHUNT_StartMiscTimer", false) //props are hiding, seekers arriving
		}
	}

	wait PROPHUNT_TELEPORT_ATTACKERS_DELAY-3
	
	foreach(player in GetPlayerArray())
	{
		if(!IsValid(player)) continue
		
		if(player.GetTeam() == TEAM_IMC)
			ScreenFade( player, 0, 0, 0, 255, 4.0, 1, FFADE_OUT | FFADE_PURGE )
	}
	wait 4
	
	UpdatePlayerCounts()
	
	SetFallTriggersStatus(false)

	FS_PROPHUNT.cantUseChangeProp = true
	//printt("Flowstate DEBUG - Tping attackers team.")
	
	foreach(player in IMCplayers)
	{
		if(!IsValid(player)) continue
		
		Remote_CallFunction_NonReplay(player, "PROPHUNT_EnableControlsUI", true)
		
		AddButtonPressedPlayerInputCallback( player, IN_OFFHAND4, ClientCommand_hunters_ForceChangeProp )
		EmitSoundOnEntityOnlyToPlayer( player, player, "PhaseGate_Enter_1p" )
		EmitSoundOnEntityExceptToPlayer( player, player, "PhaseGate_Enter_3p" )
		player.SetOrigin(prophuntSpawns[RandomIntRangeInclusive(0,prophuntSpawns.len()-1)].origin)
		player.kv.solid = 6
		player.kv.CollisionGroup = TRACE_COLLISION_GROUP_PLAYER
		player.kv.fadedist = 999999
		player.AllowMantle()
		player.SetThirdPersonShoulderModeOff()
		string pri = GetCurrentPlaylistVarString("flowstatePROPHUNTweapon1", "~~none~~")
		string sec = GetCurrentPlaylistVarString("flowstatePROPHUNTweapon2", "~~none~~")
		if(pri != "")
		{
			player.TakeNormalWeaponByIndexNow( WEAPON_INVENTORY_SLOT_PRIMARY_0 )
			entity weapon = player.GiveWeapon( pri, WEAPON_INVENTORY_SLOT_PRIMARY_0, [] )
			array<string> mods = weapon.GetMods()
			mods.append( "prophunt" )
			try{weapon.SetMods( mods )} catch(e42069){printt("failed to put prophunt mod.")}
			
		}
		if(sec != "")
		{
			player.TakeNormalWeaponByIndexNow( WEAPON_INVENTORY_SLOT_PRIMARY_1 )
			entity weapon = player.GiveWeapon( sec, WEAPON_INVENTORY_SLOT_PRIMARY_1, [] )
			array<string> mods = weapon.GetMods()
			mods.append( "prophunt" )
			try{weapon.SetMods( mods )} catch(e42069){printt("failed to put prophunt mod.")}
		}
		
		player.TakeOffhandWeapon(OFFHAND_TACTICAL)
		player.GiveOffhandWeapon("mp_ability_heal", OFFHAND_TACTICAL)
		player.GiveWeapon( "mp_weapon_combat_katana_primary", WEAPON_INVENTORY_SLOT_PRIMARY_2, [] )
		player.GiveOffhandWeapon( "melee_combat_katana", OFFHAND_MELEE, [] )
		player.TakeOffhandWeapon( OFFHAND_EQUIPMENT )
		player.GiveOffhandWeapon( "mp_ability_emote_projector", OFFHAND_EQUIPMENT )
		DeployAndEnableWeapons(player)
		
		Highlight_SetFriendlyHighlight( player, "prophunt_teammate" )
		Highlight_SetEnemyHighlight( player, "survival_enemy_skydiving" )
		Remote_CallFunction_NonReplay(player, "Minimap_EnableDraw_Internal")
	}
	
	FS_PROPHUNT.ringBoundary_PreGame.Destroy()
	FS_PROPHUNT.ringBoundary = CreateRingBoundary_PropHunt(FS_PROPHUNT.selectedLocation)
	
	foreach(player in GetPlayerArray())
	{
		if(!IsValid(player)) continue
		
		if (player.GetTeam() == TEAM_MILITIA)
		{
			Remote_CallFunction_NonReplay( player, "PROPHUNT_CustomHint", 5)
		}
		// else if (player.GetTeam() == TEAM_IMC)
		// {
			// array<entity> MILITIAplayersAlive = GetPlayerArrayOfTeam_Alive(TEAM_MILITIA)
			// //Message(player, "ATTENTION", "Kill the props. Props alive: " + MILITIAplayersAlive.len(), 20)
		// }			
	}
	
	// SetGlobalNetInt( "currentDeathFieldStage", 0 )
	// SetGlobalNetTime( "nextCircleStartTime", FS_PROPHUNT.endTime )
	// SetGlobalNetTime( "circleCloseTime", FS_PROPHUNT.endTime + 8 )
		
	if(!GetCurrentPlaylistVarBool("flowstatePROPHUNTDebug", false ))
		thread CheckForPlayersPlaying()
	
	int TeamWon
	while( Time() <= FS_PROPHUNT.endTime )
		{
			if(Time() == FS_PROPHUNT.endTime-GetCurrentPlaylistVarFloat("flowstatePROPHUNTLimitTime", 300 )/2)
			{
				foreach(player in GetPlayerArray())
				{
					if(!IsValid(player)) continue
					
					Remote_CallFunction_NonReplay(player, "PROPHUNT_QuickText", 0, 3)
				}
			}

			if(Time() == FS_PROPHUNT.endTime-30)
			{
				foreach(player in GetPlayerArray())
				{
					if(!IsValid(player)) continue
					
					//Message(player,"30 SECONDS REMAINING", "", 5, "diag_ap_aiNotify_circleMoves30sec")
					Remote_CallFunction_NonReplay(player, "PROPHUNT_QuickText", 1, 4)
				}
			}
			if(GetTDMState() == 1)
			{
				//printt("Flowstate DEBUG - tdmState is eTDMState.NEXT_ROUND_NOW Loop ended.")
				break
			}
			WaitFrame()	
		}
	
	array<entity> MILITIAplayersAlive = GetPlayerArrayOfTeam_Alive(TEAM_MILITIA)
	array<entity> IMCplayersAlive = GetPlayerArrayOfTeam_Alive(TEAM_IMC)		
	entity champion
	if(MILITIAplayersAlive.len() > 0){
		TeamWon = TEAM_MILITIA
				
		foreach(player in GetPlayerArray())
		{
			if(!IsValid(player)) continue
						
			RemoveButtonPressedPlayerInputCallback( player, IN_ATTACK, ClientCommand_ChangeProp )
			RemoveButtonPressedPlayerInputCallback( player, IN_ZOOM, ClientCommand_LockAngles )
			RemoveButtonPressedPlayerInputCallback( player, IN_ZOOM_TOGGLE, ClientCommand_LockAngles ) //fix for the weirdos using ads toggle
			RemoveButtonPressedPlayerInputCallback( player, IN_MELEE, ClientCommand_CreatePropDecoy )
			RemoveButtonPressedPlayerInputCallback( player, IN_OFFHAND4, ClientCommand_EmitFlashBangToNearbyPlayers )
			Message(player, "PROPS TEAM WIN", "", 4, "diag_ap_aiNotify_winnerFound")
			
			bool clearOnClient = false
			
			int i = 0
			foreach( Winnerplayer in MILITIAplayersAlive )
			{
				if(i == 0)
					Remote_CallFunction_NonReplay(player, "PROPHUNT_AddWinningSquadData_PropTeamAddModelIndex", true, Winnerplayer.GetEncodedEHandle(), Winnerplayer.p.PROPHUNT_LastModelIndex)
				else
					Remote_CallFunction_NonReplay(player, "PROPHUNT_AddWinningSquadData_PropTeamAddModelIndex", false, Winnerplayer.GetEncodedEHandle(), Winnerplayer.p.PROPHUNT_LastModelIndex)
				i++
			}
			
			player.SetThirdPersonShoulderModeOn()
			HolsterAndDisableWeapons(player)
			player.FreezeControlsOnServer()
			MakeInvincible( player )
		}
		
		champion = MILITIAplayersAlive[0]
		
		foreach(player in GetPlayerArrayOfTeam_Alive(TEAM_IMC))
		{
			if(!IsValid(player)) continue
			
			RemoveButtonPressedPlayerInputCallback( player, IN_OFFHAND4, ClientCommand_hunters_ForceChangeProp )
			Remote_CallFunction_NonReplay(player, "CreateAndMoveCameraToWinnerProp", MILITIAplayersAlive[0])
			Remote_CallFunction_NonReplay(player, "PROPHUNT_QuickText", 2, 4)
		}
	} else {
		TeamWon = TEAM_IMC
		
		foreach(player in GetPlayerArray())
		{
			if(!IsValid(player)) continue
			
			RemoveButtonPressedPlayerInputCallback( player, IN_OFFHAND4, ClientCommand_hunters_ForceChangeProp )
			Message(player, "HUNTERS TEAM WIN", "", 4, "diag_ap_aiNotify_winnerFound")
			player.SetThirdPersonShoulderModeOn()	
			HolsterAndDisableWeapons(player)
		}
		
		champion = IMCplayersAlive[0]
	}
	
	if(IsValid(champion))
		SetChampion( champion )
	
	foreach(player in GetPlayerArray())
	{
		if(!IsValid(player)) continue
		
		AddCinematicFlag( player, CE_FLAG_HIDE_MAIN_HUD )
		//AddCinematicFlag( player, CE_FLAG_EXECUTION )
		
		Remote_CallFunction_NonReplay(player, "Minimap_DisableDraw_Internal")
		Highlight_ClearEnemyHighlight( player )
		Highlight_ClearFriendlyHighlight( player )
		Remote_CallFunction_NonReplay(player, "PROPHUNT_RemoveControlsUI")
	}
	SetGameState(eGameState.MapVoting)
	
	SendScoreboardToClient()
	
	wait 5
	foreach(player in GetPlayerArray())
	{
		if(!IsValid(player)) continue
		
		if(player.p.isSpectating)
		{
			player.p.isSpectating = false
			player.SetPlayerNetInt( "spectatorTargetCount", 0 )
			player.SetSpecReplayDelay( 0 )
			player.SetObserverTarget( null )
			player.StopObserverMode()
			Remote_CallFunction_NonReplay(player, "ServerCallback_KillReplayHud_Deactivate")
		}
	}
	
	UpdatePlayerCounts()
	FS_PROPHUNT.InProgress = false
	FS_PROPHUNT.ringBoundary.Destroy()
	SetDeathFieldParams( <0,0,0>, 100000, 0, 90000, 99999 )
	//printt("Flowstate DEBUG - Prophunt round finished Swapping teams.")
	foreach( player in GetPlayerArray() )
	{
		if( !IsValid( player ) ) continue
		RemoveCinematicFlag( player, CE_FLAG_HIDE_MAIN_HUD | CE_FLAG_EXECUTION )
		player.SetThirdPersonShoulderModeOff()	
		player.FreezeControlsOnServer()
	}
	
	// Only do voting for maps with multi locations
	// if ( FS_PROPHUNT.locationSettings.len() >= NUMBER_OF_MAP_SLOTS_FSDM )
	// {
		// for each player, open the vote menu and set it to the winning team screen
		
	ResetMapVotes()

	foreach( player in GetPlayerArray() )
	{
		if( !IsValid( player ) )
			continue
		
		//reset props abilities
		player.p.PROPHUNT_AreAnglesLocked = false
		player.p.PROPHUNT_ChangePropUsageLimit = 0
		player.p.PROPHUNT_DecoysPropUsageLimit = 0
		player.p.PROPHUNT_FlashbangPropUsageLimit = 0
		player.p.teamasked = -1
		
		//reset votes
		Remote_CallFunction_Replay(player, "ServerCallback_FSDM_UpdateMapVotesClient", FS_PROPHUNT.mapVotes[0], FS_PROPHUNT.mapVotes[1], FS_PROPHUNT.mapVotes[2], FS_PROPHUNT.mapVotes[3])
		
		//launch champion screen + voting phase
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

		// foreach( player in GetPlayerArray() )
		// {
			// if( !IsValid( player ) )
				// continue
			
			// Remote_CallFunction_NonReplay(player, "ServerCallback_FSDM_CoolCamera")
			// Remote_CallFunction_Replay(player, "ServerCallback_FSDM_SetScreen", eFSDMScreen.ScoreboardUI, TeamWon, eFSDMScreen.NotUsed, eFSDMScreen.NotUsed)
			// EmitSoundOnEntityOnlyToPlayer(player, player, "UI_Menu_RoundSummary_Results")
		// }
		
		// wait 7

		FS_PROPHUNT.maxvotesallowedforTeams = int(floor(GetPlayerArray().len()/2))
		FS_PROPHUNT.requestsforIMC = 0
		FS_PROPHUNT.requestsforMILITIA = 0
		
		// Set voting to be allowed
		FS_PROPHUNT.votingtime = true

		// For each player, set voting screen and update maps that are picked for voting
		foreach( player in GetPlayerArray() )
		{
			if( !IsValid( player ) )
				continue
			
			Remote_CallFunction_NonReplay(player, "ServerCallback_FSDM_CoolCamera")
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
		wait 7

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
	player.MakeVisible()
	//printt(player, player.GetTeam())
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
		player.MovementEnable()
		GiveTeamToProphuntPlayer(player)
		WaitFrame()
		if(!IsValid(player)) return
		
		_HandleRespawnPROPHUNT(player)
		player.UnforceStand()
		player.UnfreezeControlsOnServer()
	
		return
	}
		
	//for ded players midround
	if ( player.p.PROPHUNT_isSpectatorDiedMidRound )
	{
		player.p.isSpectating = false
		player.SetPlayerNetInt( "spectatorTargetCount", 0 )
	    player.SetSpecReplayDelay( 0 )
		player.SetObserverTarget( null )
        player.StopObserverMode()
		Remote_CallFunction_NonReplay(player, "ServerCallback_KillReplayHud_Deactivate")

		if(player.p.teamasked != -1)
		{
			TakeAllWeapons(player)
			player.SetThirdPersonShoulderModeOn()
			
			switch(player.p.teamasked)
			{
				case 0:
					SetTeam(player, TEAM_IMC )
					break
				case 1:
					SetTeam(player, TEAM_MILITIA )
					break
				default:
				break
			}
		
			WaitFrame()
			if(!IsValid(player)) return
			
			_HandleRespawnPROPHUNT(player)
			player.MakeVisible()
			player.UnforceStand()
			player.UnfreezeControlsOnServer()			
			
			return
		}
		
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

		if(player.p.teamasked != -1)
		{
			TakeAllWeapons(player)
			player.SetThirdPersonShoulderModeOn()
			
			switch(player.p.teamasked)
			{
				case 0:
					SetTeam(player, TEAM_IMC )
					break
				case 1:
					SetTeam(player, TEAM_MILITIA )
					break
				default:
				break
			}
		
				WaitFrame()
				if(!IsValid(player)) return
				
				_HandleRespawnPROPHUNT(player)
				player.MakeVisible()
				player.UnforceStand()
				player.UnfreezeControlsOnServer()			
			
			return
		}
	
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
			   // FS_PROPHUNT.InProgress = false
			}
			
			if(args.len() > 1){
				now = args[1]
				if (now == "now")
				{
				   SetTdmStateToNextRound()
				   // FS_PROPHUNT.InProgress = false
				}
			}
		}
	}
	else {
		return false
	}
	
	return true
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
void function ClientCommand_hunters_ForceChangeProp(entity hunterPlayer)
{
	if(!IsValid(hunterPlayer) || IsValid(hunterPlayer) && hunterPlayer.GetTeam() != TEAM_IMC || GetGameState() != eGameState.Playing) return

	foreach(player in GetPlayerArrayOfTeam_Alive(TEAM_MILITIA))
	{
		if(!IsValid(player) || IsValid(player) && player.GetTeam() != TEAM_MILITIA || IsValid(player) && player == hunterPlayer) continue
		
		if(player.p.PROPHUNT_AreAnglesLocked)
		{
			// int newscore = player.p.PROPHUNT_ChangePropUsageLimit + 1
			// player.p.PROPHUNT_ChangePropUsageLimit = newscore
			// if (player.p.PROPHUNT_ChangePropUsageLimit <= PROPHUNT_CHANGE_PROP_USAGE_LIMIT)
			// {
				player.SetBodyModelOverride( $"" )
				player.SetArmsModelOverride( $"" )
				player.kv.solid = 0
				player.kv.CollisionGroup = TRACE_COLLISION_GROUP_PLAYER
				player.kv.fadedist = 999999
				player.AllowMantle()
				player.Hide()
				thread PROPHUNT_GiveAndManageProp(player, false, true)
				// Remote_CallFunction_NonReplay( player, "PROPHUNT_AddUsageToHint", 0)
				// Remote_CallFunction_NonReplay( player, "PROPHUNT_CustomHint", 7)
			// } else 
			// {
				Remote_CallFunction_NonReplay( player, "PROPHUNT_CustomHint", 11)
			// }		
		} else if(!player.p.PROPHUNT_AreAnglesLocked)
		{
			// int newscore = player.p.PROPHUNT_ChangePropUsageLimit + 1
			// player.p.PROPHUNT_ChangePropUsageLimit = newscore
			// if (player.p.PROPHUNT_ChangePropUsageLimit <= PROPHUNT_CHANGE_PROP_USAGE_LIMIT)
			// {
				thread PROPHUNT_GiveAndManageProp(player)
				// Remote_CallFunction_NonReplay( player, "PROPHUNT_AddUsageToHint", 0)
				// Remote_CallFunction_NonReplay( player, "PROPHUNT_CustomHint", 7)
			// } else 
			// {
				Remote_CallFunction_NonReplay( player, "PROPHUNT_CustomHint", 11)
			// }		
		}
	}
	
	foreach(player in GetPlayerArrayOfTeam_Alive(TEAM_IMC))
	{
		Remote_CallFunction_NonReplay( player, "PROPHUNT_CustomHint", 11)
		RemoveButtonPressedPlayerInputCallback( hunterPlayer, IN_OFFHAND4, ClientCommand_hunters_ForceChangeProp )
		Remote_CallFunction_NonReplay( hunterPlayer, "ForceDisableHuntersAbilityHint")
	}

	thread StartHuntersAbilityTimer()
}

void function ClientCommand_ChangeProp(entity player)
{
	if(!IsValid(player) || IsValid(player) && player.GetTeam() != TEAM_MILITIA || GetGameState() != eGameState.Playing) return

	if(player.p.PROPHUNT_AreAnglesLocked)
	{
		int newscore = player.p.PROPHUNT_ChangePropUsageLimit + 1
		player.p.PROPHUNT_ChangePropUsageLimit = newscore
		if (player.p.PROPHUNT_ChangePropUsageLimit <= PROPHUNT_CHANGE_PROP_USAGE_LIMIT)
		{
			player.SetBodyModelOverride( $"" )
			player.SetArmsModelOverride( $"" )
			player.kv.solid = 0
			player.kv.CollisionGroup = TRACE_COLLISION_GROUP_PLAYER
			player.kv.fadedist = 999999
			player.AllowMantle()
			player.Hide()
			thread PROPHUNT_GiveAndManageProp(player, false, true)
			Remote_CallFunction_NonReplay( player, "PROPHUNT_AddUsageToHint", 0)
			Remote_CallFunction_NonReplay( player, "PROPHUNT_CustomHint", 7)
		} else 
		{
			Remote_CallFunction_NonReplay( player, "PROPHUNT_CustomHint", 2)
		}		
	} else if(!player.p.PROPHUNT_AreAnglesLocked)
	{
		int newscore = player.p.PROPHUNT_ChangePropUsageLimit + 1
		player.p.PROPHUNT_ChangePropUsageLimit = newscore
		if (player.p.PROPHUNT_ChangePropUsageLimit <= PROPHUNT_CHANGE_PROP_USAGE_LIMIT)
		{
			thread PROPHUNT_GiveAndManageProp(player)
			Remote_CallFunction_NonReplay( player, "PROPHUNT_AddUsageToHint", 0)
			Remote_CallFunction_NonReplay( player, "PROPHUNT_CustomHint", 7)
		} else 
		{
			Remote_CallFunction_NonReplay( player, "PROPHUNT_CustomHint", 2)
		}		
	}
}

void function ClientCommand_MatchSlope(entity player)
{
	if(!IsValid(player) || IsValid(player) && player.GetTeam() != TEAM_MILITIA) return

	vector testOrg = player.GetOrigin()
	vector mins = player.GetPlayerMins()
	vector maxs = player.GetPlayerMaxs()
	int collisionGroup = TRACE_COLLISION_GROUP_PLAYER
	
	TraceResults result = TraceHull( testOrg, testOrg + < 0, 0, -150 >, mins, maxs, [ player ], TRACE_MASK_PLAYERSOLID | TRACE_MASK_SOLID | TRACE_MASK_SHOT, TRACE_COLLISION_GROUP_PLAYER )
		
	float slope = fabs( result.surfaceNormal.x ) + fabs( result.surfaceNormal.y )
	if ( slope > 0.6 )
	{
		printt("is slope and now what")
		
	}
	
	// vector GoodAngles = AnglesOnSurface(result.surfaceNormal, -AnglesToRight(player.EyeAngles()))
	// player.SetAngles( GoodAngles )
	
	// Remote_CallFunction_NonReplay( player, "PROPHUNT_CustomHint", 3)
	
	// if(!IsValid(player.p.PROPHUNT_LastPropEntity)) return
	
	// entity prop = player.p.PROPHUNT_LastPropEntity
	// prop.SetAngles( GoodAngles )
}

void function ClientCommand_LockAngles(entity player)
{
	if(!IsValid(player) || IsValid(player) && player.GetTeam() != TEAM_MILITIA) return

	if(!player.p.PROPHUNT_AreAnglesLocked)
	{
		player.SetBodyModelOverride( player.p.PROPHUNT_LastModel )
		player.SetArmsModelOverride( player.p.PROPHUNT_LastModel )

		player.p.PROPHUNT_AreAnglesLocked = true
		Remote_CallFunction_NonReplay( player, "PROPHUNT_CustomHint", 0)
		Remote_CallFunction_NonReplay( player, "PROPHUNT_AddUsageToHint", 3)
		//Angles are locked!!
	} else if(player.p.PROPHUNT_AreAnglesLocked)
	{
		Signal(player, "DestroyProp")

		player.SetBodyModelOverride( $"" )
		player.SetArmsModelOverride( $"" )

		thread PROPHUNT_GiveAndManageProp(player, true)
		player.p.PROPHUNT_AreAnglesLocked = false
		Remote_CallFunction_NonReplay( player, "PROPHUNT_CustomHint", 1)
		Remote_CallFunction_NonReplay( player, "PROPHUNT_AddUsageToHint", 3)
		//Angles are unlocked!!
	}
}

void function ClientCommand_CreatePropDecoy(entity player)
{
	if(!IsValid(player) || IsValid(player) && player.GetTeam() != TEAM_MILITIA) return
	
	player.p.PROPHUNT_DecoysPropUsageLimit = player.p.PROPHUNT_DecoysPropUsageLimit + 1
	if (player.p.PROPHUNT_DecoysPropUsageLimit <= PROPHUNT_DECOYS_USAGE_LIMIT)
	{
		entity decoy = player.CreateTargetedPlayerDecoy( player.GetOrigin(), $"", player.p.PROPHUNT_LastModel, 0, 0 )
		decoy.SetMaxHealth( 100 )
		decoy.SetHealth( 100 )
		decoy.EnableAttackableByAI( 50, 0, AI_AP_FLAG_NONE )
		SetObjectCanBeMeleed( decoy, true )
		decoy.SetTimeout( Time()-FS_PROPHUNT.endTime )
		decoy.SetPlayerOneHits( true )
		decoy.SetAngles( player.GetAngles() )
		PutEntityInSafeSpot( decoy, player, null, player.GetOrigin(), decoy.GetOrigin() )
		Remote_CallFunction_NonReplay( player, "PROPHUNT_AddUsageToHint", 1)
		Remote_CallFunction_NonReplay( player, "PROPHUNT_CustomHint", 4)
	} else
	{
		Remote_CallFunction_NonReplay( player, "PROPHUNT_CustomHint", 2)
	}
}

void function ClientCommand_EmitFlashBangToNearbyPlayers(entity player)
{
	if(!IsValid(player) || IsValid(player) && player.GetTeam() != TEAM_MILITIA) return
	
	player.p.PROPHUNT_FlashbangPropUsageLimit = player.p.PROPHUNT_FlashbangPropUsageLimit + 1
	if (player.p.PROPHUNT_FlashbangPropUsageLimit <= PROPHUNT_FLASH_BANG_USAGE_LIMIT)
	{
	
		foreach(sPlayer in GetPlayerArray_Alive())
		{
			if(!IsValid(sPlayer)) continue
			
			if(sPlayer == player || player.GetTeam() == sPlayer.GetTeam() ) continue
			
			float playerDist = Distance2D( player.GetOrigin(), sPlayer.GetOrigin() )
			if ( playerDist <= PROPHUNT_FLASH_BANG_RADIUS )
			{
				Remote_CallFunction_NonReplay( sPlayer, "PROPHUNT_DoScreenFlashFX", sPlayer, player)						

				StatusEffect_AddTimed( sPlayer, eStatusEffect.turn_slow, 0.35, 3.0, 0.5 )
				StatusEffect_AddTimed( sPlayer, eStatusEffect.move_slow, 0.50, 3.0, 0.5 )
			}
		}
		Remote_CallFunction_NonReplay( player, "PROPHUNT_DoScreenFlashFX", player, player)
		EmitSoundOnEntityExceptToPlayer(player, player, "explo_proximityemp_impact_3p")
		Remote_CallFunction_NonReplay( player, "PROPHUNT_AddUsageToHint", 2)
		Remote_CallFunction_NonReplay( player, "PROPHUNT_CustomHint", 6)
		entity trailFXHandle = StartParticleEffectInWorld_ReturnEntity(GetParticleSystemIndex( $"P_plasma_exp_SM" ), player.GetOrigin(), <RandomIntRangeInclusive(-180,180), RandomIntRangeInclusive(-180,180), RandomIntRangeInclusive(-180,180)>)
		entity trailFXHandle2 = StartParticleEffectInWorld_ReturnEntity(GetParticleSystemIndex( $"P_impact_exp_xo_shield_med_CP" ), player.GetOrigin(), <RandomIntRangeInclusive(-180,180), RandomIntRangeInclusive(-180,180), RandomIntRangeInclusive(-180,180)>)
		
		entity smokes = StartParticleEffectInWorld_ReturnEntity( GetParticleSystemIndex( $"P_smokescreen_FD" ), player.GetOrigin(), <0,0,0> )
		EmitSoundOnEntity( smokes, "bangalore_smoke_grenade_explosion_3p" )
		
		entity circle = CreateEntity( "prop_dynamic" )
		circle.SetValueForModelKey( $"mdl/fx/ar_edge_sphere_512.rmdl" )
		circle.kv.modelscale = 1.2
		circle.SetOrigin( player.GetOrigin() + <0.0, 0.0, -25>)
		circle.SetAngles( <0, 0, 0> )
		DispatchSpawn(circle)
		circle.SetParent(player)
		
		thread HandleCircleEntity(player, circle)
		thread HandleSmokesEntity(player, smokes)
		
		if(player.p.PROPHUNT_FlashbangPropUsageLimit == PROPHUNT_FLASH_BANG_USAGE_LIMIT && IsValid(player.GetOffhandWeapon( OFFHAND_ULTIMATE )))
			player.TakeOffhandWeapon( OFFHAND_ULTIMATE )
	} else 
	{
		Remote_CallFunction_NonReplay( player, "PROPHUNT_CustomHint", 2)
	}
}

void function HandleCircleEntity(entity player, entity circle)
{
	EndSignal(player, "OnDeath")
	float endTime = Time() + 1
	
	OnThreadEnd(
	function() : ( circle )
	{
		if(IsValid(circle))
			circle.Destroy()
	})
	
	while( Time() <= endTime && IsValid(player) && FS_PROPHUNT.InProgress)
		WaitFrame()
}

void function HandleSmokesEntity(entity player, entity smokes)
{
	EndSignal(player, "OnDeath")
	float endTime = Time() + 5
	
	OnThreadEnd(
	function() : ( smokes )
	{
		if(IsValid(smokes))
			smokes.Destroy()
	})
	
	while( Time() <= endTime && IsValid(player) && FS_PROPHUNT.InProgress)
		WaitFrame()
}

bool function ClientCommand_PROPHUNT_EmitWhistle(entity player, array < string > args) 
{	
	if(!IsValid(player) || IsValid(player) && player.GetTeam() != TEAM_MILITIA) return false
	
	// foreach(sPlayer in GetPlayerArrayOfTeam_Alive(TEAM_IMC))
	// {
		// if(!IsValid(sPlayer)) continue

		// float playerDist = Distance2D( player.GetOrigin(), sPlayer.GetOrigin() )
		// if ( playerDist <= PROPHUNT_WHISTLE_RADIUS )
		// {
			// EmitSoundOnEntityOnlyToPlayer( player, sPlayer, "Wattson_Tactical_M_3p" )			
		// }
	// }
	// EmitSoundOnEntityOnlyToPlayer( player, player, "Wattson_Tactical_M_1p" )
	
	//EmitSoundOnEntity( player, "explo_mgl_impact_3p" )
	EmitSoundAtPosition( TEAM_UNASSIGNED, player.GetOrigin(), "explo_mgl_impact_3p" )
	return true
}

bool function ClientCommand_PROPHUNT_AskForTeam(entity player, array < string > args) 
{	
	if( !IsValid(player) || args.len() != 1 || !FS_PROPHUNT.votingtime || player.p.teamasked != -1 ) return false

	switch(args[0])
	{
		case "0":
			if(FS_PROPHUNT.requestsforIMC <= FS_PROPHUNT.maxvotesallowedforTeams)
			{
				player.p.teamasked = 0
				FS_PROPHUNT.requestsforIMC++
			}
			
			if(FS_PROPHUNT.requestsforIMC == FS_PROPHUNT.maxvotesallowedforTeams)
			{
				foreach(sPlayer in GetPlayerArray()) //no more votes allowed for imc, disable this button for all players that have not voted yet and select the other team for them
				{
					if(!IsValid(sPlayer) || IsValid(sPlayer) && sPlayer == player ) continue
					
					if(sPlayer.p.teamasked == -1)
					{
						sPlayer.p.teamasked = 1
						Remote_CallFunction_NonReplay(sPlayer, "PROPHUNT_Disable_IMCButton")	
					}
				}
			}			
		break
		
		case "1":
			if(FS_PROPHUNT.requestsforMILITIA <= FS_PROPHUNT.maxvotesallowedforTeams)
			{
				player.p.teamasked = 1
				FS_PROPHUNT.requestsforMILITIA++
			}
			
			if(FS_PROPHUNT.requestsforMILITIA == FS_PROPHUNT.maxvotesallowedforTeams)
			{
				foreach(sPlayer in GetPlayerArray()) //no more votes allowed for militia, disable this button for all players that have not voted yet and select the other team for them
				{
					if(!IsValid(sPlayer) || IsValid(sPlayer) && sPlayer == player ) continue
					
					if(sPlayer.p.teamasked == -1)
					{
						sPlayer.p.teamasked = 0
						Remote_CallFunction_NonReplay(sPlayer, "PROPHUNT_Disable_MILITIAButton")	
					}						
				}					
			}			
		break
		
		default:
			player.p.teamasked = -1
		break
	}	
	
	return true
}