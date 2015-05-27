/*
*Pouzit zdrojak vrany
*Vsetke l4d budu podporovat nove native set_camera
*pridame model, model ruky, priemerne vlastnosti
*zachytime R, cim sa spusti StartAction, na cas 5 sec
*odpojime mu ovladanie, nove native
*a spravyme vektor pohybu, dlzka je const priblizne 2000.0 (treba vela)
*pocas nej ma 350speed a zachytavame touch s hracmy
*touch len na ludi, ak sa dotkne prepne zachyteny[id]
*moze zachytavat viacej ludi, radius nedat ale array hej
*pocas akcie zachytavame pomocou traceline skutocny koniec, const END_OFFSET = 30.0
*ak narazi, spusti sa efekt
*ak nastane koniec, hraca zabije, viac asi nic,. ..
*ak je koniec vsetke TASK skoncia

charger pri utoku ma nanimaciu behu, nakloneni do predu
zvucka na startaction nenei to ono
*/
#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <zombieplague>
#include <hamsandwich>
#include <Vexd_Utilities>
#include <cstrike>
#include <zombie_basic>
#include <xs>

#define PLUGIN  	"[ZP] L4D2 Charger"
#define VERSION 	"1.0"
#define AUTHOR  	"Seky"

#define debug(%1)	// client_print(0, print_chat, "DEBUG - %s", %1)
#define is_user_valid_alive(%1) (1 <= %1 <= maxplayers && is_user_alive(%1))
#define is_user_valid(%1) (1 <= %1 <= maxplayers)

// Info
new const sounds_startaction[][] = { 
	"zombie_plague/l4d2/charger/charger_charge_01.wav", 
	"zombie_plague/l4d2/charger/charger_charge_02.wav"  
} //buaa
new const sounds_throw[][] = { 
	"zombie_plague/gl_new/Death_04.wav", 
	"zombie_plague/gl_new/Death_05.wav" 
}// huaaa
new const sounds_take[][] = { 
	"zombie_plague/gl_new/Death_04.wav", 
	"zombie_plague/gl_new/Death_05.wav" 
} // aaa
new const sounds_hitwall[][] = { 
	"zombie_plague/l4d2/charger/loud_chargerimpact_01.wav", 
	"zombie_plague/l4d2/charger/loud_chargerimpact_02.wav", 
	"zombie_plague/l4d2/charger/loud_chargerimpact_03.wav", 
	"zombie_plague/l4d2/charger/loud_chargerimpact_04.wav" 
} // boom
new const sounds_idle[][] = { 
	"zombie_plague/l4d2/charger/charger_lurk_01.wav" ,
	"zombie_plague/l4d2/charger/charger_lurk_02.wav" ,
	"zombie_plague/l4d2/charger/charger_lurk_03.wav" ,
	"zombie_plague/l4d2/charger/charger_lurk_06.wav" ,
	"zombie_plague/l4d2/charger/charger_lurk_09.wav" ,
	"zombie_plague/l4d2/charger/charger_lurk_10.wav" ,
	"zombie_plague/l4d2/charger/charger_lurk_11.wav" ,
	"zombie_plague/l4d2/charger/charger_lurk_22.wav"
} //hrrr
new const models[] = { "l4d2_charger" }
new const models_hand[] = { "l4d2_charger.mdl" }

// Vlastnosti
new const class_name[] = { "L4D2 Charger" }
new const class_info[] = { "ta stiahne a je s tebou koniec" }
const class_health = 1200
const class_speed = 260
const Float:class_gravity = 1.2
const Float:class_knockback = 1.0

// Turbo vlastnosti
const Float:turbo_speed = 370.0;
const Float:turbo_stopspeed = 150.0;
const turbo_maxtime = 7;
const Float:turbo_maxdistance = 300.0;
const Float:turbo_distancetograb = 50.0;
const Float:turbo_speedgrab = 900.0;
const Float:charger_damagemultiplier = 1.5;
const charger_maxschopnost = 200;

