#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <zombieplague>
#include <engine> // na force 

#define fm_precache_sound(%1) 		engfunc(EngFunc_PrecacheSound,%1)
#define PLUGIN 	"[ZP] Karantena"
#define VERSION "1.0"
#define AUTHOR 	"Seky"

#define TASK_SOUND	 	200
#define TASK_HUD	 	300
#define TASK_POLOVKA 	400
#define MAX_ENTIT 		20

new bool:karantena, cvar_karantena, entity[MAX_ENTIT], cvar_hracov,
	status_icon, cvar_karantena_po, g_maxplayers,
	Float:polovicka, bool:ma_ikonu[33]
	
new const Sirena[] = { "zombie_plague/cham.wav"};

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("zp_karantena", "cmd_karantena", ADMIN_LEVEL_E);
	register_clcmd("zp_karantena_reload", "cmd_karantena_r", ADMIN_RCON);
	cvar_karantena = register_cvar("zp_karantena_sanca", "8")
	cvar_karantena_po = register_cvar("zp_karantena_polovica", "30.0")
	cvar_hracov = register_cvar("zp_karantena_hracov", "8")
	
	register_logevent("event_round_start", 2, "1=Round_Start")
	// status_icon = get_user_msgid("StatusIcon")
	g_maxplayers = get_maxplayers()
	karantena = false;
}
public plugin_precache() { fm_precache_sound(Sirena); }
public cmd_karantena(id, level, cid) {
	if (!cmd_access(id,level,cid,1)) return PLUGIN_HANDLED
	start_karantena();
	return PLUGIN_CONTINUE;
}
public event_round_start()  {	
	static nahoda;
	nahoda = get_pcvar_num(cvar_karantena);
	// Je vypnute ...
	if(!nahoda) return PLUGIN_CONTINUE;	
	// Nezhodlo sa ...
	if(nahoda > 1) {
		if(random_num(1, nahoda) != 1) return PLUGIN_CONTINUE;
	}
	// Minimalny pocet hracov
	nahoda = get_pcvar_num(cvar_hracov)
	if(nahoda > 1) {
		if(zivych() <= nahoda) return PLUGIN_CONTINUE;
	}
	set_task(2.0, "start_karantena");
}
public start_karantena()  {	
	if(karantena) return PLUGIN_CONTINUE;
	// Mame entity ?
	nacitaj_entity();
	if(!entity[0]) return PLUGIN_CONTINUE;
	// polovicka
	polovicka = get_pcvar_float(cvar_karantena_po);
	if(polovicka > 0.0) set_task(polovicka, "task_polovicka", TASK_POLOVKA)
	// ostatne ...
	karantena = true;
	nastav_entity();	
	// UI prvky
	hud_warning()
	PlaySound_loop()
	set_task(1.0, "hud_warning", TASK_HUD, _, _, "b")	
	set_task(12.0, "PlaySound_loop", TASK_SOUND, _, _, "b")	
	/*for(new i=1; i <= g_maxplayers; i++) {
		if(!is_user_alive(i)) continue;
		ma_ikonu[i] = true;
		efekt_icon(i, 2);
	}*/
	client_print(0, print_chat, "[G/L ZP] Je karantena, niektore steny su nerozbitne !")
	return PLUGIN_CONTINUE;
}
public hud_warning() {
	// chceme aby blikalo ....
	polovicka -= 1.0;
	set_hudmessage(128, 128, 128, 0.7, 0.2, 0, 0.1, 0.5, 0.0, 0.0, 4) 
	if(polovicka) {
		show_hudmessage(0, "Warning of Biohazard !^n          (%i)", floatround(polovicka))
	} else {								// pekne do stredu dame
		show_hudmessage(0, "Warning of Biohazard !")
	}	
}
public zp_round_ended(winteam) {
	if(task_exists(TASK_POLOVKA)) remove_task(TASK_POLOVKA);
	return PLUGIN_CONTINUE;
}
stock ukonci_karantenu()
{
	if(!karantena) return 0; 
	/*for(new i=1; i <= g_maxplayers; i++) {		
		if(!is_user_connected(i)) continue;
		if(!is_user_alive(i)) {
			ma_ikonu[i] = false;
			continue;
		}
		if(ma_ikonu[i]) {
			efekt_icon(i, 0);
			ma_ikonu[i] = false;
		}
	}*/
	remove_task(TASK_SOUND)	
	remove_task(TASK_HUD)
	karantena = false;
	return 1;
}
public plugin_natives() {register_native("get_karantena", "native_karantena", 1); }
public native_karantena() { return karantena; }
stock efekt_icon(id, typ) {
	message_begin(MSG_ONE, status_icon, {0,0,0}, id)  
	write_byte(typ)  
	write_string("dmg_rad")  
	write_byte(255)
	write_byte(0)
	write_byte(0)  
	message_end()  
}
public PlaySound_loop() { client_cmd(0, "spk ^"%s^"", Sirena); }
public cmd_karantena_r(id,level,cid) { 
	if (!cmd_access(id,level,cid,1)) return PLUGIN_HANDLED;
	entity[0] = 0; // kvoli kontrole
	if(nacitaj_entity()) {
		client_print(id, print_chat, "Karantena system je aktivny.")	
	} else {
		client_print(id, print_chat, "Karantena system je neaktivny.")	
	}
	for(new i=0; i < sizeof entity - 1; i++ ) {
		if(!entity[i]) break;
		if (!pev_valid(entity[i]) ) continue;
		client_print(id, print_chat, "%i", entity[i])
	}
	return PLUGIN_CONTINUE;
}
stock nacitaj_entity() {
	// Ak sa uz raz nacitavalo ...
	if(entity[0]) return 1; 
	
	// Cesty
	new cesta[256], mapname[32];
	get_datadir(cesta, 255);
	get_mapname(mapname, 31);
	format(cesta, 255, "%s/karantena/%s.ini", cesta, mapname);
	// Subor
	if( !file_exists(cesta) ) return 0;
	
	// Otvarame
	new subor = fopen(cesta, "rt");
	if(!subor) return 0;
	
	// Nacitavame udaje ...
	new buffer[11], pocet_entit = 0	
	while( !feof(subor) ) {
		fgets(subor, buffer, 10); // jeden riadok	
		if(buffer[0] == ';' || !buffer[0]) continue;
		entity[pocet_entit] = str_to_num(buffer);
		pocet_entit++;
		if(pocet_entit = MAX_ENTIT-1) break;
	}	
	fclose(subor);
	return 1;
}
stock nastav_entity() {
	for(new i=0; i < MAX_ENTIT - 1; i++ ) {
		if(!entity[i]) break;
		if(!pev_valid(entity[i]) ) continue;
		// Objekt rozbily ...
		/*if(!pev(entity[i], pev_solid)) {
			set_pev(entity[i], pev_effects, 0.0);
		}*/
		
		// Vlastnosti ...
		set_pev(entity[i], pev_solid, SOLID_BBOX); // neprechodne ...
		// pev(index, pev_takedamage, val)
		// return (val == DAMAGE_NO);

		set_pev(entity[i], pev_health, 1000000.0); // nesmrtelne.....
	}
	return PLUGIN_CONTINUE;
}
public task_polovicka() {
	ukonci_karantenu();
	// Ziadny hrac ?
	// new obet = najst_obet();
	// if(!obet) return 0;
	
	// Obnovyme entity
	for(new i=0; i < MAX_ENTIT - 1; i++ ) {
		if(!entity[i]) break; 
		if(!pev_valid(entity[i]) ) continue;
		
		// Novy system pouzitia len skryjeme :)
		set_pev(entity[i], pev_effects, 128);
		set_pev(entity[i], pev_solid, SOLID_NOT);
		// fake_touch(entity[i], obet);
		// force_use(obet, entity[i]);
	}
	return 1;
}
stock najst_obet() {
	// Potrebujeme najst "obet"
	for(new i=1; i <= g_maxplayers; i++) {
		if(is_user_alive(i)) return i;
	}
	// Ziadny hrac ?
	return 0;
}	
stock zivych() {
	static pocet, i;
	pocet = 0;
	for(i=1; i <= g_maxplayers; i++) {
		if(is_user_alive(i)) pocet++;
	}
	return pocet;
}