#include maps\mp\zombies\_zm_hackables_doors;
#include maps\mp\zombies\_zm_utility;

main()
{
	replaceFunc( maps\mp\zombies\_zm_hackables_doors::hack_doors, ::hack_doors );
	replaceFunc( maps\mp\zombies\_zm_hackables_doors::watch_door_for_open, ::watch_door_for_open );
	replaceFunc( maps\mp\zombies\_zm_hackables_doors::door_hack, ::door_hack );
}

hack_doors( targetname, door_activate_func )
{
	if ( !isdefined( targetname ) )
		targetname = "zombie_door";

	doors = getentarray( targetname, "targetname" );

	if ( !isdefined( door_activate_func ) )
		door_activate_func = maps\mp\zombies\_zm_blockers::door_opened;

	var = !is_classic();
	radius = 48;
	no_sight_check = ( targetname == "zombie_debris" ) ? undefined : 1;

	switch ( getdvar( "mapname" ) )
	{
		case "zm_buried":
			no_sight_check = 1;
			break;
		case "zm_tomb":
			radius = 60;
			break;
	}

	for ( i = 0; i < doors.size; i++ )
	{
		door = doors[i];

		if ( var
			&& ( isdefined( door.script_parameters ) && door.script_parameters == "grief_remove"
			|| isdefined( door.script_noteworthy ) && ( door.script_noteworthy == "electric_door" || door.script_noteworthy == "electric_buyable_door" || door.script_noteworthy == "local_electric_door" ) )
		)
			continue;

		struct = spawnstruct();
		struct.origin = door.origin + anglestoforward( door.angles ) * 2;
		struct.radius = radius;
		struct.height = 72;
		struct.script_float = 32.7;
		struct.script_int = 200;
		struct.door = door;
		struct.no_bullet_trace = 1;
		struct.door_activate_func = door_activate_func;
		trace_passed = 0;
		struct.no_sight_check = no_sight_check;
		door thread hide_door_buy_when_hacker_active( struct );
		maps\mp\zombies\_zm_equip_hacker::register_pooled_hackable_struct( struct, maps\mp\zombies\_zm_hackables_doors::door_hack );
		door thread maps\mp\zombies\_zm_hackables_doors::watch_door_for_open( struct );
	}
}

watch_door_for_open( door_struct )
{
	switch ( self.targetname )
	{
		case "zombie_debris":
			do
				self waittill( "trigger", who, force );
			while ( !is_player_valid( who )
				|| getdvarint( #"zombie_unlock_all" ) <= 0
				&& ( !( isdefined( force ) && force ) && ( !who usebuttonpressed() || who in_revive_trigger() ) || who.score < self.zombie_cost )
			);

			break;
		default:
			self waittill( "door_opened" );
			self endon( "door_hacked" );
			break;
	}

	remove_all_door_hackables_that_target_door( door_struct.door );
}

door_hack( hacker )
{
	switch ( self.door.targetname )
	{
		case "zombie_debris":
			remove_all_door_hackables_that_target_door( self.door );
			self.door.zombie_cost = 0;
			self.door notify( "trigger", hacker, 1 );
			break;
		default:
			self.door notify( "door_hacked" );
			self.door notify( "kill_door_think" );
			remove_all_door_hackables_that_target_door( self.door );
			self.door [[ self.door_activate_func ]]();
			self.door._door_open = 1;
			break;
	}
}
