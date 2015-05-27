#include <amxmodx>
#include <amxmisc>
#include <zombieplague>

#define PLUGIN 	"[ZP] Autobind"
#define VERSION "1.0"
#define AUTHOR 	"Seky"

#define FLARE_ENTITY args[0]
#define FLARE_DURATION args[1]
#define TASK_NADES 100

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("zp_bind", "cmd_bind", ADMIN_ALL, "Mozte si nabidovat nakupovanie bonusov.");
	//register_clcmd("zp_bindlist", "cmd_bind_list", ADMIN_ALL, "Zoznam bonusov....");
}
public cmd_bind(id,level,cid) { 
	if (!cmd_access(id,level,cid,1)) return PLUGIN_HANDLED;
	static arg[4], cislo, pocet;
	pocet = zp_extra_item_pocet();
	read_argv ( 1, arg, 4)
	cislo = str_to_num(arg)
	if(cislo < 1 || cislo >= pocet) {
		client_print(id, print_console, "Nezadal si spravne poradie bonusu.")
		return PLUGIN_CONTINUE;
	}
	zp_extra_item_buy(id, cislo+1);	
	return PLUGIN_CONTINUE;
}/*
public cmd_bind_list(id,level,cid) { 
	if (!cmd_access(id,level,cid,1)) return PLUGIN_HANDLED;
	static pocet
	pocet = zp_extra_item_pocet();
	client_print(id, print_console, "------ Zoznam bonusov ------")
	client_print(id, print_console, "ID	         Nazov	     Cena")
	new subor[33]
	
	for(new i=0; i < pocet; i++){
		zp_extra_item_name(i, subor, 32)
		client_print(id, print_console, "%i - %s - %i", i+1, subor, zp_extra_item_cost(i))
	}
}*/