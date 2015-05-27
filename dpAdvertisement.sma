#include <amxmodx>
#include <amxmisc>
#include <dproto>

public plugin_init() {
	register_plugin("DPAdvertisement", "1.0", "Seky");
}
public client_putinserver(id) {
	set_task(2.0, "enter_msg", id)
}
public enter_msg(id) { 
    if(!is_user_connected(id)) return PLUGIN_HANDLED
    if(is_user_bot(id)) return PLUGIN_HANDLED
    if(is_steam(id)) return PLUGIN_HANDLED
        
	set_hudmessage(195, 195, 195, 0.10, 0.55, 0, 6.0, 6.0, 0.5, 0.15, 3) 
	show_hudmessage(id, 
		"Tento server pouziva patch v42 !^n \
		Ak si chces plnohodnotne zahrat, musis si ho stiahnut !^n \
		www.cs.gecom.sk/patch") 
    return PLUGIN_CONTINUE
}