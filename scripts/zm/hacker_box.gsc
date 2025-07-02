#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_hackables_box;
#include maps\mp\zombies\_zm_unitrigger;
#include maps\mp\zombies\_zm_utility;

main()
{
	replaceFunc( maps\mp\zombies\_zm_unitrigger::main, ::main_func );
	replaceFunc( maps\mp\zombies\_zm_hackables_box::box_respin_think, ::box_respin_think );
	replaceFunc( maps\mp\zombies\_zm_hackables_box::respin_box_thread, ::respin_box_thread );
	replaceFunc( maps\mp\zombies\_zm_hackables_box::box_respin_respin_think, ::box_respin_respin_think );
	// replaceFunc( maps\mp\zombies\_zm_hackables_box::respin_respin_box, ::respin_respin_box );
	replaceFunc( maps\mp\zombies\_zm_hackables_box::init_summon_box, ::init_summon_box );
}

main_func()
{
	level thread debug_unitriggers();

	if ( level._unitriggers._deferredinitlist.size )
	{
		for ( i = 0; i < level._unitriggers._deferredinitlist.size; i++ )
			register_static_unitrigger( level._unitriggers._deferredinitlist[i], level._unitriggers._deferredinitlist[i].trigger_func );

		for ( i = 0; i < level._unitriggers._deferredinitlist.size; i++ )
			level._unitriggers._deferredinitlist[i] = undefined;

		level._unitriggers._deferredinitlist = undefined;
	}

	valid_range = level._unitriggers.largest_radius + 15.0;
	valid_range_sq = valid_range * valid_range;

	while ( !isdefined( level.active_zone_names ) )
		wait 0.1;

	while ( true )
	{
		waited = 0;
		active_zone_names = level.active_zone_names;
		candidate_list = [];

		for ( j = 0; j < active_zone_names.size; j++ )
		{
			if ( isdefined( level.zones[active_zone_names[j]].unitrigger_stubs ) )
				candidate_list = arraycombine( candidate_list, level.zones[active_zone_names[j]].unitrigger_stubs, 1, 0 );
		}

		candidate_list = arraycombine( candidate_list, level._unitriggers.dynamic_stubs, 1, 0 );
		players = getplayers();

		for ( i = 0; i < players.size; i++ )
		{
			player = players[i];

			if ( !isdefined( player ) )
				continue;

			player_origin = player.origin + vectorscale( ( 0, 0, 1 ), 35.0 );
			trigger = level._unitriggers.trigger_pool[player getentitynumber()];
			old_trigger = undefined;
			closest = [];

			if ( isdefined( trigger ) )
			{
				dst = valid_range_sq;
				origin = trigger unitrigger_origin();
				dst = trigger.stub.test_radius_sq;
				time_to_ressess = 0;
				trigger_still_valid = 0;

				if ( distance2dsquared( player_origin, origin ) < dst )
				{
					if ( isdefined( trigger.reassess_time ) )
					{
						trigger.reassess_time = trigger.reassess_time - 0.05;

						if ( trigger.reassess_time > 0.0 )
							continue;

						time_to_ressess = 1;
					}

					trigger_still_valid = 1;
				}

				closest = get_closest_unitriggers( player_origin, candidate_list, valid_range );

				if ( isdefined( trigger ) && time_to_ressess && ( closest.size < 2 || isdefined( trigger.thread_running ) && trigger.thread_running ) )
				{
					if ( assess_and_apply_visibility( trigger, trigger.stub, player, 1 ) )
						continue;
				}

				if ( trigger_still_valid && closest.size < 2 )
				{
					if ( assess_and_apply_visibility( trigger, trigger.stub, player, 1 ) )
						continue;
				}

				if ( trigger_still_valid )
				{
					old_trigger = trigger;
					trigger = undefined;
					level._unitriggers.trigger_pool[player getentitynumber()] = undefined;
				}
				else if ( isdefined( trigger ) )
					cleanup_trigger( trigger, player );
			}
			else
				closest = get_closest_unitriggers( player_origin, candidate_list, valid_range );

			index = 0;
			first_usable = undefined;
			first_visible = undefined;
			trigger_found = 0;

			while ( index < closest.size )
			{
				if ( !is_player_valid( player ) && !( isdefined( closest[index].ignore_player_valid ) && closest[index].ignore_player_valid ) )
				{
					index++;
					continue;
				}

				if ( !( isdefined( closest[index].registered ) && closest[index].registered ) )
				{
					index++;
					continue;
				}

				trigger = check_and_build_trigger_from_unitrigger_stub( closest[index], player );

				if ( isdefined( trigger ) )
				{
					trigger.parent_player = player;

					if ( assess_and_apply_visibility( trigger, closest[index], player, 0 ) )
					{
						if ( player is_player_looking_at( closest[index].origin, 0.9, 0 ) )
						{
							if ( !is_same_trigger( old_trigger, trigger ) && isdefined( old_trigger ) )
								cleanup_trigger( old_trigger, player );

							level._unitriggers.trigger_pool[player getentitynumber()] = trigger;
							trigger_found = 1;
							break;
						}

						if ( !isdefined( first_usable ) )
							first_usable = index;
					}

					if ( !isdefined( first_visible ) )
						first_visible = index;

					if ( isdefined( trigger ) )
					{
						if ( is_same_trigger( old_trigger, trigger ) )
							level._unitriggers.trigger_pool[player getentitynumber()] = undefined;
						else
							cleanup_trigger( trigger, player );
					}

					last_trigger = trigger;
				}

				index++;
				waited = 1;
				wait 0.05;
			}

			if ( !isdefined( player ) )
				continue;

			if ( trigger_found )
				continue;

			if ( isdefined( first_usable ) )
				index = first_usable;
			else if ( isdefined( first_visible ) )
				index = first_visible;

			trigger = check_and_build_trigger_from_unitrigger_stub( closest[index], player );

			if ( isdefined( trigger ) )
			{
				trigger.parent_player = player;
				level._unitriggers.trigger_pool[player getentitynumber()] = trigger;

				if ( is_same_trigger( old_trigger, trigger ) )
					continue;

				if ( isdefined( old_trigger ) )
					cleanup_trigger( old_trigger, player );

				if ( isdefined( trigger ) )
					assess_and_apply_visibility( trigger, trigger.stub, player, 0 );
			}
		}

		if ( !waited )
			wait 0.05;
	}
}

