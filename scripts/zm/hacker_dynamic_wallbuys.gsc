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
