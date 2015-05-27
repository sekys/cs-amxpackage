#include <amxmodx>
#include <fakemeta>
#include <zombieplague>

new cvar_cost, cost, g_itemid_curezivot

public plugin_init() 
{
	register_plugin("Zp Lekarnicka", "1.0" ,"Seky")
	cvar_cost = register_cvar("zp_lekarnicka", "10")
	cost = get_pcvar_num(cvar_cost)
	g_itemid_curezivot = zp_register_extra_item("Lekarnicka HP+++", cost, ZP_TEAM_ANY)
}

public zp_extra_item_selected(player, itemid)
{
	if (itemid == g_itemid_curezivot)  {
		if (!is_user_alive(player)) return PLUGIN_HANDLED	
			
		new Float:pluszivot
		if (!zp_get_user_zombie(player))  {	
			pluszivot	= 100.0;	
		} else { 
			pluszivot	= 1000.0; 
		}
		new Float:health
		pev(player, pev_health, health)
		set_pev(player, pev_health, health+pluszivot)
		
		client_print(player, print_chat, "[G/L ZP] Zaplatil si %d bodov za lekarnicku,pridane %d HP.",cost, floatround(pluszivot))
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}