is_same_trigger( old_trigger, trigger )
{
	return isdefined( old_trigger ) && old_trigger == trigger && trigger.parent_player == old_trigger.parent_player;
}

check_and_build_trigger_from_unitrigger_stub( stub, player )
{
	if ( !isdefined( stub ) )
		return undefined;

	if ( isdefined( stub.trigger_per_player ) && stub.trigger_per_player )
	{
		if ( !isdefined( stub.playertrigger ) )
			stub.playertrigger = [];

		if ( !isdefined( stub.playertrigger[player getentitynumber()] ) )
		{
			trigger = build_trigger_from_unitrigger_stub( stub, player );
			level._unitriggers.trigger_pool[player getentitynumber()] = trigger;
		}
		else
			trigger = stub.playertrigger[player getentitynumber()];
	}
	else if ( !isdefined( stub.trigger ) )
	{
		trigger = build_trigger_from_unitrigger_stub( stub, player );
		level._unitriggers.trigger_pool[player getentitynumber()] = trigger;
	}
	else
		trigger = stub.trigger;

	return trigger;
}

box_respin_think( chest, player )
{
	if ( getdvar( "mapname" ) == "zm_highrise" && issubstr( chest.script_noteworthy, "start_chest" ) )
		org = groundpos( self.origin ) + vectorscale( ( 0, 0, 1 ), 52.5 );
	else
		org = self.origin;

	respin_hack = spawnstruct();
	respin_hack.origin = org + vectorscale( ( 0, 0, 1 ), 24.0 );
	respin_hack.radius = 48;
	respin_hack.height = 72;
	respin_hack.script_int = 600;
	respin_hack.script_float = 1.5;
	respin_hack.player = player;
	respin_hack.no_bullet_trace = 1;
	respin_hack.chest = chest;

	if ( getdvar( "mapname" ) == "zm_buried" )
		respin_hack.no_sight_check = 1;

	maps\mp\zombies\_zm_equip_hacker::register_pooled_hackable_struct( respin_hack, ::respin_box, ::hack_box_qualifier );
	self.weapon_model waittill_either( "death", "kill_respin_think_thread" );
	maps\mp\zombies\_zm_equip_hacker::deregister_hackable_struct( respin_hack );
}

