#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <dr>

#define HRACOV	20
#define MIEST	5

#define CENA_VIP 2
#define CENA_NOVIP 3

const KEYSMENU = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)

new ch_posledny[HRACOV+1], ch_vectory[HRACOV+1][MIEST][3], ch_cas[HRACOV+1][MIEST][9],
	g_msgSayText, bool:JednoZdarma[HRACOV+1]

public plugin_init() {
	register_plugin( "Dr Checkpointy", "1.0", "Seky" );

	register_clcmd( "menu_checkpoint", "checkpoints" );
	register_clcmd( "say /checkpointy", "checkpoints" );
	register_clcmd( "say /checkpoints", "checkpoints" );
	register_clcmd( "say /ch", "checkpoints" );
	register_clcmd( "say /save", "checkpoints" );
	register_clcmd( "say /load", "checkpoints_load" );
	
	g_msgSayText = get_user_msgid("SayText")
	register_menu("Save Menu", KEYSMENU, "menu_game_save")
	register_menu("Load Menu", KEYSMENU, "menu_game_load")
}
stock dr_colored_print(target, const message[], any:...) {
	static buffer[512]
	vformat(buffer, sizeof buffer - 1, message, 3)
	message_begin(MSG_ONE, g_msgSayText, _, target)
	write_byte(target)
	write_string(buffer)
	message_end()
}
public client_disconnect(id) {
	// Nulujeme
	native_vymaz_checkpointy(id)
}
public client_connect(id) {
	JednoZdarma[id] = true;
}
public plugin_natives() {
	register_native("vymaz_checkpointy", "native_vymaz_checkpointy", 1)
}
public native_vymaz_checkpointy(id) {
	// Nulujeme
	static i, a, temp;
	i=a=0;
	temp = ch_posledny[id]
	ch_posledny[id] = -1;
	
	for( i=0; i < MIEST; i++)	{
		format(ch_cas[id][i], 8, "");
		for(a=0; a < 3; a++) ch_vectory[id][i][a] = 0;
	}
	return temp;
}
public checkpoints(id) {
	show_menu_game(id, 0)
}
public checkpoints_load(id) {
	show_menu_game(id, 1)
}
/*
nadpis Save Menu / Load Menu
1. Pozicia 1 ulkozaena 17:00
2. Pozicia 2 ulkozaena 16:59
3. Pozicia 3 ulkozaena 17:31
4. Neulozena pozicia
5. Pozicia 5 ulkozaena 17:00
6.-medzera
7. Ulozit / nacitat
8/mezera
9.exit
*/
stock show_menu_game(id, typ)
{
	// Ak neje CT
	if( get_user_team(id) != 2) {
		dr_colored_print(id, "^x04[G/L DR]^x01 Checkpointy su len pre CTcka !")
		return PLUGIN_HANDLED;
	}
	if (!is_user_alive(id)) 	{
		dr_colored_print(id, "^x04[G/L DR]^x01 Si mrtvy, nemozes pouzit checkpointy !")
		return PLUGIN_HANDLED;
	}
	
	new menu[250], len = 0
	// Nazov
	len += formatex(menu[len], sizeof menu - 1 - len, "\r%s^n^n", typ == 0 ? "Save Menu" : "Load Menu")	
	
	//Jednotlive checkpointy
	for(new i=0; i < MIEST; i++) {
		if( ch_vectory[id][i][0] == 0 && ch_vectory[id][i][1] == 0 && ch_vectory[id][i][2] == 0) {
			len += formatex(menu[len], sizeof menu - 1 - len, "\d%i. Neulozena pozicia^n", i+1)	
		} else {
			if(ch_posledny[id] == i)
				len += formatex(menu[len], sizeof menu - 1 - len, "\r%i.\w Ulozene (%s)\y - posledne^n", i+1, ch_cas[id][i])	
			else
				len += formatex(menu[len], sizeof menu - 1 - len, "\r%i.\w Ulozene (%s)^n", i+1, ch_cas[id][i])		
		}
	}
	// Medzera
	len += formatex(menu[len], sizeof menu - 1 - len, "^n")
	
	// Tlacidlo
	if(typ == 0)
		len += formatex(menu[len], sizeof menu - 1 - len, "\r7. \rUlozit \w/\d Nacitat^n")
	else
		len += formatex(menu[len], sizeof menu - 1 - len, "\r7. \dUlozit \w/\r Nacitat^n")
	
	// Medzera a exit
	len += formatex(menu[len], sizeof menu - 1 - len, "^n^n\r9.\w Exit")
	if(typ == 0)
		show_menu(id, KEYSMENU, menu, -1, "Save Menu")
	else	
		show_menu(id, KEYSMENU, menu, -1, "Load Menu")
}
public menu_game_save(id, key)
{
	// Exit
	if(key == 8) return PLUGIN_HANDLED;		
	// Zmena	
	if(key == 6)	{
		show_menu_game(id, 1)
		return PLUGIN_HANDLED;
	}	
	// Nejaka chyba v rozmezi
	if(key >= MIEST || key < 0) return PLUGIN_HANDLED;
	
	// Kontrola penazi
	if(!(get_user_flags(id) & ADMIN_LEVEL_F) ) {
		new temp = dr_get_user_ammo_packs(id)
		if(temp < 1) {
			dr_colored_print(id, "^x04[G/L DR]^x01 Na ulozenie pozicie potrebujes 1 bod.")
			return PLUGIN_HANDLED;
		}	
		dr_set_user_ammo_packs(id, temp - 1)
		dr_colored_print(id, "^x04[G/L DR]^x01 Ulozena nova pozicia. (-1 bod)")
	} else {
		dr_colored_print(id, "^x04[G/L DR]^x01 Ulozena nova pozicia.")
	}
	// Check pointy
	ch_posledny[id] = key
	get_user_origin(id, ch_vectory[id][key])
	get_time("%X", ch_cas[id][key], 8)
	return PLUGIN_CONTINUE;
}
public menu_game_load(id, key)
{
	// Exit
	if(key == 8) return PLUGIN_HANDLED;	
	// Zmena	
	if(key == 6) show_menu_game(id, 0); return PLUGIN_HANDLED;
	// Nejaka chyba v rozmezi
	if(key >= MIEST || key < 0) return PLUGIN_HANDLED;
	// Kntrola penazi
	if(!(get_user_flags(id) & ADMIN_LEVEL_F) ) {
		new temp = dr_get_user_ammo_packs(id)
		if(temp < CENA_VIP) {
			dr_colored_print(id, "^x04[G/L DR]^x01 Na nacitanie pozicie potrebujes %d body.", CENA_VIP);
			return PLUGIN_HANDLED;
		}
		dr_colored_print(id, "^x04[G/L DR]^x01 Nacitana pozicia. (-%d body)", CENA_VIP)
		dr_set_user_ammo_packs(id, temp - CENA_VIP);
	} else {
		if(JednoZdarma[id]) {
			dr_colored_print(id, "^x04[G/L DR]^x01 Nacitana 1. pozicia zdarma.")
			JednoZdarma[id] = false;
		} else {
			new temp = dr_get_user_ammo_packs(id)
			if(temp < CENA_NOVIP) {
				dr_colored_print(id, "^x04[G/L DR]^x01 Na nacitanie pozicie potrebujes %d body.", CENA_NOVIP)
				return PLUGIN_HANDLED;
			}
			dr_colored_print(id, "^x04[G/L DR]^x01 Nacitana pozicia. (-%d body)", CENA_NOVIP)
			dr_set_user_ammo_packs(id, temp - CENA_NOVIP);
		}
	}
	// Check pointy
	set_user_origin(id, ch_vectory[id][key])
	return PLUGIN_CONTINUE;
}