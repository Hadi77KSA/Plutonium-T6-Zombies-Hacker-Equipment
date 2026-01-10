main()
{
	if ( ( isdefined( level._wallbuy_override_num_bits ) && level._wallbuy_override_num_bits < 2 ) || getDvar( #"mapname" ) == "zm_tomb" )
	{
		replaceFunc( clientscripts\mp\zombies\_zm_weapons::init, ::_wallbuy_override_num_bits );
	}
}

_wallbuy_override_num_bits()
{
	removeDetour( clientscripts\mp\zombies\_zm_weapons::init );
	level._wallbuy_override_num_bits = undefined;
	clientscripts\mp\zombies\_zm_weapons::init();
}

init()
{
	level.wallbuy_callback_hack_override = ::rotate_hacked_wallbuy;
}

rotate_hacked_wallbuy()
{
	self rotateroll( 180, 0.5 );
}
