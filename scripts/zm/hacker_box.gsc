#include maps\mp\_utility;
#include maps\mp\zombies\_zm_hackables_box;
#include maps\mp\zombies\_zm_utility;

main()
{
	replaceFunc( maps\mp\zombies\_zm_hackables_box::box_respin_think, ::box_respin_think );
	replaceFunc( maps\mp\zombies\_zm_hackables_box::box_respin_respin_think, ::box_respin_respin_think );
	replaceFunc( maps\mp\zombies\_zm_hackables_box::init_summon_box, ::init_summon_box );
}

box_respin_think( chest, player )
{
	if ( getdvar( "mapname" ) == "zm_highrise" )
		org = groundpos( self.origin ) + vectorscale( ( 0, 0, 1 ), 12.5 );
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

box_respin_respin_think( chest, player )
{
	if ( getdvar( "mapname" ) == "zm_highrise" )
		org = groundpos( self.origin ) + vectorscale( ( 0, 0, 1 ), 12.5 );
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

		if ( getdvar( "mapname" ) == "zm_highrise" )
			org = groundpos( self.chest_box.origin ) + vectorscale( ( 0, 0, 1 ), 12.5 );
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
