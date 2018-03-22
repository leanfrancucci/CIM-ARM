#ifndef KEYPAD_CONF_LIB_H
#define KEYPAD_CONF_LIB_H

#include <keypad.h>

/* Initialize the library with default configuration.
 * Mode of use: xlate and alphanumeric mode.
 * Reads th /etc/ct8016/keypad.conf and configures the library.
 * If the file does not exists or is bas formated then configures 
 * with default configuration.
 */
void init_conf_modes(struct KPMapScancode *map_num, 
					 struct KPMapScancode *map_alphanum, 
					 struct KPMapScancode *map_nav);


#endif


	




