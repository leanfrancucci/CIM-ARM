#ifndef UTIL_H
#define UTIL_H

#include <time.h>
#include "system/lang/all.h"
#include <strings.h>
//#include <Object.h>
#include "StringTokenizer.h"
#include "log.h"

#ifdef __ARM_LINUX
#define BASE_PATH "/rw"
#define BASE_APP_PATH "/rw/CT8016"
#define BASE_VAR_PATH "/var"
#define BASE_TELESUP_PATH "./rwi/telesup/app"
#endif

#ifdef __UCLINUX
#define BASE_PATH "/rw"
#define BASE_APP_PATH "/rw/CT8016"
#define BASE_VAR_PATH "/var"
#define BASE_TELESUP_PATH "/rwi/telesup/app"
#endif

#ifdef __LINUX
#define BASE_PATH "."
#define BASE_APP_PATH "."
#define BASE_VAR_PATH "./var"
#define BASE_TELESUP_PATH "./rwi/telesup/app"
#endif

#define ENCODE_DECIMAL(a) ( (a) * llpow(10,MONEY_DECIMAL_DIGITS) )

#define DFP_PRECITION		6
#define DFP_ACURRANCY		0.0000001

#define PASO_POR_ACA() { printf(0,"Paso por la linea %d del archivo %s\n", __LINE__, __FILE__); fflush(stdout); }

#define TEST_SPEED_START { unsigned long __ticks = getTicks();
#define TEST_SPEED_END	   /*doLog(0,"SPEED --> %ld msec, %s, %s, line %d\n", getTicks() - __ticks, __FILE__, __FUNCTION__, __LINE__);*/ }

/** 
 *	Devuelve la cantidad de elementos de un arreglo.
 */
#define sizeOfArray(a) ( sizeof(a) / sizeof(a[0]) )

/**
 *	Devuelve el maximo entre dos valores.
 */
#define max(a,b) ( (a) > (b) ? (a) : (b) )

/**
 *	Devuelve el minimo  entre dos valores.
 */
#define min(a,b) ( (a) < (b) ? (a) : (b) )

#define freeAndNull(instance)        { if (instance != NULL) {[instance free]; instance = NULL;} } 

/**
 * Encapsula la funcion strncpy2() para copiar strings en forma segura.
 * Copia 
 * @to  (char *) debe ser declarado "char string[X + 1]" si se quiere una cadena 
 * de longitu X. El + 1 se utiliza para almacenar el '\0' de fin de cadena.
 */
#define stringcpy(to, from)  strncpy2((to), (from), sizeof(to) - 1)

#define PRINTER_LINE_LEN 23

typedef enum {
  ENTITY_PRT_NOT_DEFINED,
  TICKET_PRT,
  USER_CASH_REGISTER_CLOSE_PRT,
  TOTALIZE_CASH_REGISTER_CLOSE_PRT,
  COLLECTOR_TOTAL_PRT,
  TARIFF_QUERY_PRT,
  DETAIL_REPORT_PRT,
  CLOSE_X_PRT,
  CLOSE_Z_PRT,
  ADVANCE_PAPER_PRT,
  INIT_HEADERS_FOOTERS_PRT,
	TEXT_PRT,
  PRINTER_STATUS,
  RESET_VOUCHER,
  TICKET_LIST_REPORT_PRT,
  TICKET_RESUME_REPORT_PRT,
  DETAIL_SALES_REPORT_PRT,
  Z_FISCAL_CLOSE_REPORT_PRT,
  OPEN_CASH_DRAWER_PRT,
	DEPOSIT_PRT,
	EXTRACTION_PRT,
	CURRENT_VALUES_PRT,
	CIM_ZCLOSE_PRT,
	CIM_OPERATOR_PRT,
	ENROLLED_USER_PRT,
	CIM_XCLOSE_PRT,
	MANUAL_DEPOSIT_RECEIPT_PRT,
	CIM_AUDIT_PRT,
	SYSTEM_INFO_PRT,
	CASH_REFERENCE_PRT,
	CONFIG_TELESUP_PRT,
	REPAIR_ORDER_PRT,
	CIM_X_CASH_CLOSE_PRT,
	CIM_COMMERCIAL_STATE_PRT,
	COMMERCIAL_STATE_CHANGE_REPORT_PRT,
	MODULES_LICENCE_PRT,
	TRANS_BOX_MODE_EXTRACTION_PRT,
	BAG_TRACKING_PRT,
	CLOSING_CODE_PRT,
	BACKUP_INFO_PRT
} EntityPrintingType;

