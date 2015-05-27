#include <amxmodx>
#include <amxmisc>
/*
	Co nemaju STEAM :
	STEAM_ID_LAN p47
	STEAM_ID_PENDING p48

	STEAM_xx:xx:xx
	get_user_authid ( index, authid[], len ) // 35max char
	STEAM_0:0:26635210
*/

#define DP_AUTH_NONE 		0
#define DP_AUTH_DPROTO		1
#define DP_AUTH_STEAM		2
#define DP_AUTH_STEAMEMU	3
#define DP_AUTH_REVEMU		4
#define DP_AUTH_OLDREVEMU	5
#define DP_AUTH_HLTV		6

#define NONSTEAM 			false
#define STEAM 				true

new bool:JeSteam[33], DP_Protokol[33], DP_Type[33],
	pcv_dp_r_protocol, pcv_dp_r_id_provider
	
public plugin_init() {
	register_plugin("DPEngine", "1.0", "Seky");
	pcv_dp_r_protocol = get_cvar_pointer ("dp_r_protocol");
	pcv_dp_r_id_provider = get_cvar_pointer ("dp_r_id_provider");
	register_concmd("amx_ip", "dpwho", ADMIN_ALL, "- informacie o hracoch")
	register_concmd("dp_who", "dpwho", ADMIN_ALL, "- informacie o hracoch")
	
	register_clcmd("say /test", "zachit_test")
	register_clcmd("say_team /test", "zachit_test")	
	register_clcmd("say /steam", "zachit_steam")
	register_clcmd("say_team /steam", "zachit_steam")
}
public plugin_natives() {
	register_native("is_steam", "native_is_steam", 1);
	register_native("is_p47", "native_is_p47", 1);
	register_native("is_gecompatch", "native_is_gecompatch", 1);
	register_native("dp_protokol", "native_dp_protokol", 1);
	register_native("dp_type", "native_dp_type", 1);
}
public client_connect(id) { return engine_start(id); }
public client_disconnect(id) { return engine_end(id); }
public native_is_steam(const id) { return JeSteam[id]; }
public native_is_p47(const id) { return DP_Protokol[id] == 47; }
public native_dp_protokol(const id) { return DP_Protokol[id]; }
public native_is_gecompatch(const id) { return DP_AUTH_REVEMU == DP_Type[id]; }
public native_dp_type(const id) { return DP_Type[id]; }
/*
	Je vyslovne dolezite !
	* Kontrolovat ci je uzivatel pripojeny.
	* Ci nahodou nieje BOT, HLTV, ...
	Inak vysledky mozu byt skreslene.
*/
stock engine_end(const id) {
	JeSteam[id] = NONSTEAM;
	DP_Protokol[id] = DP_AUTH_NONE;
	DP_Type[id] = DP_AUTH_NONE;
	return PLUGIN_CONTINUE;
}
stock engine_start(id) {	
	//if (!pcv_dp_r_protocol || !pcv_dp_r_id_provider) return PLUGIN_CONTINUE;
	//server_cmd("dp_clientinfo %d", id);
	//server_exec();
	// Parsuj
	DP_Protokol[id] = 48; // get_pcvar_num(pcv_dp_r_protocol);
	DP_Type[id] = DP_AUTH_NONE // get_pcvar_num(pcv_dp_r_id_provider);
	new steamcislo[37]
	get_user_authid(id, steamcislo, 36);
	//JeSteam[id] = ( DP_Type[id] == DP_AUTH_STEAM || DP_Type[id] == DP_AUTH_REVEMU || DP_Type[id] == DP_AUTH_HLTV)
	JeSteam[id] = ( 
			!equal(steamcislo, "STEAM_ID_LAN") 
			&& 	!equal(steamcislo, "STEAM_ID_PENDING") 
			&& 	!equal(steamcislo, "VALVE_ID_LAN") 
			&& 	!equal(steamcislo, "VALVE_ID_PENDING") 
			&& 	!equal(steamcislo, "STEAM_666:88:666") 
	);
	return PLUGIN_CONTINUE;
}
public dpwho(id, level, cid) {
	if (!cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED
	new players[32], inum, cl_on_server[64], authid[35], name[32], flags, ips[32], auth_prov_str[33]
	new lImm[16], lRes[16],lYes[16], lNo[16]
	
	format(lImm, 15, "imunita")
	format(lRes, 15, "rezer")
	format(lYes, 15, "YES")
	format(lNo, 15, "NO")
	
	get_players(players, inum)
	format(cl_on_server, 63, "%L", id, "CLIENTS_ON_SERVER")
	console_print(id, "^n%s:^n #  %-16.15s %-20s %-20s %-8.7s %-8.7s %-8.7s %-8.7s", 
		cl_on_server, 
		"Meno", 
		"steam cislo", 
		"IP Adresa", 
		lImm, 
		lRes, 
		"vip",
		"protokol"
	)
	
	for (new a = 0; a < inum; ++a) {
		switch (DP_Type[id]) 
			{
				case DP_AUTH_NONE: copy(auth_prov_str, 32, "N/A") //slot is free
				case DP_AUTH_DPROTO: copy(auth_prov_str, 32, "dproto")
				case DP_AUTH_STEAM: copy(auth_prov_str, 32, "Steam(Native)")
				case DP_AUTH_STEAMEMU: copy(auth_prov_str, 32, "SteamEmu")
				case DP_AUTH_REVEMU: copy(auth_prov_str, 32, "revEmu")
				case DP_AUTH_OLDREVEMU: copy(auth_prov_str, 32, "old revEmu")
				case DP_AUTH_HLTV: copy(auth_prov_str, 32, "HLTV")	
				default: copy(auth_prov_str, 32, "Error") //-1 if slot id is invalid	
			}
		get_user_authid(players[a], authid, 35)
		get_user_name(players[a], name, 31)
		get_user_ip (players[a], ips, 31) 
		flags = get_user_flags(players[a])
		console_print(id, "%2d  %-16.15s %-20s %-20s %-8.7s %-8.7s %-8.7s %-8.7s", 
			players[a], 
			name, 
			JeSteam[id] ? authid : "NON-STEAM", 
			ips,
			(flags&ADMIN_IMMUNITY) ? lYes : lNo, 
			(flags&ADMIN_RESERVATION) ? lYes : lNo, 
			(flags&ADMIN_LEVEL_F) ? lYes : lNo, 
			auth_prov_str
		)
	}
	
	console_print(id, "%L", id, "TOTAL_NUM", inum)
	get_user_authid(id, authid, 35)
	get_user_name(id, name, 31)
	log_amx("Cmd: ^"%s<%d><%s><>^" ask for players list", name, get_user_userid(id), authid) 	
	return PLUGIN_CONTINUE;
}
public zachit_test(id) {
	if( JeSteam[id] ) {
		client_print(id, print_chat,"[PATCHv42] Patch si spravne nainstaloval.");
	} else {
		client_print(id, print_chat,"[PATCHv42] Patch si zrejme nainstaloval do zlej zlozky.");
		client_print(id, print_chat,"[PATCHv42] Pozri si navod www.cs.gecom.sk/patch");
	}
	return PLUGIN_CONTINUE;
}
public zachit_steam(id) {
	if( JeSteam[id] ) {
		new authid[35]
		get_user_authid(id, authid, 35)
		client_print(id, print_chat,"[PATCHv42] Tvoje cele steam cislo: %s", authid);
	} else {
		client_print(id, print_chat,"[PATCHv42] Patch si zrejme nainstaloval do zlej zlozky alebo nenainstaloval.");
		client_print(id, print_chat,"[PATCHv42] Pozri si navod www.cs.gecom.sk/patch");
	}
	return PLUGIN_CONTINUE;
}