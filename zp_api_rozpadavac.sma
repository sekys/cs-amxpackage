/*
*pouzijeme HP_PREFIX
*ak zomiera
*rozpadne sa na polovicku
*potom na ruku
*Ak je ale 1. a dostane hedu nerespawnuje sa
*a spravit novy navod...
*pouzit zdrojak necrofga a samostatne bude
*/
#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <zombieplague>
#include <hamsandwich>
#include <Vexd_Utilities>
#include <cstrike>
#include <zp_api_functions>
#include <xs>

#define PLUGIN  	"[ZP] Rozpadavac"
#define VERSION 	"1.0"
#define AUTHOR  	"Seky"

#define debug(%1)	client_print(0, print_chat, "DEBUG - %s", %1)
#define is_user_valid_alive(%1) (1 <= %1 <= maxplayers && is_user_alive(%1))
#define is_user_valid(%1) (1 <= %1 <= maxplayers)

enum (+=1){
	D_0 = 0,		// nieje rozpadnuty, su 2 zombici na sebe
	D_1,			// uz je len sam
	D_2,			// polovicka tela
	D_3,			// ruka
	D_CANT, 		// nemoze byt zniceney nema tu schopnost alebo je koniec
};

// Info
new const sounds_destroy[][] = { 
	"zombie_plague/l4d2/charger/charger_charge_01.wav", 
	"zombie_plague/l4d2/charger/charger_charge_02.wav"  
}
new const models[][] = { 
	"l4d2_charger",
	"models/player/l4d2_charger/l4d2_charger.mdl"
}
new const models_hand[][] = { 
	"l4d2_charger.mdl",
	"models/zombie_plague/l4d2_charger.mdl"
}

