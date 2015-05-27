#include <amxmodx>
#include <zombieplague>
#include <hamsandwich>
#include <fakemeta>

//new bool:gHasHulk[33]
new bool:gMarychlost[33]

new const gHeroName[] = "Big Zombie"
new const zclass_info[] = { "HP++ Speed- Hulk utok" } // description
new const TSkins[] = { "zombie_moustro" }
new const zclass_clawmodel[] = { "big.mdl" }
const zclass_health = 2700 // health
const zclass_speed = 150 // speed
const Float:zclass_gravity = 1.0 // gravity
const Float:zclass_knockback = 0.5 // knockback

new const gStompSound[] = "zombie_plague/gon_die1.wav"
new g_zclass_climb, g_sb_maxspeed, g_sb_time,hulkRadius
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("ZP Hulk zombie", "1.0", "Seky")
	RegisterHam(Ham_Player_PreThink, "player", "cheese_player_prethink", 1)
	register_event("ResetHUD", "newround", "b");
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	
	g_sb_maxspeed = register_cvar("zp_hulk_maxspeed", "70.0")
	hulkRadius = register_cvar("zp_hulk_radius", "500.0")
	g_sb_time = register_cvar("zp_hulk_time", "4.0")

}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	g_zclass_climb = zp_register_zombie_class(gHeroName, zclass_info, TSkins, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
	precache_sound(gStompSound)
}
//----------------------------------------------------------------------------------------------
public newround(id) 
{
	//gHasHulk[id] = false
	gMarychlost[id] = false
	remove_task(id)
}
//--------------------------------ZVUK---------------------------------------------------
public client_connect(id)
{
	//gHasHulk[id] = false
	gMarychlost[id] = false
	remove_task(id)
}
//--------------------------------------E----MENU-----------------------------------------------
public cheese_player_prethink(id) 
{
	if(zp_is_survivor_round() || zp_is_nemesis_round() || zp_get_user_zombie_class(id) != g_zclass_climb) {
		return
	}
	if(!is_user_alive(id) || !zp_get_user_zombie(id)) {
		return 
	}
	
	if(pev(id, pev_button ) & IN_RELOAD && !(pev(id, pev_oldbuttons ) & IN_RELOAD )) {
		
	//if (gHasHulk[id]) {
		//client_print(id,print_chat,"[G/L ZP] Uz si raz pouzil Zombie utok!"); //2x
		//return 
	//}
		
	//spusti odpalenie na hraca a nic viacej
	//gHasHulk[id] = true
	
	//if (gHasHulk[id] == true) {
	if(zp_get_user_energy(id) == 100) {
		zp_set_user_energy(id,0)
		client_print(id,print_chat,"[G/L ZP] Zobrana energia za schopnost!");
		new Float:velocity[3]
		pev(id, pev_velocity, velocity)

		if ( velocity[2] < -10.0 || velocity[2] > 10.0 ) {
			return
		}

		// OK Power stomp enemies closer than x distance
		new Float:userOrigin[3], Float:victimOrigin[3], Float:distanceBetween
		//new Float:hulkRadius = gPcvarRadius
		//new Float:hulkStunTime = gPcvarStunTime
		//new Float:hulkStunSpeed = gPcvarStunSpeed

		pev(id, pev_origin, userOrigin)

		new players[32]
		new playerCount, player
		get_players(players, playerCount, "ah")
		//client_print(0,print_notify,"E "); // LOG
		for ( new i = 0; i < playerCount; i++ ) {
			player = players[i]

			if ( player != id ) {
			
				emit_sound(player, CHAN_ITEM, gStompSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				pev(player, pev_origin, victimOrigin)
				distanceBetween = get_distance_f(userOrigin, victimOrigin)

				if ( distanceBetween < hulkRadius ) {
						//sh_set_stun(player, hulkStunTime, hulkStunSpeed)
						sh_screen_shake(player, 4.0, get_pcvar_float(g_sb_time), 8.0)	
						
						gMarychlost[player] = true;
						set_pev(player, pev_maxspeed, get_pcvar_float(g_sb_maxspeed))
						set_task(get_pcvar_float(g_sb_time), "rychlost", player);
					
				}
			}
		}
	} else {
		client_print(id,print_chat,"[G/L ZP] Nedostatok energie !");
	}
		
	}
}
//=========== Fukcia scree shake
stock sh_screen_shake(id, Float:amplitude, Float:duration, Float:frequency)
{
	if ( !is_user_connected(id) ) return 0;

	static msgScreenShake;

	if ( !msgScreenShake ) {
		msgScreenShake = get_user_msgid("ScreenShake");
	}

	// Check unsigned short range
	static amp, dura, freq;
	amp = clamp(floatround(amplitude * float(1<<12)), 0, 0xFFFF);
	dura = clamp(floatround(duration * float(1<<12)), 0, 0xFFFF);
	freq = clamp(floatround(frequency * float(1<<8)), 0, 0xFFFF);

	message_begin(MSG_ONE_UNRELIABLE, msgScreenShake, _, id);
	write_short(amp);	// amplitude
	write_short(dura);	// duration
	write_short(freq);	// frequency
	message_end();
	return 1;
}
public rychlost(id)
{
	gMarychlost[id] = false
}
public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED
		
	
	if (gMarychlost[id])
	{
		set_pev(id, pev_maxspeed, get_pcvar_float(g_sb_maxspeed))		
	}
	return PLUGIN_CONTINUE
}