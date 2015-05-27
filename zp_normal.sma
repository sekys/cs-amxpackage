#include <amxmodx>
#include <fakemeta>
#include <zombieplague>
#include <fakemeta>

new const zclass5_name[] = { "Srotovnik" }
new const zclass5_info[] = { "-Regeneracia 20HP/sec + 200HP/kill" }
new const zclass5_model[] = { "gl_zombie" }
new const zclass5_clawmodel[] = { "gl_water.mdl" }
const zclass5_health = 1800
const zclass5_speed = 190
const Float:zclass5_gravity = 1.0
const Float:zclass5_knockback = 1.0
const zclass5_infecthp = 200 // extra hp for infections

new g_zclass_normal,zivot
public plugin_init()
{
	register_plugin("[ZP] Zombie Classic", "1.0", "Seky")
	set_task(1.0, "regeneracia", _, _, _, "b")
}
public plugin_precache()
{
	g_zclass_normal = zp_register_zombie_class(zclass5_name, zclass5_info, zclass5_model, zclass5_clawmodel, zclass5_health, zclass5_speed, zclass5_gravity, zclass5_knockback)
}


public zp_user_infected_post(id, infector)
{
	if (zp_get_user_zombie_class(infector) == g_zclass_normal) {
		set_pev(infector, pev_health, float(pev(infector, pev_health) + zclass5_infecthp))
	}	
}
public regeneracia()
{
	if(zp_is_survivor_round() || zp_is_nemesis_round()) return;
		
		
	new players[32], player, pnum;
	get_players(players, pnum, "a");
	for(new i = 0; i < pnum; i++)
	{
		player = players[i];

		if(is_user_alive(player)) {
			if(zp_get_user_zombie(player)) {
				if(zp_get_user_zombie_class(player) == g_zclass_normal) {
					zivot = pev(player, pev_health)
					if(zivot < zclass5_health) {
						set_pev(player, pev_health, float(zivot + 20))
					}
				}
			}
		}	
	}
}