/**
*  Define los tipos de impresora
*/

/*typedef enum {
	PRINTER_NOT_DEFINED,
	THERMAL,
	FISCAL_EPSON_TMU200,
  FISCAL_EPSON_TMU210,
  PARALLEL,
	FISCAL_HASAR,
	TICKETING
} PrinterType;*/

typedef enum {
	PRINTER_NOT_DEFINED,
	INTERNAL, //es la THERMAL
	EXTERNAL  //es la TICKETING
} PrinterType;


/**
 *	Loguea la cadena pasada como parametro en el archivo pasado como parametro.
 */
void logToFile(char *fileName, char* format, ...);

/**
 *	Convierte un string en representacion ASCII a BCD.
 *
 *	@param dest el string destino, donde se guardara la cadena convertida.
 *	@param source el string origen, donde se toman los datos a convertir.
 *	@return retorna dest, para encadenar funciones.
 */
char* asciiToBcd(char *dest, char *source);

/**
 *	Convierte un string en representacion BCD a ASCII.
 *
 *	@param dest el string destino, donde se guardara la cadena convertida.
 *	@param source el string origen, donde se toman los datos a convertir.
 *	@param maxLen la cantidad maxima de digitos a convertir.
 *	@return retorna dest, para encadenar funciones.
 */
char* bcdToAscii(char *dest, char *source, int maxLen);

/*
 *	Devuelve la longitud en cantidad de digitos de una cadena BCD.
 *	@param str la cadena en BCD.
 *	@param maxlen el tama� maximo de digitos que puede tener la cadena.
 *	@return la cantidad de digitos de la cadena.
 */
int bcdlen(char *str, int maxlen);

/**
 *	Trunca la hora de la fecha/hora, seteandola a las 00:00:00
 *	Util para cuando solamente se quieren comparar fechas.
 */
time_t truncDateTime( time_t date );

/**
 * Reemplaza un caracter por otro en una cadena 
 * @param str la cadena que se debe modificar
 * @param from el caracter a reemplazar
 * @param to el caracter que va reemplazar a @from
 * @result el puntero a la cadena con los caracteres reemplazados (devuelve @param str) 
 */
char *strrep(char *str, char from, char to);

/**
 * Copia from en to pero copia de manera segura los datos.
 * Si la cadena tiene menos de size elementos copia size elementos y
 * asegura un '\0' final. En cambio, si la cadena tiene size elementos
 * entonces copia size - 1 elementos y tambien asegura un  '\0' final.
 * (Copia size - 1 y en to[size] pone un '\0')
 * Entonces size debe ser el tamano maximo que puede tener la cadena to.
 * De esto se desprende que to debe tener al menos size + 1 bytes asignados
 * de memoria.
 * @param char * to la cadena en donde se copiaran como mucho size caracteres
 * @param char * from la cadena origen de los caracteres a copiar
 * @result char * devuelve la direccion de la cadena @param to  
 */
char * strncpy2(char *to, const char *from, size_t size);

/**
 * Configura la fecha y hora del sistema.
 * @param (datetime_t) dt el valor de fecha y hora a configurar siempre definido
 * enn zona horaria GMT.
 * Dispara la excepcion DATETIME_EX
 */
void setDateTime(datetime_t dt);

/**
 * Obtiene la fecha y hora del sistema.
 * @result (datetime_t) el valor de fecha y hora actual del sistema definido
 * enn zona horaria GMT.
 * Dispara la excepcion DATETIME_EX
 */
datetime_t getDateTime(void);


