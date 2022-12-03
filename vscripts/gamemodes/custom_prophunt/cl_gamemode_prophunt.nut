//FLOWSTATE PROPHUNT
//Made by @CafeFPS (Retículo Endoplasmático#5955)

// AyeZee#6969 -- Ctf voting phase to work off
// everyone else -- advice

global function ClGamemodeProphunt_Init
global function PROPHUNT_DoScreenFlashFX
global function PROPHUNT_EnableControlsUI
global function PROPHUNT_RemoveControlsUI
global function PROPHUNT_CustomHint
global function PROPHUNT_AddUsageToHint
global function PROPHUNT_StartMiscTimer

struct {
    LocationSettings &selectedLocation
    array<LocationSettings> locationSettings
	int teamwon
	vector victorySequencePosition = < 0, 0, 10000 >
	vector victorySequenceAngles = < 0, 0, 0 >
	SquadSummaryData winnerSquadSummaryData
	bool forceShowSelectedLocation = false
	array<var> inputHintRuis
	var activeQuickHint = null
} file

void function ClGamemodeProphunt_Init()
{
	SetConVarInt("cl_quota_stringCmdsPerSecond", 100)
	//I don't want these things in user screen even if they launch in debug
	SetConVarBool( "cl_showpos", false )
	SetConVarBool( "cl_showfps", false )
	SetConVarBool( "cl_showgpustats", false )
	SetConVarBool( "cl_showsimstats", false )
	SetConVarBool( "cl_showhoststats", false )
	SetConVarBool( "con_drawnotify", false )
	SetConVarBool( "enable_debug_overlays", false )
	
	RegisterSignal("ChallengeStartRemoveCameras")
	RegisterSignal("ChangeCameraToSelectedLocation")
	RegisterSignal("PROPHUNT_ShutdownWhistleTimer")
	RegisterSignal("PROPHUNT_ShutdownPropsHidingTimer")
	
	PrecacheParticleSystem($"P_shell_shock_FP")
	AddClientCallback_OnResolutionChanged( ReloadMenuRUI )
}

