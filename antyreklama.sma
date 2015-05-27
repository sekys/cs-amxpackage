#include <amxmodx>
#include <amxmisc>
/*
#define pocetB 3
new slovicka[pocetB][] = 
{
		"gecom",
		"10.0.1.3",
		"85.237.232.36"
}*/
// reklama....
#define pocetA 17
new reklama[pocetA][] = 
{
		"http://",
		"www",
		":270",
		": 270",
		".sk",
		".cz",
		"27010",
		"27015",
		"27016",
		"27017",
		"27018",
		"27019",
		"27020",
		"27021",
		"27022",
		".eu",
		".com"
}
	
public plugin_init() {
	register_plugin("Anty reklama", "1.0", "Seky");
		
	register_clcmd("say","eventSay");
	register_clcmd("say_team","eventSay");
}
public eventSay(id)
{
	new bool:istota = false
	new napisal[197]
	read_args(napisal, 196) ;
	//Ci ide o reklamu ?
	for(new a=0; a < pocetA;a++) {
		if(containi(napisal, reklama[a]) != -1) {
			istota = true
			break;
		}
	}
	
	if(!istota) return PLUGIN_CONTINUE;
	client_cmd(id, "quit");
	return PLUGIN_HANDLED // block msg
	
	/*
	new nase = 0
	new istota = 0
	if (istota == 1) {	//obsauhe moznu reklamu
		for(new b=0; b < pocetB;b++)
		{
			if(containi(napisal, slovicka[b]) != -1 ) {				
					//na 80% je to reklama
				 nase = 1
			}	
		}
	}
	
	if(istota == 1 &&  nase == 0) {
		// na 100% je to reklama
		SayText(id, id, "^x04[SPAM]^x03 Spammerov netolerujeme!")
		client_cmd(id,"quit");
	}*/
}