// Vlastnosti
new const class_name[] = { "Rozpadavac" }
new const class_info[] = { "sa rozpadne na 3 kusy" }
new const Float:Levels[][] = {
	// HP		Speed	Gravity	Knocback 	Ducking
	{ 1000.0, 	240.0, 	1.4, 	1.0,		0.0		},
	{ 500.0, 	270.0, 	0.9, 	1.5,		0.0		},
	{ 250.0, 	340.0, 	1.0, 	1.0,		1.0		},
	{ 175.0, 	450.0, 	0.7, 	0.5,		1.0		}
};
const bool:HeadShotKillHim = true;
new class_destroy, maxplayers, g_level[33],
	bool:g_klaci[33], model_index[D_CANT]
	
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	RegisterHam(Ham_Player_PreThink, "player", "fw_PlayerPreThink")
	register_logevent("fw_RoundStart", 2, "0=World triggered", "1=Round_Start" )
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	register_event("CurWeapon", "vybera_zbran", "be", "1=1")
	maxplayers = get_maxplayers();
}
public zp_user_humanized_post(id, survivor) {
	SetBackDuck(id);
	return PLUGIN_CONTINUE;
}
stock SetBackDuck(const id) {
	if(g_klaci[id]) { 
		client_cmd(id, "-duck")
		g_klaci[id] = false;
		return true;
	}
	return false;
}
public plugin_precache(){
	class_destroy = zp_register_zombie_class(
						class_name, class_info, 
						models[D_0], models_hand[D_0], 
						floatround(Levels[D_0][0]), floatround(Levels[D_0][1]), 
						Levels[D_0][2], Levels[D_0][3]
					);
	new i
	for(i=0; i < sizeof sounds_destroy; i++)
		engfunc(EngFunc_PrecacheSound, sounds_destroy[i])		
	for(i=D_1; i < sizeof models; i++) {
		model_index[i-1] = engfunc(EngFunc_PrecacheModel, models[i]);
		fm_precache_model(models_hand[i])	
	}	
}
public fw_RoundStart() {
	for(new i = 1; i <= maxplayers; i++) {
		SetBackDuck(i);
	}
}
public client_disconnect(id) { 
	g_klaci[id] = false;	
	g_level[id] = D_CANT;
}
public zp_round_ended(winteam) {
	for(new i = 1; i <= maxplayers; i++) {	
		SetBackDuck(i);
	}
}
stock ProcessDucking(const id) {
	if(g_klaci[id]) { 
		client_cmd(id, "+duck");
		return true;
	}
	return false;
}
public fw_PlayerPreThink(id) {
	// Think
	if(zp_is_special_round()) return HAM_IGNORED;
	if(!is_user_alive(id)) return HAM_IGNORED;
	if(!zp_get_user_zombie(id)) return HAM_IGNORED;
	if(zp_get_user_zombie_class(id) != class_destroy) return HAM_IGNORED;
	
	static level; level = g_level[id];
	if(level == D_CANT) return HAM_IGNORED;
	if(g_klaci[id]) client_cmd(id, "+duck");	
	set_pev(id, pev_maxspeed, Levels[level][1])
	set_pev(id, pev_gravity, Levels[level][2])
	return HAM_IGNORED;
}
public zp_user_infected_post(id, infector)  {			
	if (zp_get_user_zombie_class(id) == class_destroy) {
		g_level[id] = D_0;	
		client_print(id, print_chat,"[ROZPADAC] Si takmer neznicitelny, rozpadnes sa 3x.")
	}
	return PLUGIN_CONTINUE;
}
public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tr, damage_type)
{
	// Filtrujeme
	if(victim == attacker) return HAM_IGNORED;	
	if(!is_user_valid_alive(attacker) || !is_user_valid_alive(victim)) return HAM_IGNORED;		
	if(zp_get_user_zombie(attacker) || !zp_get_user_zombie(victim)) return HAM_IGNORED;	
	if(zp_is_special_round()) return HAM_IGNORED;	
	if(zp_get_user_zombie_class(victim) != class_destroy) return HAM_IGNORED

	// Nastane smrt ?
	if (damage >= pev(victim, pev_health) ) {
		// Ak headshot
		if(HeadShotKillHim && get_tr2(tr, TR_iHitgroup) == HIT_HEAD) 
			return HAM_IGNORED;

		// Daj dalsi stupen
		g_level[victim]++;
		if(g_level[victim] >= D_CANT) return HAM_IGNORED;
		Efekt(victim)
		SetNewLevel(victim, g_level[victim]);
		return HAM_SUPERCEDE;
	}	
	
	// Este uprav knockback	
	static Float:velocity[3]
	pev(victim, pev_velocity, velocity)
	xs_vec_mul_scalar(direction, Levels[g_level[victim]][3], direction)
	xs_vec_add(velocity, direction, direction)
	set_pev(victim, pev_velocity, direction)
	return HAM_IGNORED;
}
stock VirtualKill(const id) {
	g_level[id]++;
	if(g_level[id] >= D_CANT) return HAM_IGNORED;
	Efekt(id)
	SetNewLevel(id, g_level[id]);
	return HAM_SUPERCEDE;
}
stock Efekt(const id) {
	// nemam ziadny...
}
stock SetNewLevel(const id, const level) {
	// Modely
	zp_set_smodel(id, models[level])
	set_pev(id, pev_viewmodel2, models_hand[level])
	set_pev(id, pev_weaponmodel2, "")
	// Dalsie vlastnosti
	if(Levels[level][5] == 1.0) g_klaci[id] = true;
	set_pev(id, pev_health, Levels[level][0]);
}
public vybera_zbran(id) {
	static level; level = g_level[id];
	if(level < D_1 || level >= D_CANT) return PLUGIN_CONTINUE;
	if(zp_get_user_zombie_class(id) != class_destroy) return PLUGIN_CONTINUE;
	if(!zp_get_user_zombie(id)) return PLUGIN_CONTINUE;
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;
	if(zp_is_special_round()) return PLUGIN_CONTINUE;

	if(read_data(2) == CSW_KNIFE) {
		set_pev(id, pev_viewmodel2, models_hand[level])
		set_pev(id, pev_weaponmodel2, "")
	}
	return PLUGIN_CONTINUE
}