#include maps\mp\zombies\_zm_hackables_doors;
#include maps\mp\zombies\_zm_utility;

hack_debris()
{
	doors = getentarray( "zombie_debris", "targetname" );

	foreach ( door in doors )
	{
		struct = spawnstruct();
		struct.origin = door.origin + anglestoforward( door.angles ) * 2;
		struct.radius = 48;
		struct.height = 72;
		struct.script_float = 32.7;
		struct.script_int = 200;
		struct.door = door;
		struct.no_bullet_trace = 1;
		door thread hide_door_buy_when_hacker_active( struct );
		maps\mp\zombies\_zm_equip_hacker::register_pooled_hackable_struct( struct, ::debris_hack );
		door thread watch_debris_for_open( struct );
	}
}

debris_hack( hacker )
{
	remove_all_door_hackables_that_target_door( self.door );
	self.door.zombie_cost = 0;
	self.door notify( "trigger", hacker, 1 );
}

watch_debris_for_open( door_struct )
{
	self debris_waittill_purchased();
	remove_all_door_hackables_that_target_door( door_struct.door );
}

debris_waittill_purchased()
{
	for (;;)
	{
		self waittill( "trigger", who, force );

		if ( is_player_valid( who )
			&& ( getdvarint( #"zombie_unlock_all" ) > 0
			|| ( isdefined( force ) && force || who usebuttonpressed() && !who in_revive_trigger() ) && who.score >= self.zombie_cost )
		)
			break;
	}
}
