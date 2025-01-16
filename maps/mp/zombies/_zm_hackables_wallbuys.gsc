#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_equip_hacker;

hack_wallbuys()
{
    weapon_spawns = getstructarray( "weapon_upgrade", "targetname" );
    location = getdvar( #"ui_zm_mapstartlocation" );

    if ( ( location == "default" || location == "" ) && isdefined( level.default_start_location ) )
        location = level.default_start_location;

    match_string = getdvar( #"ui_gametype" );

    if ( "" != location )
        match_string = match_string + "_" + location;

    match_string_plus_space = " " + match_string;

    for ( i = 0; i < weapon_spawns.size; i++ )
    {
        if ( weapontype( weapon_spawns[i].zombie_weapon_upgrade ) == "grenade" )
            continue;

        if ( weapontype( weapon_spawns[i].zombie_weapon_upgrade ) == "melee" )
            continue;

        if ( weapontype( weapon_spawns[i].zombie_weapon_upgrade ) == "mine" )
            continue;

        if ( weapontype( weapon_spawns[i].zombie_weapon_upgrade ) == "bomb" )
            continue;

        if ( isdefined( weapon_spawns[i].script_noteworthy ) && weapon_spawns[i].script_noteworthy != "" )
        {
            skip = true;
            matches = strtok( weapon_spawns[i].script_noteworthy, "," );

            for ( j = 0; j < matches.size; j++ )
            {
                if ( matches[j] == match_string || matches[j] == match_string_plus_space )
                {
                    skip = false;
                    break;
                }
            }

            if ( skip )
                continue;
        }

        struct = spawnstruct();
        struct.origin = weapon_spawns[i].origin;
        struct.radius = 48;
        struct.height = 48;
        struct.script_float = 2;
        struct.script_int = 3000;
        struct.wallbuy = weapon_spawns[i];
        maps\mp\zombies\_zm_equip_hacker::register_pooled_hackable_struct( struct, ::wallbuy_hack );
    }

    bowie_triggers = getentarray( "bowie_upgrade", "targetname" );
    array_thread( bowie_triggers, maps\mp\zombies\_zm_equip_hacker::hide_hint_when_hackers_active );
}

wallbuy_hack( hacker )
{
    self.wallbuy.trigger_stub.hacked = 1;

    if ( !isdefined( level._wallbuy_override_num_bits ) || level._wallbuy_override_num_bits >= 2 )
    {
        self.clientfieldname = self.wallbuy.zombie_weapon_upgrade + "_" + self.origin;
        level setclientfield( self.clientfieldname, 2 );
    }

    maps\mp\zombies\_zm_equip_hacker::deregister_hackable_struct( self );
}
