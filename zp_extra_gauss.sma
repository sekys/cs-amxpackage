#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>

//////////////////////////////////////////////////////////////////////////////
// Customizations ////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

new const model_vgauss[] = "models/v_gauss.mdl" /* Weapon Model */

new const g_gauss_cost = 40 /* Item Cost */

//////////////////////////////////////////////////////////////////////////////
// Customizations Ends Here :D ///////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

#define is_valid_player(%1) (1 <= %1 <= g_maxplayers)

new g_gauss, g_maxplayers, big_explode, g_deathmsg
new bool:g_bHasGauss[33]
new cvar_enable, cvar_kill, cvar_remove_hltv, cvar_enable2, cvar_explode, cvar_particles, cvar_blood

public plugin_init()
{
	// Register the Plugin
	register_plugin("[ZP] Extra Item: Gauss", "0.4", "meTaLiCroSS")
	
	// Variables
	g_maxplayers = get_maxplayers()
	g_deathmsg = get_user_msgid("DeathMsg")
	g_gauss = zp_register_extra_item("Molekulator", g_gauss_cost, ZP_TEAM_HUMAN)
	
	// Cvars
	cvar_enable = register_cvar("zp_gauss_enable", "1")
	cvar_kill = register_cvar("zp_gauss_ap_for_kill", "2")
	cvar_remove_hltv = register_cvar("zp_gauss_roundstart_remove", "0")
	cvar_enable2 = register_cvar("zp_gauss_block_delay_buy", "1")
	
	// Special Efects Cvars
	cvar_explode = register_cvar("zp_gauss_explode", "1")
	cvar_blood = register_cvar("zp_gauss_bloodspurt", "1")
	cvar_particles = register_cvar("zp_gauss_particles", "1")
	
	// Events: HamSandwich
	RegisterHam(Ham_TakeDamage, "player", "fw_gauss_damage")
	RegisterHam(Ham_Killed, "player", "fw_player_killed")
	RegisterHam(Ham_Spawn, "player", "fw_player_spawn", 1)
	
	// Events: Normal HL1 Events
	register_event("CurWeapon", "gauss_model", "be", "1=1", "2=18")
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, model_vgauss)
	engfunc(EngFunc_PrecacheSound, "ambience/particle_suck2.wav")
	big_explode = engfunc(EngFunc_PrecacheModel, "sprites/fexplo.spr")
}
public plugin_natives()
{
	register_native("molekulator", "native_molekulator", 1)
}
public native_molekulator(id, bool:hodnota)
{
	g_bHasGauss[id] = hodnota;
}
public fw_player_spawn(id)
{
	if (g_bHasGauss[id] && get_pcvar_num(cvar_remove_hltv))
	{
		g_bHasGauss[id] = false
		fm_strip_user_gun(id, 18)
	}
}

public client_putinserver(id)
	g_bHasGauss[id] = false;

public client_disconnect(id)
	g_bHasGauss[id] = false;

public fw_player_killed(victim, attacker, shouldgib)
{
	if(g_bHasGauss[victim])
	{
		g_bHasGauss[victim] = false
	}
}

