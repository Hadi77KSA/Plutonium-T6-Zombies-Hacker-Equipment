#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_magicbox;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;

main()
{
	replaceFunc( maps\mp\zombies\_zm_hackables_wallbuys::hack_wallbuys, ::hack_wallbuys );
	replaceFunc( maps\mp\zombies\_zm_hackables_wallbuys::wallbuy_hack, ::wallbuy_hack );

	if ( ( isdefined( level._wallbuy_override_num_bits ) && level._wallbuy_override_num_bits < 2 ) || getDvar( "mapname" ) == "zm_tomb" )
	{
		replaceFunc( maps\mp\zombies\_zm_weapons::init_spawnable_weapon_upgrade, ::init_spawnable_weapon_upgrade );
	}

	replaceFunc( maps\mp\zombies\_zm_weapons::wall_weapon_update_prompt, ::wall_weapon_update_prompt );
	replaceFunc( maps\mp\zombies\_zm_weapons::weapon_spawn_think, ::weapon_spawn_think );
}

init_spawnable_weapon_upgrade()
{
	removeDetour( maps\mp\zombies\_zm_weapons::init_spawnable_weapon_upgrade );
	level._wallbuy_override_num_bits = undefined;
	maps\mp\zombies\_zm_weapons::init_spawnable_weapon_upgrade();
}

