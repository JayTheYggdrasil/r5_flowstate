global function ClGamemodeProphunt_Init
// global function Cl_RegisterLocationPROPHUNT

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
}

// void function Cl_RegisterLocationPROPHUNT(LocationSettings locationSettings)
// {
    // file.locationSettings.append(locationSettings)
// }
