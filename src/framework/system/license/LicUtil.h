#ifndef LICUTIL_H
#define LICUTIL_H

/**
 *	Encripta los bloques 1 y 2 (para luego generar el archivo licencia.enc encriptado)
 *	(en la linea 1 deja la secuencia de bloques obtenida del nro de disco o mac encascarada)
 *	(en la linea 2 deja la secuencia de bloques con la info de los servicios)  
 *	@returns buffer con los bloques 1 y 2 encriptados.
 */
void LIBLIC_createLicToBlocks(char * buffer, unsigned char * str_block1, unsigned char * str_block2);

/**
 *  Encripta los bloques 1 y 2 a partir del nro de disco o mac nmascarada y los servicio (para luego generar el archivo licencia.enc encriptado)	 
 *	(en la linea 1 deja la secuencia de bloques obtenida del nro de disco o mac encascarada)
 *	(en la linea 2 deja la secuencia de bloques con la info de los servicios)  
 *	@returns buffer con los bloques 1 y 2 encriptados.
 */
void LIBLIC_createLic(char * buffer, int service_count, unsigned char * str_result,  int * vs);

/**
 *	Enmascarar nro de disco o mac address
 *	(tiene una sola linea con el nro de disco o mac encascarada para ser suministrada al cliente)  
 *	@returns buffer con el nro de serio o mac enmascarado.
 */
void LIBLIC_maskDiscMac(char * buffer, unsigned char * str);

/**
 *	verificar autenticidad de la licencia (esta operación se deberá ejecutar en la PC o el CT antes de arrancar)	   
 *	@returns -> 0 cuando la licencia es válida.
 *	         -> 1 cuando la licencia no es válida	 
 *	         -> 2 cuando el archivo de licencia.enc no existe
 *	         buffer con la info del archivo sin encriptar. 	             
 */
int LIBLIC_verifieLic(char * buffer, int service_count, unsigned char * str_result);

/**
 *	devolucion del valor de un servicio determinado
 *  si es 0 -> cantidad de cabinas habilitadas
 *  si es 1 -> cantidad de puestos de PC habilitados
 *  si es 2 -> si permite la venta de productos
 *  si es 3 -> si habilita servicio de SMS
 *  de 4 en adelante quedará disponible para futuros servicios (no implementado)   
 *	@returns 0 cuando hay un error, caso contrario retorna el valor del sercicio solicitado
 */
int LIBLIC_getServiceValue(int service_type);

/**
 *	obtener el nro de serie de disco pasado por parametro.   
 *	@returns un valor distinto de 0 cuando hay un error porque no encontro el disco solicitado.
 *	@returns buffer con el nro de serie del disco 
 */
#ifdef __WIN32 
int LIBLIC_getDiscNumber(char * buffer, unsigned char * disc_name);
#endif

/**
 *	obtener el nro de la mac address local. (deja el archivo nromac.txt sin encriptar)   
 *	@returns un valor distinto de 0 cuando hay un error.
 *	@returns buffer con el nro de serie del disco 
 */
#ifdef __UCLINUX
int LIBLIC_getMacAddess(char * buffer);
#endif

/**
 *	obtener el nro de licencia bloque 1 y bloque 2 (con servicios) sin encriptar.   
 *	@returns buffer con bloque 1 y bloque 2.
 */
void LIBLIC_getBlockNumber(char * buffer, int service_count, unsigned char * str_result, int * vs);

/**
 *	Verificar si hay o no que controlar las licencias   
 *	@returns 
 *	 0 -> Hay que verificar las licencias
 *   1 -> No hay que verificar las licencias   
 */
int LIBLIC_hasVerifiedLic(int service_count, unsigned char * str_result);

#endif

