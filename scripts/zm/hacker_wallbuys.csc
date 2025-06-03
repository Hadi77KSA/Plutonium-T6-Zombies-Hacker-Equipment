main()
{
	if ( ( isdefined( level._wallbuy_override_num_bits ) && level._wallbuy_override_num_bits < 2 ) || getDvar( "mapname" ) == "zm_tomb" )
	{
		replaceFunc( clientscripts\mp\zombies\_zm_weapons::init, ::init_func );
	}
}

init_func()
{
	removeDetour( clientscripts\mp\zombies\_zm_weapons::init );
	level._wallbuy_override_num_bits = undefined;
	clientscripts\mp\zombies\_zm_weapons::init();
}

init()
{
	level.wallbuy_callback_hack_override = ::wallbuy_callback_hack_override;
}

wallbuy_callback_hack_override()
{
	self rotateroll( 180, 0.5 );
}
