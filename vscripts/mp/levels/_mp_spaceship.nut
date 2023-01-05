global function CodeCallback_MapInit

void function CodeCallback_MapInit()
{
	//PrecacheModel($"mdl/props/flowstatecustom/spaceship/floor1/prop_test.rmdl")
	AddCallback_EntitiesDidLoad( OnEntitiesDidLoad )
}

void function OnEntitiesDidLoad()
{
    SpawnMap()
}

void function SpawnMap()
{
 
}