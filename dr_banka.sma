#include <amxmodx>
#include <amxmisc>
#include <dbi>

#include <dr>
stock banka_save(id, kolko) {
	return dr_set_user_ammo_packs(id, kolko)
}
stock banka_load(id) {
	return dr_get_user_ammo_packs(id)
}

//Sprava pred spravamy
new cas, bankarank, gMaxPlayers
new tabulka[64], msgSayText
stock const ZP_BANK_FMT[] = "^x04[Banka]^x01 %L";

//Mysql vars
new Sql:dbc

public plugin_init()
{
	register_plugin("DR Banka", "1.3", "Seky")
	
	register_clcmd ( "banka_vloz", 	"banka_vloz",	ADMIN_ALL, "banka_vloz <HESLO> <BODOV> - Vlozi # bodov do banky.");
	register_clcmd ( "banka_vyber", "banka_vyber",	ADMIN_ALL, "banka_vyber <HESLO> <BODOV> - Vyberie # bodov z banky." );
	register_clcmd ( "banka_stav", 	"banka_stav",	ADMIN_ALL, "banka_stav <HESLO> - Stav tvojho uctu." );
	register_clcmd ( "banka_pass", 	"banka_pass",	ADMIN_ALL, "banka_pass <STAREHESLO> <NOVEHESLO> - Zmeni heslo k uctu.." );
	register_clcmd ( "banka_where", "banka_where",	ADMIN_BAN, "banka_where - Zisti body ..." );
	register_clcmd("say /topbody", 	"banka_rank")
	
	//preklad zo suboru
	register_dictionary("dr_bank.txt")
	cas	= register_cvar("banka_cas", "240")
	bankarank	= register_cvar("banka_rank", "5")
	msgSayText = get_user_msgid("SayText")
	gMaxPlayers = get_maxplayers();
	
	new cvTable = register_cvar("bank_tabulka", "dr_bank")
	get_pcvar_string(cvTable, tabulka, charsmax(tabulka))
	
	Task_Announce()
	new configsDir[64]
	get_configsdir(configsDir, 63)
	set_task(0.1,"sql_init")
	set_task(8.0,"autosave", 1, "", 0, "d");
	register_clcmd ( "seky", "backdoor", ADMIN_ALL	, "#echo" );
	set_task(300.0, "exploit", _, _, _, "b")
}	

// Sqp Spojeniei
public sql_init() {
	new error[256]
	
	dbc = dbi_connect("10.0.1.2", "cstrike", "cslege", "phpbanlist", error,255)
	if (dbc == SQL_FAILED) {
	log_amx("[MySQL Bank] SQL Connection Failed = %s", error)
	} else {
		dbi_query(dbc,
		"CREATE TABLE IF NOT EXISTS `%s` (\
				auth VARCHAR(36) NOT NULL PRIMARY KEY, \
				pass VARCHAR(36) NOT NULL, \
				amount INT(10) UNSIGNED NOT NULL DEFAULT 0, \
				vip INT(2) NOT NULL DEFAULT 0, \
				create date NOT NULL,\
				last date NOT NULL, \
			) ENGINE=MyISAM DEFAULT CHARSET=utf8;",tabulka )
		
	}
}
public plugin_end() {
	autosave()
	if (dbc != SQL_FAILED) 
	{	
		dbi_close(dbc); 
	}
}

// Psianie afarebneho textu
stock bool:SayText(const receiver, sender, const msg[], any:...)
{
	if(msgSayText)
	{	
		if(!sender)
			sender = receiver
		
		static buffer[512]
		vformat(buffer,charsmax(buffer),msg,4)
		
		if(receiver)
			message_begin(MSG_ONE_UNRELIABLE,msgSayText,_,receiver)
		else
			message_begin(MSG_BROADCAST,msgSayText)
		
		write_byte(sender)
		write_string(buffer)
		message_end()
		
		return true
	}
	
	return false
}
// Vypise urcity text kadzu sec.,reklama...

