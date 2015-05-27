#include <amxmodx>
#include <fakemeta>
#include <zombieplague>
#include <Vexd_Utilities>


new const SOUND[] = "zombie_plague/necrofago.wav"

new const zclass_name[] = { "Necrofago" } 
new const zclass_info[] = { "Stane z mrtvych" } 
new const zclass_model[] = { "duch" } //{ "Necrofago_frk_14" } // model
new const zclass_clawmodel[] = { "duch_hand.mdl" }//{ "necrofago.mdl" } // claw model
const zclass_health = 1500 // health
const zclass_speed = 190 // speed
const Float:zclass_gravity = 1.0 // gravity
const Float:zclass_knockback = 1.0 // knockback

new bool:medzi_kola
new ulozeny_vektor[33][3]
new posledna_pozicia[33][3]
new bool:pouzil[33]
new g_zclass_crow

public plugin_init()
{
	register_plugin("[ZP] Necrofago", "1.0" , "Seky");
	register_event("DeathMsg", "smrt", "a")
	register_logevent("round_start", 2, "0=World triggered", "1=Round_Start" )
}
public plugin_precache()
{
	g_zclass_crow = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)	
	precache_sound(SOUND)
}
public smrt()
{
	if(zp_is_survivor_round() || zp_is_nemesis_round())
		return PLUGIN_CONTINUE
	
	new id = read_data(2)
	if (!is_user_connected(id))
		return PLUGIN_CONTINUE
	if (!zp_get_user_zombie(id))
		return PLUGIN_CONTINUE
	if (zp_get_user_last_zombie(id))
		return PLUGIN_CONTINUE	
	if(zp_get_user_zombie_class(id) != g_zclass_crow)
		return PLUGIN_CONTINUE
		
	get_user_origin(id, ulozeny_vektor[id])
	ulozeny_vektor[id][2] += 512 // 8
	zp_set_user_zombie_class(id, g_zclass_crow);
	
	if (!is_user_alive(id) && !pouzil[id]) {
		// never set higher then 1.9 or lower then 0.5
		set_task(1.5, "zm_respawn", id)
	}
}
public round_start()
{
	medzi_kola = false
	for ( new i = 0; i < 33; i++ ) {
		pouzil[i] = false
	}
}
public zp_round_started(gamemode, player)
{
	medzi_kola = false
}
public zp_round_ended(winteam)
{
	medzi_kola = true
}
public zm_respawn(id)
{
	if ( !is_user_connected(id) || is_user_alive(id) ) return
	if ( medzi_kola ) return

	emit_sound(id, CHAN_STATIC, SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM)
	client_print(id, print_chat, "[G/L ZP] Vstal si z mrtvych !")

	// Double spawn prevents the no HUD glitch
	pouzil[id] = true
	// Opravny bug ....
	zp_set_user_zombie_class(id, g_zclass_crow);
	// Respawn
	zp_respawn_user(id, ZP_TEAM_ZOMBIE)
	phoenix_teleport(id)
}
stock phoenix_teleport(id)
{
	// Teleport the player
	//entity_set_origin(id, ulozeny_vektor[id]);
	Entvars_Set_Vector(id, EV_VEC_velocity, ulozeny_vektor[id])
	
	// Teleport Effects
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(11)					// TE_TELEPORT
	write_coord(ulozeny_vektor[id][0])	// start position
	write_coord(ulozeny_vektor[id][1])
	write_coord(ulozeny_vektor[id][2])
	message_end()

	positionChangeTimer(id)
}
public positionChangeTimer(id)
{
	if ( !is_user_alive(id) ) return

	get_user_origin(id, posledna_pozicia[id])

	new Float:velocity[3]
	Entvars_Get_Vector(id, EV_VEC_velocity, velocity)

	if ( velocity[0]==0.0 && velocity[1]==0.0 ) {
		// Force a Move (small jump)
		velocity[0] += 20.0
		velocity[2] += 100.0
		Entvars_Set_Vector(id, EV_VEC_velocity, velocity)
	}

	set_task(0.4, "positionChangeCheck", id+100)
}
public positionChangeCheck(id)
{
	id -= 100
	if ( !is_user_alive(id) ) return

	new origin[3]
	get_user_origin(id, origin)

	// Kill this player if Stuck in Wall!
	if ( posledna_pozicia[id][0] == origin[0] && posledna_pozicia[id][1] == origin[1] && posledna_pozicia[id][2] == origin[2] && is_user_alive(id) ) {
		user_kill(id, 1)
		client_print(id, print_chat, "[G/L ZP] Zasekol si sa v stene.")
	}
}