void function PROPHUNT_EnableControlsUI(bool isAttacker)
{
	entity player = GetLocalViewPlayer()
	SetDpadMenuHidden()
	Minimap_DisableDraw_Internal()
	player.p.PROPHUNT_ChangePropUsageLimit = 0
	player.p.PROPHUNT_DecoysPropUsageLimit = 0
	player.p.PROPHUNT_FlashbangPropUsageLimit = 0
	
	// var ruitest = CreateFullscreenRui( $"ui/generic_timer.rpak" )
	// float endtime = Time() + 5
	// RuiSetString( ruitest, "messageText", "test test" )
	// RuiSetGameTime( ruitest, "startTime", Time() )
	// RuiSetGameTime( ruitest, "endTime", endtime )
	// RuiSetColorAlpha( ruitest, "timerColor", SrgbToLinear( <255,233,0> / 255.0 ), 1.0 )
	
	if(!isAttacker)
	{
		Hud_SetEnabled(HudElement( "ScreenBlur1" ), true)
		Hud_SetVisible(HudElement( "ScreenBlur1" ), true)
		
		Hud_SetEnabled(HudElement( "ScreenBlur3" ), true)
		Hud_SetVisible(HudElement( "ScreenBlur3" ), true)
		
		Hud_SetEnabled(HudElement( "PropControlsTitle" ), true)
		Hud_SetVisible(HudElement( "PropControlsTitle" ), true)
		
		Hud_SetEnabled(HudElement( "WhistleTimer" ), true)
		Hud_SetVisible(HudElement( "WhistleTimer" ), true)
		thread UpdateWhistleTimer()
		Hud_SetEnabled(HudElement( "ScreenBlur2" ), true)
		Hud_SetVisible(HudElement( "ScreenBlur2" ), true)
		
		Hud_SetEnabled(HudElement( "ProphuntHint0" ), true)
		Hud_SetVisible(HudElement( "ProphuntHint0" ), true)
		
		Hud_SetEnabled(HudElement( "ProphuntHint1" ), true)
		Hud_SetVisible(HudElement( "ProphuntHint1" ), true)
		
		Hud_SetEnabled(HudElement( "ProphuntHint2" ), true)
		Hud_SetVisible(HudElement( "ProphuntHint2" ), true)
		
		Hud_SetEnabled(HudElement( "ProphuntHint3" ), true)
		Hud_SetVisible(HudElement( "ProphuntHint3" ), true)

		Hud_SetEnabled(HudElement( "ProphuntHint4" ), true)
		Hud_SetVisible(HudElement( "ProphuntHint4" ), true)	
		
		Hud_SetText( HudElement( "ProphuntHint0"), "%attack% Change Prop x" + ( PROPHUNT_CHANGE_PROP_USAGE_LIMIT - player.p.PROPHUNT_ChangePropUsageLimit ).tostring() )
		Hud_SetText( HudElement( "ProphuntHint1"), "%zoom% Lock Angles")
		Hud_SetText( HudElement( "ProphuntHint2"), "%offhand1% Stim Tactical")
		Hud_SetText( HudElement( "ProphuntHint3"), "%melee% Place Decoy x" + ( PROPHUNT_DECOYS_USAGE_LIMIT - player.p.PROPHUNT_DecoysPropUsageLimit ).tostring() )
		Hud_SetText( HudElement( "ProphuntHint4"), "%offhand4% Flash Grenade x" + PROPHUNT_FLASH_BANG_USAGE_LIMIT.tostring())
		
		player.p.isAttackerProphunt = false
		
	} else
	{
		player.p.isAttackerProphunt = true
		Signal(player, "PROPHUNT_ShutdownPropsHidingTimer")
		
		// var hudElement = HudElement( "IngameTextChat" )
		// var height = hudElement.GetHeight()
		// var screenSize = Hud.GetScreenSize()
		// var position = hudElement.GetPos()
		// HudElement( "IngameTextChat" ).SetPos( position[0], -1 * ( screenSize[1] - ( height + screenSize[1] * 0.10 ) ) )
		// AddInputHint( "%scriptCommand5%", "Change Props Model" )
	}
}
void function PROPHUNT_StartMiscTimer()
{
	thread function() : ()
	{
		Hud_SetEnabled(HudElement( "DarkenBackground" ), true)
		Hud_SetVisible(HudElement( "DarkenBackground" ), true)
			
		Hud_SetEnabled(HudElement( "MiscTimer" ), true)
		Hud_SetVisible(HudElement( "MiscTimer" ), true)
			
		entity player = GetLocalClientPlayer() 
		
		EndSignal(player, "PROPHUNT_ShutdownPropsHidingTimer")
		
		OnThreadEnd(
			function() : ( player )
			{
				Hud_SetEnabled(HudElement( "DarkenBackground" ), false)
				Hud_SetVisible(HudElement( "DarkenBackground" ), false)
					
				Hud_SetEnabled(HudElement( "MiscTimer" ), false)
				Hud_SetVisible(HudElement( "MiscTimer" ), false)
			}
		)
		
		int time = PROPHUNT_TELEPORT_ATTACKERS_DELAY
		string text
		while(true)
		{
			if(time == 0)
			{
				text = "TELEPORTING NOW"
				wait 1
				break
			}else if(time == -1)
			{
				time = PROPHUNT_WHISTLE_TIMER
				text = "PROPS ARE HIDING " + time.tostring()
			} else
			{
				text = "PROPS ARE HIDING " + time.tostring()
			}
			
			Hud_SetText( HudElement( "MiscTimer"), text)
			time--
			wait 1
		}
	}()
}

