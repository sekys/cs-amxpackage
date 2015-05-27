#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <zombieplague>
#include <hamsandwich>
#include <engine>

#define fm_precache_sound(%1) 	engfunc(EngFunc_PrecacheSound,%1)
#define TASK_HUD	 			300
#define TASK_CONTROL	 		301
#define CAS_KONIEC	 			-100000.0
#define NEXT_THINK	 			0.3

#define PLUGIN 				"[ZP] Escape functions"
#define VERSION 			"1.0"
#define AUTHOR 				"Seky"

enum EscType {
	E_NONSTARTED = 0,
	E_STARTED,
	E_WAITING,
	E_FINISHING
};

new const NADPIS[] = "^x04[G/L ZP]^x01";
new const TxTSound[][] = { 
	"Ok chlapci, pomoc je na ceste",
	"Heyyy pomoc je na ceste.",
	"Ok ....h... pomoc je na ceste."
}
new const Sound[][] = { 
	"zombie_plague/radio/radio1.wav",
	"zombie_plague/radio/radio2.wav",
	"zombie_plague/radio/radio3.wav"
};

new msgid_say, g_maxplayers, EscType:status,
	cvar_active, bool:active,  				// Je cely system aktivny ?
	F_button, 								// Na snifovanie stisknutia .....a oboznamy kto spravyl ....
	Float:F_casovac, Float:KoloCasovac,  	// Celkovy F_casovac , zobrazime odpocet .......vrtulnik prisiel
	bool:F_zombie_volat, 					// Mozu zombici, nemesis, witch, matka, volat vrtulnik ....
	Ftransport, 							// Entita vrtunlika ...
	Float:F_radius 			 				// Zastavit vrtulnik ak po polacse vo vrtulniku nieje CT
	
