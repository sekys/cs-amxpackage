#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <zombieplague>

#define fm_precache_model(%1) 		engfunc(EngFunc_PrecacheModel,%1)
#define fm_remove_entity(%1) 		engfunc(EngFunc_RemoveEntity, %1)
#define fm_find_ent_by_class(%1,%2) engfunc(EngFunc_FindEntityByString, %1, "classname", %2)
#define fm_drop_to_floor(%1) engfunc(EngFunc_DropToFloor,%1)

#define PLUGIN 	"[ZP] Lampas"
#define VERSION "1.0"
#define AUTHOR 	"Seky"
#define NAZOV_ENT	"zp_lampas"

#define FLARE_ENTITY args[0]
#define FLARE_DURATION args[1]
#define TASK_NADES 100

new tovar, cvar_flaresize, cvar_flareduration
const PEV_FLARE_COLOR = pev_punchangle
new const modely[][] = { "models/zombie_plague/lampas.mdl" };

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	tovar = zp_register_extra_item("Lampas", 7, ZP_TEAM_ANY)
	cvar_flareduration = register_cvar("zp_lampas_dlzka", "300")
	cvar_flaresize = register_cvar("zp_lampas_velksot", "25")
}
public plugin_precache() { 
	for(new i = 0; i < sizeof modely; i++)
		fm_precache_model(modely[i]);	
}
public zp_extra_item_selected(player, itemid) {
	if (itemid == tovar){
		postav_lampas(player);
	}
	return PLUGIN_CONTINUE;
}
stock postav_lampas(const id)
{
	// Vlastnosti nastavujeme
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_wall"))
	set_pev(ent, pev_classname, NAZOV_ENT);	
	set_pev(ent, pev_solid, SOLID_TRIGGER)
	set_pev(ent, pev_movetype, MOVETYPE_NONE);
	engfunc(EngFunc_SetModel, ent, modely[random_num(0, sizeof modely - 1)]);	
	// a pozicie
	static Float:temp[3];
	pev(id, pev_origin, temp)
	set_pev(ent, pev_origin, temp)
	fm_drop_to_floor(ent);
	// + svetlo ..
	static params[2]
	params[0] = ent; // entity id
	params[1] = get_pcvar_num(cvar_flareduration)/5 // duration
	set_task(0.1, "flare_lighting", TASK_NADES, params, sizeof params)
	return PLUGIN_CONTINUE;
}
public zp_round_ended(winteam) {
	remove_task(TASK_NADES)
	return entity_delete(NAZOV_ENT);
}
public flare_lighting(args[2])
{
	// Unexistant flare entity?
	if (!pev_valid(FLARE_ENTITY)) return;
	
	// Flare depleted -clean up the mess-
	if (FLARE_DURATION <= 0) {
		engfunc(EngFunc_RemoveEntity, FLARE_ENTITY)
		return;
	}
	// Get origin
	static Float:originF[3]
	pev(FLARE_ENTITY, pev_origin, originF)
	
	// Lighting
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_DLIGHT) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	write_byte(get_pcvar_num(cvar_flaresize)) // radius
	write_byte(255) // r
	write_byte(255) // g
	write_byte(255) // b
	write_byte(51) //life
	write_byte((FLARE_DURATION < 2) ? 3 : 0) //decay rate
	message_end()
	
	// Sparks
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_SPARKS) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	message_end()
	
	// Decrease task cycle counter
	FLARE_DURATION -= 1;
	
	// Keep sending flare messaegs
	set_task(5.0, "flare_lighting", TASK_NADES, args, sizeof args)
}
stock entity_delete( classname[] ) {
	new ent = -1;
	while((ent = fm_find_ent_by_class(ent, classname))) fm_remove_entity(ent);		
}