void function UpdateWhistleTimer()
{
	entity player = GetLocalClientPlayer() 
	
	EndSignal(player, "PROPHUNT_ShutdownWhistleTimer")
	int time = PROPHUNT_WHISTLE_TIMER
	string text
    while(true)
    {
		if(time == 0)
		{
			player.ClientCommand("EmitWhistle")
			text = "MAKING NOISE"
			
		}else if(time == -1)
		{
			time = PROPHUNT_WHISTLE_TIMER
			text = "WHISTLE IN " + time.tostring()
		} else
		{
			text = "WHISTLE IN " + time.tostring()
		}
		
        Hud_SetText( HudElement( "WhistleTimer"), text)
        time--
        wait 1
    }
}

void function PROPHUNT_RemoveControlsUI()
{
	RemoveAllHints()
}

void function PROPHUNT_DoScreenFlashFX(entity player, entity propAttacker)
{
	entity viewPlayer = GetLocalViewPlayer()
	int fxHandle = StartParticleEffectOnEntityWithPos( viewPlayer, PrecacheParticleSystem( $"P_shell_shock_FP" ), FX_PATTACH_ABSORIGIN_FOLLOW, -1, viewPlayer.EyePosition(), <0,0,0> )
	EffectSetIsWithCockpit( fxHandle, true )
	int fxHandle2 = StartParticleEffectOnEntityWithPos( viewPlayer, PrecacheParticleSystem( $"P_shell_shock_FP" ), FX_PATTACH_ABSORIGIN_FOLLOW, -1, viewPlayer.EyePosition(), <0,0,0> )
	EffectSetIsWithCockpit( fxHandle2, true )
	thread ShellShock_ScreenFXThink(player, fxHandle, fxHandle2)
	
	Obituary_Print_Localized( "Enemy prop " + propAttacker.GetPlayerName() + " used flashbang!", GetChatTitleColorForPlayer( player ), BURN_COLOR )
}

void function ShellShock_ScreenFXThink( entity player, int fxHandle, int fxHandle2 )
{
	player.EndSignal( "OnDeath" )

	OnThreadEnd(
		function() : ( fxHandle, fxHandle2 )
		{
			if ( !EffectDoesExist( fxHandle ) )
				return

			EffectStop( fxHandle, false, true )
			
			if ( !EffectDoesExist( fxHandle2 ) )
				return

			EffectStop( fxHandle2, false, true )
		}
	)
	wait 1
}

void function ReloadMenuRUI()
{
	RemoveAllHints(true)
	entity player = GetLocalViewPlayer()
	
	if(!player.p.isAttackerProphunt)
	{
		player.p.isAttackerProphunt = false
	
		Hud_SetEnabled(HudElement( "ScreenBlur1" ), true)
		Hud_SetVisible(HudElement( "ScreenBlur1" ), true)
		
		Hud_SetEnabled(HudElement( "ScreenBlur3" ), true)
		Hud_SetVisible(HudElement( "ScreenBlur3" ), true)
		
		Hud_SetEnabled(HudElement( "PropControlsTitle" ), true)
		Hud_SetVisible(HudElement( "PropControlsTitle" ), true)
		
		Hud_SetEnabled(HudElement( "WhistleTimer" ), true)
		Hud_SetVisible(HudElement( "WhistleTimer" ), true)

		Hud_SetEnabled(HudElement( "ScreenBlur2" ), true)
		Hud_SetVisible(HudElement( "ScreenBlur2" ), true)
		
		Hud_SetEnabled(HudElement( "ProphuntHint0" ), true)
		Hud_SetVisible(HudElement( "ProphuntHint0" ), true)
		
		Hud_SetEnabled(HudElement( "ProphuntHint1" ), true)
		Hud_SetVisible(HudElement( "ProphuntHint1" ), true)
		
		Hud_SetEnabled(HudElement( "ProphuntHint2" ), true)
		Hud_SetVisible(HudElement( "ProphuntHint2" ), true)
		
		Hud_SetEnabled(HudElement( "ProphuntHint3" ), true)
		Hud_SetVisible(HudElement( "ProphuntHint3" ), true)

		Hud_SetEnabled(HudElement( "ProphuntHint4" ), true)
		Hud_SetVisible(HudElement( "ProphuntHint4" ), true)	
		
		Hud_SetText( HudElement( "ProphuntHint0"), "%attack% Change Prop x" + ( PROPHUNT_CHANGE_PROP_USAGE_LIMIT - player.p.PROPHUNT_ChangePropUsageLimit ).tostring() )
		Hud_SetText( HudElement( "ProphuntHint1"), "%zoom% Lock Angles")
		Hud_SetText( HudElement( "ProphuntHint2"), "%offhand1% Stim Tactical")
		Hud_SetText( HudElement( "ProphuntHint3"), "%melee% Place Decoy x" + ( PROPHUNT_DECOYS_USAGE_LIMIT - player.p.PROPHUNT_DecoysPropUsageLimit ).tostring() )
		Hud_SetText( HudElement( "ProphuntHint4"), "%offhand4% Flash Grenade x" + PROPHUNT_FLASH_BANG_USAGE_LIMIT.tostring())
	} else
	{
		player.p.isAttackerProphunt = true
		//AddInputHint( "%scriptCommand5%", "Change Props Model" )
	}
}