/* Priklad v suboru ...
;42 - tlacidlo entita
;25.0 - cas prichodu
;0 - zombie volat nemozu
;5 - entita transportu
;50.0 - radius na polcas, ci zastavit vrtulnik
*/

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("zp_escape_reload", "cmd_escape", ADMIN_RCON);
	RegisterHam(Ham_Use, "func_button", "button_use")
	
	cvar_active = register_cvar("zp_escape", "1")
	g_maxplayers = get_maxplayers()
	msgid_say = get_user_msgid("SayText");
	
	active = nacitaj_vlastnosti();
	return PLUGIN_CONTINUE;
}
public plugin_precache() {
	for (new i = 0; i < sizeof Sound; i++) fm_precache_sound(Sound[i]); 	
}
public cmd_escape(id,level,cid) { 
	if (!cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED;
	active = false; // kvoli kontrole a uplne vsetko vypneme
	// Je to uplne vypnute ...
	if(!get_pcvar_num(cvar_active)) return PLUGIN_CONTINUE;
	
	active = nacitaj_vlastnosti();
	if(active) {
		client_print(id, print_chat, "Escape system je aktivny.")	
	} else {
		client_print(id, print_chat, "Escape system je neaktivny.")	
	}	
	return PLUGIN_CONTINUE;
}
public zp_round_ended(winteam) {
	status = E_NONSTARTED;
	if(task_exists(TASK_CONTROL)) remove_task(TASK_CONTROL);
	if(task_exists(TASK_HUD)) remove_task(TASK_HUD);
	KoloCasovac = CAS_KONIEC;
	return PLUGIN_CONTINUE;
}
stock nacitaj_vlastnosti() {
	// Cesty
	new cesta[256], mapname[32];
	get_datadir(cesta, 255);
	get_mapname(mapname, 31);
	format(cesta, 255, "%s/escape/%s.ini", cesta, mapname);
	// Subor
	if( !file_exists(cesta) ) return false;
	// otvarame
	new subor = fopen(cesta, "rt");
	if(!subor) return false;
	// nacitavame udaje ...
	new buffer[11], riadok = 0	
	while( !feof(subor) ) {
		fgets(subor, buffer, 10); // jeden riadok	
		if(buffer[0] == ';' || !buffer[0]) continue; // take nepocitame
		
		// Parsujeme .....
		switch(riadok) {
			case 0:	{
				F_button = str_to_num(buffer);
				if(!pev_valid(F_button) ) {
					fclose(subor);
					return false; // nastavy ACTIVE na false
				}
			}	
			case 1:	{
				F_casovac = str_to_float(buffer);
			}	
			case 2:	{
				F_zombie_volat = (str_to_num(buffer)==1) ? true : false;
			}
			case 3:	{
				Ftransport = str_to_num(buffer);
				if(!pev_valid(Ftransport) ) {
					fclose(subor);
					return false; // nastavy ACTIVE na false
				}
			}	
			case 4:	{
				F_radius = str_to_float(buffer);
			}
			default : { break; }
		}
		++riadok;
	}	
	fclose(subor);
	return (riadok > 0) ? true : false;
}	
public button_use(ent, caller, activator, use_type, Float:value)
{
	if(!active) return HAM_IGNORED;
	if(F_button != ent) return HAM_IGNORED;
	if(!is_user_connected(caller)) return HAM_IGNORED;
	if(!is_user_alive(caller)) return HAM_IGNORED;
	
	// Opakovane stlacanie ....
	if(status > E_NONSTARTED) {
		client_print(caller, print_chat, "[G/L ZP] Nemozes tlacidlo opakovane pouzit.")
		return HAM_SUPERCEDE;
	}
	if(!MozuZombieVolat(caller)) {
		client_print(caller, print_chat, "[G/L ZP] Zombici, Nemesis, ...nemozu pouzit toto tlacidlo.")
		return HAM_SUPERCEDE;
	}
	// Spustame ...
	start_escape_action(caller, ent)
	return HAM_IGNORED;
}
stock MozuZombieVolat(const id) {
	// Maju povolene
	if(F_zombie_volat) return true;
	return (!special_mod(id));
}
stock special_mod(const id) {
	// Specialne mody ...
	if(zp_get_user_last_zombie(id)) return false;
	if(zp_get_user_zombie(id)) return true;
	if(zp_get_user_nemesis(id)) return true;
	if(zp_get_user_witch(id)) return true;
	if(zp_get_user_mom(id)) return true;
	if(zp_get_user_survivor(id)) return true;
	return false;
}
stock start_escape_action(const id, const ent) {
	// Info
	static nahoda, name[32]
	nahoda = random_num(0, sizeof Sound - 1);
	engfunc(EngFunc_EmitSound, ent, CHAN_AUTO, Sound[nahoda], 1.0, ATTN_NORM, 0, PITCH_NORM);
	get_user_name(id, name, 31)
	oznam("%s %s: %s", NADPIS, name, TxTSound[nahoda]);
	status = E_STARTED;
	
	// Hud system
	KoloCasovac = F_casovac;
	hud_cyklus();
	set_task(1.0, "hud_cyklus", TASK_HUD, _, _, "b")
	return PLUGIN_CONTINUE;
}
public hud_cyklus() {
	// Pekne sa nam cykli kazdu 1 sekundu
	set_hudmessage(128, 128, 128, 0.7, 0.2, 0, 0.1, 0.9, 0.0, 0.0, 4) 
	nastal_polcas();
	
	// Polcas ?
	switch(status) {
		case E_STARTED: {
			show_hudmessage(0, "Pomoc pride: %i sec", floatround(KoloCasovac))
		}		
		case E_WAITING: {
			show_hudmessage(0, "Pomoc caka na CT !.!")
		}		
		case E_FINISHING: {
			show_hudmessage(0, "Pomoc odchadza !.!")
		}
	}
}
stock nastal_polcas() {
	if(status != E_STARTED) return;
	KoloCasovac -= 1.0;	
	// Nastala zmena		
	if(KoloCasovac < 1.0) {
		if(F_radius > 0.0 && pev_valid(Ftransport)) {
			// Prve defaultne hodnoty aby sme objekt zastavily ....
			TransportSTOP();
			oznam("%s %s", NADPIS, "Pomoc prisla, bez ludi neodide !");
			set_task(NEXT_THINK, "ControlOfEscape", TASK_CONTROL, _, _, "b");
		} else {	
			oznam("%s %s", NADPIS, "Pomoc prisla ale odchadza, ponahlaj sa !");
			status = E_FINISHING;
		}
	}
}
public ControlOfEscape() {
	static NiektoJeVoVnutri;
	NiektoJeVoVnutri = JePrazdny(Ftransport);
	
	// Stoji a nieje prazdny
	if(status == E_WAITING && NiektoJeVoVnutri > 0) {
		TransportGO(NiektoJeVoVnutri);
		return;
	}	
	//	Ide a nikto tam nieje
	if(status == E_FINISHING && NiektoJeVoVnutri == 0) {
		TransportSTOP();
		return;
	}
}
stock TransportSTOP() {
	status = E_WAITING;
	static osoba;
	osoba = NajstObet();
	if(!osoba)  return;
	TransportChange(osoba);
}
stock TransportGO(const osoba) {
	status = E_FINISHING;
	TransportChange(osoba);
}
stock TransportChange(const id) {
	fake_touch(Ftransport, id)
	force_use(id, Ftransport)
	// dllfunc(DLLFunc_Use, used, user)
	// dllfunc(DLLFunc_Touch, toucher, touched)
}
stock JePrazdny(const ent) {
	// Hladame blizko hracov ...
	static Float:temp[3], i, Float:postava[3]
	pev(ent, pev_origin, temp);
	for(i=1; i <= g_maxplayers; i++) {
		if(!is_user_connected(i)) continue;
		if (!is_user_alive(i)) continue;
		if (special_mod(i)) continue;
		pev(i, pev_origin, postava);
		if ( get_distance_f(temp, postava) < F_radius) return i;
	}
	return 0;
}
stock NajstObet() {
	// Potrebujeme najst "obet"
	for(new i=1; i <= g_maxplayers; i++){
		if(!is_user_connected(i)) continue;
		if(is_user_alive(i)) return i;
	}
	// Ziadny hrac ?
	return 0;
}	


stock oznam( const msg[] , any:...) {	
	if(msgid_say) {
		static temp[64]
		vformat(temp, sizeof temp - 1, msg, 2)			
		// Ak chceme farbene musime dat FOR a pre kazdeho zvlast :(
		for(new hrac = 1; hrac <= g_maxplayers; hrac++) {								
			if(is_user_connected(hrac)) {	
				message_begin(MSG_ONE_UNRELIABLE, msgid_say,_,hrac)
				write_byte(hrac)
				write_string(temp)
				message_end()	
			}	
		}
	}
	return PLUGIN_CONTINUE
}