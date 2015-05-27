#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_util>
#include <zombieplague>
#include <hamsandwich>
#include <Vexd_Utilities>
#include <cstrike>
#include <zombie_basic>
#include <xs>

#define PLUGIN  	"[ZP] L4D2 The Jockey"
#define VERSION 	"1.0"
#define AUTHOR  	"Seky"

#define debug(%1)				client_print(0, print_chat, "DEBUG - %s", %1)
#define is_user_valid_alive(%1) (1 <= %1 <= maxplayers && is_user_alive(%1))
#define is_user_valid(%1) 		(1 <= %1 <= maxplayers)

#define S_NOTALLOWED		-1
#define S_SEARCHING			0

// Info
new const sounds_startaction[][] = { 
	"zombie_plague/l4d2/jockey/jockey_attackloop01.wav", 
	"zombie_plague/l4d2/jockey/jockey_attackloop02.wav", 
	"zombie_plague/l4d2/jockey/jockey_attackloop03.wav", 
	"zombie_plague/l4d2/jockey/jockey_attackloop04.wav" 
}
new const sounds_control[][] = { 
	"zombie_plague/l4d2/jockey/jockey_lurk01.wav", 
	"zombie_plague/l4d2/jockey/jockey_lurk03.wav", 
	"zombie_plague/l4d2/jockey/jockey_lurk04.wav", 
	"zombie_plague/l4d2/jockey/jockey_lurk05.wav", 
	"zombie_plague/l4d2/jockey/jockey_lurk06.wav", 
	"zombie_plague/l4d2/jockey/jockey_lurk07.wav", 
	"zombie_plague/l4d2/jockey/jockey_lurk08.wav", 
	"zombie_plague/l4d2/jockey/jockey_lurk09.wav", 
	"zombie_plague/l4d2/jockey/jockey_lurk11.wav" 
}
new const sounds_idle[][] = { 
	"zombie_plague/l4d2/jockey/jockey_06.wav", 
	"zombie_plague/l4d2/jockey/jockey_08.wav" 
}
new const models[] = { "l4d2_charger" }
new const models_hand[] = { "l4d2_charger.mdl" }

// Vlastnosti
new const class_name[] = { "L4D2 Jockey" }
new const class_info[] = { "ovladaca hraca" }
const class_health = 700
const Float:class_speed = 300.0
const Float:class_gravity = 0.5
const Float:class_knockback = 0.5

// Jump vlastnosti
const boneofhead = 6;
const maxschopnost = 200;
const Float:control_speed = 250.0;
const Float:jockey_DamageWhenControl = 0.0;
//const Float:jump_height = 255.0;
//const Float:jump_radius = 400.0;
const Float:headfix = 64.0;

