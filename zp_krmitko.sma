#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <zombieplague>

#define fm_precache_model(%1) 		engfunc(EngFunc_PrecacheModel,%1)
#define fm_remove_entity(%1) 		engfunc(EngFunc_RemoveEntity, %1)
#define fm_find_ent_by_class(%1,%2) engfunc(EngFunc_FindEntityByString, %1, "classname", %2)
#define fm_drop_to_floor(%1) engfunc(EngFunc_DropToFloor,%1)

#define PLUGIN 	"[ZP] Krmitko"
#define VERSION "1.0"
#define AUTHOR 	"Seky"
#define NAZOV_ENT	"zp_krmitko"

new const modely[][] = {
	"models/zombie_plague/krmitko.mdl",
	"models/zombie_plague/krmitko2.mdl"
};
new tovar, cvar_radius, cvar_hp, g_maxplayers, cvar_zivot

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	tovar = zp_register_extra_item("Krmitko", 7, ZP_TEAM_ZOMBIE)
	cvar_radius = register_cvar("zp_krmitko_radius", "200.0")
	cvar_hp = register_cvar("zp_krmitko_addhp", "20.0")
	cvar_zivot = register_cvar("zp_krmitko_hp", "30.0")
	register_forward(FM_Think, "entity_think" );
	g_maxplayers = get_maxplayers()	
}
public plugin_precache() { 
	for(new i = 0; i < sizeof modely; i++) fm_precache_model(modely[i]);	
}
public zp_extra_item_selected(player, itemid) {
	if (itemid == tovar){
		postav_krmitko(player);
	}
	return PLUGIN_CONTINUE;
}
stock postav_krmitko(id)
{
	// Vlastnosti nastavujeme
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_wall"))
	set_pev(ent, pev_classname, NAZOV_ENT);	
	set_pev(ent, pev_solid, SOLID_BBOX)
	set_pev(ent, pev_movetype,MOVETYPE_NONE);
	set_pev(ent, pev_health, get_pcvar_float(cvar_zivot));
	set_pev(ent, pev_takedamage, DAMAGE_YES);
	engfunc(EngFunc_SetModel, ent, modely[random_num(0, sizeof modely - 1)]);	
	// a pozicie
	new Float:temp[3];
	/*pev(id, pev_velocity, temp)
	set_pev(ent, pev_velocity, temp)*/
	pev(id, pev_origin, temp)
	set_pev(ent, pev_origin, temp)
	fm_drop_to_floor(ent);
	set_pev(ent, pev_nextthink, get_gametime() + 1.0);
	return PLUGIN_CONTINUE;
}
public entity_think(krmitko)
{
	//Je to vobec vajco ?
	if (!pev_valid(krmitko) ) return FMRES_IGNORED;	
	new EntityName[32];
	pev(krmitko, pev_classname, EntityName, 31);
	if(!equal(EntityName, NAZOV_ENT) ) return FMRES_IGNORED;	
	
	static Float:Radius, Float:hp
	Radius = get_pcvar_float(cvar_radius)
	if(!Radius) return FMRES_IGNORED;	
	hp = get_pcvar_float(cvar_hp);
	if(!hp) return FMRES_IGNORED;	
	
	// Hladame blizko hracov ...
	static Float:temp[3], i, Float:postava[3], zivot
	pev(krmitko, pev_origin, temp);

	for(i=1; i <= g_maxplayers; i++) {
		if (!is_user_alive(i) || !zp_get_user_zombie(i)) continue;
		pev(i, pev_origin, postava);
		if ( get_distance_f(temp, postava) > Radius) continue;
		pev(i, pev_health, postava[0]);
		zivot = floatround(postava[0]);
		if(zp_get_zombie_maxhealth(i) > zivot) {
			set_pev(i, pev_health, float(zivot)+hp)
		}
	}		
	set_pev(krmitko, pev_nextthink, get_gametime() + 1.0);
	return FMRES_IGNORED;
}
public zp_round_ended(winteam) {
	return entity_delete(NAZOV_ENT);
}
stock entity_delete( classname[] ){
	new ent = -1;
	while((ent = fm_find_ent_by_class(ent, classname))) fm_remove_entity(ent);		
}