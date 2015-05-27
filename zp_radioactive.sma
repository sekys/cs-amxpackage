/*
* radioaktivny zombie
* chodi a casovo cez ticrate
* postupne dookola ludom ubera
*/
#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <zombieplague>
#include <engine>
#include <cstrike>

#define PLUGIN  		"[ZP] Radioaktivny zombie"
#define VERSION 		"1.0"
#define AUTHOR  		"Seky"
#define TASK_TICRATE 	1.0
#define TASK			155	

new const zclass_name[] = 	{ "Radioaktivny" } // name
new const zclass_info[] = 	{ "Vyhana ludi z kempu" } // description
new const zclass_model[] = { "gl_radioactive" } // model
new const zclass_clawmodel[] = { "gl_radioactive.mdl" } // claw model
const zclass_health = 500 // health
const zclass_speed = 250 // speed
const Float:zclass_gravity = 0.6 // gravity
const Float:zclass_knockback = 2.0 // knockback

new g_zclass, cvar_radius, cvar_hp, g_maxplayers, 
	g_msgDeathMsg, g_msgScoreInfo

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	cvar_radius = register_cvar("zp_radioactive_radius", "200.0")
	cvar_hp = register_cvar("zp_radioactive_hp", "2.0")
	g_maxplayers = get_maxplayers()	
	g_msgDeathMsg = get_user_msgid("DeathMsg");
	g_msgScoreInfo = get_user_msgid("ScoreInfo");
}
public plugin_precache() { 
	g_zclass = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
}
public VerejnyCasovac() 
{
	static 	id, Float:Radius, Float:hp,
			Float:temp[3], i, Float:postava[3]
	Radius = get_pcvar_float(cvar_radius)
	hp = get_pcvar_float(cvar_hp);
		
	for(id=1; id <= g_maxplayers; id++) {
		if(!is_user_alive(id) || !zp_get_user_zombie(id)) continue;
		if(zp_get_user_zombie_class(id) != g_zclass) continue;
		
		// Radioaktivita - Hladame blizko hracov ...
		pev(id, pev_origin, temp);
		for(i=1; i <= g_maxplayers; i++) {
			if (is_user_alive(i) && !zp_get_user_zombie(i)) {
				pev(i, pev_origin, postava);
				if ( get_distance_f(temp, postava) < Radius) {
					pev(i, pev_health, postava[0]);					
						// Zvladne to  ?
						if(postava[0] <= hp) {
							set_score(id, i, 1)
						} else {				
							fakedamage(i, "radioaktivita", hp, 262144);
						}
				}
			}
		}
	}
	return PLUGIN_CONTINUE;
}
public zp_round_started(gamemode, id)  {	
	if(zp_is_survivor_round() || zp_is_nemesis_round()) return PLUGIN_CONTINUE;	
	set_task(TASK_TICRATE, "VerejnyCasovac", TASK, _, _, "b")
	return PLUGIN_CONTINUE;
}
public zp_round_ended(winteam) {
	if(task_exists(TASK)) remove_task(TASK);
}
stock set_score(const id, const target, const hitscore)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;	
	static Float:frags;
	pev(id, pev_frags, frags);
	frags += float(hitscore);	
	zp_add_user_ammo_packs(id, hitscore);
	set_pev(id, pev_frags, frags)
	
	message_begin(MSG_ALL, g_msgDeathMsg, {0, 0, 0} ,0)
	write_byte(id)
	write_byte(target)
	write_byte(0)
	write_string("radioaktivita")
	message_end()

	message_begin(MSG_ALL, g_msgScoreInfo)
	write_byte(id)
	write_short(floatround(frags))
	write_short(cs_get_user_deaths(id))
	write_short(0)
	write_short( int:cs_get_user_team(id) )
	message_end()

	set_msg_block(g_msgDeathMsg, BLOCK_ONCE)
	dllfunc(DLLFunc_ClientKill, target)
	return PLUGIN_CONTINUE;	
}