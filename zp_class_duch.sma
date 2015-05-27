#include <amxmod>
#include <Vexd_Utilities>
#include <hamsandwich>
#include <zombieplague>

#define HP_UBERA 100 // hp/sec

// GLOBAL VARIABLES
//new bool:pouzil_silu[33]
new bool:mod_ducha[33]
new gUserHealth[33]
new gUserArmor[33]
new gGhostHealth[33]
new gGhostArmor[33]
new g_lastPosition[33][3]

// Crow Zombie Atributes
new const zclass_name[] = { "Duch" } // name
new const zclass_info[] = { "Prechadza stenamy" } // description
new const zclass_model[] = { "gl_Slimer" } // model
new const zclass_clawmodel[] = { "gl_duch2.mdl" } // claw model
const zclass_health = 900 // health
const zclass_speed = 190 // speed
const Float:zclass_gravity = 1.0 // gravity
const Float:zclass_knockback = 1.1 // knockback
new g_zclass_crow

public plugin_init()
{
	register_plugin("[ZP] Duch", "1.0" , "Seky");
	RegisterHam(Ham_Player_PreThink, "player", "cheese_player_prethink", 1)
	
	register_event("ResetHUD", "newSpawn", "b")
	register_event("DeathMsg", "casper_death", "a")
}
public plugin_precache()
{
	g_zclass_crow = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
}
public newSpawn(id)
{
	if (is_user_alive(id) ) {
		if ( mod_ducha[id] ) {
			casper_removeghost(id)
		}
	}
	mod_ducha[id] = false
	//pouzil_silu[id] = false
}
public zp_user_infected_pre(id, infector)
{
	if(mod_ducha[infector])
	{
		client_print(infector,print_chat,"[G/L ZP] Si v mode ducha,nemozes teraz nakazit cloveka !")
		set_pev(id, pev_armorvalue, pev(id, pev_armorvalue) + 100.0) // blokneme infekciu
		dllfunc(DLLFunc_ClientKill, infector); // potrestame
		return PLUGIN_HANDLED; // skusime vypnut
	}
}
public cheese_player_prethink(id) 
{			
	// Schopnost 
	if((pev(id, pev_button ) & IN_RELOAD) && !(pev(id, pev_oldbuttons ) & IN_RELOAD ))
	{
		if(zp_is_survivor_round() || zp_is_nemesis_round()) return PLUGIN_CONTINUE
		if(!is_user_alive(id) || !zp_get_user_zombie(id)) return PLUGIN_CONTINUE
		if(zp_get_user_zombie_class(id) != g_zclass_crow) return PLUGIN_CONTINUE
				
		if(!mod_ducha[id])
		{
			//pouzil_silu[id] = true
			mod_ducha[id] = true
				
			// Set invisible first then loop it
			set_user_noclip(id, 1)
			set_user_rendering(id, kRenderFxGlowShell, 8, 8, 8, kRenderTransAlpha, 12)
			set_task(1.0, "casper_loop", id, "", 0, "b")
	
			client_print(id,print_chat,"[G/L ZP] Teraz mozes prechadzat stenamy, nezasekni sa !")
			client_print(id,print_chat,"[G/L ZP] Za 1 sec ti ubera %d HP.", HP_UBERA)
			
			// HP
			new Float:health
			pev(id,pev_health,health)
			health = health - float(HP_UBERA)
			health > 0.0 ? set_pev(id, pev_health, health) : dllfunc(DLLFunc_ClientKill, id);
			
		} else {
			casper_removeghost(id)
		}
	}
	return PLUGIN_CONTINUE;
}
public plugin_natives()
{
	register_native("is_mod_ducha", "native_mod_ducha", 1)
}	
public native_mod_ducha(id)
{
	return mod_ducha[id];
}
public casper_loop(id)
{
	if (!is_user_alive(id) || !mod_ducha[id] ) return

	// rENDER
	set_user_rendering(id, kRenderFxGlowShell, 8, 8, 8, kRenderTransAlpha, 12)
	
	// HP
	new Float:health
	pev(id,pev_health,health)
	health = health - float(HP_UBERA)
	health > 0.0 ? set_pev(id, pev_health, health) : dllfunc(DLLFunc_ClientKill, id);
}
public casper_removeghost(id)
{
	remove_task(id)

	if ( !is_user_connected(id) ) return

	positionChangeTimer(id)
	set_user_noclip(id, 0)
	set_user_rendering(id)
	mod_ducha[id] = false
}
public positionChangeTimer(id)
{
	if ( !is_user_alive(id) ) return

	get_user_origin(id, g_lastPosition[id])

	new Float:velocity[3]
	Entvars_Get_Vector(id, EV_VEC_velocity, velocity)

	if ( velocity[0]==0.0 && velocity[1]==0.0 ) {
		// Force a Move (small jump)
		velocity[0] += 20.0
		velocity[2] += 100.0
		Entvars_Set_Vector(id, EV_VEC_velocity, velocity)
	}

	set_task(0.8, "positionChangeCheck", id)
}
public positionChangeCheck(id)
{
	if ( !is_user_alive(id) ) return

	new origin[3]
	get_user_origin(id, origin)

	if ( g_lastPosition[id][0] == origin[0] && g_lastPosition[id][1] == origin[1] && g_lastPosition[id][2] == origin[2] && is_user_alive(id) ) {
		user_kill(id)
		client_print(id, print_chat, "[G/L ZP] Zasekol si sa v stene.")
	}
}
public casper_death()
{
	new id = read_data(2)

	if ( !mod_ducha[id] ) return

	casper_removeghost(id)
}
public client_disconnect(id)
{
	if ( !mod_ducha[id] ) return

	casper_removeghost(id)
}