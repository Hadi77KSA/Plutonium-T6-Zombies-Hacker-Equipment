init()
{
	level.wallbuy_callback_hack_override = ::hacker_wallbuy_callback_hack_override;
}

hacker_wallbuy_callback_hack_override()
{
	self rotateroll( 180, 0.5 );
}