new class_charger, maxplayers, g_grabbed[33], g_casovac[33],
	g_schopnost[33], bool:g_inaction[33], Float:g_angle[33][3]

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	RegisterHam(Ham_Player_PreThink, "player", "fw_PlayerPreThink")
	register_logevent("fw_RoundStart", 2, "0=World triggered", "1=Round_Start" )
	RegisterHam(Ham_Touch, "player", "fw_TouchPlayer", 1)	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled", 1)
	maxplayers = get_maxplayers();
}
public fw_PlayerKilled(id, attacker, shouldgib) {
	if(g_inaction[id]) EndOfAction(id);
	return HAM_IGNORED;
}
public zp_user_humanized_post(id, survivor) {
	if(g_inaction[id]) EndOfAction(id);
	return PLUGIN_CONTINUE;
}
public plugin_precache(){
	class_charger = zp_register_zombie_class(class_name, class_info, models, models_hand, class_health, class_speed, class_gravity, class_knockback)
	
	new i
	for(i=0; i < sizeof sounds_startaction; i++)
		engfunc(EngFunc_PrecacheSound, sounds_startaction[i])	
	for(i=0;i < sizeof sounds_hitwall;i++)
		engfunc(EngFunc_PrecacheSound ,sounds_hitwall[i]);	
	for(i=0;i < sizeof sounds_idle;i++)
		engfunc(EngFunc_PrecacheSound, sounds_idle[i]);	
	for(i=0;i < sizeof sounds_take;i++)
		engfunc(EngFunc_PrecacheSound, sounds_take[i]);	
	for(i=0;i < sizeof sounds_throw;i++)
		engfunc(EngFunc_PrecacheSound, sounds_throw[i]);	
}
public fw_RoundStart() {
	for(new i = 1; i <= maxplayers; i++) {
		g_schopnost[i] = charger_maxschopnost;
	}
}
public client_disconnect(id) { 
	g_inaction[id] = false;	
	g_grabbed[id] = 0;
}
public zp_round_ended(winteam) {
	for(new i = 1; i <= maxplayers; i++) {	
		g_inaction[i] = false;
		g_grabbed[i] = 0;
	}
}
public fw_PlayerPreThink(id) {
	// Think
	if(zp_is_special_round()) return HAM_IGNORED;
	if(!is_user_alive(id)) return HAM_IGNORED;
	if(!zp_get_user_zombie(id)) return turbo_grabed(id);
	if(zp_get_user_zombie_class(id) != class_charger) return HAM_IGNORED

	// Schopnost
	if(pev(id, pev_button ) & IN_RELOAD && !(pev(id, pev_oldbuttons ) & IN_RELOAD )) {
		if(g_schopnost[id]) {
			if(g_inaction[id]) {
				client_print(id, print_chat, "[CHARGER] Prave pouzivas schopnost !")
			} else {
				StartAction(id);
				g_schopnost[id]--;
			}
		} else {
			client_print(id, print_chat, "[CHARGER] Uz viac nemozes pouzit schopnost !")
		}
	}	
	// Turbo
	if(g_inaction[id]) InActionThink(id);				
	return HAM_IGNORED;
}
stock turbo_grabed(const id) {
	if(!g_grabbed[id]) return HAM_IGNORED;
	// Animacia
	static Float:snimok;
	pev(id, pev_framerate, snimok)
	if(!Animacia_PlayOnlyOne(id, 110, 0.01, snimok, 24.0)) {
		Animacia_PlayOneFrame(id, 110, 24.0);
	}

	// Drzime hraca
	static 	Float:velocity[3], Float:distance,
			Float:origin[3], Float:origin2[3];
	pev(g_grabbed[id], pev_origin, origin);
	pev(id, pev_origin, origin2);
	distance = get_distance_f(origin, origin2);

	// Vzdialenost
	if( distance > turbo_maxdistance ) {
		g_grabbed[id] = 0;
		return HAM_IGNORED;
	} else if( distance > turbo_distancetograb ) {
		static Float:fl_Time;
		fl_Time = distance / turbo_speedgrab;

		velocity[0] = (origin[0] - origin2[0]) / fl_Time;
		velocity[1] = (origin[1] - origin2[1]) / fl_Time;
		velocity[2] = (origin[2] - origin2[2]) / fl_Time;
	} else {
		velocity[0] = velocity[1] = velocity[2] = 0.0; 
	}
	set_pev(id, pev_velocity, velocity);
	return HAM_IGNORED;
}
stock InActionThink(const id) {
	static Float:velocity[3], Float:speed;	
	// Dotkol sa niecoho
	pev(id, pev_velocity, velocity);
	speed = vector_length(velocity)
	if(speed < turbo_stopspeed) {
		EndOfAction(id);
		return HAM_IGNORED;
	}
	
	// Vlastnosti 
	set_pev(id, pev_maxspeed, turbo_speed)
	UTIL_set_speed(id, turbo_speed, g_angle[id])
	return HAM_IGNORED;
}
stock StartAction(const id) {	
	debug("StartAction")
	g_inaction[id] = true;
	g_casovac[id] = turbo_maxtime;
	pev(id, pev_v_angle, g_angle[id]);
	UTIL_set_speed(id, turbo_speed, g_angle[id]) // bug fix
		
	// Efekty ..
	UTIL_setcamera(id, CAMERA_3RDPERSON);	
	PlaySound(id, sounds_startaction)
	//UTIL_triast_obrazovku(id, 3.0, 3.0, 1.0)
	return HAM_IGNORED;
}
stock EndOfAction(const id) {
	// Charger
	debug("EndOfAction")	
	g_inaction[id] = false;
	set_pev(id, pev_maxspeed, float(class_speed))
	set_pev(id, pev_gravity, class_gravity)
	UTIL_setcamera(id, CAMERA_NONE);
	
	// Knockback
	static Float:vec[3]
	pev(id, pev_velocity, vec);	
	vec[0] *= -1.0; vec[1] *= -1.0; vec[2] *= -1.0;	
	set_pev(id, pev_velocity, vec);
	
	// Obete
	for(new i=1; i <= maxplayers; i++) {
		if(i == id || g_grabbed[i] != id) continue;
		if(!is_user_alive(i) || zp_get_user_zombie(i)) {
			g_grabbed[i] = 0;
			continue;
		}
		// Zabit ho...
		UTIL_set_score(id, i, 1, 1, "charger");
		g_grabbed[i] = 0;
	}
	
	// Efekty na koniec
	UTIL_triast_obrazovku(id, 5.0, 5.0, 3.0)
	PlaySound(id, sounds_hitwall)
}
public PublicSecTimer() {
	for(new id=1; id <= maxplayers; id++) {
		if(!g_inaction[id]) continue;
		g_casovac[id]--;
		if(!g_casovac[id]) EndOfAction(id);
	}
}
public zp_user_infected_post(id, infector)  {		
	if(zp_is_special_round()) return PLUGIN_CONTINUE;
	g_grabbed[id] = 0;
	
	if (zp_get_user_zombie_class(id) == class_charger) {
		PlaySound(id, sounds_idle)
		set_task(3.0, "PlayIdleSounds", id)		
		client_print(id, print_chat,"[CHARGER] Charger utok pouzijes s R, snaz sa zachytit co najviac ludi.")
	}
	return PLUGIN_CONTINUE;
}
public PlayIdleSounds(id) {
	if(!is_user_alive(id) || !zp_get_user_zombie(id)) return PLUGIN_CONTINUE;
	if(zp_get_user_zombie_class(id) != class_charger) return PLUGIN_CONTINUE;
	
	PlaySound(id, sounds_idle)
	set_task(float(random_num(4, 11)), "PlayIdleSounds", id)
	return PLUGIN_CONTINUE;
}
public fw_TouchPlayer(charger, id) {
	if(!is_user_valid(charger) || !is_user_valid(id)) return HAM_IGNORED;
	if(!g_inaction[charger]) return HAM_IGNORED;
	if(g_grabbed[id]) return HAM_IGNORED;	
	if(!is_user_alive(id)) return HAM_IGNORED;
	if(zp_get_user_zombie(id)) return HAM_IGNORED;
	return ChargerTakePlayer(charger, id);
}
stock ChargerTakePlayer(const charger, const id) {
	// Zachytil hraca
	debug("Zachytil hraca")
	PlaySound(id, sounds_take)
	// UTIL_set_speed(id, turbo_speed, g_angle[id]) // bug fix
	set_pev(id, pev_movetype, MOVETYPE_NONE);
	set_pev(id, pev_solid, SOLID_NOT);
	set_pev(id, pev_sequence, 110)
	set_pev(id, pev_gaitsequence, 110)
	set_pev(id, pev_framerate, 1.0)
	g_grabbed[id] = charger;
	return HAM_SUPERCEDE;
}
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Filtrujeme
	if (victim == attacker) return HAM_IGNORED;	
	if (!is_user_valid_alive(attacker) || !is_user_valid_alive(victim))
		return HAM_IGNORED;		
	if(!zp_get_user_zombie(attacker) || zp_get_user_zombie(victim))
		return HAM_IGNORED;	
	if(zp_get_user_nemesis(attacker)) 
		return HAM_IGNORED	
	if(zp_get_user_zombie_class(attacker) != class_charger) 
		return HAM_IGNORED
		
	// ChargerMeleAttack	
	if (inflictor == attacker) {
		SetHamParamFloat(4, damage * charger_damagemultiplier);
	}	
	return HAM_IGNORED;
}
/*
stock ChargerThrowPlayer(const charger, const id) {
	// Najst origin hrac
	debug("ChargerThrowPlayer")
	static Float:SrcOfExplode[3], Float:origin[3]
	PlaySound(id, sounds_throw)
	pev(charger, pev_origin, SrcOfExplode);
	pev(id, pev_origin, origin);
	
	// Potom spravit dolny koncovy bod
	UTIL_DolnyKoncovyBod(charger, SrcOfExplode, SrcOfExplode, 300.0);
	UTIL_ExplodeThrow(origin, SrcOfExplode, 10.0, origin);
	set_pev(id, pev_velocity, origin);
	return HAM_SUPERCEDE;
}	
stock UTIL_ExplodeThrow(	const Float:origin[3], 
							const Float:SrcOfExplode[3], 
							const Float:multi = 1.0,
							Float:velocity[3]
) {
	static Float:vec[3], Float:distance
	// Spravit vektor medzi tym bodom a obetom
	distance = get_distance_f(origin, vec);
	xs_vec_sub(origin, SrcOfExplode, vec)
	
	// Vynasobit tento vektor o constantu a vzdialenost
	// - Cim blizsie tym dalej
	distance = 1.0 / distance;
	xs_vec_mul_scalar(vec, distance * multi, velocity)
	// - Mozme aj tak nastavit vlastne..
}
*/