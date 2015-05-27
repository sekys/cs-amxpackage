#include <amxmodx>
#include <zombieplague>
#include <fakemeta>
#include <hamsandwich>

#if cellbits == 32
const OFFSET_CLIPAMMO = 51
#else
const OFFSET_CLIPAMMO = 65
#endif
const OFFSET_LINUX_WEAPONS = 4

new const MAXCLIP[] = { -1, 13, -1, 10, 1, 7, -1, 30, 30, 1, 30, 20, 25, 30, 35, 25, 12, 20,
			10, 30, 100, 8, 30, 30, 20, 2, 7, 30, 30, -1, 50 }
			
new g_msgDeathMsg, g_msgScoreInfo, bool:kolo, populacia,
	min_populacia, max_populacia, g_has_unlimited_clip[33], g_maxplayers
new const sound[] = {"zombie_plague/mob_spawn.wav" }

public plugin_init()
{
	register_plugin("[ZP] Nemrtvy kolo", "1.0", "Seky")			
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	
	min_populacia = register_cvar("zp_mob_min", "70")
	max_populacia = register_cvar("zp_mob_max", "150")
	g_maxplayers = get_maxplayers()
	
	g_msgDeathMsg 	= get_user_msgid("DeathMsg");
	g_msgScoreInfo = get_user_msgid("ScoreInfo")
	register_message(get_user_msgid("CurWeapon"), "message_cur_weapon")
}
public plugin_precache()
{
	precache_sound(sound)
}	
public plugin_natives()
{
	register_native("get_populacia", "native_get_populacia", 1)
}	
public native_get_populacia()
{
	return populacia >= 0 ? populacia : 0;
}
public zp_round_started(gamemode, id) 
{	
	if(gamemode == MODE_MOB)	{ 
		kolo = true
		// Ak pocas kola sa odpoji ....
		if(!populacia)	{
			populacia = random_num( get_pcvar_num(min_populacia), get_pcvar_num(max_populacia))
		}

		for (id = 1; id <= g_maxplayers; id++)
		{
			if (!is_user_connected(id))
				continue;
			if (zp_get_user_zombie(id))	
				continue;
				
			g_has_unlimited_clip[id] = true;
		}		
	}
}
public zp_round_ended(winteam)
{
	kolo = false;
	populacia=0;
	for (new id; id <= 32; id++) g_has_unlimited_clip[id] = false;
}
public zp_user_infected_pre(id, infector)
{		
	if(kolo)	{
		if(populacia) {
			populacia--;
		}	
	}
}
public fw_PlayerKilled(id, attacker, shouldgib)
{
	if(!kolo || !zp_get_user_zombie(id) || zp_get_user_last_zombie(id) || populacia < 1) {
		return PLUGIN_CONTINUE
	}		
	// never set higher then 1.9 or lower then 0.5
	set_task(1.0, "zm_respawn", id)
}
public zm_respawn(id)
{
	if ( is_user_alive(id) || !kolo) return
	// Misc
	zp_respawn_user(id, ZP_TEAM_ZOMBIE)
	populacia--;
	// Effect
	emit_sound(id, CHAN_AUTO, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	new temp = get_user_deaths(id) - 1
	fm_set_user_deaths(id, temp)
	Update_ScoreInfo(id,  get_user_frags(id), temp)
}
stock fm_set_user_deaths(index, deaths) // Set User Deaths
{
	set_pdata_int(index, 444, deaths, 5)
}
stock Update_ScoreInfo(id, frags, deaths) // Update Player's Frags and Deaths
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
public message_cur_weapon(msg_id, msg_dest, msg_entity)
{
	// Player doesn't have the unlimited clip upgrade
	if (!g_has_unlimited_clip[msg_entity])
		return;
	
	// Player not alive or not an active weapon
	if (!is_user_alive(msg_entity) || get_msg_arg_int(1) != 1)
		return;
	
	static weapon, clip
	weapon = get_msg_arg_int(2) // get weapon ID
	clip = get_msg_arg_int(3) // get weapon clip
	
	// Unlimited Clip Ammo
	if (MAXCLIP[weapon] > 2) // skip grenades
	{
		set_msg_arg_int(3, get_msg_argtype(3), MAXCLIP[weapon]) // HUD should show full clip all the time
		
		if (clip < 2) // refill when clip is nearly empty
		{
			// Get the weapon entity
			static wname[32], weapon_ent
			get_weaponname(weapon, wname, sizeof wname - 1)
			weapon_ent = fm_find_ent_by_owner(-1, wname, msg_entity)
			
			// Set max clip on weapon
			fm_set_weapon_ammo(weapon_ent, MAXCLIP[weapon])
		}
	}
}
stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && pev(entity, pev_owner) != owner) {}
	
	return entity;
}
stock fm_set_weapon_ammo(entity, amount)
{
	set_pdata_int(entity, OFFSET_CLIPAMMO, amount, OFFSET_LINUX_WEAPONS);
}