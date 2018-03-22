#ifndef DOOR_OVERRIDE_C_H_
#define DOOR_OVERRIDE_C_H_

#include <time.h>

void testover();


/**
 * Entrada: fecha y hora del equipo.
 *          codigo de verificacion que se muestra por pantalla
 */
void genVerifCode( struct tm * fechaHora, unsigned char * codVerif );


/**
 * Entrada: mac_address del equipo, Id del punto de venta y fecha y hora del equipo.
 * Salida: codigo interno que se debe comparar con el código ingresado por el operador.
 */
unsigned long genInternalCode( char * mac, char * idPunto, struct tm * fechaHora );

#endif
