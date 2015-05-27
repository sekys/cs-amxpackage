#include <amxmodx>
#include <zombieplague>
#include <fakemeta>
#include <hamsandwich>
#include <engine>

#define MODELSET_TASK 	100
#define MODEL_CT 		1 // "gl_ct" // stacia len kratke nazvy
#define MODEL_ZM 		0 // "gl_chameleon"
#define TASK_TICRATE 	1.0

new const zclass_name[] = { "Chameleon" } // name
new const zclass_info[] = { "Zmeni na CT" } // description
new const zclass_clawmodel[] = { "v_knife_zombie.mdl" } // claw model
new const sound[] = { "zombie_plague/Tomes.wav" }
new const model_zombie[] = { "gl_chameleon" }  // model
// info
const zclass_health = 1300 // health
const zclass_speed = 170 // speed
const Float:zclass_gravity = 1.0 // gravity
const Float:zclass_knockback = 1.25 // knockback

new Float:casovac[33], bool:CasovacJePovoleny[33], Zombie_id, cvar_casovac, 
	g_maxplayers

public plugin_init() {
	register_plugin("ZP Chameleon", "1.0", "Seky")
	RegisterHam(Ham_Player_PreThink, "player", "PlayerPreThink", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	cvar_casovac = register_cvar("zp_chameleon", "15.0")
	g_maxplayers = get_maxplayers()
}
public plugin_precache() {
	Zombie_id = zp_register_zombie_class(zclass_name, zclass_info, model_zombie, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
	precache_sound(sound)	
}
public PlayerPreThink(const id) 
{
	if(pev(id, pev_button ) & IN_RELOAD && !(pev(id, pev_oldbuttons ) & IN_RELOAD ))
	{
		if(zp_is_survivor_round() || zp_is_nemesis_round()) return FMRES_IGNORED;
		if(!is_user_alive(id) || !zp_get_user_zombie(id)) return FMRES_IGNORED;
		if(zp_get_user_zombie_class(id) != Zombie_id) return FMRES_IGNORED;
		// Ak vyzera ako clovek
		if(CasovacJePovoleny[id]) {
			ZmenitSpat(id)	
		} else {
			if(!casovac[id]) {
				client_print(id,print_chat,"[G/L ZP] Casovac na chameleona dosiel !");
				return FMRES_IGNORED;
			} 
			ZmenitNaCT(id)
		}
	}
	return FMRES_IGNORED;
}
public zp_user_infected_post(id, infector) {		
	if (zp_get_user_zombie_class(id) == Zombie_id) {
		casovac[id] = get_pcvar_float(cvar_casovac); // od znova ziska cas ...
	}
	return PLUGIN_CONTINUE;
}
public VerejnyCasovac() {
	static id;
	for(id=1; id <= g_maxplayers; id++) {
		if(!CasovacJePovoleny[id]) continue; // je v CasovacJePovolenye ?
		casovac[id] -= TASK_TICRATE;
		if(!casovac[id]) {
			ZmenitSpat(id);	
		}
	}
	return PLUGIN_CONTINUE;
}
stock ZmenitNaCT(const id) {	
	CasovacJePovoleny[id] = true;
	client_print(id, print_chat,"[G/L ZP] Chameleon zmena len na %i sec.", floatround(casovac[id]));
	mystique_sound(id)
	client_print(id, print_center,"Vyzeras ako clovek.");
	zp_set_model(id, MODEL_CT)
}
stock ZmenitSpat(const id) {
	ZmenitSpat2(id);
	mystique_sound(id)
	client_print(id, print_center, "Si spat vo svojej kozi.");
}
stock ZmenitSpat2(const id) {
	CasovacJePovoleny[id] = false;
	zp_set_model(id, MODEL_ZM)
}
stock mystique_sound(id) {
	engfunc(EngFunc_EmitSound, id, CHAN_AUTO, sound, 1.0, ATTN_NORM, 0, PITCH_NORM);	
}
public fw_PlayerKilled(id, attacker, shouldgib){
	// Ak zomrel pocas ZM model
	if(CasovacJePovoleny[id]) {
		ZmenitSpat2(id);
	}
	return PLUGIN_CONTINUE;
}
public zp_user_humanized_post(id) {
	// teraz bez modelu ....
	if(CasovacJePovoleny[id]) {
		ZmenitSpat2(id);
	}	
	return PLUGIN_CONTINUE;
}
public zp_round_ended(winteam) {
	remove_task(MODELSET_TASK);
	static id;
	for(id=1; id <= g_maxplayers; id++) {
		if(CasovacJePovoleny[id]) { // este ti co ostali premeneny
			ZmenitSpat2(id);
		}
	}
	return PLUGIN_CONTINUE;
}
public zp_round_started(gamemode, id)  {	
	set_task(TASK_TICRATE, "VerejnyCasovac", MODELSET_TASK, _, _, "b")
	return PLUGIN_CONTINUE;
}/*
stock Animacia(const ent, const typ) {
	entity_set_float( ent, EV_FL_animtime, 2.0 )
	entity_set_float( ent, EV_FL_framerate, 1.0 )
	entity_set_int( ent, EV_INT_sequence, typ )	
}





if(zp_is_survivor_round() || zp_is_nemesis_round()) return PLUGIN_CONTINUE
if(!is_user_alive(id) || !zp_get_user_zombie(id)) return PLUGIN_CONTINUE
if(zp_get_user_zombie_class(id) != g_zclass_crow) return PLUGIN_CONTINUE
*/