#include <amxmodx>	
#include <amxmisc>		
#include <sqlx>			

#define SVC_DISCONNECT  		2

new Handle:databaza, Handle:databaza_cvar, CONFIG_MENO, CONFIG_HESLO, user_webid[33], user_heslo[33], bool:user_vip[33], max_hracov
	
public plugin_init() 
{
	register_plugin("Web2 User System", "1.0", "Seky")	
	CONFIG_MENO			= register_cvar("cup_user_meno", 	"1") 							// on/off kontrola mena a hesla z databazi
	CONFIG_HESLO		= register_cvar("cup_user_heslo", 	"heslo") 						// text zadavajuci ako heslo ,musi byt nejaky cvar
	register_clcmd ("web2_who", "web2_who",	ADMIN_RCON, "web2_who zistime si idcka" );
	max_hracov = get_maxplayers()
	spoj_databazu() 
}
public plugin_natives()
{
	register_native("web2_id", "native_web2_id", 1)
}	
public native_web2_id(id)
{
	return user_webid[id];
}
public spoj_databazu() 
{	
	new temp[512], ErrorCode
	databaza_cvar = SQL_MakeDbTuple("10.0.1.2", "",  "", "cstrike")
	databaza 	  = SQL_Connect(databaza_cvar, ErrorCode, temp, 511)
   
	if(databaza == Empty_Handle)	{	
		log_amx(temp);
	}
}
public plugin_end() {
	if (databaza != Empty_Handle) {		
		SQL_FreeHandle(databaza) 
		SQL_FreeHandle(databaza_cvar) 
	}
}
public client_authorized(id)
{
	user_access(id)
}
public client_infochanged(id)
{
	new newname[32], oldname[32]	
	get_user_info(id, "name", newname, 31)
	get_user_name(id, oldname, 31)

	if (!equal(newname, oldname))
	{
		user_access(id)
	}
}
stock user_access(id)
{
	user_webid[id] = 0
	user_heslo[id] = 0
	user_vip[id] = false;
	
	if(is_user_hltv(id))	{
		return PLUGIN_HANDLED;
	}
	
// Meno a heslo
	if( get_pcvar_num(CONFIG_MENO))
	{			
		new pw_option[32], pw_string[32], pw_num					
		get_pcvar_string(CONFIG_HESLO, pw_option, 31)
		get_user_info(id, pw_option, pw_string, 31)
		pw_num = str_to_num(pw_string)
		
		user_search(id)
		if(!user_webid[id]) {
			return PLUGIN_HANDLED;
		} else	{				
			// Naslo a nezadal
			if(!pw_num || equal(pw_string[0], ""))
			{
				kick_player(id, "Tvoje herne meno je zarezervovane na webe.^nZadaj prosim heslo alebo si daj ine meno.^nPriklad: setinfo %s 123", pw_option)
				return PLUGIN_HANDLED
			}		
			if( user_heslo[id] != pw_num)
			{
				kick_player(id, "Nespravne heslo !^nPriklad do konzole: setinfo %s 123", pw_option)
				return PLUGIN_HANDLED
			}	
			//	ak ma vip	bool:user_vip[33]

			if(user_vip[id]) {
				set_user_flags(id, ADMIN_LEVEL_F)
			}
			// heslo rovnake ?			
		}
	} 
	return PLUGIN_CONTINUE
}
	/*~~~~~~~~~~~~  
	   - uzivatelia -  
	~~~~~~~~~~~~~*/

stock user_search(id)
{
	/*
		-1  	SQL EROR
		0	Nenaslo	
		>	Naslo
	*/
	if(databaza == Empty_Handle) {
		log_amx("Web2 User System error pri hladani uzivatela.");
		user_webid[id] = 0;
	}
	new meno[32], buffer[64], Handle:result
	get_user_name(id, meno,31)
		
	// Presne tak.....
	SQL_QuoteString (databaza, buffer, 63, meno) 
	result = SQL_PrepareQuery(databaza,"SELECT user_id, cs_heslo, m_vip FROM `cstrike`.`fusion_users` WHERE `cs_meno` LIKE '%s' AND m_amx='1'", meno ) 	   
	
	if (!SQL_Execute(result)) {	
		new eror[512]
		SQL_QueryError(result,eror,511)
		log_amx("[Mysql ERROR] %s",eror)	
		SQL_GetQueryString (result, eror, 511) 
		log_amx("[Mysql QUERY] %s", eror)
		SQL_FreeHandle(result)		
		return PLUGIN_HANDLED;		
	}  else if (SQL_NumResults(result) == 0) { 	
		// Nenaslo ....
		return PLUGIN_CONTINUE;	
	}					
												
	user_webid[id] = SQL_ReadResult(result, 0)
	user_heslo[id] = SQL_ReadResult(result, 1);
	//SQL_ReadResult(result, 2, meno, 1);
	
	if(SQL_ReadResult(result, 2))	{
		user_vip[id] = true;
	}
	SQL_FreeHandle(result)
	return PLUGIN_CONTINUE;
}
stock kick_player(id, const dovod[] , any:...) 
{
	new temp[256]
	vformat(temp, 255, dovod, 3)
	
	message_begin(MSG_ONE, SVC_DISCONNECT, {0,0,0}, id)
	write_string(temp)
	message_end() 
}
public web2_who(id,level,cid)
{
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	new meno[32]
	for(new hrac = 1; hrac <= max_hracov; hrac++)
	{								
		if (!is_user_connected(hrac))
			continue;	
		
		get_user_name(id, meno, 31)
		client_print( id,  print_console, "%s - %d - %s", meno,  user_webid[hrac], (user_vip[hrac]) ? "Ano" : "Nie")	
	}	
	return PLUGIN_CONTINUE
}