/**
 * Convierte val a formato ISO8106: "2004-12-03T12:14:30" copiando el resultado
 * en buf (no esta manejando zona horaria).
 * @buf (char *) recibe el puntero a char en donde se copia el valo convertido
 * @val datetime_t el valor fecha/hora que es convertido a string
 * @result (char *) devuelve buf si convierte OK y NULL en caso contrario
 */		 
char *datetimeToISO8106(char *buf, datetime_t val);


/**
 * Convierte el string de fecha en formato ISO8106 a valor numerico datetime_t
 * @val (char *) la cadena de caracteres en formato ISO8106.
 * @result datetime_t el valor de fecha y hora devuelto. 
 */
datetime_t ISO8106ToDatetime(char *val);

/**
 * Devuelve la fecha y hora de creaci� del archivo
 * @param (char *) el nombre del archivo consultado.
 * @result (datetime_t) la fecha y hora de creacion del archivo. Devuelve NULL en caso de error. 
 */
datetime_t getFileDateTime(const char *name);

/**
 * Compara dos numeros float.
 * La comparacion se realiza con solo dos decimales de precision.
 * @decimals (int) la cantidad de decimales de precision con la que se quiere comparar
 * @result  0 si f1 == f2
 * @result  1 si f1  > f2
 * @result -1 si f1  < f2  
 */
int compareFloat(float f1, float f2, int decimals);

/**
 * Compara dos numeros double.
 * @decimals (int) la cantidad de decimales de precision con la que se quiere comparar
 * @result  0 si f1 == f2
 * @result  1 si f1  > f2
 * @result -1 si f1  < f2  
 */
int compareDouble(double f1, double f2, int decimals);

/**
 * Compara dos currency.
 * @decimals (int) la cantidad de decimales de precision con la que se quiere comparar
 * @result  0 si c1 == c2
 * @result  1 si c1  > c2
 * @result -1 si c1  < c2  
 */
int compareMoney(money_t c1, money_t c2, int decimals);

/**
 * Devuelve el valor double en formato de punto flotante decimal : value = m * 10^e
 *	@value (double) es el vlor de moneda que se debe convertir
 *  @val (decimal_fp) es un puntero a una variable de tipo decimal punto flotante en donde
 *  se almacena la mantisa y el exponente del resultado obtenido.
 *  @result retorna el puntero al punto flotante decimal @val i todo termino exitosamente.
 */
decimal_fp *doubleToDecimalFloatPoint(double value, decimal_fp *val);

/**
 * Devuelve el valor especificado por el numero de punto flotant en base decimal.
 * @result (double) el valor convertido: val->mantise * pot(10, val->exp)
 */
double decimalFloatPointToDouble(decimal_fp *val);

/**
 * Devuelve el valor del valor money en formato de punto flotante decimal : value = m * 10^e
 *	@value (money_t) es el vlor de moneda que se debe convertir
 *  @val (decimal_fp) es un puntero a una variable de tipo decimal punto flotante en donde
 *  se almacena la mantisa y el exponente del resultado obtenido.
 *  @result retorna el puntero al punto flotante decimal @val i todo termino exitosamente.
 */
decimal_fp *moneyToDecimalFloatPoint(money_t value, decimal_fp *val);

/**
 * Devuelve el valor especificado por el numero de punto flotant en base decimal.
 * @result (money_t) el valor convertido: val->mantise * pot(10, val->exp)
 */
money_t decimalFloatPointToMoney(decimal_fp *val);

/**
 *	Convierte un valor en double a un valor de tipo money_t
 */
money_t doubleToMoney(double value);

/**
 *	Convierte un valor de tipo money_t a un valor de tipo double
 */
double moneyToDouble(money_t value);

/**
 * Eleva @param base  a la potencia @param exp
 * @result (long long) devuelve el resultado de la potencia como long long de 62 bits.
 */
long long llpow(long long base, int exp);

/**
 * Compara dos valores punto flotante decimal. 
 * @param fp1 y fp2 son punteros puntos flotante decimales.
 * @result  0 si fp1 == fp2
 * @result  1 si fp1  > fp2
 * @result -1 si fp1  < fp2  
 */
int compareFloatPoint(decimal_fp *fp1, decimal_fp *fp2);