new class_charger, maxplayers, g_control[33], g_schopnost[33],
	g_jeobsadeny[33], g_search[33]

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	RegisterHam(Ham_Player_PreThink, "player", "fw_PlayerPreThink")
	register_logevent("fw_RoundStart", 2, "0=World triggered", "1=Round_Start" )
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled", 1)
	RegisterHam(Ham_Touch, "player", "fw_TouchPlayer", 1)	
	RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "armoury_entity", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "weapon_shield", "fw_TouchWeapon")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	maxplayers = get_maxplayers();
}
stock Unset(const id) {
	static Float:vec[3]
	pev(id, pev_velocity, vec)
	vec[2] += boneofhead;
	set_pev(id, pev_velocity, vec)
}
stock SetDefault(const id) {
	debug("SetDefault");
	if(g_control[id]) {
		g_jeobsadeny[ g_control[id] ] = 0;
		if(is_user_alive(g_control[id])) {
			set_pev(g_control[id], pev_movetype, MOVETYPE_WALK);
			fm_give_item(g_control[id], "weapon_knife")
			Unset(id);
		}
		g_control[id] = 0;
	}
	if(g_jeobsadeny[id]) {	
		g_control[ g_jeobsadeny[id] ] = 0;
		if(is_user_alive(g_jeobsadeny[id])) {
			Unset(g_jeobsadeny[id]);
			set_pev(g_jeobsadeny[id], pev_solid, SOLID_BBOX);
			set_task(2.5, "SetBackCamera", g_jeobsadeny[id])					
		}
		g_jeobsadeny[id] = 0;		
	}
	g_search[id] = 0;
}
public fw_PlayerKilled(id, attacker, shouldgib) { 
	SetDefault(id);
	return HAM_IGNORED;
}
public zp_user_humanized_post(id, survivor) {
	SetDefault(id);
	return PLUGIN_CONTINUE;
}
public plugin_precache(){
	class_charger = zp_register_zombie_class(class_name, class_info, models, models_hand, class_health, floatround(class_speed), class_gravity, class_knockback)
	
	new i
	for(i=0; i < sizeof sounds_startaction; i++)
		engfunc(EngFunc_PrecacheSound, sounds_startaction[i])	
	for(i=0;i < sizeof sounds_control;i++)
		engfunc(EngFunc_PrecacheSound ,sounds_control[i]);	
	for(i=0;i < sizeof sounds_idle;i++)
		engfunc(EngFunc_PrecacheSound, sounds_idle[i]);	
}
public fw_RoundStart() {
	for(new i = 1; i <= maxplayers; i++) {
		g_schopnost[i] = maxschopnost;
	}
}
public client_disconnect(id) { 
	SetDefault(id);
}
public zp_round_ended(winteam) {
	for(new id = 1; id <= maxplayers; id++) {	
		SetDefault(id);
	}
}
public fw_PlayerPreThink(id) {	
	// Think
	if(zp_is_special_round()) return HAM_IGNORED;
	if(!is_user_alive(id) || !zp_get_user_zombie(id)) return HAM_IGNORED;
	if(zp_get_user_zombie_class(id) != class_charger) return HAM_IGNORED
	
	// Schopnost
	if(pev(id, pev_button ) & IN_RELOAD && !(pev(id, pev_oldbuttons ) & IN_RELOAD )) {
		CheckAction(id);
	}	
	// Ovlada niekoho...
	static obet; obet = g_control[id];
	if(obet) return InActionThink(id, obet);
	/// Skace naniekoho
	/// obet = g_search[id];
	/// if(obet) JockeyJump(id, obet);
	return HAM_IGNORED;
}
stock CheckAction(const id) {
	// Vypnut ovladanie..
	if(g_control[id]) {
		debug("Vypnute ovladanie")
		SetDefault(id);
		return;
	}
	// Akcia
	if(g_schopnost[id]) {
		/// SearchAction(id)
		g_search[id] = 1;
	} else {
		client_print(id, print_chat, "[JOCKEY] Uz viac nemozes pouzit schopnost !")
	}
}
stock InActionThink(const id, const obet) {	
	// Este kontrolujeme druheho hraca
	if(!g_jeobsadeny[obet]) {
		SetDefault(id);
		return HAM_IGNORED;
	}
	// Nastavyme vlastnosti
	static Float:vec[3], Float:angle[3]
	client_cmd(id, "+duck");
	set_pev(id, pev_solid, SOLID_NOT);

	// Ma byt natoceny podla obete, je to zujimavejsie..
	pev(id, pev_angles, angle) // pev_v_angle pev_angles
	//set_pev(obet, pev_v_angle, angle)
	//set_pev(obet, pev_fixangle, 1)
	UTIL_set_speed(obet, control_speed, angle)

	// Constantnu poziciu na hlave
	engfunc(EngFunc_GetBonePosition, obet, boneofhead, vec, angle)
	vec[2] += headfix;
	set_pev(id, pev_origin, vec)
	return HAM_IGNORED;
}
public SetBackCamera(const id) {
	UTIL_setcamera(id, CAMERA_NONE);
}
public zp_user_infected_post(id, infector)  {
	SetDefault(id);
	if (zp_get_user_zombie_class(id) == class_charger) {
		if(zp_is_special_round()) return PLUGIN_CONTINUE;
		PlaySound(id, sounds_idle)	
		set_task(3.0, "PlayIdleSounds", id)		
		client_print(id, print_chat,"[JOCKEY] Najdi si obet, pribliz sa k nej a stlac R :)")
	}
	return PLUGIN_CONTINUE;
}
public PlayIdleSounds(id) {
	if(!is_user_alive(id) || !zp_get_user_zombie(id)) return PLUGIN_CONTINUE;
	if(zp_get_user_zombie_class(id) != class_charger) return PLUGIN_CONTINUE;	
	if(g_control[id]) {
		PlaySound(id, sounds_idle)
	} else {
		PlaySound(id, sounds_control)
	}
	set_task(float(random_num(4, 11)), "PlayIdleSounds", id)
	return PLUGIN_CONTINUE;
}
public fw_TouchPlayer(jockey, id) {
	// Prefiltrujeme
	if(!is_user_valid(jockey) || !is_user_valid(id)) return HAM_IGNORED;
	if(g_control[jockey] || !g_search[jockey] || g_jeobsadeny[id]) return HAM_IGNORED;
	if(!is_user_alive(id) || zp_get_user_zombie(id)) return HAM_IGNORED;
		
	// Schopnost
	StartAction(jockey, id);
	g_search[jockey] = 0;
	g_schopnost[jockey]--;
	return HAM_SUPERCEDE;
}
public fw_TakeDamage(jockey, inflictor, id, Float:damage, damage_type)
{
	// Filtrujeme
	if(jockey == id) return HAM_IGNORED;	
	if(!is_user_valid(id) || !is_user_valid(jockey)) return HAM_IGNORED;		
	if(!g_control[jockey]) return HAM_IGNORED;	
	if(g_control[jockey] == id) {
		// Blokujeme damage od hraca/obete do jorkeyho/majitela
		debug("dmg to jockey")
		SetHamParamFloat(4, damage * jockey_DamageWhenControl);
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED;
}	
stock StartAction(const id, const obet) {	
	// Efekt
	debug("StartAction")
	PlaySound(id, sounds_startaction)
	UTIL_setcamera(id, CAMERA_3RDPERSON);	
	g_control[id] = obet;
	g_jeobsadeny[obet] = id;
	g_schopnost[id]--;
	
	// Vlastnosti
	fm_strip_user_weapons(obet)
	set_pev(id, pev_solid, SOLID_NOT);
	set_pev(obet, pev_movetype, MOVETYPE_NONE);
}
public fw_TouchWeapon(weapon, id) {
	if(!is_user_valid_alive(id)) return HAM_IGNORED;
	if(g_jeobsadeny[id]) return HAM_SUPERCEDE;
	return HAM_IGNORED;
}
/*
stock SearchAction(const id) {
	// Vypiname hladanie
	if(g_search[id]) {
		debug("Vypnut hladanie")
		g_search[id] = 0;
		return;	
	}

	// Hladame hraca
	static obet; 
	obet = Jockey_NajblizsiHrac(id);
	if(!obet) {
		debug("Hladanie fail")
		return;
	}
	debug("Hladanie do")
	g_search[id] = obet;	
}
stock Jockey_NajblizsiHrac(const hrac) {
	static 	id, Float:vektor[3], Float:origin[3], 
			Float:distance, Float:min_distance, min_id;
	
	pev(hrac, pev_origin, origin);
	min_distance = 10000.0, 
	min_id = 0;	
	for(id = 1; id <= maxplayers; id++) {		
		if(!is_user_alive(id) || zp_get_user_zombie(id)) continue;
		if(g_jeobsadeny[id]) continue;
		
		// Hladame najblizsieho ....
		pev(id, pev_origin, vektor);
		distance = get_distance_f(origin, vektor);		
		if( distance < jump_radius) {
			if( distance < min_distance) {
				min_id = id;
				min_distance = distance;
			}
		}
	}
	return min_id;
}
stock JockeyJump(const jockey, const id) {
	// Ak uz skace...
	//if(pev(ent,pev_flags) & FL_IN_JUMP) return;
	set_pev(jockey, pev_solid, SOLID_NOT);
	
	// Pohlad
	static Float:vec[3], Float:origin[3]
	engfunc(EngFunc_GetBonePosition, id, boneofhead, vec, origin)
	pev(jockey, pev_origin, origin);
	vec[2] += 100.0;
	entity_set_aim(jockey, vec)
		
	// Mame 2 body -> treba uhol
	velocity_by_aim(id, get_distance_f(vec, origin), vec);
	vec[2] += jump_height;
	static Float:fl_Time;
	fl_Time = vector_length(Vel) / 50.0;
	get_distance_f(origin, origin2);
	set_pev(id, pev_velocity, vec);	
}

stock aim_at_origin(id,Float:target[3],Float:angles[3],Tower)
{
	static Float:vec[3]
	pev(id,pev_origin,vec)
	vec[0] = target[0] - vec[0]
	vec[1] = target[1] - vec[1]
	vec[2] = target[2] - vec[2]
	engfunc(EngFunc_VecToAngles,vec,angles)
	angles[0] *= -1.0
	angles[2] = 0.0
	if(Tower)angles[1] -= 180
	
}
*/




/*
hrac na hlave spusti animaciu
ppre zombikov dat menej ovela menej zelenejsie nocne
na ZP plague je moznost ako blokovat CMD, mozno lepsia volba...

risenie na chargera aj jockeyho, blokovanie TLACIDIEL
+virtualne ich volanie:
cahrger len do predu
a jockey prenasa na hraca...
*/
/*
public Forward_CmdStart( id, uc_handle, seed )
{
    static Buttons ; Buttons = get_uc( uc_handle, UC_Buttons );
    
    if( ( Buttons & IN_ATTACK2 ) && get_user_weapon( id ) == CSW_KNIFE )
    {
        set_uc( uc_handle, UC_Buttons, Button & ~IN_ATTACK2 )
    }
}  
public CmdStart(Cl, Handle)
{
        if (!g_WarmUp) return FMRES_IGNORED;
 
        static Buttons;
        Buttons = get_uc(Handle, UC_Buttons);
 
        if (Buttons & IN_ATTACK) Buttons &= ~IN_ATTACK;
        if (Buttons & IN_ATTACK2) Buttons |= ~IN_ATTACK2;
 
        set_uc(Handle, UC_Buttons, Buttons);
 
        return FMRES_SUPERCEDE;
}
#define Distance2D(%1,%2) floatsqroot((%1*%1) + (%2*%2))
#define Radian2Degree(%1) (%1 * 180.0 / M_PI)			//(%1 * 360.0 / (2 * M_PI))

set_weaponslot(1,{ 24,25,34,35,0 })
set_weaponslot(slot,weapons[]) {
	slot--
	new len = strlen(weapons)
	for(new i = 0; i < len; i++) weapon_slots[slot][i] = weapons[i]
}*/