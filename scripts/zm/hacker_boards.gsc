init()
{
	level._zm_blocker_trigger_think_return_override = ::hacker_zm_blocker_trigger_think_return_override;
	level._zm_build_trigger_from_unitrigger_stub_override = ::hacker_zm_build_trigger_from_unitrigger_stub_override;
}

hacker_zm_blocker_trigger_think_return_override( player )
{
	return player maps\mp\zombies\_zm_equipment::is_equipment_active( "equip_hacker_zm" );
}

hacker_zm_build_trigger_from_unitrigger_stub_override( player )
{
	return player maps\mp\zombies\_zm_equipment::is_equipment_active( "equip_hacker_zm" ) && isdefined( self.trigger_target ) && self.trigger_target.targetname == "exterior_goal";
}
