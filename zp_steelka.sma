#include <amxmodx>
#include <fakemeta>
#include <zombieplague>
#include <engine>

new const sound_fire[] = "zombie_plague/steelka_fire.wav";
new const sound_fire2[] = "zombie_plague/steelka_fire2.wav";
new const sound_idle[] = "zombie_plague/steelka_idle.wav";
new const sound_start[] = "zombie_plague/steelka_start.wav";
new const sound_start_fail[] = "zombie_plague/steelka_start_fail.wav";

new const v_model[] = "models/zombie_plague/v_steelka.mdl";
new const p_model[] = "models/zombie_plague/p_steelka.mdl";
new const w_model[] = "models/zombie_plague/w_steelka.mdl";

new const v_model_stare[] = "models/zombie_plague/gecom_leg.mdl";
new const p_model_stare[] = "models/p_knife.mdl";

new bool:g_ma_pilu[33], bool:g_ma_aktivovanu[33],  g_striela_typ[33], g_zaseknuty[33],
	g_item, g_cena, g_ammo, g_frags, g_damage, g_xplode_dmg, g_distance, g_zasekne, 
	g_vyleti, g_msgScoreInfo, g_zasekne_kolko, g_zasekne_pretazenie, g_prehriata[33],
	g_damage2, g_distance2

public plugin_init()
{
	register_plugin("[ZP] Motorova piiila xD", "1.0", "Seky")
	// nastavenia	
	g_cena = register_cvar("zp_steelka_cena", 				  				"16")
	
	g_damage = register_cvar("zp_steelka_damage", 			   				"90")	// damage	
	g_damage2 = register_cvar("zp_steelka_damage2", 			   			"270")	// damage	
	g_distance2 = register_cvar("zp_steelka_distance2",		   				"48")	// vzdialenost
	g_distance = register_cvar("zp_steelka_distance",		   				"64")	// vzdialenost
	
	g_zasekne = register_cvar("zp_steelka_zasekne",		   					"10") // 1 nikdy
	g_zasekne_kolko = register_cvar("zp_steelka_zasekne_kolko",				"10") //asi sec drzat	
	g_zasekne_pretazenie = register_cvar("zp_steelka_zasekne_pretazenie",	"3") // 70 % presiahne
	g_vyleti = register_cvar("zp_steelka_vyleti",		   					"15") // 1 nikdy	

	g_ammo = register_cvar("zp_steelka_ammo", 								"1")
	g_frags = register_cvar("zp_steelka_frags", 							"1")
	
	g_msgScoreInfo = get_user_msgid("ScoreInfo")
	g_item = zp_register_extra_item("Sekyho Steelka xD", get_pcvar_num(g_cena), ZP_TEAM_HUMAN)
	
	register_event("DeathMsg", 	"smrt",			"a")
	register_event("CurWeapon", "vybera_zbran", "be", "1=1")
	register_event("HLTV", 		"nove_kolo", 	"a",  "1=0", "2=0")
	register_clcmd("drop", 		"cmd_drop")
	
	register_forward(FM_PlayerPostThink, "post_think")
	register_forward(FM_PlayerPreThink, "pre_think")
	register_forward(FM_EmitSound, 		 "fw_EmitSound")
	
	//register_think("steelka", 			 "think_Flamethrower")
	register_touch("steelka", 			 "player", "dotkol_sa_zbrane_na_zemy")
}
public plugin_precache()
{
	// Cachujeme
	precache_sound(sound_fire)
	precache_sound(sound_fire2)
	precache_sound(sound_idle)
	precache_sound(sound_start)
	precache_sound(sound_start_fail)
	
	precache_model(v_model)
	precache_model(p_model)
	precache_model(w_model)	
	
	precache_model(v_model_stare)	
	precache_model(p_model_stare)	
}


// nakupene