/**
 * Deuelve no cero si c es ' ' , '\t' o '\v', y devuelve 0 en caso contrario.
 */
int isblankchar(int c);

/**
 * Elimina los espacios en blanco y tabs que pueda tener la cadena @param p
 * en su extremo derecho.
 * @result devuelve el mismo puntero que se le hizo el trim
 */
char *rtrim(char *p);

/**
 * Elimina los espacios en blanco y tabs que pueda tener la cadena @param p
 * en su extremo izquierdo.
 * @result devuelve un puntero al primer caracter que no sea blanco o tab de la cadena.
 */
char *ltrim(char *p);

/**
 * Elimina los espacios en blanco y tabs que pueda tener la cadena @param p
 * en su extremo izquierdo y en su extremo derecho.
 * @result devuelve un puntero al primer caracter que no sea blanco o tab de la cadena.
 */
char *trim(char *p);

/**
 *	Devuelve un datetime_t (en segundos desde 1970) a partir de los datos
 *	pasados como parametro.
 *	@param year el anio completo, [1970-xxxx]
 *	@param month el mes, [1-12].
 *	@param day el dia, [1-31].
 *	@param hour la hora, [0-23].
 *	@param min los minutos, [0-59].
 *	@param sec los segundos, [0-59].
 */
datetime_t encodeTime(int year, int month, int day, int hour, int min, int sec);

/**
 * Genera caracteres imprimibles aleatorios en todo el string.
 * Se generan hasta size caracteres inclusive, es decir, la cadena debera
 * poder almacenar size caracteres mas uno mas para el '\0'. 
 */
char *randomString(char *string, int size);

/**
 *
 */
typedef enum {

	 UTIL_AlignLeft
	,UTIL_AlignRight
	,UTIL_AlignCenter
	
} UTIL_AlignType;

/**
 * Copia src en dst alineando adecuadamente completando con espacios en blanco.
 * Copia hasta n caracteres.
 * La cadena dst debe tener un tamanio al menos de n + 1.
 * @return dst
 */ 
char *alignString(char *dst , char *src, int n, UTIL_AlignType align);

/**
 *	Formatea la moneda pasada como parametro a una maxima cantidad de caracteres.
 *	La funcion recorta de acuerdo al siguiente criterio (en caso que no entre):
 *		- En primer lugar elimina el simbolo de la moneda y el espacio del mismo.
 *	  - En caso que todavia no entre, recorta decimales, de los menos significativos
 *		  en adelante (y el punto si es necesario).
 *	  - En ultimo lugar, elimina digitos de la parte del numero.
 *
 *	@param dest un buffer adonde se guardara la cadena formateada.
 *	@param moneySimbol simbolo de moneda.
 *	@param amount monto a formatear.
 *	@param decimals cantidad de decimales que debe tener el resultado.
 *	@param maxChars maxima cantidad de caracteres que permite.
 *	@return un puntero a la cadena dest para concatenar funciones.
 *
 */
char *
formatMoney(char *dest, char *moneySimbol, money_t amount, int decimals, int maxChars);

/**/
char *formatDate(datetime_t date, char *buffer);

/**/
char *formatTime(datetime_t date, char *buffer);

/**/
char *formatDateTime(datetime_t date, char *buffer);

/**/
char *formatDateTimeComplete(datetime_t date, char *buffer);

/**/
char *formatTimeHourMin(datetime_t date, char *buffer);

/**
 *	Multiplica el parametro value1 por value2, el resultado lo divide por value3 y lo devuelve.
 *	En otras palabras, realiza la siguiente operacion value1 * value2 / value3.
 *	Esto rutina ademas controla que no se produzca desbordamiento rapidamente, que surgen
 *	de realizar la multiplicacion value1 * value2 con numero grandes.
 */
money_t muldiv(money_t value1, money_t value2, money_t value3);

/**
 *	
 */
money_t decimalToMoney(decimal_t decimal);

/**
 *	
 */
decimal_t moneyToDecimal(money_t value);

/**
 *	Carga el archivo pasado por parametro en memoria y devuelve un
 *	buffer con los datos del archivo.
 *	@param fileName el nombre del archivo.
 *	@param appendZero define si debe concatenar un \0 al final del buffer.
 *	@return el buffer con los datos del archivo, NULL si hubo un error.
 */