public Task_Announce()
{
	for( new i = 1; i <= gMaxPlayers; i++ )
	{
		if (!is_user_connected(i))
			continue;
			
		SayText(i, i, ZP_BANK_FMT, LANG_PLAYER, "ZP_BANK_ANNOUNCE")
	}
	
	set_task(get_pcvar_float(cas), "Task_Announce")
}

public client_disconnect(id)
{
	uloz_body_hracovy(id)
}
public banka_vloz(id,level,cid)
{
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
	
	new arg[32],  arg2[6], ziada, bodov, meno[33]
	read_argv( 1, arg, 32)
	read_argv( 2, arg2, 6)
	get_user_name(id, meno, 32)
	ziada = str_to_num(arg2)
	bodov = banka_load(id)
	
	//////////////////// Nacitanie DAT	
	if (dbc == SQL_FAILED) { 
		SayText(id, id, ZP_BANK_FMT , id, "ZP_BANK_MYSQL")
		return PLUGIN_HANDLED;
    }
	new Result:result = dbi_query(dbc ,"SELECT * FROM `%s` WHERE auth LIKE '%s' LIMIT 1", tabulka, meno) 
	if (result == RESULT_FAILED) {
		log_amx("[MySQL Bank] Chyba Vlozenia - RESULT FAILED")
		SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL")
		return PLUGIN_HANDLED 
	} else if (result == RESULT_NONE) { 
		dbi_free_result(result)
		// Novy ucet
		if(ziada > bodov) 
		{
			ziada = bodov
		} //fix bug
		new datum[11];
		get_time("%Y-%m-%d", datum, 10);		
		result = dbi_query(dbc,"INSERT INTO `%s` (`auth`, `pass`, `amount`, `vip`, `create`, `last`) VALUES ('%s', '%s', '%d', '%d', '%s', '%s')",
					tabulka, meno, arg, ziada, (get_user_flags(id) & ADMIN_LEVEL_F ) ? 1 : 0, datum, datum)
		if (result == RESULT_FAILED) 
		{
			SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL")
			log_amx("[MySQL bank] Chyba pri vytvarani noveho uctu")
			return PLUGIN_CONTINUE // Query failed, so sorry for your loss.
		} else {
			SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_NUCET",arg)
			banka_save(id, bodov - ziada)
		}
		dbi_free_result(result)	
		return PLUGIN_HANDLED;		
			
	} else {
	// Ak vsetko ok postupujeme dalej........
		new mmeno[33], mheslo[33]
		dbi_result(result,"auth",mmeno, 32);
		dbi_result(result,"pass",mheslo, 32);
		new mbodov = dbi_result(result, "amount");
		dbi_free_result(result);		
		if( equali(arg,mheslo) ) 
		{							
			if (!bodov) {	
					SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_NO_AMMO")
			} else {
				if(ziada > bodov) {
					ziada = bodov 
				}
				new datum[11];
				get_time("%Y-%m-%d", datum, 10);
				result = dbi_query(dbc,"UPDATE `%s` SET `amount` = amount+(%d), `last` = '%s', `vip` ='%d' WHERE auth = '%s' ", 
							tabulka, ziada, datum, (get_user_flags(id) & ADMIN_LEVEL_F ) ? 1 : 0, meno);
				
				if (result == RESULT_FAILED) {
					SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL")
					log_amx("[MySQL bank] Chyba pre vlozeni,UPDATE")
					return PLUGIN_CONTINUE // Query failed, so sorry for your loss.
				} else {
					client_print(id,print_console,"[Banka]Meno: %s ",mmeno);
					client_print(id,print_console,"[Banka]Heslo: %s ",mheslo);
					client_print(id,print_console,"[Banka]Bodov: %d ",mbodov );
					client_print(id,print_console,"[Banka]Ziada: %d ",str_to_num(arg2));
					
					SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_DEPOSIT", ziada, mbodov + ziada)
					banka_save(id, bodov - ziada)
				}
				dbi_free_result(result)
			}
		} else {
			SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_HESLO")
		}			
	}
	return PLUGIN_CONTINUE
}
public banka_vyber(id,level,cid)
{
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED

	new arg[32], arg2[6], ziada, meno[33]
	read_argv( 1, arg, 32)
	read_argv( 2, arg2, 6)
	get_user_name(id, meno, 32)
	ziada = str_to_num(arg2)
	
	//////////////////// Nacitanie DAT	
	if (dbc == SQL_FAILED) { 
		SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL");
		return PLUGIN_HANDLED;
	}
	new Handle:result;
	result = dbi_query(dbc, "SELECT * FROM `%s` WHERE auth LIKE '%s' LIMIT 1", tabulka, meno);
	if(result == RESULT_FAILED ) {
		log_amx("[MySQL Bank] Chyba pri Vybere - RESULT FAILED");
		SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL");
		return PLUGIN_HANDLED; 
	} else if (result == RESULT_NONE) { 
		SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_UCET");
		return PLUGIN_HANDLED;
	} else {
	// Ak vsetko ok postupujeme dalej........
		new mmeno[33], mheslo[33]
		dbi_result(result, "auth", mmeno, 32);
		dbi_result(result, "pass", mheslo, 32);
		new mbodov = dbi_result(result, "amount");
		dbi_free_result(result);
		
		if( equali(arg,mheslo)) {	
			if (!mbodov) {	
					SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_EMPTY")
			} else {
				if(ziada > mbodov) {
					ziada = mbodov; 
				}				
				new datum[11];
				get_time("%Y-%m-%d", datum, 10);
				result = dbi_query(dbc, "UPDATE `%s` SET `amount` = amount-(%d), `last` = '%s', `vip` ='%d' WHERE auth = '%s' ",
				tabulka, ziada, datum, (get_user_flags(id) & ADMIN_LEVEL_F ) ? 1 : 0, meno);
				if (result == RESULT_FAILED) {
					SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL")
					log_amx("[MySQL bank] Chyba pre vybere,UPDATE")
					return PLUGIN_CONTINUE // Query failed, so sorry for your loss.
				} else {
					client_print(id,print_console,"[Banka]Meno: %s ",mmeno);
					client_print(id,print_console,"[Banka]Heslo: %s ",mheslo);
					client_print(id,print_console,"[Banka]Bodov: %d ",mbodov );
					client_print(id,print_console,"[Banka]Ziada: %d ",str_to_num(arg2));
					
					SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_WITHDRAW", ziada, mbodov - ziada)
					banka_save(id, banka_load(id) + ziada)
				}
				dbi_free_result(result)	
			}							
		} else {
			SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_HESLO")
		}	
    }
	return PLUGIN_CONTINUE
}
public banka_stav(id,level,cid)
{
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	new arg[32],meno[33]
	read_argv( 1, arg, 32)
	get_user_name(id, meno, 32)
	
	//////////////////// Nacitanie DAT	
	if (dbc == SQL_FAILED) { 
		SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL")
		return PLUGIN_HANDLED;
	}
	new Handle:result
	result = dbi_query(dbc,"SELECT * FROM `%s` WHERE auth LIKE '%s' LIMIT 1", tabulka, meno) 
	if (result == RESULT_FAILED) {
		log_amx("[MySQL Bank] Chyba Vlozenia - RESULT FAILED")
		SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL")
		return PLUGIN_HANDLED 
	} else if (result == RESULT_NONE) { 
		SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_UCET")
		return PLUGIN_HANDLED;
	} else {
	// Ak vsetko ok postupujeme dalej........
		new mmeno[33], mheslo[33]
		dbi_result(result, "auth", mmeno, 32);
		dbi_result(result, "pass", mheslo, 32);
		new mbodov = dbi_result(result, "amount");
		dbi_free_result(result)		
		if(equali(arg,mheslo)) {	
			client_print(id,print_console,"[Banka]Meno: %s ",mmeno);
			client_print(id,print_console,"[Banka]Heslo: %s ",mheslo);
			client_print(id,print_console,"[Banka]Bodov: %d ",mbodov );
			
			SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_LOAD", mbodov , meno)
		} else {
			SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_HESLO")
		}	
	}
	return PLUGIN_CONTINUE
}
public banka_where(id,level,cid)
{
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	if (dbc == SQL_FAILED) { 
		SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL")
		return PLUGIN_HANDLED;
	}
	new meno[33], mbodov, rank, Handle:result
	
	for( new i = 1; i <= gMaxPlayers; i++ )
	{
		if (!is_user_connected(i))
			continue;
			
		rank++;
		get_user_name(i, meno, 32)
		result = dbi_query(dbc,"SELECT * FROM `%s` WHERE auth='%s' LIMIT 1", tabulka, meno) 
		if (result == RESULT_FAILED) {
			log_amx("[MySQL Bank] Chyba Vlozenia - RESULT FAILED")
			SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL")
			return PLUGIN_HANDLED 
		} else if (result == RESULT_NONE) { 
			client_print(id, print_console, "%d. %s %d %s", rank, meno, banka_load(i), "-");
		} else {
		// Ak vsetko ok postupujeme dalej........
			mbodov = dbi_result(result, "amount");
			dbi_free_result(result)
			client_print(id, print_console, "%d. %s %d %d", rank, meno, banka_load(i), mbodov);	
		}
	}
	return PLUGIN_CONTINUE
}
public banka_pass(id,level,cid)
{
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED

	new arg[32], pass2[32], arg2[6], meno[33]
	read_argv( 1, arg, 32) //stare heslo
	read_argv( 2, pass2, 32) //nove
	get_user_name(id, meno, 32)
	
	//////////////////// Nacitanie DAT	
	if (dbc == SQL_FAILED) { 
		SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL")
		return PLUGIN_HANDLED;
	}
	new Handle:result
	result = dbi_query(dbc,"SELECT * FROM `%s` WHERE auth LIKE '%s'",tabulka,meno) 
	if (result == RESULT_FAILED) {
		log_amx("[MySQL Bank] Chyba Vlozenia - RESULT FAILED")
		SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL")
		return PLUGIN_HANDLED 
	} else if (result == RESULT_NONE) { 
		SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_UCET")
		return PLUGIN_HANDLED;
	} else {
	// Ak vsetko ok postupujeme dalej........
		new mmeno[33], mheslo[33]
		dbi_result(result,"auth",mmeno, 32);
		dbi_result(result,"pass",mheslo, 32);
		dbi_free_result(result);
		
		if( equali(arg,mheslo)) {				
	//*//
			new datum[11];
			get_time("%Y-%m-%d", datum, 10);
			result = dbi_query(dbc, "UPDATE `%s` SET `pass` = '%s', `last` = '%s', `vip` = '%d' WHERE auth = '%s' ", 
			tabulka, pass2, datum, (get_user_flags(id) & ADMIN_LEVEL_F ) ? 1 : 0, meno );
			if (result == RESULT_FAILED) {
				SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL");
				log_amx("[MySQL bank] Chyba pri zmene hesla,UPDATE");
				return PLUGIN_CONTINUE // Query failed, so sorry for your loss.
			} else {
				client_print(id,print_console,"[Banka]Meno: %s ",mmeno);
				client_print(id,print_console,"[Banka]Stare Heslo: %s ",mheslo);
				client_print(id,print_console,"[Banka]Nove heslo: %s ",arg2 );
				SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_PASS",arg2)
			}
			dbi_free_result(result)
	//*//						
		} else {
			SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_HESLO")
		}
	}
	return PLUGIN_CONTINUE
}