public fw_gauss_damage(victim, inflictor, attacker, Float:damage, damage_bits)
{	
	if(!zp_get_user_zombie(victim))
		return;
		
	if(!is_valid_player(attacker))
		return;
		
	new clip, ammo, wpnid = get_user_weapon(attacker, clip, ammo)
	
	if (g_bHasGauss[attacker] && wpnid == CSW_AWP)
	{
		new origin[3] 
		get_user_origin(victim, origin)
		
		// player fades.. 
		set_user_rendering(victim, kRenderFxFadeSlow, 255, 255, 255, kRenderTransColor, 4); 
		
		// beeeg explody!
		if(get_pcvar_num(cvar_explode))
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
			write_byte(TE_EXPLOSION)	
			write_coord(origin[0]) 
			write_coord(origin[1]) 
			write_coord(origin[2]+128) 
			write_short(big_explode)	// big explosion
			write_byte(40)			// scale in 0.1's
			write_byte(12)			// frame rate 
			write_byte(TE_EXPLFLAG_NONE)	
			message_end() 
		}

		// do turn down that awful racket..to be replaced by a blood spurt!
		if(get_pcvar_num(cvar_blood))
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
			write_byte(TE_LAVASPLASH)
			write_coord(origin[0]) 
			write_coord(origin[1]) 
			write_coord(origin[2]-26) 
			message_end()
		}
		
		// particle suck
		if(get_pcvar_num(cvar_particles))
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_IMPLOSION) 
			write_coord(origin[0]) 
			write_coord(origin[1]) 
			write_coord(origin[2]) 
			write_byte(200) 
			write_byte(40) 
			write_byte(45) 
			message_end()
			emit_sound(victim, CHAN_WEAPON, "ambience/particle_suck2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			emit_sound(victim, CHAN_VOICE, "ambience/particle_suck2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		}
		
		// Setting damage to 0 for some bugs
		SetHamParamFloat(4, 0.0);
		
		// kill victim
		user_silentkill(victim)
		
		message_begin(MSG_ALL, g_deathmsg,{0,0,0},0 )
		write_byte(attacker)
		write_byte(victim)
		write_byte(0)
		write_string("awp")
		message_end()
		
		// Save Hummiliation
		new namea[24],namev[24],authida[20],authidv[20],teama[8],teamv[8]
		
		// Info On Attacker
		get_user_name(attacker,namea,23) 
		get_user_team(attacker,teama,7) 
		get_user_authid(attacker,authida,19)
		new attackerid = get_user_userid(attacker)
		
		// Info On Victim
		get_user_name(victim,namev,23) 
		get_user_team(victim,teamv,7) 
		get_user_authid(victim,authidv,19)
		new victimid = get_user_userid(victim)
		
		// Log This Kill
		log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"Molekulator^"", namea, attackerid, authida, teama, namev, victimid, authidv, teamv)
		
		// for some reason this doesn't update in the hud until the next round.. whatever. 
		//if (zp_get_user_zombie(victim)) 
		//{ 
			new Float:frags;
			pev(attacker,pev_frags,frags);
			set_pev(attacker, pev_frags, 1.0 + frags)
	
			zp_set_user_ammo_packs(attacker, zp_get_user_ammo_packs(attacker) + get_pcvar_num(cvar_kill))
		//}
	} 
}
public zp_extra_item_selected(id, item)
{
	if (item == g_gauss)
	{
		if(get_pcvar_num(cvar_enable))
		{
			if(get_pcvar_num(cvar_enable2))
			{
				if (!zp_has_round_started())
				{
					client_print(id, print_chat, "[G/L ZP] Este nezacalo kolo.")
					//zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + g_gauss_cost)
					vrat_body(id, g_gauss_cost)
					return PLUGIN_HANDLED;
				}
			}
			if(g_bHasGauss[id])
			{
				client_print(id, print_chat, "[G/LZP] Uz mas Molekulator.")
				//zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + g_gauss_cost)
				vrat_body(id, g_gauss_cost)	
				return PLUGIN_HANDLED;
			}
			
			// Var's
			g_bHasGauss[id] = true
			
			// Gauss
			give_item(id, "weapon_awp")
			give_item(id, "ammo_338magnum")
			give_item(id, "ammo_338magnum")
			give_item(id, "ammo_338magnum")
			
			// Msgs
			client_print(id, print_chat, "[G/L ZP] Kupil si Molekulator.")
			
			// Setting Models
			put_models(id)
		}
		else
		{
			client_print(id, print_chat, "[G/L ZP] Molekulator je vypnuty.")
			//zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + g_gauss_cost)
			vrat_body(id, g_gauss_cost)
			return PLUGIN_HANDLED;
		}
	}
}

public gauss_model(id)
{	
	// Not alive
	if (!is_user_alive(id))
		return;
	
	if (!g_bHasGauss[id])
		return;
	
	new clip, ammo, wpnid = get_user_weapon(id, clip, ammo)
	
	if (wpnid == CSW_AWP && g_bHasGauss[id])
	{
		if(zp_is_survivor_round() || zp_is_nemesis_round())
		{
			g_bHasGauss[id] = false;
		} else {	
			set_pev(id, pev_viewmodel2, model_vgauss)
		}
	}
}

public zp_user_infected_post(id)
{
	if(g_bHasGauss[id])
	{
		g_bHasGauss[id] = false
	}
}

public put_models(id)
{
	if(!g_bHasGauss[id])
		return;
	
	if (get_user_weapon(id) == CSW_AWP)
	{
		gauss_model(id)
	}
	else
	{
		engclient_cmd(id, "weapon_awp")
		gauss_model(id)
	}
}
	
// Stock: fm_strip_user_gun (taked from fakemeta_util)
stock bool:fm_strip_user_gun(index, wid = 0, const wname[] = "") 
{
	new ent_class[32];
	if (!wid && wname[0])
		copy(ent_class, sizeof ent_class - 1, wname);
	else 
	{
		new weapon = wid, clip, ammo;
		if (!weapon && !(weapon = get_user_weapon(index, clip, ammo)))
			return false;
		
		get_weaponname(weapon, ent_class, sizeof ent_class - 1);
	}
	
	new ent_weap = fm_find_ent_by_owner(-1, ent_class, index);
	if (!ent_weap)
		return false;
	
	engclient_cmd(index, "drop", ent_class);
	
	new ent_box = pev(ent_weap, pev_owner);
	if (!ent_box || ent_box == index)
		return false;
	
	dllfunc(DLLFunc_Think, ent_box);
	
	return true;
}

// Stock: fm_find_ent_by_owner (taked from fakemeta_util)
stock fm_find_ent_by_owner(index, const classname[], owner, jghgtype = 0) 
{
	new strtype[11] = "classname", ent = index;
	switch (jghgtype) 
	{
		case 1: strtype = "target";
			case 2: strtype = "targetname";
		}
	
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, strtype, classname)) && pev(ent, pev_owner) != owner) {}
	
	return ent;
}
stock vrat_body(id, kolko)
{
	if(get_user_flags(id) & ADMIN_LEVEL_F ) {
		kolko = floatround( float(kolko) * 0.5 , floatround_floor );	
	}
	zp_set_user_ammo_packs(id, kolko)
}