char *loadFile(char *fileName, BOOL appendZero);

/**
 *	Convierte de una representacion de moneda con n decimales a la representacion interna.
 *	@param value el valor de moneda a convertir.
 *	@param currentDecimals la cantidad de decimales actual del parametro value.
 *	@return la moneda convertida a la representacion interna.
 */
money_t adjustMoneyDecimals(money_t value, int currentDecimals);

/**
 *	Permite utizar loguear a un archivo dependiendo de una variable de entorno.
 *	El el nombre de la categoria esta definido como una variable de entorno, entonces
 *	loguea a un archivo con nombre = a la variable de entorno.
 *	Por ejemplo:
 *		Defino una categoria LOG_MODEM
 *		Cuando quiero activar el logueo de esta categoria, defino la variable de entorno
 *		export LOG_MODEM = modem.log con lo cual escribira a este archivo.
 *		Podria hacer tambien un LOG_MODEM = stdout con lo cual escribe a la salida standard.
 */
void logCategory(char *aCategory, BOOL includeTimestamp, char* format, ...);

/**/
void sysRandomize(void);

/**/
int sysRandom(int from, int to);

/**
 * Formatea un valor de punto flotante en una cadena al estilo 000xx.xx00 rellenando
 * con ceros la cadena hasta llegar a las cantidades de enteros y decimales pasados como 
 * parametro.
 * Ej: formateo del valor 3.1 a 5 enteros y 3 decimales -> 00003.100
 *	@param dest la cadena destino.
 *  @param integerQty la cantidad de enteros a formatear el numero.
 *  @param decimalQty la cantidad de decimales a formatear el numero.
 *  @param amount el numero a formatear.
 *  @param includeSeparator el parametro que indica si en la cadena destino incluira el separador
 *  entre enteros y decimales.
 *	@return el buffer el numero formateado.
 */
char* formatFloatAmount(char* dest, int integerQty, int decimalQty, double amount, int includeSeparator);
 
/**
 *
 */
money_t cut_digits(money_t value, int count);
int digits_to_cut(money_t value);
int count_digits(money_t value);
money_t stringToMoney(char *str);

/**
 * Dado un texto reemplaza los \n con \0A y la \ con \5C.
 */ 
char *fillTextSpecialCharacter(char* doc, char* finalDoc);

/** Rutinas de encriptacion/desencriptacion por sustitucion simple */
char *encryptSimple(unsigned char *dest, unsigned char *source, int qty);
char *decryptSimple(unsigned char *dest, unsigned char *source, int qty);
char *decryptFile(char *fileName);

/*Devuelve la MacAddress*/
int if_netInfo (char *intf , char *rslt);

/*Devuelve la MAC del equipo. Esta funcion se utiliza para el caso de estar con hadware secundario*/
void get_mac (char* aMac);

/*Devuelve la IP, mask y gateway (se utiliza cuando el DHCP esta habilitado)*/
int if_netInfo_with_dhcp (char *intf , char *ip, char *mask, char *gateway);

/*Devuelve el gateway (se utiliza cuando el DHCP esta habilitado)*/
int get_default_gateway (char *intf, char *gateway);

/** Obtiene el bit numero "number" del arreglo */
int getbit(unsigned char  *set, int number);

/** Configura el bit numero "number" del arreglo */
void setbit(unsigned char *set, int number, int value);

/** Invierte el bit numero "number" del arreglo */
void flipbit(unsigned char  *set, int number);

/**/
void loadIPConfig(char* aDHCP, char* anIpAddress, char* aNetMask, char* aGateway);

/**/
void loadIPConfigFromFile(char* aDHCP, char* anIpAddress, char* aNetMask, char* aGateway);

/**/
char* formatText (char *originalText, char* finalText);

/**/
char *wordwrap( char *instring, int wrap_pnt, int wrap_mgn, char *outstring );

#ifdef __UCLINUX
// por algun motivo no esta definido strdup en string.h
char *strdup(const char *s);
#endif

#endif