public zp_extra_item_selected(id, itemid)
{
	if(itemid == g_item)
	{
		// Zakupil si ...	
		daj_zbran(id)
  	}
	return PLUGIN_CONTINUE
}
stock daj_zbran(id)
{
	g_ma_pilu[id] = true	
	if(get_user_weapon(id) == CSW_KNIFE) 
	{
		emit_sound(id, CHAN_WEAPON, sound_start, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		nastav_model(id)
		g_ma_aktivovanu[id] = true
		set_task(2.0, "hraj_idle", id)
	} else {
		client_cmd(id, "spk items/ammopickup2")
		g_ma_aktivovanu[id] = false
	}
	client_print(id, print_chat, "[G/L ZP] Pozor motorova pila nieje pre deti, zasekava sa a retaz vyskakuje !")
}
public vybera_zbran(id)
{
	if(!g_ma_pilu[id]) 
		return PLUGIN_CONTINUE
	
	new WeaponID = read_data(2)
	if(WeaponID == CSW_KNIFE) 
	{
		// Ak si prepol na NOZIK teda na motorovu pilu
		g_ma_aktivovanu[id] = true
		nastav_model(id)
		//entity_set_int(id, EV_INT_weaponanim, 3)
		emit_sound(id, CHAN_WEAPON, sound_start, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		set_task(2.0, "hraj_idle", id)
	} else {
		g_ma_aktivovanu[id] = false
	}
	
	return PLUGIN_CONTINUE
}
stock nastav_model(id)
{
	entity_set_string(id, EV_SZ_viewmodel, v_model)
	entity_set_string(id, EV_SZ_weaponmodel, p_model)
}
stock nastav_model_spat(id)
{
	entity_set_string(id, EV_SZ_viewmodel, v_model_stare)
	entity_set_string(id, EV_SZ_weaponmodel, p_model_stare)
}
public hraj_idle(id)
{
	if(!g_ma_pilu[id] || !g_ma_aktivovanu[id])
		return

	// Ak ma stale nasu zbran  
	if(!g_zaseknuty[id]) {
		emit_sound(id, CHAN_WEAPON, sound_idle, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}
	set_task(1.95, "hraj_idle", id)
}



// Udalosti


public nove_kolo() 
{
	for(new id = 1; id <= 32; id++) 
	{	
		// Mazeme pili
		if(g_ma_pilu[id]) {
			daj_zbran(id)
		} else {
			g_ma_pilu[id] = false		
			g_ma_aktivovanu[id] = false
		}
	}	
	
	// Odstranime pily na zemy ....
	new flamethrowers = -1
	while((flamethrowers = find_ent_by_class(flamethrowers, "steelka")))
		remove_entity(flamethrowers)	
}
public smrt()
{
	// Strati pilu
	new id = read_data(2)
	zhod_zbran(id)
	g_ma_aktivovanu[id] = false
}
public zp_user_infected_pre(id, infector)
{		
	// Strati pilu tak sito
	zhod_zbran(id)
	g_ma_aktivovanu[id] = false
}
public cmd_drop(id)
{
	// Vyhodi pilu
	zhod_zbran(id)
	nastav_model_spat(id)
	g_ma_aktivovanu[id] = false
}
stock zhod_zbran(id)
{
	if(!g_ma_pilu[id])
		return PLUGIN_CONTINUE
	
	g_ma_pilu[id] = false
	
	if(!is_user_alive(id) && !g_ma_aktivovanu[id])
		return PLUGIN_CONTINUE
	
	new Float:fVelocity[3], Float:fOrigin[3]
	entity_get_vector(id, EV_VEC_origin, fOrigin)
	VelocityByAim(id, 34, fVelocity)
	
	fOrigin[0] += fVelocity[0]
	fOrigin[1] += fVelocity[1]

	VelocityByAim(id, 300, fVelocity)
	
	new ent = create_entity("info_target")
	if(is_valid_ent(ent))
	{
		entity_set_string(ent, EV_SZ_classname, "steelka")
		entity_set_model(ent, w_model)
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_TOSS)
		entity_set_int(ent, EV_INT_solid, SOLID_TRIGGER)
		entity_set_vector(ent, EV_VEC_origin, fOrigin)
		entity_set_vector(ent, EV_VEC_velocity, fVelocity)
		entity_set_float(ent, EV_FL_takedamage, 1.0)
		entity_set_float(ent, EV_FL_health, 1000.0)
		entity_set_size(ent, Float:{-2.5, -2.5, -1.5}, Float:{2.5, 2.5, 1.5})
		entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.01)
	}			
	return PLUGIN_CONTINUE
}
public dotkol_sa_zbrane_na_zemy(ent, id)
{
	if(!is_valid_ent(ent) || !is_user_alive(id) || zp_get_user_zombie(id)) 
		return PLUGIN_CONTINUE
	
	if(g_ma_pilu[id])
		return PLUGIN_CONTINUE
	
	daj_zbran(id)
	remove_entity(ent)	
}



// Akcia


public pre_think(id) 
{
	if(!g_ma_pilu[id] || !g_ma_aktivovanu[id])
		return FMRES_IGNORED	
	
	g_striela_typ[id] = 0
	//client_print(id, print_console, "# 0") // log
	
// Vkuse stlaca doblovovat - prehriata
	if( (pev(id, pev_oldbuttons ) & IN_RELOAD ) && g_zaseknuty[id] > 0 ) // vkuse stlaca ....
	{
		g_prehriata[id]--;
		if(g_prehriata[id] <= get_pcvar_num(g_zasekne_kolko) * get_pcvar_num(g_zasekne_pretazenie) )
		{
			client_print(id, print_center, "Prehrial si ju, stlacaj pomalsie R !")
			g_prehriata[id] = g_zaseknuty[id] =  get_pcvar_num(g_zasekne_kolko) * 10;
			return FMRES_IGNORED
		}
	} else {
		// Prerusil odblokovanie, nabijeme znova
		g_prehriata[id] = get_pcvar_num(g_zasekne_kolko) * 10;
	}
	
// Odblokovat
	if( (pev(id, pev_button ) & IN_RELOAD) && g_zaseknuty[id] > 0)
	{
		emit_sound(id, CHAN_WEAPON, sound_start_fail, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		g_zaseknuty[id]--;		
		//client_print(id, print_console, "# r") // log
		return FMRES_IGNORED
	}
	
// Nahodne sa zasekne :D pre obidva moznosti
	if((pev(id, pev_button ) & IN_ATTACK) || ((pev(id, pev_button ) & IN_ATTACK2)  && !(pev(id, pev_oldbuttons ) & IN_ATTACK2) ))
	{
		if(g_zaseknuty[id]) {
			entity_set_int(id, EV_INT_weaponanim, 3)
			client_print(id, print_center, "Zdochla ti pila, stlacaj R !")
			return FMRES_IGNORED
		}
		
		if( random_num(0, get_pcvar_num(g_zasekne) * 100) == 101 )
		{
			client_print(id, print_center, "Zdochla ti pila, stlacaj R !")
			g_prehriata[id] = g_zaseknuty[id] =  get_pcvar_num(g_zasekne_kolko) * 10;
			return FMRES_IGNORED
		}
	}
	
// Ak vkuse striela ATTACKOM
	if(pev(id, pev_button ) & IN_ATTACK)
	{

		// Retaz vyleti
		if( random_num(0, get_pcvar_num(g_vyleti) * 100) == 101 )
		{
			client_print(id, print_center, "Vyletela ti retaz a ujebala zombika !")
			zhod_zbran(id)
			nastav_model_spat(id)
			g_ma_aktivovanu[id] = false			
			return FMRES_IGNORED
		}
		
		g_striela_typ[id] = 1	
	}		
	
// Natahovanie moze len kliknutim
	if((pev(id, pev_button ) & IN_ATTACK2)  && !(pev(id, pev_oldbuttons ) & IN_ATTACK2 ))  
	{
		//client_print(id, print_console, "# 2") // log
		g_striela_typ[id] = 2	
	}
	return FMRES_IGNORED
}

public post_think(id)
{	
	if(!g_ma_pilu[id] || !g_ma_aktivovanu[id])
		return FMRES_IGNORED
					
	// Zaseknuty
	if(g_zaseknuty[id]) {
		entity_set_int(id, EV_INT_weaponanim, 3)
		return FMRES_IGNORED
	}
	
	// Ak striela ...				
	direct_damage(id, g_striela_typ[id])
	return FMRES_IGNORED
}
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	// Najvacsi odzub vo fakamete ....
	if (!is_user_connected(id) || !g_ma_pilu[id] || !g_ma_aktivovanu[id])
		return FMRES_IGNORED;
		
	// Attacks with knife
	if (equal(sample[8], "kni", 3))
	{
		if(g_zaseknuty[id]) {
			return FMRES_SUPERCEDE;
		}
		
		//client_print(id, print_console, "sound") // log
		if (equal(sample[14], "sla", 3)) // slash
		{
			engfunc(EngFunc_EmitSound, id, channel, sound_fire, volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
		if (equal(sample[14], "hit", 3))
		{
			if (sample[17] == 'w') // wall
			{
				engfunc(EngFunc_EmitSound, id, channel, sound_fire, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
			else // hit
			{
				engfunc(EngFunc_EmitSound, id, channel, sound_fire, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
		}
		if (equal(sample[14], "sta", 3)) // stab
		{
			engfunc(EngFunc_EmitSound, id, channel, sound_fire2, volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}
stock direct_damage(id, typ)
{
	if(typ == 0) {
		return
	}
	
	new ent, body
	get_user_aiming(id, ent, body, typ==2 ? get_pcvar_num(g_distance2) : get_pcvar_num(g_distance))
	
	if(ent > 0 && is_user_alive(ent))
	{
		if(!zp_get_user_zombie(ent))
			return
		
		new damage
		damage = (typ==2) ? get_pcvar_num(g_damage2) : get_pcvar_num(g_damage)
		if(get_user_health(ent) > damage) {
			fakedamage(ent, "weapon_steelka", float(damage), DMG_SLASH)
			//client_print(id, print_console, "# %d", get_user_health(ent)) // log
		} else{
			user_silentkill(ent)
			make_deathmsg(id, ent, 0, "Steelka")
			
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + get_pcvar_num(g_ammo))
			new frags = get_user_frags(id) +  get_pcvar_num(g_frags)
			fm_set_user_frags(id, frags)
			Update_ScoreInfo(id, frags, get_user_deaths(id) )
		}		
	}
}


stock fm_set_user_frags(index, frags) 
{
	set_pev(index, pev_frags, float(frags))
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