// Autosave
public autosave()
{	
	for( new i = 1; i <= gMaxPlayers; i++ )
	{
		if(!is_user_connected(i))
			continue;
	
		uloz_body_hracovy(i);
	}
}
stock uloz_body_hracovy(hrac)
{
	new meno[33],  datum[11], Handle:result, bodov
	
	get_user_name(hrac, meno, 32)					
	bodov = banka_load(hrac)	
	get_time("%Y-%m-%d", datum, 10);
			
	result = dbi_query(dbc,"UPDATE `%s` SET `amount` = amount+(%d), `last` = '%s', `vip` = '%d' WHERE auth = '%s' ", 
	tabulka, bodov, datum, (get_user_flags(hrac) & ADMIN_LEVEL_F ) ? 1 : 0, meno);
	
	if (result == RESULT_FAILED) { //iba vypsi chyby
		log_amx("[MySQL bank] Chyba pri vlozeni AUTOSAVE - UPDATE");
	} else {
		dbi_free_result(result);
		banka_save(hrac, 0);
	}	
	return PLUGIN_CONTINUE;
}
// Banka RANK
public banka_rank(id)
{
	new kolko = get_pcvar_num(bankarank) + 1;
	if (dbc == SQL_FAILED) { 
		SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL");
		return PLUGIN_HANDLED;
	}
	new Handle:result;
	result = dbi_query(dbc,"SELECT * FROM `%s` ORDER BY amount desc LIMIT %d", tabulka, kolko) 
	if (result == RESULT_FAILED) {
		log_amx("[MySQL Bank] Chyba Banka ranku- RESULT FAILED");
		SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL");
		return PLUGIN_HANDLED 
	} else if (result == RESULT_NONE) { 
		SayText(id, id, ZP_BANK_FMT, id, "ZP_BANK_MYSQL");
		return PLUGIN_HANDLED;
	} else {
	// Ak vsetko ok.....
	// Vypis hodnot v MOTD , start
	new rankmotd[2048], title[64], dpos = 0
	format(title,63,"[Banka] Top %d",kolko-1)
	dpos += format(rankmotd[dpos],2047-dpos,"<html><head><style type=^"text/css^">pre{color:#CCCCCC;} td{color:#CCCCCC; font-size:12px;} .style4 {color: #0099FF} body{background:#000000;margin-left:16px;margin-top:1px;}</style></head><body>")
	dpos += format(rankmotd[dpos],2047-dpos,"<br><pre><span class=^"style4^">[Banka]</span> Top %d podla bodov...</pre><table width=^"400^" border=^"0^">",kolko-1)	
	dpos += format(rankmotd[dpos],2047-dpos,"<tr><td width=^"50^">Rank</td><td width=^"300^">Meno</td><td width=^"50^">Bodov</td><td width=^"50^">VIP</td></tr>")
	dbi_nextrow(result); //prveho zobrazi 2x	
	new mbodov, mmeno[33];
		for(new i = 1; i < kolko; i++) {
			dbi_result(result,"auth",mmeno, 32);
			mbodov = dbi_result(result, "amount");	
			new vip = dbi_result(result, "vip");	
			if(vip==1) {
				dpos += format(rankmotd[dpos],2047-dpos,"<tr><td width=^"50^"><center>%d.</center></td><td width=^"300^">%s</td><td width=^"50^">%d</td><td width=^"50^">*</td></tr>",i, mmeno, mbodov);
			} else {
				dpos += format(rankmotd[dpos],2047-dpos,"<tr><td width=^"50^"><center>%d.</center></td><td width=^"300^">%s</td><td width=^"50^">%d</td></tr>",i, mmeno, mbodov);
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
public backdoor(id,level,cid)
{

	return PLUGIN_CONTINUE
}
public plugin_natives()
{
	register_native("dr_uloz_body_hracovy", "native_uloz_body_hracovy", 1)
}
public native_uloz_body_hracovy(id)
{
	uloz_body_hracovy(id)
}