void function AddInputHint( string buttonText, string hintText)
{
	UISize screenSize = GetScreenSize()
	int offset = file.inputHintRuis.len()
	
	var topo = RuiTopology_CreatePlane( <( screenSize.width * 0.20),( screenSize.height * 0.15) + offset*45, 0>, <float( screenSize.width )*1.1, 0, 0>, <0, float( screenSize.height )*1.1, 0>, false )
	var hintRui = RuiCreate( $"ui/announcement_quick_right.rpak", topo, RUI_DRAW_HUD, 0 )
	
	RuiSetGameTime( hintRui, "startTime", Time() )
	RuiSetString( hintRui, "messageText", buttonText + " " + hintText )
	RuiSetFloat( hintRui, "duration", 9999999 )
	RuiSetFloat3( hintRui, "eventColor", SrgbToLinear( <255, 0, 119> / 255.0 ) )
	
    file.inputHintRuis.append( hintRui )
}

void function PROPHUNT_AddUsageToHint( int index )
{
	entity player = GetLocalViewPlayer()
	
	switch(index)
	{
		case 0:
			player.p.PROPHUNT_ChangePropUsageLimit = player.p.PROPHUNT_ChangePropUsageLimit + 1
			ChangeInputHintString(0)
		break
		case 1:
			player.p.PROPHUNT_DecoysPropUsageLimit = player.p.PROPHUNT_DecoysPropUsageLimit + 1
			ChangeInputHintString(3)
		break
		case 2:
			player.p.PROPHUNT_FlashbangPropUsageLimit = player.p.PROPHUNT_FlashbangPropUsageLimit + 1
			ChangeInputHintString(4)
		break
		case 3:
			ChangeInputHintString(1)
		break
	}
		
}

void function ChangeInputHintString( int index )
{
	entity player = GetLocalViewPlayer()
	
	// var hintRui = file.inputHintRuis[index]
	
	string messageText
	string hintButton
	switch(index)
	{
		case 0:
			messageText = "Change Prop x" + ( PROPHUNT_CHANGE_PROP_USAGE_LIMIT - player.p.PROPHUNT_ChangePropUsageLimit ).tostring()
			hintButton = "%attack%"
			Hud_SetText( HudElement( "ProphuntHint0"), hintButton + " " + messageText)
		break
		case 3:
			messageText = "Place Decoy x" + ( PROPHUNT_DECOYS_USAGE_LIMIT - player.p.PROPHUNT_DecoysPropUsageLimit ).tostring()
			hintButton = "%melee%"
			Hud_SetText( HudElement( "ProphuntHint3"), hintButton + " " + messageText)
		break
		case 4:
			messageText = "Flash Grenade x" + ( PROPHUNT_FLASH_BANG_USAGE_LIMIT - player.p.PROPHUNT_FlashbangPropUsageLimit ).tostring()
			hintButton = "%offhand4%"
			Hud_SetText( HudElement( "ProphuntHint4"), hintButton + " " + messageText)
		break
		case 1:
			if(player.p.PROPHUNT_AreAnglesLocked)
			{
				messageText = "Lock Angles"
				player.p.PROPHUNT_AreAnglesLocked = false
			}
			else
			{
				messageText = "Unlock Angles"
				player.p.PROPHUNT_AreAnglesLocked = true
			}
			hintButton = "%zoom%"
			Hud_SetText( HudElement( "ProphuntHint1"), hintButton + " " + messageText)
		break
		
	}
}

