#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <zombieplague>
#include <hamsandwich>

public plugin_init()
{
	register_plugin("Entity Model","1.0","Seky")
    register_forward(FM_AddToFullPack, "fwd_AddToFullPack", 1);
	register_clcmd ( "ent_mod", "pouzi", ADMIN_RCON, "<IDcislo> Pouzije entitu podla cisla alebo mieritka." );
	register_forward(FM_PlayerPreThink, "FW_PlayerPreThink");
}

/* public fwd_AddToFullPack(es_handle, e, id, host, hostflags, player, pSet)
{
		if(!is_user_alive(id) && zp_get_user_zombie(id))
	        return FMRES_IGNORED;

	    set_es(es_handle,ES_Sequence,18);
	    set_es(es_handle,ES_GaitSequence,18);

    return FMRES_HANDLED;
}  */ 
public FW_PlayerPreThink(id)
{	
	if(is_user_alive(id) && !zp_get_user_zombie(id))
	{
		set_pev(id,pev_sequence,103)
		set_pev(id,pev_gaitsequence,1)
		set_pev(id,pev_frame,1.0)
		set_pev(id,pev_framerate,1.0)
		set_pev(id,pev_gravity,0.1)
	}
} 
public pouzi(id,level,cid)
{
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
		
		new arg[32]
		read_argv ( 1, arg,4)
		new cislo = str_to_num(arg)
	if(cislo==1) {
		new tarukaz,body,tauth[32]
		get_user_aiming(id,tarukaz,body,99999)
		get_user_authid(tarukaz,tauth,31)
		if (tarukaz == 0) {
			client_print(id,print_chat,"[ENT] Na nic sa nepozeras^n")
		} else {
			fake_touch(tarukaz,id);
			force_use(id,tarukaz);
			
			entity_set_int(tarukaz, EV_INT_gaitsequence, 103);			
			client_print(id,print_chat,"[ENT] Pouzita entita%d.^n",tarukaz)
		}
			
	} 
	return PLUGIN_HANDLED
}