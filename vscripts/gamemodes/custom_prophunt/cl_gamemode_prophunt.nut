global function ClGamemodeProphunt_Init
global function PROPHUNT_DoScreenFlashFX

struct {
    LocationSettings &selectedLocation
    array<LocationSettings> locationSettings
	int teamwon
	vector victorySequencePosition = < 0, 0, 10000 >
	vector victorySequenceAngles = < 0, 0, 0 >
	SquadSummaryData winnerSquadSummaryData
	bool forceShowSelectedLocation = false
} file

void function ClGamemodeProphunt_Init()
{
	RegisterSignal("ChallengeStartRemoveCameras")
	RegisterSignal("ChangeCameraToSelectedLocation")
	
	PrecacheParticleSystem($"P_shell_shock_FP")
}

void function PROPHUNT_DoScreenFlashFX(entity player, entity propAttacker)
{
	entity viewPlayer = GetLocalViewPlayer()
	int fxHandle = StartParticleEffectOnEntityWithPos( viewPlayer, PrecacheParticleSystem( $"P_shell_shock_FP" ), FX_PATTACH_ABSORIGIN_FOLLOW, -1, viewPlayer.EyePosition(), <0,0,0> )
	EffectSetIsWithCockpit( fxHandle, true )
	int fxHandle2 = StartParticleEffectOnEntityWithPos( viewPlayer, PrecacheParticleSystem( $"P_shell_shock_FP" ), FX_PATTACH_ABSORIGIN_FOLLOW, -1, viewPlayer.EyePosition(), <0,0,0> )
	EffectSetIsWithCockpit( fxHandle2, true )
	thread ShellShock_ScreenFXThink(player, fxHandle, fxHandle2)
	
	Obituary_Print_Localized( "ENEMY PROP " + propAttacker.GetPlayerName() + " USED FLASHBANG!", GetChatTitleColorForPlayer( player ), BURN_COLOR )
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
