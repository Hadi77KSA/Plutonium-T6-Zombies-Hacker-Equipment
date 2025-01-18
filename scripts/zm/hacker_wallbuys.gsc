hack_bus_weapon()
{
	bus_buyable_weapon = getent( "bus_buyable_weapon1", "script_noteworthy" );

	if ( weapontype( bus_buyable_weapon.zombie_weapon_upgrade ) == "grenade"
		|| weapontype( bus_buyable_weapon.zombie_weapon_upgrade ) == "melee"
		|| weapontype( bus_buyable_weapon.zombie_weapon_upgrade ) == "mine"
		|| weapontype( bus_buyable_weapon.zombie_weapon_upgrade ) == "bomb"
	)
		return;

	struct = spawnstruct();
	struct.origin = bus_buyable_weapon.origin;
	struct.trigger_offset = vectorscale( ( 0, 0, 1 ), -36 );
	struct.radius = 48;
	struct.height = 48;
	struct.script_float = 2;
	struct.script_int = 3000;
	struct.wallbuy = bus_buyable_weapon;
	struct.entity = struct.wallbuy;
	maps\mp\zombies\_zm_equip_hacker::register_pooled_hackable_struct( struct, ::bus_wallbuy_hack );
	bus_buyable_weapon thread maps\mp\zombies\_zm_equip_hacker::hide_hint_when_hackers_active();
}

bus_wallbuy_hack( hacker )
{
    self.wallbuy.hacked = true;
    maps\mp\zombies\_zm_equip_hacker::deregister_hackable_struct( self );

	while ( level.the_bus.ismoving )
		wait 0.05;

	model = getent( self.wallbuy.target, "targetname" );
	model unlink();
	model rotateroll( 180, 0.5 );
	wait 0.55;
	model linkto( level.the_bus, "", level.the_bus worldtolocalcoords( model.origin ), model.angles + level.the_bus.angles );
}

hack_dynamic_wallbuys()
{
	weapon_spawns = common_scripts\utility::getstructarray( "buildable_wallbuy", "targetname" );
	match_string = level.scr_zm_ui_gametype + "_" + level.scr_zm_map_start_location;

	for ( i = 0; i < weapon_spawns.size; i++ )
	{
		if ( !isdefined( weapon_spawns[i].script_location )
			|| isdefined( weapon_spawns[i].script_noteworthy ) && !issubstr( weapon_spawns[i].script_noteworthy, match_string )
		)
			continue;

		weapon_spawns[i] thread register_hackable_wallbuy_when_added();
	}
}

register_hackable_wallbuy_when_added()
{
	while ( !isdefined( self.trigger_stub ) )
		wait 1;

	if ( weapontype( self.trigger_stub.zombie_weapon_upgrade ) == "grenade"
		|| weapontype( self.trigger_stub.zombie_weapon_upgrade ) == "melee"
		|| weapontype( self.trigger_stub.zombie_weapon_upgrade ) == "mine"
		|| weapontype( self.trigger_stub.zombie_weapon_upgrade ) == "bomb"
	)
		return;

	struct = spawnstruct();
	struct.origin = self.origin;
	struct.radius = 48;
	struct.height = 48;
	struct.script_float = 2;
	struct.script_int = 3000;
	struct.wallbuy = self;
	maps\mp\zombies\_zm_equip_hacker::register_pooled_hackable_struct( struct, maps\mp\zombies\_zm_hackables_wallbuys::wallbuy_hack );
}
