#include < amxmodx >
#include < zombieplague >
#include < engine >
#include < fakemeta >
#include <hamsandwich>

#define CLASS_MENO	"npc_dummy"

new const zclass_name[ ] = "Fake ZOmbie"
new const zclass_info[ ] = "Spravy fake zombie"
new const zclass_model[ ] = "zombie_eye"
new const zclass_clawmodel[ ] = "gl_water.mdl"
new const Float:maxs[ 3 ] = { 16.0, 16.0, 36.0 }
new const Float:mins[ 3 ] = { -16.0, -16.0, -36.0 }
const zclass_health = 2200
const zclass_speed = 200
const Float:zclass_gravity = 1.0
const Float:zclass_knockback = 1.0
new const sound[] = "zombie_plague/shadowstrikebirth.wav";
// Models
new const dummy_model[ ] = "models/player/zombie_eye/zombie_eye.mdl"

new g_zclass_dummy, gCvarDummyShouldDie, gCvarDummyHealth, 
	gCvarDummyAnimation, gCvarDummyLimit, gCounter[ 33 ], 
	bool:mozem, MAX_POCET, g_maxplayers, g_MsgSync

public plugin_init( ) 
{
	register_plugin( "[ZP] Zombie Class: Dummy Zombie", "1.0", "007 & Twilight Suzuka & 01101101" )	
	register_event( "HLTV", "event_new_round", "a", "1=0", "2=0" )
	g_maxplayers = get_maxplayers()

	gCvarDummyShouldDie = register_cvar( "zp_dummy_should_die", "1" ) // ( 0 : Dummy will not die || 1: Dummy will die ) Default: 1
	gCvarDummyHealth = register_cvar( "zp_dummy_health", "300.0" ) // Dummy's health Default: 100
	gCvarDummyAnimation = register_cvar( "zp_dummy_animation", "1" ) // ( 0 : Dummy floating animation || 1: Dummy standing animation ) Default: 1
	gCvarDummyLimit = register_cvar( "zp_dummy_spawn_limit", "4" ) // Amount of dummy he can spawn when he gets infected
	RegisterHam(Ham_TakeDamage, "info_target", "fw_TakeDamage")
	g_MsgSync = CreateHudSyncObj()
}
public plugin_precache( ) {
	g_zclass_dummy = zp_register_zombie_class( zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback )
	precache_model( dummy_model )
	precache_sound( sound )
}
public event_new_round(gamemode, id) {
	 Vymaz();
}
public zp_round_end(gamemode, id) {
	Vymaz();
}
stock Vymaz() {
	mozem = false;
	new ent = -1
	while( ( ent = find_ent_by_class( ent, CLASS_MENO ) ) ) {
		remove_entity( ent )
	}
}
public zp_round_started(gamemode, id) {
	MAX_POCET = get_pcvar_num(gCvarDummyLimit);
	if(zp_is_survivor_round() || zp_is_nemesis_round()) {
		mozem = false;
	} else {
		mozem = true;
	}
}
public client_PreThink( id )
{
	if(!mozem) return FMRES_IGNORED;
	if((pev(id, pev_button ) & IN_RELOAD) && !(pev(id, pev_oldbuttons ) & IN_RELOAD ))  {
		if(!is_user_alive(id) || !zp_get_user_zombie(id)) return FMRES_IGNORED;
		if(zp_get_user_zombie_class(id) != g_zclass_dummy) return FMRES_IGNORED;
		/*if( !is_user_alive( id ) || !zp_get_user_zombie( id ) || zp_get_user_zombie_class( id ) != g_zclass_dummy || zp_get_user_nemesis( id ) )
			return PLUGIN_HANDLED*/
		create_dummy(id) 
	}
	return FMRES_IGNORED; 
}
public zp_user_infected_post( id, infector )
{
	if( zp_get_user_zombie_class( id ) == g_zclass_dummy) {
		gCounter[ id ] = 0
		client_print( id, print_chat, "[G/L ZP] Stlac R pre pouzite specialnych schopnosti." )
	}
	return PLUGIN_CONTINUE
}
stock create_dummy( const id )
{
	if( gCounter[ id ] >= MAX_POCET ) {
		client_print( id, print_chat, "[G/L ZP] Dosiahnuty limit FAKE zombikov." )
		return PLUGIN_HANDLED
	}
	static Float:origin[ 3 ]
	entity_get_vector( id, EV_VEC_origin, origin )
	gCounter[ id ] ++
	client_print( id, print_chat, "[G/L ZP] Pouzil si %d / %d zombikov.", gCounter[ id ], MAX_POCET )
	set_task(1.0, "opakovacka", _, origin, 3);
}
public opakovacka(const Float:origin[3])	
{	
	if(!mozem) return FMRES_IGNORED; // neopakuj dalej ....
	if(!UTIL_JeHracBlizkoOrigin(origin))  {
		set_task(1.0, "opakovacka", _, origin, 3); // pockaj zase ....
		return FMRES_IGNORED;
	}
	static ent
	ent = create_entity( "info_target" )
	entity_set_origin( ent, origin )
	entity_set_float( ent, EV_FL_takedamage, get_pcvar_float( gCvarDummyShouldDie ) )
	entity_set_float( ent, EV_FL_health, get_pcvar_float( gCvarDummyHealth ) )
	entity_set_string( ent, EV_SZ_classname, CLASS_MENO )
	entity_set_model( ent, dummy_model )
	entity_set_int( ent, EV_INT_solid, 2 )
	entity_set_byte( ent, EV_BYTE_controller1, 125 )
	entity_set_byte( ent, EV_BYTE_controller2, 125 )
	entity_set_byte( ent, EV_BYTE_controller3, 125 )
	entity_set_byte( ent, EV_BYTE_controller4, 125 )		
	entity_set_size( ent, mins, maxs )
	entity_set_float( ent, EV_FL_animtime, 2.0 )
	entity_set_float( ent, EV_FL_framerate, 1.0 )
	entity_set_int( ent, EV_INT_sequence, get_pcvar_num(gCvarDummyAnimation))	
	drop_to_floor( ent )
	engfunc(EngFunc_EmitSound, ent, CHAN_AUTO, sound, 1.0, ATTN_NORM, 0, PITCH_NORM);
	return PLUGIN_CONTINUE
}
stock UTIL_JeHracBlizkoOrigin(const Float:origin[3], const Float:distance = 40.0) {
	// Hladame blizko hracov ...
	new i, Float:postava[3]
	for(i=1; i <= g_maxplayers; i++) {
		if (!is_user_alive(i)) continue;
		pev(i, pev_origin, postava);
		if ( get_distance_f(origin, postava) < distance) { // najmenej 34.0
			return false;
		}
	}
	return true; // je prazdny ...
}
public fw_TakeDamage(ent, weapon, attacker, Float:damage, damage_type) {
	if(!pev_valid(ent)) return HAM_IGNORED; 
	
	// Pre istotu
	static EntityName[32];
	pev(ent, pev_classname, EntityName, 31);
	if(!equal(EntityName, CLASS_MENO) ) return HAM_IGNORED;
	if(!is_user_connected(attacker)) return HAM_IGNORED;
	
	if(damage > 0.0) {				
		set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1)
		ShowSyncHudMsg(attacker, g_MsgSync, "%i^n", floatround(damage))
	}
	return HAM_IGNORED;
}