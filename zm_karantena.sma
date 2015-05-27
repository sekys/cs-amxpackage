#include <amxmodx>
#include <amxmisc>
#include <fakemeta>


#define STRANA_VELKOST 	128;//px
#define OWNER			pev_iuser2
#define STRANA			pev_iuser3

new const g_models[][] =	{
	"models/blockmaker/bm_block_glass.mdl",
	"models/blockmaker/bm_block_nuke.mdl"
};
new const	Float:p_mins[3] = { -32.160000, -2.0, -32.009998 };
new const	Float:p_maxs[3] = { 31.830000, 2.0, 31.980000 };
	
public plugin_init() 
{
	register_plugin("[G/L ZP] Karantena", "1.0", "Seky")
	register_clcmd("amx_set_barel", "cmd_barel", ADMIN_RCON, "-");
	register_logevent("event_newround", 2, "1=Round_Start")
}
public plugin_precache()
{
	for(new i=0;i < sizeof g_models;i++) {
		engfunc(EngFunc_PrecacheModel,g_models[i]);
	}
}
public event_newround()
{
	new karantena = -1;
	while((karantena = engfunc(EngFunc_FindEntityByString, karantena, "classname", "Karantena") ))
		engfunc(EngFunc_RemoveEntity, karantena)
		
	karantena = 0;	
}
public cmd_barel(id, level, cid)
{
	if (!cmd_access(id,level,cid,1)) {
		return PLUGIN_HANDLED
	}
	PostavKarantenu(id);
}
stock PostavKarantenu(id)
{	
	new temp[3], hrac_vector[3]
	get_user_origin(id, temp)
	
	// Pretypujeme
	hrac_vector[0] = float(temp[0]);
	hrac_vector[1] = float(temp[1]);
	hrac_vector[2] = float(temp[2]);
	
	// Karantena
	CreateCuba(hrac_vector);
	
	// Svetlo 
	
	// Misc
	client_print(id, print_chat, "[G/L ZP] Karantena postavena !");	
}
stock CreateCuba( Float:hrac[3])
{
	/*					z       D		C
						|	--------------
						|	|		|
						|	|	*	|
						|	--------------
						|      A                    B
			--------------------------------------------	x
						| 0
						|
						|
						|
						|								
	*/
	
	hrac[2] = hrac[2] - 32.0;
	CreatePodlazie(hrac, 32.0, 40.0);	
	// Dolne
	CreatePodlaziePlne(hrac, 40.0);	
	
	// Horne
	hrac[2] = hrac[2] + 60.0;
	CreatePodlazie(hrac, 32.0, 40.0);	
	hrac[2] = hrac[2] + 30.0;
	CreatePodlaziePlne(hrac, 40.0);
}

stock CreatePodlaziePlne( Float:hrac[3], Float:rozdiel)	// horne a dolne tymto vytvorime
{
	new Float:vektor[3], Float:uhol[3];
	vektor[2] = hrac[2] 
		
	vektor[0] = hrac[0] + rozdiel;
	vektor[1] = hrac[1] + rozdiel;
	StavebnaCast(vektor, uhol, 0);
	
	vektor[0] = hrac[0] + rozdiel;
	vektor[1] = hrac[1] - rozdiel;
	StavebnaCast(vektor, uhol, 0);	
	
	vektor[0] = hrac[0] - rozdiel;
	vektor[1] = hrac[1] - rozdiel;
	StavebnaCast(vektor, uhol, 0);
	
	vektor[0] = hrac[0] - rozdiel;
	vektor[1] = hrac[1] + rozdiel;
	StavebnaCast(vektor, uhol, 0);
}
stock CreatePodlazie(Float:hrac[3], Float:rozdiel , Float:prefix)	// mame dolne 4 
{	
	new Float:uhol[3], Float:vektor[3];	
	uhol[2] = 90.0;
	uhol[1] = 90.0;
	vektor[2] = hrac[2]
	
	vektor[0] = hrac[0] + rozdiel;
	vektor[1] = hrac[1] + rozdiel + prefix;
	vektor[2] = hrac[2]	
	StavebnaCast(vektor, uhol, 0);	
	
	vektor[0] = hrac[0] - rozdiel;
	vektor[1] = hrac[1] + rozdiel + prefix;
	StavebnaCast(vektor, uhol, 0);

	vektor[0] = hrac[0] + rozdiel;
	vektor[1] = hrac[1] - rozdiel - prefix;
	StavebnaCast(vektor, uhol, 0);	
	
	vektor[0] = hrac[0] - rozdiel;
	vektor[1] = hrac[1] - rozdiel - prefix;
	StavebnaCast(vektor, uhol, 0);
	// Bocne
}
stock Rotacia( vektor[3], uhol)	// pripadna rotacia
{
	/*
		          / ---------
		    /		   /
		/	*	/
	         -----------/			
	*/
}
stock StavebnaCast(Float:vektor[3], Float:uhol[3], model)
{	
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_wall"	));	
    new Float:vSizeMin[3]={-0.0,-0.0,-4.0};
    new Float:vSizeMax[3]={200.0,2100.0,20.0};

	
	set_pev(ent, pev_classname,"Karantena");
	engfunc(EngFunc_SetModel, ent, g_models[model]);
	engfunc(EngFunc_SetSize, ent, vSizeMin, vSizeMax);
	set_pev(ent, pev_mins, vSizeMin);
	set_pev(ent, pev_maxs, p_maxs );
	set_pev(ent, pev_absmin, vSizeMin);
	set_pev(ent, pev_absmax, vSizeMax );
	engfunc(EngFunc_SetOrigin, ent, vektor);	
	set_pev(ent,pev_solid,SOLID_BBOX); // touch on edge, block
	set_pev(ent, pev_movetype, MOVETYPE_FLY); // no gravity, but still collides with stuff
	set_pev(ent, pev_rendermode, 2);
	set_pev(ent, pev_renderamt, 120.0);
	set_pev(ent, pev_angles, uhol);
	engfunc(EngFunc_DropToFloor, ent)
	return ent;
}