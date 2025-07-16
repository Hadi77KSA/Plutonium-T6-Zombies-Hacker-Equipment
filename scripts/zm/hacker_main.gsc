#include common_scripts\utility;
#include maps\mp\zombies\_zm_equip_hacker;
#include maps\mp\zombies\_zm_utility;

main()
{
	replaceFunc( maps\mp\zombies\_zm_equip_hacker::hacker_do_hack, ::hacker_do_hack );
	hacker_location_random_init();

	if ( level.hacker_tool_positions.size == 0 )
		hacker_pos();

	limit_equipment( "equip_hacker_zm", 1 );
	include_equipment( "equip_hacker_zm" );
	maps\mp\zombies\_zm_equip_hacker::init();
	register_equipment_for_level( "equip_hacker_zm" );
}

init()
{
	hacker = getEnt( "wpn_hacker", "target" );

	if ( isdefined( hacker ) )
		hacker initial_spawn();

	thread init_hackables();
}

hacker_do_hack( hackable )
{
	timer = 0;
	hacked = 0;
	hackable._trigger.beinghacked = 1;

	if ( !isdefined( self.hackerprogressbar ) )
		self.hackerprogressbar = self maps\mp\gametypes_zm\_hud_util::createprimaryprogressbar();

	if ( !isdefined( self.hackertexthud ) )
		self.hackertexthud = newclienthudelem( self );

	hack_duration = hackable.script_float;

	if ( self hasperk( "specialty_fastreload" ) )
		hack_duration = hack_duration * 0.66;

	hack_duration = max( 1.5, hack_duration );
	self thread tidy_on_deregister( hackable );
	self.hackerprogressbar maps\mp\gametypes_zm\_hud_util::updatebar( 0.01, 1 / hack_duration );
	self.hackertexthud.alignx = "center";
	self.hackertexthud.aligny = "middle";
	self.hackertexthud.horzalign = "center";
	self.hackertexthud.vertalign = "bottom";
	self.hackertexthud.y = -113;

	if ( issplitscreen() )
		self.hackertexthud.y = -107;

	self.hackertexthud.foreground = 1;
	self.hackertexthud.font = "default";
	self.hackertexthud.fontscale = 1.8;
	self.hackertexthud.alpha = 1;
	self.hackertexthud.color = ( 1, 1, 1 );
	self.hackertexthud settext( &"ZOMBIE_HACKING" );
	sound_ent = spawn( "script_origin", self.origin );
	sound_ent playloopsound( "zmb_progress_bar", 0.5 );
	sound_ent linkto( self );

	while ( self is_hacking( hackable ) )
	{
		wait 0.05;
		timer = timer + 0.05;

		if ( self maps\mp\zombies\_zm_laststand::player_is_in_laststand() )
			break;

		if ( timer >= hack_duration )
		{
			hacked = 1;
			break;
		}
	}

	sound_ent stoploopsound( 0.5 );
	sound_ent thread deleteAfterTime( 0.5 );

	if ( hacked )
		self playsound( "vox_mcomp_hack_success" );
	else
		self playsound( "vox_mcomp_hack_fail" );

	if ( isdefined( self.hackerprogressbar ) )
		self.hackerprogressbar maps\mp\gametypes_zm\_hud_util::destroyelem();

	if ( isdefined( self.hackertexthud ) )
		self.hackertexthud destroy();

	hackable set_hack_hint_string();

	if ( isdefined( hackable._trigger ) )
		hackable._trigger.beinghacked = 0;

	self notify( "clean_up_tidy_up" );
	return hacked;
}

deleteAfterTime( length )
{
	wait( length );
	self unlink();
	self delete();
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

hacker_pos()
{
	hacker = spawn( "trigger_radius_use", ( 0, 0, 0 ), 0, 64, 64 );
	hacker.targetname = "zombie_equipment_upgrade";
	hacker.zombie_equipment_upgrade = "equip_hacker_zm";
	hacker.target = "wpn_hacker";
	hacker triggerIgnoreTeam();
	model = spawn( "script_model", hacker.origin );
	model.angles = ( 0, 0, -90 );
	precacheModel( "p_zom_moon_hacker_box_closed" );
	model setmodel( "p_zom_moon_hacker_box_closed" );
	model.targetname = hacker.target;
}

hacker_position_cleanup()
{
	model = getent( self.target, "targetname" );

	if ( isdefined( model ) )
		model delete();

	if ( isdefined( self ) )
		self delete();
}

initial_spawn()
{
	location = level.scr_zm_map_start_location;

	if ( ( location == "default" || location == "" ) && isdefined( level.default_start_location ) )
		location = level.default_start_location;

	match_string = level.scr_zm_ui_gametype + "_" + location;
	spawnpoints = [];
	structs = getstructarray( "initial_spawn", "script_noteworthy" );

	if ( isdefined( structs ) )
	{
		foreach ( struct in structs )
		{
			if ( isdefined( struct.script_string ) && isSubStr( struct.script_string, match_string ) )
				spawnpoints[spawnpoints.size] = struct;
		}
	}

	if ( spawnpoints.size == 0 )
		spawnpoints = getstructarray( "initial_spawn_points", "targetname" );

	initial_spawn = random( spawnpoints );
	v_spawn_point = groundtrace( initial_spawn.origin + vectorscale( ( 0, 0, 1 ), 10.0 ), initial_spawn.origin + vectorscale( ( 0, 0, -1 ), 300.0 ), 0, undefined )["position"];
	self.origin = v_spawn_point + ( 0, 0, 30 );
	model = getent( self.target, "targetname" );
	model.origin = v_spawn_point + ( 0, 0, 1 );
	struct = spawnstruct();
	struct.trigger_org = self.origin;
	struct.model_org = model.origin;
	struct.model_ang = model.angles;
	level.hacker_tool_positions[level.hacker_tool_positions.size] = struct;
}

init_hackables()
{
	thread scripts\zm\hacker_wallbuys::hack_wallbuys();

	if ( getdvar( "mapname" ) == "zm_transit" && is_classic() )
		thread scripts\zm\hacker_wallbuys::hack_bus_weapon();

	thread scripts\zm\hacker_perks::hack_perks();
	// thread maps\mp\zombies\_zm_hackables_packapunch::hack_packapunch();
	thread scripts\zm\hacker_boards::hack_boards();
	thread scripts\zm\hacker_doors::hack_debris();
	thread scripts\zm\hacker_doors::hack_doors();
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