respin_box_thread( hacker )
{
	if ( isdefined( self.chest.zbarrier.weapon_model ) )
		self.chest.zbarrier.weapon_model notify( "kill_respin_think_thread" );

	self.chest.no_fly_away = 1;
	self.chest.zbarrier notify( "box_hacked_respin" );
	thread maps\mp\zombies\_zm_unitrigger::unregister_unitrigger( self.chest.unitrigger_stub );
	play_sound_at_pos( "open_chest", self.chest.zbarrier.origin );
	play_sound_at_pos( "music_chest", self.chest.zbarrier.origin );
	maps\mp\zombies\_zm_weapons::unacquire_weapon_toggle( self.chest.zbarrier.weapon_string );
	self.chest.zbarrier thread maps\mp\zombies\_zm_magicbox::treasure_chest_weapon_spawn( self.chest, hacker, 1 );
	self.chest.zbarrier waittill( "randomization_done" );
	self.chest.no_fly_away = undefined;

	if ( !flag( "moving_chest_now" ) )
	{
		self.chest.grab_weapon_name = self.chest.zbarrier.weapon_string;
		thread maps\mp\zombies\_zm_unitrigger::register_static_unitrigger( self.chest.unitrigger_stub, maps\mp\zombies\_zm_magicbox::magicbox_unitrigger_think );
		self.chest thread maps\mp\zombies\_zm_magicbox::treasure_chest_timeout();
	}
}

box_respin_respin_think( chest, player )
{
	if ( getdvar( "mapname" ) == "zm_highrise" && issubstr( chest.script_noteworthy, "start_chest" ) )
		org = groundpos( self.origin ) + vectorscale( ( 0, 0, 1 ), 52.5 );
	else
		org = self.origin;

	respin_hack = spawnstruct();
	respin_hack.origin = org + vectorscale( ( 0, 0, 1 ), 24.0 );
	respin_hack.radius = 48;
	respin_hack.height = 72;
	respin_hack.script_int = -950;
	respin_hack.script_float = 1.5;
	respin_hack.player = player;
	respin_hack.no_bullet_trace = 1;
	respin_hack.chest = chest;

	if ( getdvar( "mapname" ) == "zm_buried" )
		respin_hack.no_sight_check = 1;

	maps\mp\zombies\_zm_equip_hacker::register_pooled_hackable_struct( respin_hack, ::respin_respin_box, ::hack_box_qualifier );
	self.weapon_model waittill_either( "death", "kill_respin_respin_think_thread" );
	maps\mp\zombies\_zm_equip_hacker::deregister_hackable_struct( respin_hack );
}

respin_respin_box( hacker )
{
	org = self.chest.zbarrier.origin;

	if ( isdefined( level.custom_magicbox_float_height ) )
		v_float = anglestoup( self.chest.zbarrier.angles ) * level.custom_magicbox_float_height;
	else
		v_float = anglestoup( self.chest.zbarrier.angles ) * 40;

	if ( isdefined( self.chest.zbarrier.weapon_model ) )
	{
		self.chest.zbarrier.weapon_model notify( "kill_respin_respin_think_thread" );
		self.chest.zbarrier.weapon_model notify( "kill_weapon_movement" );
		self.chest.zbarrier.weapon_model moveto( org + v_float, 0.5 );
	}

	if ( isdefined( self.chest.zbarrier.weapon_model_dw ) )
	{
		self.chest.zbarrier.weapon_model_dw notify( "kill_weapon_movement" );
		self.chest.zbarrier.weapon_model_dw moveto( org + v_float - vectorscale( ( 1, 1, 1 ), 3.0 ), 0.5 );
	}

	self.chest.zbarrier notify( "box_hacked_rerespin" );
	self.chest.box_rerespun = 1;
	self thread fake_weapon_powerup_thread( self.chest.zbarrier.weapon_model, self.chest.zbarrier.weapon_model_dw );
}

init_summon_box( create )
{
	if ( isdefined( create ) && create )
	{
		if ( isdefined( self._summon_hack_struct ) )
		{
			maps\mp\zombies\_zm_equip_hacker::deregister_hackable_struct( self._summon_hack_struct );
			self._summon_hack_struct = undefined;
		}

		if ( getdvar( "mapname" ) == "zm_highrise" && issubstr( self.script_noteworthy, "start_chest" ) )
			org = groundpos( self.chest_box.origin ) + vectorscale( ( 0, 0, 1 ), 52.5 );
		else
			org = self.chest_box.origin;

		struct = spawnstruct();
		struct.origin = org + vectorscale( ( 0, 0, 1 ), 24.0 );
		struct.radius = 48;
		struct.height = 72;
		struct.script_int = 1200;
		struct.script_float = 5;
		struct.no_bullet_trace = 1;
		struct.chest = self;
		self._summon_hack_struct = struct;

		if ( getdvar( "mapname" ) == "zm_buried" )
			struct.no_sight_check = 1;

		maps\mp\zombies\_zm_equip_hacker::register_pooled_hackable_struct( struct, ::summon_box, ::summon_box_qualifier );
	}
	else if ( isdefined( self._summon_hack_struct ) )
	{
		maps\mp\zombies\_zm_equip_hacker::deregister_hackable_struct( self._summon_hack_struct );
		self._summon_hack_struct = undefined;
	}
}
