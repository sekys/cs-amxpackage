#include <amxmod>
#include <zombieplague>
#include <fakemeta>
#include <hamsandwich>

#define ZOOM 125 // zoom obarzovky ,viacej nez 100

new const zclass2_name[] = { "Svab" }
new const zclass2_info[] = { " - Jump++ Kb+++ Rychli v sachte" }
new const zclass2_model[] = { "gl_svab" }
new const zclass2_clawmodel[] = { "svab_knife.mdl" }
const zclass2_health = 750
const zclass2_speed = 500 // plague sam vypocita 2.35
const Float:zclass2_gravity = 0.5
const Float:zclass2_knockback = 0.8

new const zombie_idle[][] = { 
	"headcrab/hc_alert1.wav" ,
	"headcrab/hc_die2.wav",
	"headcrab/hc_pain1.wav",
	"zombie_plague/slv_die1.wav",
	"zombie_plague/slv_die2.wav",
	"zombie_plague/slv_alert3.wav",
	"zombie_plague/slv_word1.wav" 
}
new g_zclass_svab,blood_drop, blood_spray, bool:klaci[33], 
	g_maxplayers

public plugin_init()
{
	register_plugin("Zp svab", "1.0", "Seky")
	register_event("ResetHUD", "newround", "b");
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	g_maxplayers = get_maxplayers()
}
public plugin_precache()
{
	g_zclass_svab = zp_register_zombie_class(zclass2_name, zclass2_info, zclass2_model, zclass2_clawmodel, zclass2_health, zclass2_speed, zclass2_gravity, zclass2_knockback)
	blood_drop = precache_model("sprites/blood.spr")
	blood_spray = precache_model("sprites/bloodspray.spr")
	for (new i=0; i < sizeof zombie_idle; i++) 
		engfunc(EngFunc_PrecacheSound, zombie_idle[i]);
}
public newround(id) { spat(id);  }
public zp_round_started(gamemode, id)
{
	if(	gamemode == MODE_NEMESIS || 
		gamemode == MODE_WITCH || 
		gamemode == MODE_MOM || 
		gamemode == MODE_MARRY ||
		gamemode == MODE_SURVIVOR ||
		gamemode == MODE_DERATIZER
	)  {
		klaci[id] = false
		client_cmd(id, "-duck")
	} else {
		// Ak je to svab
		if(zp_get_user_zombie_class(id) == g_zclass_svab) {
			klaci[id] = true;
		}
	}
	// Pri derakovy bug ...
	if(	gamemode == MODE_DERATIZER) {
		for(new i=1; i <= g_maxplayers; i++) {
			if(id != i && is_user_alive(i)) {
				klaci[id] = true;
			}
		}
		//client_print(0, print_chat, "ok");
		klaci[id] = false;
		client_cmd(id, "-duck")
	}
}
stock spat(id) {
	klaci[id] = false
	client_cmd(id, "-duck")
	//set_pev(id, pev_bInDuck, 0)
	if(is_user_alive(id)) {
		set_user_hitzones(0, id, 255)
		set_user_footsteps(id, 0)
	}
}
public fw_PlayerPreThink(id) {
	if(klaci[id]) { client_cmd(id, "+duck");  }
	return PLUGIN_CONTINUE;
}
public fw_PlayerKilled(id, attacker, shouldgib){
	if(klaci[id]) {
		klaci[id] = false
		//spat(id);
		client_cmd(id, "-duck")
		client_cmd(id, "+duck")
	}
	return PLUGIN_CONTINUE;
}
public client_disconnect(id) { 
	klaci[id] = false;
}
public kontrola(id) {
	if(!klaci[id]) return PLUGIN_CONTINUE;	
	set_task( random_float(2.0, 12.0) , "zvucky", id) // nahodne zvucky						
	set_task(3.0, "kontrola",id)
}
public zp_user_infected_post(id, infector)  {
	// Ak obet je tiez svab ...
	if(zp_get_user_zombie_class(id) == g_zclass_svab) {					
		// bug so nemesiom a witch atd ....
		if(
			zp_get_user_nemesis(id) ||
			zp_get_user_witch(id) ||
			zp_get_user_survivor(id) ||
			zp_get_user_mom(id)
		) {
			klaci[id] = false
			client_cmd(id, "-duck")
			return PLUGIN_CONTINUE; 
		}
		//cupi
		klaci[id] = true
		kontrola(id)
		set_user_hitzones(0, id, 192)
		set_user_footsteps(id, 1)
		// Efekty
		setScreenFlash(id, 255, 0, 0, 10, 100)
		efekt(id)				
	}	
}
public zp_user_humanized_post(id) {
	if(klaci[id]) spat(id);
	//client_print(0, print_chat, "human");
	return PLUGIN_CONTINUE;
}
public zvucky(id) {
	// nahodne zvucky ...
	if(klaci[id]) {
		emit_sound(id, CHAN_STATIC, zombie_idle[ random_num(0, sizeof zombie_idle - 1) ], 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
}
//================================================
// Efekty
stock efekt(id)
{
	static iOrigin[3]
	get_user_origin(id,iOrigin)					
	fx_blood_red(iOrigin)
	fx_blood_red(iOrigin)
	fx_blood_red(iOrigin)
	fx_bleed_red(iOrigin)
	fx_bleed_red(iOrigin)
	fx_headshot_red(iOrigin)	
}
stock fx_bleed_red(origin[3])
{
	// Blood spray
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(101)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+10)
	write_coord(random_num(-100,100))
	write_coord(random_num(-100,100))
	write_coord(random_num(-10,10))
	write_byte(70)
	write_byte(random_num(50,100))
	message_end()
}
stock fx_blood_red(origin[3])
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(115)
	write_coord(origin[0]+random_num(-20,20))
	write_coord(origin[1]+random_num(-20,20))
	write_coord(origin[2]+random_num(-20,20))
	write_short(blood_spray)
	write_short(blood_drop)
	write_byte(248)
	write_byte(15)
	message_end()
}
stock fx_headshot_red(origin[3])
{
	for (new i = 0; i < 5; i++) {
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(101)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2]+30)
		write_coord(random_num(-20,20)) // x
		write_coord(random_num(-20,20)) // y
		write_coord(random_num(50,300)) // z
		write_byte(70) // color
		write_byte(random_num(25,50)) // speed
		message_end()
	}
}
stock setScreenFlash(id, red, green, blue, decisecs, alpha)
{
	if (!is_user_connected(id)) return
	message_begin(MSG_ONE,get_user_msgid("ScreenFade"),{0,0,0},id)
	write_short( 1<<decisecs ) // fade lasts this long duration
	write_short( 1<<decisecs ) // fade lasts this long hold time
	write_short( 1<<12 ) // fade type (in / out)
	write_byte( red ) // fade red
	write_byte( green ) // fade green
	write_byte( blue ) // fade blue
	write_byte( alpha ) // fade alpha
	message_end()
}