#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;

init()
{
	hacker_location_random_init();
	limit_equipment( "equip_hacker_zm", 1 );
	include_equipment( "equip_hacker_zm" );
	maps\mp\zombies\_zm_equip_hacker::init();
	register_equipment_for_level( "equip_hacker_zm" );
	thread init_hackables();
}

hacker_location_random_init()
{
	hacker_tool_array = [];
	level.hacker_tool_positions = [];
	hacker = getentarray( "zombie_equipment_upgrade", "targetname" );

	for ( i = 0; i < hacker.size; i++ )
	{
		if ( isdefined( hacker[i].zombie_equipment_upgrade ) && hacker[i].zombie_equipment_upgrade == "equip_hacker_zm" )
		{
			hacker_tool_array[hacker_tool_array.size] = hacker[i];
			struct = spawnstruct();
			struct.trigger_org = hacker[i].origin;
			struct.model_org = getent( hacker[i].target, "targetname" ).origin;
			struct.model_ang = getent( hacker[i].target, "targetname" ).angles;
			level.hacker_tool_positions[level.hacker_tool_positions.size] = struct;
		}
	}

	if ( hacker_tool_array.size > 1 )
	{
		hacker_pos = hacker_tool_array[randomint( hacker_tool_array.size )];
		arrayremovevalue( hacker_tool_array, hacker_pos );
		array_thread( hacker_tool_array, ::hacker_position_cleanup );
	}
}

hacker_position_cleanup()
{
	model = getent( self.target, "targetname" );

	if ( isdefined( model ) )
		model delete();

	if ( isdefined( self ) )
		self delete();
}

init_hackables()
{
	thread maps\mp\zombies\_zm_hackables_wallbuys::hack_wallbuys();

	if ( getdvar( "mapname" ) == "zm_transit" && is_classic() )
		thread scripts\zm\hacker_wallbuys::hack_bus_weapon();

	thread scripts\zm\hacker_perks::hack_perks();
	// thread maps\mp\zombies\_zm_hackables_packapunch::hack_packapunch();
	thread maps\mp\zombies\_zm_hackables_boards::hack_boards();
	thread scripts\zm\hacker_doors::hack_debris();
	thread maps\mp\zombies\_zm_hackables_doors::hack_doors();
	thread maps\mp\zombies\_zm_hackables_powerups::hack_powerups();
	flag_wait( "initial_blackscreen_passed" );
	wait 0.05;

	if ( !isdefined( level.zombie_powerups["fire_sale"] ) )
		replaceFunc( maps\mp\zombies\_zm_hackables_powerups::unhackable_powerup, ::unhackable_powerup );

	thread maps\mp\zombies\_zm_hackables_box::box_hacks();
	wait 1;

	if ( getdvar( "mapname" ) == "zm_buried" )
		thread scripts\zm\hacker_wallbuys::hack_dynamic_wallbuys();
}

unhackable_powerup( name )
{
	ret = 0;

	switch ( name )
	{
		case "bonus_points_player":
		case "bonus_points_team":
		case "lose_points_team":
		case "random_weapon":
		case "full_ammo":
			ret = 1;
			break;
	}

	return ret;
}
