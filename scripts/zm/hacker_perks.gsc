#include maps\mp\zombies\_zm_hackables_perks;
/*
main()
{
	replaceFunc( maps\mp\zombies\_zm_hackables_perks::hack_perks, ::hack_perks );
}
*/
init()
{
	switch ( getdvar( "mapname" ) )
	{
		case "zm_nuked":
		case "zm_highrise":
			level._hack_perks_override = ::_hack_perks_override;
			break;
	}
}

_hack_perks_override()
{
	self.entity = self.perk;
	return self;
}

hack_perks()
{
	vending_triggers = getentarray( "zombie_vending", "targetname" );

	if ( getdvar( "mapname" ) == "zm_nuked" )
		radius = 64;
	else
		radius = 48;

	for ( i = 0; i < vending_triggers.size; i++ )
	{
		if ( isdefined( vending_triggers[i].script_noteworthy ) && vending_triggers[i].script_noteworthy == "specialty_weapupgrade" )
			continue;

		struct = spawnstruct();

		if ( isdefined( vending_triggers[i].machine ) )
			machine[0] = vending_triggers[i].machine;
		else
			machine = getentarray( vending_triggers[i].target, "targetname" );

		struct.origin = machine[0].origin + anglestoright( machine[0].angles ) * 18 + vectorscale( ( 0, 0, 1 ), 48.0 );
		struct.radius = radius;
		struct.height = 64;
		struct.script_float = 5;

		while ( !isdefined( vending_triggers[i].cost ) )
			wait 0.05;

		struct.script_int = int( vending_triggers[i].cost * -1 );
		struct.perk = vending_triggers[i];

		if ( isdefined( level._hack_perks_override ) )
			struct = struct [[ level._hack_perks_override ]]();

		vending_triggers[i].hackable = struct;
		struct.no_bullet_trace = 1;
		maps\mp\zombies\_zm_equip_hacker::register_pooled_hackable_struct( struct, ::perk_hack, ::perk_hack_qualifier );
	}

	level._solo_revive_machine_expire_func = ::solo_revive_expire_func;
}
