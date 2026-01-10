#include common_scripts\utility;
#include maps\mp\zombies\_zm_hackables_boards;
#include maps\mp\zombies\_zm_utility;

main()
{
	replaceFunc( maps\mp\zombies\_zm_hackables_boards::hack_boards, ::hack_boards );
}

init()
{
	level._zm_blocker_trigger_think_return_override = ::check_blocker_trigger_for_hacker_tool;
	level._zm_build_trigger_from_unitrigger_stub_override = ::moon_unitrigger_stub_override;
}

hack_boards()
{
	windows = getstructarray( "exterior_goal", "targetname" );

	for ( i = 0; i < windows.size; i++ )
	{
		window = windows[i];
		struct = spawnstruct();
		spot = window;

		if ( isdefined( window.trigger_location ) )
			spot = window.trigger_location;

		org = groundpos( spot.origin ) + vectorscale( ( 0, 0, 1 ), 4.0 );
		r = 96;
		h = 96;

		if ( isdefined( spot.radius ) )
			r = spot.radius;

		if ( isdefined( spot.height ) )
			h = spot.height;

		struct.origin = org + vectorscale( ( 0, 0, 1 ), 48.0 );
		struct.radius = r;
		struct.height = h;
		struct.script_float = 2;
		struct.script_int = 0;
		struct.window = window;
		struct.no_bullet_trace = 1;
		struct.no_sight_check = 1;
		struct.dot_limit = 0.7;
		struct.last_hacked_round = 0;
		struct.num_hacks = 0;
		maps\mp\zombies\_zm_equip_hacker::register_pooled_hackable_struct( struct, ::board_hack, ::board_qualifier );
	}
}

check_blocker_trigger_for_hacker_tool( player )
{
	if ( player maps\mp\zombies\_zm_equipment::is_equipment_active( "equip_hacker_zm" ) )
	{
		if ( isdefined( self.unitrigger_stub.trigger ) )
			maps\mp\zombies\_zm_unitrigger::unregister_unitrigger( self.unitrigger_stub );

		return true;
	}
	else
		return false;
}

moon_unitrigger_stub_override( player )
{
	if ( player maps\mp\zombies\_zm_equipment::is_equipment_active( "equip_hacker_zm" ) )
	{
		if ( isdefined( self.trigger_target ) )
		{
			if ( self.trigger_target.targetname == "exterior_goal" )
				return true;
		}
	}

	return false;
}