wall_weapon_update_prompt( player )
{
	weapon = self.stub.zombie_weapon_upgrade;

	if ( !( isdefined( level.monolingustic_prompt_format ) && level.monolingustic_prompt_format ) )
	{
		player_has_weapon = player has_weapon_or_upgrade( weapon );

		if ( !player_has_weapon && ( isdefined( level.weapons_using_ammo_sharing ) && level.weapons_using_ammo_sharing ) )
		{
			shared_ammo_weapon = player get_shared_ammo_weapon( self.zombie_weapon_upgrade );

			if ( isdefined( shared_ammo_weapon ) )
			{
				weapon = shared_ammo_weapon;
				player_has_weapon = 1;
			}
		}

		if ( !player_has_weapon )
		{
			cost = get_weapon_cost( weapon );
			self.stub.hint_string = get_weapon_hint( weapon );
			self sethintstring( self.stub.hint_string, cost );
		}
		else if ( isdefined( level.use_legacy_weapon_prompt_format ) && level.use_legacy_weapon_prompt_format )
		{
			cost = get_weapon_cost( weapon );
			ammo_cost = get_ammo_cost( weapon );
			self.stub.hint_string = get_weapon_hint_ammo();
			self sethintstring( self.stub.hint_string, cost, ammo_cost );
		}
		else
		{
			if ( player has_upgrade( weapon ) != ( isdefined( self.stub.hacked ) && self.stub.hacked ) )
				ammo_cost = get_upgraded_ammo_cost( weapon );
			else
				ammo_cost = get_ammo_cost( weapon );

			self.stub.hint_string = &"ZOMBIE_WEAPONAMMOONLY";
			self sethintstring( self.stub.hint_string, ammo_cost );
		}
	}
	else if ( !player has_weapon_or_upgrade( weapon ) )
	{
		string_override = 0;

		if ( isdefined( player.pers_upgrades_awarded["nube"] ) && player.pers_upgrades_awarded["nube"] )
			string_override = maps\mp\zombies\_zm_pers_upgrades_functions::pers_nube_ammo_hint_string( player, weapon );

		if ( !string_override )
		{
			cost = get_weapon_cost( weapon );
			weapon_display = get_weapon_display_name( weapon );

			if ( !isdefined( weapon_display ) || weapon_display == "" || weapon_display == "none" )
				weapon_display = "missing weapon name " + weapon;

			self.stub.hint_string = &"ZOMBIE_WEAPONCOSTONLY";
			self sethintstring( self.stub.hint_string, weapon_display, cost );
		}
	}
	else
	{
		if ( player has_upgrade( weapon ) )
			ammo_cost = get_upgraded_ammo_cost( weapon );
		else
			ammo_cost = get_ammo_cost( weapon );

		self.stub.hint_string = &"ZOMBIE_WEAPONAMMOONLY";
		self sethintstring( self.stub.hint_string, ammo_cost );
	}

	if ( getdvarint( #"tu12_zombies_allow_hint_weapon_from_script" ) )
	{
		self.stub.cursor_hint = "HINT_WEAPON";
		self.stub.cursor_hint_weapon = weapon;
		self setcursorhint( self.stub.cursor_hint, self.stub.cursor_hint_weapon );
	}
	else
	{
		self.stub.cursor_hint = "HINT_NOICON";
		self.stub.cursor_hint_weapon = undefined;
		self setcursorhint( self.stub.cursor_hint );
	}

	return true;
}

weapon_spawn_think()
{
	cost = get_weapon_cost( self.zombie_weapon_upgrade );
	ammo_cost = get_ammo_cost( self.zombie_weapon_upgrade );
	is_grenade = weapontype( self.zombie_weapon_upgrade ) == "grenade";
	shared_ammo_weapon = undefined;
	second_endon = undefined;

	if ( isdefined( self.stub ) )
	{
		second_endon = "kill_trigger";
		self.first_time_triggered = self.stub.first_time_triggered;
	}

	if ( isdefined( self.stub ) && ( isdefined( self.stub.trigger_per_player ) && self.stub.trigger_per_player ) )
		self thread decide_hide_show_hint( "stop_hint_logic", second_endon, self.parent_player );
	else
		self thread decide_hide_show_hint( "stop_hint_logic", second_endon );

	if ( is_grenade )
	{
		self.first_time_triggered = 0;
		hint = get_weapon_hint( self.zombie_weapon_upgrade );
		self sethintstring( hint, cost );
	}
	else if ( !isdefined( self.first_time_triggered ) )
	{
		self.first_time_triggered = 0;

		if ( isdefined( self.stub ) )
			self.stub.first_time_triggered = 0;
	}
	else if ( self.first_time_triggered )
	{
		if ( isdefined( level.use_legacy_weapon_prompt_format ) && level.use_legacy_weapon_prompt_format )
			self weapon_set_first_time_hint( cost, get_ammo_cost( self.zombie_weapon_upgrade ) );
	}

	for (;;)
	{
		self waittill( "trigger", player );

		if ( !is_player_valid( player ) )
		{
			player thread ignore_triggers( 0.5 );
			continue;
		}

		if ( !player can_buy_weapon() )
		{
			wait 0.1;
			continue;
		}

		if ( isdefined( self.stub ) && ( isdefined( self.stub.require_look_from ) && self.stub.require_look_from ) )
		{
			toplayer = player get_eye() - self.origin;
			forward = -1 * anglestoright( self.angles );
			dot = vectordot( toplayer, forward );

			if ( dot < 0 )
				continue;
		}

		if ( player has_powerup_weapon() )
		{
			wait 0.1;
			continue;
		}

		player_has_weapon = player has_weapon_or_upgrade( self.zombie_weapon_upgrade );

		if ( !player_has_weapon && ( isdefined( level.weapons_using_ammo_sharing ) && level.weapons_using_ammo_sharing ) )
		{
			shared_ammo_weapon = player get_shared_ammo_weapon( self.zombie_weapon_upgrade );

			if ( isdefined( shared_ammo_weapon ) )
				player_has_weapon = 1;
		}

		if ( isdefined( level.pers_upgrade_nube ) && level.pers_upgrade_nube )
			player_has_weapon = maps\mp\zombies\_zm_pers_upgrades_functions::pers_nube_should_we_give_raygun( player_has_weapon, player, self.zombie_weapon_upgrade );

		cost = get_weapon_cost( self.zombie_weapon_upgrade );

		if ( player maps\mp\zombies\_zm_pers_upgrades_functions::is_pers_double_points_active() )
			cost = int( cost / 2 );

		if ( !player_has_weapon )
		{
			if ( player.score >= cost )
			{
				if ( self.first_time_triggered == 0 )
					self show_all_weapon_buys( player, cost, ammo_cost, is_grenade );

				player maps\mp\zombies\_zm_score::minus_to_player_score( cost, 1 );
				bbprint( "zombie_uses", "playername %s playerscore %d round %d cost %d name %s x %f y %f z %f type %s", player.name, player.score, level.round_number, cost, self.zombie_weapon_upgrade, self.origin, "weapon" );
				level notify( "weapon_bought", player, self.zombie_weapon_upgrade );

				if ( self.zombie_weapon_upgrade == "riotshield_zm" )
				{
					player maps\mp\zombies\_zm_equipment::equipment_give( "riotshield_zm" );

					if ( isdefined( player.player_shield_reset_health ) )
						player [[ player.player_shield_reset_health ]]();
				}
				else if ( self.zombie_weapon_upgrade == "jetgun_zm" )
					player maps\mp\zombies\_zm_equipment::equipment_give( "jetgun_zm" );
				else
				{
					if ( is_lethal_grenade( self.zombie_weapon_upgrade ) )
					{
						player takeweapon( player get_player_lethal_grenade() );
						player set_player_lethal_grenade( self.zombie_weapon_upgrade );
					}

					str_weapon = self.zombie_weapon_upgrade;

					if ( isdefined( level.pers_upgrade_nube ) && level.pers_upgrade_nube )
						str_weapon = maps\mp\zombies\_zm_pers_upgrades_functions::pers_nube_weapon_upgrade_check( player, str_weapon );

					player weapon_give( str_weapon );
				}

				player maps\mp\zombies\_zm_stats::increment_client_stat( "wallbuy_weapons_purchased" );
				player maps\mp\zombies\_zm_stats::increment_player_stat( "wallbuy_weapons_purchased" );
			}
			else
			{
				play_sound_on_ent( "no_purchase" );
				player maps\mp\zombies\_zm_audio::create_and_play_dialog( "general", "no_money_weapon" );
			}
		}
		else
		{
			str_weapon = self.zombie_weapon_upgrade;

			if ( isdefined( shared_ammo_weapon ) )
				str_weapon = shared_ammo_weapon;

			if ( isdefined( level.pers_upgrade_nube ) && level.pers_upgrade_nube )
				str_weapon = maps\mp\zombies\_zm_pers_upgrades_functions::pers_nube_weapon_ammo_check( player, str_weapon );

			if ( isdefined( self.hacked ) && self.hacked || isdefined( self.stub.hacked ) && self.stub.hacked )
			{
				if ( !player has_upgrade( str_weapon ) )
					ammo_cost = 4500;
				else
					ammo_cost = get_ammo_cost( str_weapon );
			}
			else if ( player has_upgrade( str_weapon ) )
				ammo_cost = 4500;
			else
				ammo_cost = get_ammo_cost( str_weapon );

			if ( isdefined( player.pers_upgrades_awarded["nube"] ) && player.pers_upgrades_awarded["nube"] )
				ammo_cost = maps\mp\zombies\_zm_pers_upgrades_functions::pers_nube_override_ammo_cost( player, self.zombie_weapon_upgrade, ammo_cost );

			if ( player maps\mp\zombies\_zm_pers_upgrades_functions::is_pers_double_points_active() )
				ammo_cost = int( ammo_cost / 2 );

			if ( str_weapon == "riotshield_zm" )
				play_sound_on_ent( "no_purchase" );
			else if ( player.score >= ammo_cost )
			{
				if ( self.first_time_triggered == 0 )
					self show_all_weapon_buys( player, cost, ammo_cost, is_grenade );

				if ( player has_upgrade( str_weapon ) )
				{
					player maps\mp\zombies\_zm_stats::increment_client_stat( "upgraded_ammo_purchased" );
					player maps\mp\zombies\_zm_stats::increment_player_stat( "upgraded_ammo_purchased" );
				}
				else
				{
					player maps\mp\zombies\_zm_stats::increment_client_stat( "ammo_purchased" );
					player maps\mp\zombies\_zm_stats::increment_player_stat( "ammo_purchased" );
				}

				if ( str_weapon == "riotshield_zm" )
				{
					if ( isdefined( player.player_shield_reset_health ) )
						ammo_given = player [[ player.player_shield_reset_health ]]();
					else
						ammo_given = 0;
				}
				else if ( player has_upgrade( str_weapon ) )
					ammo_given = player ammo_give( level.zombie_weapons[str_weapon].upgrade_name );
				else
					ammo_given = player ammo_give( str_weapon );

				if ( ammo_given )
				{
					player maps\mp\zombies\_zm_score::minus_to_player_score( ammo_cost, 1 );
					bbprint( "zombie_uses", "playername %s playerscore %d round %d cost %d name %s x %f y %f z %f type %s", player.name, player.score, level.round_number, ammo_cost, str_weapon, self.origin, "ammo" );
				}
			}
			else
			{
				play_sound_on_ent( "no_purchase" );

				if ( isdefined( level.custom_generic_deny_vo_func ) )
					player [[ level.custom_generic_deny_vo_func ]]();
				else
					player maps\mp\zombies\_zm_audio::create_and_play_dialog( "general", "no_money_weapon" );
			}
		}

		if ( isdefined( self.stub ) && isdefined( self.stub.prompt_and_visibility_func ) )
			self [[ self.stub.prompt_and_visibility_func ]]( player );
	}
}

hack_wallbuys()
{
	weapon_spawns = getstructarray( "weapon_upgrade", "targetname" );
	weapon_spawns = arrayCombine( weapon_spawns, getstructarray( "buildable_wallbuy", "targetname" ), 1, 0 );
	location = getdvar( #"ui_zm_mapstartlocation" );

	if ( ( location == "default" || location == "" ) && isdefined( level.default_start_location ) )
		location = level.default_start_location;

	match_string = getdvar( #"ui_gametype" );

	if ( "" != location )
		match_string = match_string + "_" + location;

	if ( getdvar( "mapname" ) == "zm_transit" && is_classic() )
	{
		thread bus_buyable_weapon1();
	}

	for ( i = 0; i < weapon_spawns.size; i++ )
	{
		if ( isdefined( weapon_spawns[i].script_noteworthy ) && !issubstr( weapon_spawns[i].script_noteworthy, match_string ) )
			continue;

		switch ( weapon_spawns[i].targetname )
		{
			case "buildable_wallbuy":
				if ( isdefined( weapon_spawns[i].script_location ) )
				{
					weapon_spawns[i] thread buildable_wallbuy();
				}

				continue;
		}

		if ( weapontype( weapon_spawns[i].zombie_weapon_upgrade ) == "grenade" )
			continue;

		if ( weapontype( weapon_spawns[i].zombie_weapon_upgrade ) == "melee" )
			continue;

		if ( weapontype( weapon_spawns[i].zombie_weapon_upgrade ) == "mine" )
			continue;

		if ( weapontype( weapon_spawns[i].zombie_weapon_upgrade ) == "bomb" )
			continue;

		struct = spawnstruct();
		struct.origin = weapon_spawns[i].origin;
		struct.radius = 48;
		struct.height = 48;
		struct.script_float = 2;
		struct.script_int = 3000;
		struct.wallbuy = weapon_spawns[i];
		maps\mp\zombies\_zm_equip_hacker::register_pooled_hackable_struct( struct, maps\mp\zombies\_zm_hackables_wallbuys::wallbuy_hack );
	}

	bowie_triggers = getentarray( "bowie_upgrade", "targetname" );
	array_thread( bowie_triggers, maps\mp\zombies\_zm_equip_hacker::hide_hint_when_hackers_active );
}

wallbuy_hack( hacker )
{
	if ( isdefined( self.wallbuy.script_noteworthy ) && self.wallbuy.script_noteworthy == "bus_buyable_weapon1" )
	{
		self.wallbuy.hacked = true;
		maps\mp\zombies\_zm_equip_hacker::deregister_hackable_struct( self );

		if ( level.the_bus.ismoving )
		{
			do
				wait 2;
			while ( level.the_bus.ismoving );
		}
		else
			level.the_bus waittill( "ready_to_depart" );

		model = getent( self.wallbuy.target, "targetname" );
		model unlink();
		model rotateroll( 180, 0.5 );
		wait 0.55;
		model linkto( level.the_bus, "", level.the_bus worldtolocalcoords( model.origin ), model.angles + level.the_bus.angles );
	}
	else
	{
		self.wallbuy.trigger_stub.hacked = 1;
		self.clientfieldname = self.wallbuy.zombie_weapon_upgrade + "_" + self.origin;
		level setclientfield( self.clientfieldname, 2 );
		maps\mp\zombies\_zm_equip_hacker::deregister_hackable_struct( self );
	}
}

bus_buyable_weapon1()
{
	bus_buyable_weapon1 = getent( "bus_buyable_weapon1", "script_noteworthy" );

	switch ( weapontype( bus_buyable_weapon1.zombie_weapon_upgrade ) )
	{
		case "grenade":
		case "melee":
		case "mine":
		case "bomb":
			return;
	}

	struct = spawnstruct();
	struct.origin = bus_buyable_weapon1.origin;
	struct.trigger_offset = vectorscale( ( 0, 0, 1 ), -36 );
	struct.radius = 48;
	struct.height = 48;
	struct.script_float = 2;
	struct.script_int = 3000;
	struct.wallbuy = bus_buyable_weapon1;
	struct.entity = struct.wallbuy;
	maps\mp\zombies\_zm_equip_hacker::register_pooled_hackable_struct( struct, maps\mp\zombies\_zm_hackables_wallbuys::wallbuy_hack );
	bus_buyable_weapon1 thread maps\mp\zombies\_zm_equip_hacker::hide_hint_when_hackers_active();
}

buildable_wallbuy()
{
	while ( !isdefined( self.trigger_stub ) )
		wait 1;

	switch ( weapontype( self.trigger_stub.zombie_weapon_upgrade ) )
	{
		case "grenade":
		case "melee":
		case "mine":
		case "bomb":
			return;
	}

	struct = spawnstruct();
	struct.origin = self.origin;
	struct.radius = 48;
	struct.height = 48;
	struct.script_float = 2;
	struct.script_int = 3000;
	struct.wallbuy = self;
	maps\mp\zombies\_zm_equip_hacker::register_pooled_hackable_struct( struct, maps\mp\zombies\_zm_hackables_wallbuys::wallbuy_hack );
}
