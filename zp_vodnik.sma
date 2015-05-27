#include <amxmisc>
#include <amxmodx> 
#include <fakemeta>
#include <hamsandwich> 
#include <zombieplague>

static const PLUGIN_NAME[] = "[ZP] vodnik";
static const PLUGIN_VERSION[] = "1.0";
static const PLUGIN_AUTHOR[] = "Seky";

enum
{
	WATERLEVEL_NOT,
};

#define DMG_DROWN (1<<14)
new g_zclass_vodnik;
new bool:g_counter_strike;

new const zclass_name[] = { "Vodnik" } // name
new const zclass_info[] = { "Nesmrtelny a rychly vo vode" } // description
new const zclass_model[] = { "gl_water" } // model
new const zclass_clawmodel[] = { "gl_water.mdl" } // claw model
const zclass_health = 1700 // health
const zclass_speed = 250 // speed
const Float:zclass_gravity = 1.0 // gravity
const Float:zclass_knockback = 1.7 // knockback

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR); 
	RegisterHam(Ham_TakeDamage, "player", "FwdTakeDamage");     
	register_forward(FM_PlayerPreThink, "FwdPlayerPreThink");
	g_counter_strike = bool:is_running("cstrike");
}

public plugin_precache()
{
	g_zclass_vodnik = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
}

public FwdTakeDamage(id, inflictor, attacker, Float:damage, damagebits)
{
	if(zp_is_survivor_round() || zp_is_nemesis_round() )
		return HAM_IGNORED;

	
	if(!is_user_alive(id) || !zp_get_user_zombie(id)) 
		return HAM_IGNORED;

	if(zp_get_user_zombie_class(id) != g_zclass_vodnik) 
		return HAM_IGNORED;
	
	if(damagebits & DMG_DROWN)
	{
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}

public FwdPlayerPreThink(client)
{
	static old_waterlevel[33];
	
	if( !is_user_alive(client) || !zp_get_user_zombie(client))
	{
		old_waterlevel[client] = WATERLEVEL_NOT;
		return;
	}	
	if(zp_get_user_zombie_class(client) != g_zclass_vodnik || pev(client, pev_movetype) == MOVETYPE_NOCLIP )
	{
		old_waterlevel[client] = WATERLEVEL_NOT;
		return;
	}
	
	if(pev(client, pev_movetype) == MOVETYPE_NOCLIP )
	{
		old_waterlevel[client] = WATERLEVEL_NOT;
		return;
	}
	
	new waterlevel = pev(client, pev_waterlevel);
	if( waterlevel != WATERLEVEL_NOT )
	{
		SetMaxspeed(client, 350.0);
	}
	else if( old_waterlevel[client] != WATERLEVEL_NOT )
	{
		ResetMaxspeed(client);
	}
	
	old_waterlevel[client] = waterlevel;
}

ResetMaxspeed(client)
{
	if( g_counter_strike )
	{
		static Float:maxspeed;
		switch ( get_user_weapon(client) )
		{
			case CSW_SG550, CSW_AWP, CSW_G3SG1:		 maxspeed = 210.0;
			case CSW_M249:					 maxspeed = 220.0;
			case CSW_AK47:					 maxspeed = 221.0;
			case CSW_M3, CSW_M4A1:				 maxspeed = 230.0;
			case CSW_SG552:					 maxspeed = 235.0;
			case CSW_XM1014, CSW_AUG, CSW_GALIL, CSW_FAMAS:	 maxspeed = 240.0;
			case CSW_P90:					 maxspeed = 245.0;
			case CSW_SCOUT:					 maxspeed = 260.0;
			default:					 maxspeed = 250.0;
		}
		
		SetMaxspeed(client, maxspeed);
	}
	else
	{
		SetMaxspeed(client, 250.0);
	}
}

SetMaxspeed(client, Float:maxspeed)
{
	engfunc(EngFunc_SetClientMaxspeed, client, maxspeed);
	set_pev(client, pev_maxspeed, maxspeed);
}