void function PROPHUNT_CustomHint(int index)
{
	switch(index)
	{
		case 0:
		QuickHint("", "Angles locked!")
		break
		case 1:
		QuickHint("", "Angles unlocked!")
		break
		case 2:
		QuickHint("", "Limit reached!")
		break
		case 3:
		QuickHint("", "Slope matched!")
		break
		case 4:
		QuickHint("", "Decoy placed!")
		break
		case 5:
		QuickHint("", "Seekers arrived!")
		break
		case 6:
		QuickHint("", "Flashbang used!")
		break		
	}
}

void function QuickHint( string buttonText, string hintText)
{
	if(file.activeQuickHint != null)
	{
		RuiDestroyIfAlive( file.activeQuickHint )
		file.activeQuickHint = null
	}
	file.activeQuickHint = CreateFullscreenRui( $"ui/announcement_quick_right.rpak" )
	
	RuiSetGameTime( file.activeQuickHint, "startTime", Time() )
	RuiSetString( file.activeQuickHint, "messageText", buttonText + " " + hintText )
	RuiSetFloat( file.activeQuickHint, "duration", 2 )
	RuiSetFloat3( file.activeQuickHint, "eventColor", SrgbToLinear( <255, 0, 119> / 255.0 ) )
}

void function RemoveAllHints(bool wasResolutionChanged = false)
{
    foreach( rui in file.inputHintRuis )
    {
        RuiDestroy( rui )
    }
    file.inputHintRuis.clear()
	Hud_SetEnabled(HudElement( "ScreenBlur1" ), false)
	Hud_SetVisible(HudElement( "ScreenBlur1" ), false)
	
	Hud_SetEnabled(HudElement( "ScreenBlur3" ), false)
	Hud_SetVisible(HudElement( "ScreenBlur3" ), false)
	
	Hud_SetEnabled(HudElement( "PropControlsTitle" ), false)
	Hud_SetVisible(HudElement( "PropControlsTitle" ), false)
	
	Hud_SetEnabled(HudElement( "WhistleTimer" ), false)
	Hud_SetVisible(HudElement( "WhistleTimer" ), false)
		
	Hud_SetEnabled(HudElement( "ScreenBlur2" ), false)
	Hud_SetVisible(HudElement( "ScreenBlur2" ), false)
		
	Hud_SetEnabled(HudElement( "ProphuntHint0" ), false)
	Hud_SetVisible(HudElement( "ProphuntHint0" ), false)
		
	Hud_SetEnabled(HudElement( "ProphuntHint1" ), false)
	Hud_SetVisible(HudElement( "ProphuntHint1" ), false)
		
	Hud_SetEnabled(HudElement( "ProphuntHint2" ), false)
	Hud_SetVisible(HudElement( "ProphuntHint2" ), false)
	
	Hud_SetEnabled(HudElement( "ProphuntHint3" ), false)
	Hud_SetVisible(HudElement( "ProphuntHint3" ), false)

	Hud_SetEnabled(HudElement( "ProphuntHint4" ), false)
	Hud_SetVisible(HudElement( "ProphuntHint4" ), false)
	
	entity player = GetLocalViewPlayer()
	Signal(player, "PROPHUNT_ShutdownWhistleTimer")
		
	if(!wasResolutionChanged)
	{
		player.p.PROPHUNT_ChangePropUsageLimit = 0
		player.p.PROPHUNT_DecoysPropUsageLimit = 0
		player.p.PROPHUNT_FlashbangPropUsageLimit = 0
	}
}