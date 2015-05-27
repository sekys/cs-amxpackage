#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <zombieplague>
#include <hamsandwich>
#include <Vexd_Utilities>
#include <fun>

#define RemoveEntity(%1)	engfunc(EngFunc_RemoveEntity,%1)
#define fm_drop_to_floor(%1) engfunc(EngFunc_DropToFloor,%1)

#define OWNER				pev_iuser2
#define CLASS_MENO			"zp_hovno"
#define MAX_HP				300.0

#define PLUGIN  	"[ZP] Vrana"
#define VERSION 	"1.0"
#define AUTHOR  	"Seky"

new const sounds[][] = { "zombie_plague/crow.wav" }
new const g_models[][] = { "models/zombie_plague/gecom_skull.mdl" }
new const zclass_name[] = { "Vrana" } // name
new const zclass_info[] = { "Lieta, Serie hovno :D" } // description
new const zclass_model[] = { "crow" } // model
new const zclass_clawmodel[] = { "svab_knife.mdl" } // claw model
const zclass_health = 300 // health
const zclass_speed = 200 // speed
const Float:zclass_gravity = 0.6 // gravity
const Float:zclass_knockback = 2.0 // knockback

new g_zclass_crow, g_hovno[33]

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	RegisterHam(Ham_Player_PreThink, "player", "cheese_player_prethink", 1)
	register_logevent("round_start", 2, "0=World triggered", "1=Round_Start" )
}
public plugin_precache()
{
	g_zclass_crow = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
	new i
	for (i=0; i < sizeof sounds; i++)
		engfunc(EngFunc_PrecacheSound, sounds[i])	
	for(i=0;i < sizeof g_models;i++)
		engfunc(EngFunc_PrecacheModel,g_models[i]);	
}
public round_start() {
	static ent; // hraci
	for(ent=0; ent < 33; ent++ ) g_hovno[ent] = 3;	
	ent=-1; // a teraz entity
	while( ( ent = engfunc( EngFunc_FindEntityByString, ent, "classname", CLASS_MENO ) ) ){
        RemoveEntity(ent)
    }
}
public client_disconnect(id) { 
	g_hovno[id] = 0; 
}
public cheese_player_prethink(id) 
{
	if(!is_user_alive(id) || !zp_get_user_zombie(id)) return PLUGIN_CONTINUE
	if(zp_is_survivor_round() || zp_is_nemesis_round() || zp_is_plague_round()) return PLUGIN_CONTINUE
	if(zp_get_user_zombie_class(id) != g_zclass_crow) return PLUGIN_CONTINUE
	
	// Lietanie
	if(pev(id, pev_button ) & IN_JUMP) {		
		static Float:fAim[3] , Float:fVelocity[3];
		VelocityByAim(id , zclass_speed - 20, fAim);			
		fVelocity[0] = fAim[0];
		fVelocity[1] = fAim[1];
		fVelocity[2] = fAim[2];
		set_user_velocity(id , fVelocity);
	}
	// Ochrana proti vela HP
	if( pev(id, pev_health) > MAX_HP) {
		set_pev(id, pev_health, MAX_HP);
	}
	// Schopnost srat
	if(pev(id, pev_button ) & IN_RELOAD && !(pev(id, pev_oldbuttons ) & IN_RELOAD ))
	{
		if(g_hovno[id] <= 0) {
			//g_hovno[id]++;
			static bodov
			bodov = zp_get_user_ammo_packs(id)
			if(bodov > 0) {
				client_print(id,print_chat,"[G/L ZP] Kupene hovno za 1 bod.")
				zp_set_user_ammo_packs(id, bodov -  1)
			} else {
				client_print(id, print_chat,"[G/L ZP] Nedostatok bodov.")
				return PLUGIN_CONTINUE;
			}
		} else {
			g_hovno[id]--;
			client_print(id, print_chat,"[G/L ZP] Mas este %d naboje zdarma !", g_hovno[id])
		}
		spawn_sracka(id)
		emit_sound(id, CHAN_ITEM, sounds[random_num(0, sizeof sounds - 1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}	
	return PLUGIN_CONTINUE;
}
public zp_user_infected_post(id, infector)  {		
	if (zp_get_user_zombie_class(id) == g_zclass_crow) {
		// Velkost + efekty ....
		//set_user_hitzones(0, id, 6)
		emit_sound(id, CHAN_ITEM, sounds[random_num(0, sizeof sounds - 1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		// Vypneme pri specialnych schopnosti
		set_task(3.0, "next_sound", id)		
		client_print(id, print_chat,"[G/L ZP] Lietas pomocou MEDZERNIKA a series nakazene hovna s R")
	}
	return PLUGIN_CONTINUE;
}
public next_sound(id)
{
	if(!is_user_alive(id) || !zp_get_user_zombie(id)) return PLUGIN_CONTINUE
	if(zp_is_survivor_round() || zp_is_nemesis_round() || zp_is_plague_round()) return PLUGIN_CONTINUE
	if(zp_get_user_zombie_class(id) != g_zclass_crow) return PLUGIN_CONTINUE
	
	emit_sound(id, CHAN_ITEM, sounds[random_num(0, sizeof sounds - 1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	set_task(float(random_num(4, 11)), "next_sound", id)
}
stock spawn_sracka(id) {	
	
	static Float:origin[3], ent
    entity_get_vector(id, EV_VEC_origin, origin)	
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));	
	set_pev(ent,pev_classname, CLASS_MENO);
	engfunc(EngFunc_SetModel,ent,g_models[random(sizeof g_models)]);
	engfunc(EngFunc_SetOrigin, ent, origin);	
	set_pev(ent,pev_solid, SOLID_TRIGGER);
	set_pev(ent,pev_movetype,MOVETYPE_TOSS); //MOVETYPE_TOSS na zem a FLY lieta
	set_pev(ent, OWNER, id);
	//client_print(id,print_chat,"[G/L ZP] Vykakal si sa !")
	fm_drop_to_floor(ent);
/*
	entity_set_float(ent, EV_FL_renderamt, 1000.0)
	entity_set_int(ent, EV_INT_effects, 32);
	entity_set_int(ent, EV_INT_renderfx, kRenderFxGlowShell)
	entity_set_int(ent, EV_INT_rendermode, kRenderNormal)
*/
	return PLUGIN_CONTINUE;
}
public pfn_touch(coho, id) {	
	if( (coho == 0) || (id == 0)) return PLUGIN_HANDLED		
	if(!pev_valid(coho)) return PLUGIN_HANDLED
	
	static classname[32]
    pev(coho, pev_classname, classname, 31 )
    if(equal(classname, CLASS_MENO)) {
		//client_print(0, print_chat, "lol" )	// log
		if(is_user_alive(id)) {			
			if(!zp_get_user_last_human(id) && !zp_get_user_zombie(id))
			{
				new majitel = pev(coho,OWNER)
				majitel = is_user_connected(majitel) ? majitel : 0
				zp_infect_user(id, majitel)
				client_print(id, print_chat,"[G/L ZP] Stupil si na nakazene hovno !")	
				RemoveEntity(coho)
			}
		}
    }     
    return PLUGIN_CONTINUE
}