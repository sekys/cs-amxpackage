/*================================================================================
 * Please don't change plugin register information.
================================================================================*/
#include <amxmodx>
#include <fakemeta>
#include <zombieplague>
#include <amxmisc>
#include <hamsandwich>

#define PLUGIN_NAME "BoOmer"
#define PLUGIN_VERSION "1.2"
#define PLUGIN_AUTHOR "Seky"
#define MAX_DAMAGE 280


// Self Explosion Zombie Attributes
new const zclass_name[] = { "Boomer" }
new const zclass_info[] = { "Vybuchne a nakazi" }
new const zclass_model[] = { "Tirant_Boomer_Frk_14" }
new const zclass_clawmodel[] = { "boomer_hand.mdl" }
const zclass_health = 300
const zclass_speed = 180
const Float:zclass_gravity = 1.0
const Float:zclass_knockback = 0.5

new const sound_player_die[] = {"zombie_plague/boomer2.wav" }
new g_exploSpr_1, g_exploSpr_2, g_msgScoreInfo, g_zclass_explo, 
	g_explo_range, g_msgDeathMsg, bool:mozem, max_hracov, g_msgScoreAttrib

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	g_explo_range = register_cvar("zp_explo_range", "200.0")
	max_hracov = get_maxplayers()
	//register_event("DeathMsg", "smrt", "a") 	Sposobuje BUG
	RegisterHam(Ham_Player_PreThink, "player", "cheese_player_prethink", 1)
	g_msgScoreAttrib = get_user_msgid("ScoreAttrib")
	g_msgDeathMsg 	= get_user_msgid("DeathMsg");
	g_msgScoreInfo = get_user_msgid("ScoreInfo")
}
public plugin_precache()
{
	engfunc(EngFunc_PrecacheSound, sound_player_die)
	g_exploSpr_1 = engfunc(EngFunc_PrecacheModel, "sprites/fexplo1.spr")
	g_exploSpr_2 = engfunc(EngFunc_PrecacheModel, "sprites/explode1.spr")
	 
	g_zclass_explo = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
}
public zp_round_started(gamemode, player)
{
	mozem = (gamemode == MODE_INFECTION) ? true :false;
}
public cheese_player_prethink(id) 
{
	// Schopnost
	if(pev(id, pev_button ) & IN_RELOAD && !(pev(id, pev_oldbuttons ) & IN_RELOAD ))
	{
		if(!is_user_alive(id) || !zp_get_user_zombie(id)) return PLUGIN_CONTINUE
		if(zp_is_survivor_round() || zp_is_nemesis_round() || zp_is_plague_round()) return PLUGIN_CONTINUE
		if(zp_get_user_zombie_class(id) != g_zclass_explo) return PLUGIN_CONTINUE
		
		explo_process(id)
		fm_set_user_health(id, -1)
	}
}	
stock explo_process(id)
{
	new Float:origin1[3], Float:origin2[3], Float:i_range, Float:range
	new damage, armor, kills, frags, deaths
	
	pev(id, pev_origin, origin1); 	
	create_sprite(origin1, g_exploSpr_1)
	create_sprite(origin1, g_exploSpr_2)
	create_explo2(origin1)
	emit_sound(id,CHAN_AUTO, sound_player_die, 1.0, ATTN_NORM, 0, PITCH_NORM)
		 	
	kills = 0
	range = get_pcvar_float(g_explo_range)
	
	for (new i = 1; i <= max_hracov; i++)
	{
		if (!is_user_connected(i))
			continue;		
		if (!is_user_alive(i))
			continue;
		
		if ( i != id) {
			if ( !zp_get_user_zombie(i) ) {
		
				pev(i, pev_origin, origin2);
				i_range = get_distance_f(origin1, origin2);
				
				if (i_range <= range)
				{				   
					damage = MAX_DAMAGE - floatround( MAX_DAMAGE * (i_range / range) )		// damage - damage * pomer			
					/*armor = floatround( pev(i, pev_armorvalue) );
					// set_pev(index, pev_armorvalue, float(armor));
					if (armor > 0)
					{
						if (armor > damage)
						{
							set_pev(i, pev_armorvalue, float( armor - damage ));
							damage = 0
						}
						else
						{
							set_pev(i, pev_armorvalue, 0.0);
							damage = armor - damage
						}
					}*/
					
					if(damage > 0)
					{
						if ( !zp_get_user_last_human(i) )	// !zp_get_user_last_human(i) vracalo somariny a bolo bugnute kontrola_poctu()
						{
							kills++
							zp_infect_user(i, id)
							
							/*message_begin(MSG_ALL, g_msgDeathMsg, {0, 0, 0} ,0)
							write_byte(id)
							write_byte(i)
							write_byte(0)
							write_string("Boomer")
							message_end()*/
							
							deaths = get_user_deaths(i) + 1
							fm_set_user_deaths(i, deaths)
							Update_ScoreInfo(i, get_user_frags(i), deaths)
						}	
					}
				
				}
			}
		}
	}
 
	zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + kills)
	frags = get_user_frags(id) + kills
	fm_set_user_frags(id, frags)
	Update_ScoreInfo(id, frags, get_user_deaths(id) )
}/*
stock kontrola_poctu()
{
	new pocet
	for(new hrac = 1; hrac <= max_hracov; hrac++)
	{
		if (!is_user_connected(hrac))
			continue;		
		if (!is_user_alive(hrac))
			continue;
			
		if( !zp_get_user_zombie(hrac) )
		{
			pocet++;
			if(pocet == 2)
				return true;
		}
	}
	return false;
}*/
stock fm_set_user_health(index, health)
{
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index);
	return 1;
}
stock fm_set_user_armor(index, armor)
{
	set_pev(index, pev_armorvalue, float(armor));
	return 1;
}
stock fm_set_user_frags(index, frags)
{
	set_pev(index, pev_frags, float(frags));
	return 1;
}
stock fm_set_user_deaths(index, deaths) // Set User Deaths
{
	set_pdata_int(index, 444, deaths, 5)
}
create_sprite(const Float:originF[3], sprite_index)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPRITE) // TE id (Additive sprite, plays 1 cycle)
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	write_short(sprite_index) // sprite index
	write_byte(10) // scale in 0.1's
	write_byte(200) // brightness
	message_end()
}
create_explo2(const Float:originF[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION2) // TE id: 12
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	write_byte(1) // starting color
	write_byte(10) // num colors
	message_end()
}
Update_ScoreInfo(id, frags, deaths) // Update Player's Frags and Deaths
{
	// Update scoreboard with attacker's info
	message_begin(MSG_BROADCAST, g_msgScoreInfo)
	write_byte(id) // id
	write_short(frags) // frags
	write_short(deaths) // deaths
	write_short(0) // class?
	write_short(get_user_team(id)) // team
	message_end()
}
