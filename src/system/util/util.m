#include <assert.h>
#include <stdlib.h> 
#include <string.h>
#include <stdio.h>
#include <stdarg.h>
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>
#include <math.h>
#include <time.h>
#include "util.h"
#include "UtilExcepts.h"
#include "excepts.h"
#include <limits.h>
#include "system/lang/all.h"

#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <linux/if.h>
#include <sys/ioctl.h> 
#include <arpa/inet.h>


#define MAX_NUM_IFREQ 512

#define ETH0_FILE_NAME BASE_PATH "/etc/interfaces/eth0"

/* hay que cambiarla por una que ande y que devuelva hora local */
#define timegm		mktime

//#undef gmtime_r
/* eliminar estas dos lineas (la de arriba y la de abajo) */
//#define gmtime_r localtime_r

#ifdef __UCLINUX
void __assert_fail(const char *file, const char *function, int line, const char *n)
{
	//doLog(0,"Assertion failed (%s), file %s, line %d\n", n, file, line);	
}
#endif

#define MAX_LONG_LONG_DIGITS 18
#define ABS(a) if ( (a) < 0 ) (a) = 0 - (a)

#ifdef __WIN32
/** En el caso de Windows, no esta esta definida la funcion strcasestr por lo tanto la defino aca */
char *strcasestr (char *haystack, char *needle)
{
	char *p, *startn = 0, *np = 0;

	for (p = haystack; *p; p++) {
		if (np) {
			if (toupper(*p) == toupper(*np)) {
				if (!*++np)
					return startn;
			} else
				np = 0;
		} else if (toupper(*p) == toupper(*needle)) {
			np = needle + 1;
			startn = p;
		}
	}

	return 0;
}
  
#endif

/**/
char* asciiToBcd(char *dest, char *source)
{
	char *p = dest;
	*p = 0xFF;
	
	while (*source != 0)
	{

		if (*source == '#')
			*p = 11 << 4;
		else if (*source == '*')
			*p = 10 << 4;
		else
			*p = (*source - 48) << 4;
			
		source++;
		if (*source == 0) {
			*p = *p + *source + 0x0F;
			break;
		}

		if (*source == '#')
			*p = *p + 11;
		else if (*source == '*')
			*p = *p + 10;		
		else	
			*p = *p + *source - 48;
			
		source++;
		p++;
		if (*source == 0) {
			*p = 0xFF;
			break;
		}
	}
	return dest;
}



/**/
static const unsigned char BcdToCharArray[] = "0123456789*#?Cr\0";

/**/
#define GET_CHAR_FROM_BCD(bcd, pos) ( (pos % 2) == 0 ? BcdToCharArray[ bcd[pos/2] >> 4 ] : BcdToCharArray[ bcd[pos/2] &  0x0F] )

/**/
char* bcdToAscii(char *dest, char *source, int maxLen)
{
	int i;
	unsigned char *p = source;

	for (i = 0 ; i < maxLen ; ++i)
		if ((dest[i] = (char)GET_CHAR_FROM_BCD(p, i) ) == 0) return dest;

	dest[maxLen] = 0;
	return dest;
}


/**/
int bcdlen( char *str, int maxlen)
{
	int i;
	for (i = 0 ; i < maxlen && GET_CHAR_FROM_BCD(str, i) != 0; ++i);
	return(i);
}

/**/
time_t truncDateTime( time_t date )
{
	struct tm *sourceDate;
	struct tm truncDate;

	sourceDate = gmtime( &date );
	truncDate = *sourceDate;
	truncDate.tm_hour = 0;
	truncDate.tm_min = 0;
	truncDate.tm_sec = 0;

	return mktime(&truncDate);
	
}


/**/
void logToFile(char *fileName, char* format, ...)
{
	FILE *f;
	va_list ap;
	char result[50];
	time_t now = time(NULL);
	struct tm brokenTime;

	if (fileName == NULL || strcmp(fileName, "stdout") == 0)
		f = stdout;
	else {
		f = fopen(fileName, "a+");
		if (!f) return;
	}
	
	localtime_r(&now, &brokenTime);
	strftime (result, 50, "%H:%M:%S", &brokenTime );
	fprintf(f, "%s --> ", result);
	 
	va_start(ap, format);
	vfprintf(f, format, ap);
	va_end(ap);
	
	if (f != stdout) fclose(f);
	
}

/**/
void logCategory(char *aCategory, BOOL includeTimestamp, char* format, ...)
{
	FILE *f;
	va_list ap;
	char result[50];
	time_t now = time(NULL);
	struct tm brokenTime;
	char *fileName;

	fileName = getenv(aCategory);
	if (!fileName) return;
	
	if (strcmp(fileName, "stdout") == 0)
		f = stdout;
	else {
		f = fopen(fileName, "a+");
		if (!f) return;
	}

	if (includeTimestamp) {	
		localtime_r(&now, &brokenTime);
		strftime (result, 50, "%H:%M:%S", &brokenTime );
		fprintf(f, "%s --> ", result);
	}

	va_start(ap, format);
	vfprintf(f, format, ap);
	va_end(ap);
	
	if (f != stdout) fclose(f);

}

/**/
char *strrep(char *str, char from, char to)
{
	char *p = str;
	while (*p) { 
		if (*p == from) *p = to;
		p++;
	}
	return str;
}

/**/
char * strncpy2(char *to, const char *from, size_t size)
{
	THROW_NULL(to);
	THROW_NULL(from);
	
	strncpy(to, from, size);
	to[size] = '\0';
	return to;
}

/**/
datetime_t getDateTime(void)
{
	datetime_t dt;

	if ((dt = time(NULL)) == -1)
			THROW( DATETIME_EX );
	return dt;
}

/**/
void setDateTime(datetime_t dt)
{
}

/**/
char * datetimeToISO8106(char *buf, datetime_t val)
{
	struct tm brokentime;	

	/*
	 *	Formato (siempre en hora GMT): 	 2004-10-18T12:53:21
	 *			 				2004-10-18T12:53:21
	 */	
	gmtime_r(&val, &brokentime);

	// : strftime(buf, 19 , "%y-%m-%dT%H:%M:%S", &brokentime);
	snprintf(buf, 20, "%4d-%02d-%02dT%02d:%02d:%02d",
				brokentime.tm_year + 1900,	// a?o 
				brokentime.tm_mon  + 1,		// mes 
				brokentime.tm_mday,			// dia 
				brokentime.tm_hour,			// hora
				brokentime.tm_min,			// minutos 
				brokentime.tm_sec			// segundos 	
	);
	return buf;	
}

		 
/**
 * Devuelve el valor correspondiente al parametro en formato time_t
 * El valor viene como cadena ascii en formato ISO8601
 */
datetime_t ISO8106ToDatetime(char *val)
{
	/*
	 *	Formato (siempre en hora GMT): 	 2004-10-18T12:53:21
	 *			 				2004-10-18T12:53:21
	 */	
	struct tm timem;
	datetime_t  dt;	

	/*reemplaza '-' y ':' por ' ' (espacio) para que sea mas facil
	realizar la conversion (chancho pero efectivo */
	strrep(val, '-', ' ');
	strrep(val, ':', ' ');

	/*       0                         10
		 0123  4  56 7  89  0   12  3  45  6  78
		"2004  -  10  -  18  T   04  :   53  :  21"		 */
	timem.tm_year 	= atoi( &val[ 0 ] ) - 1900;	/* a?o */
	timem.tm_mon 	= atoi( &val[ 5 ] ) - 1;		/* mes */
	timem.tm_mday 	= atoi( &val[ 8 ] );		/* dia */
	timem.tm_hour 	= atoi( &val[ 11 ] );		/* hora */
	timem.tm_min 	= atoi( &val[ 14 ] );			/* minutos */
	timem.tm_sec 	= atoi( &val[ 17 ] );			/* segundos */

	/* Convierte a time_t */
	if ((dt = timegm(&timem)) == -1) 
		return 0;
	return dt;
}

/**/
datetime_t getFileDateTime(const char *name)
{
    struct stat status;
    if ( stat(name, &status) == -1) 
		return 0;
    return status.st_mtime;
}

/**/
int compareFloat(float f1, float f2, int decimals)
{
	float r = pow(10.0, (float)decimals);
	float x1 = rint( f1 * r ) / r;
	float x2 = rint( f2 * r ) / r;

	if( x1 == x2 ) return 0;
	if( x1 < x2 )  return -1;
	return 1;
}

/**/
int compareDouble(double f1, double f2, int decimals)
{
	double r = pow(10.0, (double)decimals);
	double x1 = rint( f1 * r ) / r;
	double x2 = rint( f2 * r ) / r;

	if( x1 == x2 ) return 0;
	if( x1 < x2 )  return -1;
	return 1;
}

/**/
int compareMoney(money_t c1, money_t c2, int decimals)
{
	return compareDouble(c1, c2, decimals);
}		 

/**/
int count_digits(money_t value)
{
	int count = 0;

	ABS(value);
	while (value != 0) {
		value = value / 10;
		count++;
	}
	
	return count;
}

/**/
int digits_to_cut(money_t value)
{
	int count = 0;

	ABS(value);
	
	while (value != 0) {
		if (value % 10 != 0) break;
		count++;
		value = value / 10;
	}
	
	return count;
}

/**/
money_t cut_digits(money_t value, int count)
{
	return value / llpow(10, count); 
}


/**/
money_t muldiv(money_t value1, money_t value2, money_t value3)
{
	int count_digits1, count_digits2;
	int digits;
	int cutdigits;
	money_t result;
	int cutdigits1, cutdigits2;
	int morecut;

	// Esta funcion realiza el calculo value1 * value2 / value3 con un tipo de datos long long.
	// Para que no ocurran desbordamientos de buffer, recorta los ultimos digitos "0" de cada
	// numero hasta que entre.
	
	count_digits1 = count_digits(value1);
	count_digits2 = count_digits(value2);
	digits = count_digits1 + count_digits2;
	cutdigits = digits - MAX_LONG_LONG_DIGITS;

	// debo cortar digitos
	if (cutdigits > 0) {
		cutdigits1 = digits_to_cut(value1);
		cutdigits2 = digits_to_cut(value2);
		morecut = cutdigits - cutdigits1 - cutdigits2;
		
		// tengo que recortar mas digitos, recorto la cantidad necesaria de cada uno.
		if (morecut > 0)  {
			cutdigits1 = cutdigits1 + (morecut / 2);
			cutdigits2 = cutdigits2 + (morecut / 2);
		} else {

			if (cutdigits1 > cutdigits) {
				cutdigits1 = cutdigits;
				cutdigits2 = 0;
				cutdigits = 0;
			} else {
				cutdigits = cutdigits - cutdigits1;
			}

			if (cutdigits >= 0) {
				cutdigits2 = cutdigits;
			}
			
		}

		cutdigits = cutdigits1 + cutdigits2;
		
		value1 = cut_digits(value1, cutdigits1);
		value2 = cut_digits(value2, cutdigits2);
	}

	if (cutdigits > 0) value3 = cut_digits(value3, cutdigits);
  
	result = value1 * value2;
  
	return result / value3;
}

/**/
decimal_fp *doubleToDecimalFloatPoint(double value, decimal_fp *val)
{
	double d1, d2;
	int i;
	
	d1 = d2 = value;
	/* corre la coma a derecha  y  resulta exponente negativo */
	if (value <= LONG_MAX) { 		
		for (i = 0; i < DFP_PRECITION; ++i) {	
			/* Si pasa los limites del long detiene el formateo */
			if (d1 * 10.0 > LONG_MAX) 
				break;
			d1 = d1 * 10.0;
			d2 = rint(d1);	
			/* Si llega a la precision maxima detiene el formateo */
			if (fabs( d1 - d2)  < DFP_ACURRANCY) {
				i++;
				break;
			}
		}
		i = -i;
	} else {
		/* corre la coma a izquierda y  resulta exponente positivo */
		for (i = 1; ; ++i) {	
			d2 = d2 / 10.0;			
			/* Si entra en el rango entonces sale */
			if (d2 <= LONG_MAX) 
				break;
		}
	}
	
	val->exp = i;
	val->mantise = rint(d2);

	return val;
}

/**/
double decimalFloatPointToDouble(decimal_fp *val)
{
	double m = (double)(val->mantise);
	double e = (double)val->exp;

	if (m == 0) return 0;
	return m * pow(10.0, e);
}

/**/
decimal_fp *moneyToDecimalFloatPoint(money_t  value, decimal_fp *newval)
{
	return doubleToDecimalFloatPoint(value, newval);
}

/**/
money_t decimalFloatPointToMoney(decimal_fp *val)
{
	return decimalFloatPointToDouble(val);
}

/**/
decimal_t moneyToDecimal(money_t value)
{
	int count;
	decimal_t decimal;
	int negative;

	// En valor del importe se guarda con 6 decimales
	if (MONEY_DECIMAL_DIGITS == 7) value = value/10;
	
	count = digits_to_cut(value);
	if (count > 6) count = 6;
	if (count > 0) {
		value = cut_digits(value, count);
	}

	negative = (value < 0);
	ABS(value);
	while (value > LONG_MAX) {
		value = value / 10;
		count++;
	}

	decimal.mantise = negative?0-value:value;
	decimal.exp = count;

	return decimal;
}

/**/
money_t decimalToMoney(decimal_t decimal)
{
	// El valor del importe se guarda con 6 decimales
	return decimal.mantise * llpow(10, decimal.exp+(MONEY_DECIMAL_DIGITS-6));
}

/**/
money_t doubleToMoney(double value)
{
	double d;
	int q = 6;

	// Normaliza el numero.
	d = value * pow(10, q);
	d = rint(d);
	d = d / pow(10, q);

	return d * llpow(10, MONEY_DECIMAL_DIGITS);
}

/**/
double moneyToDouble(money_t value)
{
	return value * 1.0 / llpow(10, MONEY_DECIMAL_DIGITS) * 1.0;
}

/**/
money_t adjustMoneyDecimals(money_t value, int currentDecimals)
{
	return value * llpow(10, MONEY_DECIMAL_DIGITS - currentDecimals);
}

/**/
long long llpow(long long base, int exp)
{
	long long a = base;

	if (base <= 0) return 0;	
	if (exp == 0) base = 1;	
	else if (exp > 0) while (--exp) base *= a;
	else if (exp < 0) while (++exp) base /= a;
	return base;
}

/**/
int compareFloatPoint(decimal_fp *fp1, decimal_fp *fp2)
{
	long long val1, val2;

	val1 = (long long)(fp1->mantise) * llpow(10, fp1->exp);
	val2 = (long long)(fp2->mantise) * llpow(10, fp2->exp);

	if (val1 == val2) return 0;
	if (val1 > val2) return 1;
	return -1;	
}

/**/
#ifdef __WIN32
int isblank(int c)
{
	return c == ' ' || c == '\t' || c == '\v';
}
#endif

/**/
int isblankchar(int c)
{
	return c == ' ' || c == '\t' || c == '\v';
}


/**/
char *trim(char *p)
{
	rtrim(p);
	return ltrim(p);
}

/**/
char *rtrim(char *p)
{
	char *s;
	
	assert(p != NULL);
	
	s = p + strlen(p) - 1;
	while (1) {
		if (!isblankchar(*s)) break;
		if (s-- == p) break;
	};
	
	*(s + 1) = '\0';
	return p;	
}

/**/
char *ltrim(char *p)
{
	while (isblankchar(*p))
		p++;
		
	return p;
}
		
/**/
datetime_t 
encodeTime(int year, int month, int day, int hour, int min, int sec)
{
	struct tm brokenTime;
	datetime_t result; 
	
	if (year < 1970) THROW(DATETIME_EX);
	if (month < 1 || month > 12) THROW(DATETIME_EX);
	if (day < 1 || day > 31) THROW(DATETIME_EX);
	if (hour < 0 || hour > 23)  THROW(DATETIME_EX);
	if (min < 0 || min > 59) THROW(DATETIME_EX);
	if (sec < 0 || sec > 59) THROW(DATETIME_EX);
	
	brokenTime.tm_year = year - 1900;
	brokenTime.tm_mon = month -1;
	brokenTime.tm_mday = day;
	brokenTime.tm_hour = hour;
	brokenTime.tm_min = min;
	brokenTime.tm_sec = sec;

	result = mktime(&brokenTime);
	if (result == -1) THROW(DATETIME_EX);
	return result;	
}

/**/
char *alignString(char *dst , char *src, int n, UTIL_AlignType align)
{
	char format[10];
	
	switch (align) {
	
		case UTIL_AlignRight:

						sprintf(format, "%%%ds", n);
						snprintf(dst, n+1, format, src);						
						dst[n] = 0;
						
						break;
						
		case UTIL_AlignCenter:
		
						
		default: // UTIL_AlignLeft
		
						sprintf(format, "%%-%ds", n);
						snprintf(dst, n+1, format, src);
						dst[n] = 0;
						break;
	
	}

	return dst;
}


/**/
char *
formatMoney(char *dest, char *moneySimbol, money_t amount, int decimals, int maxChars)
{
	char format[25];
	char *p;
	char aux[50];
	char decstr[20];
	int  diff;
	long integer;
	long decimal;
	int  len;
	int  min;
	int  negative = 0;
	
	p = aux;

	integer = amount / llpow(10, MONEY_DECIMAL_DIGITS);
	decimal = amount % llpow(10, MONEY_DECIMAL_DIGITS);

	if (integer < 0 || decimal < 0) negative = 1;
	
	decimal = labs(decimal);
	integer = labs(integer);

	assert(decimals < 20);

	sprintf(aux, "%ld", decimal);
	len = strlen(aux);
	memset(decstr, '0', decimals);
	if ( MONEY_DECIMAL_DIGITS - len < decimals) min = MONEY_DECIMAL_DIGITS; else min = decimals;
	memcpy(&decstr[MONEY_DECIMAL_DIGITS-len], aux, min );
	decstr[decimals] = '\0';

	// Formateo la cadena con simbolo de moneda, y monto con la cantidad
	// de decimales correspondiente
	if (decimals == 0) {
		sprintf( format, "%s %s", "%s", "%s%ld");
		sprintf( p, format, moneySimbol, negative?"-":"", integer);
	}
	else {
		sprintf( format, "%s %s", "%s", "%s%ld.%s");
		sprintf( p, format, moneySimbol, negative?"-":"", integer, decstr);		
	}

	// Si no tenia simbolo de moneda, quito el espacio en blanco innecesario al inicio.
	// Si se pasa de la maxima cantidad de caracteres, en principio
	// quito el simbolo de moneda
	if (strlen(moneySimbol) == 0) p++;
	else if (strlen(p) > maxChars) p += strlen(moneySimbol) + 1;

	// Si sigue sin alcanzar, comienzo a quitar digitos, del menos
	// significativo en adelante, ademas saco el punto si queda solo
	diff = strlen(p) - maxChars;
	if (diff > 0) {
		if (diff == decimals) diff++;
		p[strlen(p) - diff] = 0;
	}

	strcpy(dest, p);

	return dest;
	
}

/**/
char *formatDate(datetime_t date, char *buffer)
{
	struct tm brokenTime;
	localtime_r(&date, &brokenTime);
	strftime (buffer, 11, "%d-%m-%Y", &brokenTime );
	return buffer;
}

/**/
char *formatTime(datetime_t date, char *buffer)
{
	struct tm brokenTime;
	localtime_r(&date, &brokenTime);
	strftime (buffer, 9, "%H:%M:%S", &brokenTime );
	return buffer;	
}

/**/
char *formatDateTime(datetime_t date, char *buffer)
{
	struct tm brokenTime;
	localtime_r(&date, &brokenTime);
	strftime (buffer, 20, "%d-%m-%Y %H:%M", &brokenTime );
	return buffer;	
}

/**/
char *formatDateTimeComplete(datetime_t date, char *buffer)
{
	struct tm brokenTime;
	localtime_r(&date, &brokenTime);
	strftime (buffer, 20, "%d-%m-%Y %H:%M:%S", &brokenTime );
	return buffer;	
}

/**/
char *formatTimeHourMin(datetime_t date, char *buffer)
{
	struct tm brokenTime;
	localtime_r(&date, &brokenTime);
	strftime (buffer, 20, "%H:%M", &brokenTime );
	return buffer;	
}


/**/
char *loadFile(char *fileName, BOOL appendZero)
{
  FILE *file;
	char *buffer;
  int  size;

  file = fopen(fileName, "rb");
	if (!file) return NULL;

  fseek(file,0,SEEK_END);
  size = ftell(file);
	if (appendZero) 
		buffer = malloc(size+1);
	else
		buffer = malloc(size);

  rewind(file);
  fread(buffer, size, 1, file);
	fclose(file);

	if (appendZero) buffer[size] = 0;

  return buffer;
}

/**/
void sysRandomize(void)
{
	srand((unsigned long)getTicks());
}


/**/
int sysRandom(int from, int to)
{
	double n = to-from+1;
	int ran = from + (int) ((n)*rand()/(RAND_MAX+1.0));
	assert(ran >= from);
	assert(ran <= to);
	return ran;
}

/**/
char* formatFloatAmount(char* dest, int integerQty, int decimalQty,
						double amount, int includeSeparator)
{
  char tempAmount[30];
  char final[30];
  char format[20];
  int i = 0;
  int decimalPoint = 0;
  int aux;

  sprintf(format, "%s%s%d%s", "%", ".", decimalQty, "f");

  /*strcpy(&final[integerQty+decimalQty], "\0");*/

  sprintf(tempAmount, format, amount);

  if (decimalQty > 0) ++decimalPoint;

  aux = integerQty - (strlen(tempAmount) - decimalQty - decimalPoint);

  if  (aux < 0)
    THROW(INVALID_NUMBER_TO_FORMAT_EX);

  for (i=0; i<( integerQty - (strlen(tempAmount) - decimalQty - decimalPoint) )  ; ++i)
    memcpy(&final[i], "0", 1);
    
  memcpy(&final[i], tempAmount, strlen(tempAmount));
  strcpy(&final[i+strlen(tempAmount)], "\0");
  
  if ( !(includeSeparator) ) {
    strncpy(dest, final, integerQty);
    strcpy(&dest[integerQty], "\0");
    strcat(dest, &final[integerQty+1]);
    strcpy(&dest[integerQty+decimalQty+1], "\0");
  } else strcpy(dest, final);

//  doLog(0,"formatFloatAmount --> dest = [%s] \n", dest);

  return dest;
} 

/**/
money_t stringToMoney(char *str)
{
	char aux[40];
	char *index;
	money_t result;
  int negative = 1;

  if (*str == '-') {
    negative = -1;
    strcpy(aux, &str[1]);
   }
  else
	 strcpy(aux, str);
	index = strchr(aux, '.');

	if (index == NULL) {
		return negative * atol(aux) * llpow(10, MONEY_DECIMAL_DIGITS);
	} else {
		*index = 0;
		result = (long long)atol(aux) * (long long)llpow(10, MONEY_DECIMAL_DIGITS); 
		result = (result + (atol(index+1) * llpow(10, MONEY_DECIMAL_DIGITS-strlen(index+1)))) * negative;
		return result;
	}

}

/**/
char * fillTextSpecialCharacter(char* doc, char* finalDoc) 
{
  int count = 0;
  char *p = doc;
      
  while ( *p != '\0' ) {
    
    if (*p != '\n')
      finalDoc[count] = *p;
    else 
      if (*p == '\\') {
        finalDoc[count] = '\\';
        count++;
        finalDoc[count] = '5';
        count++;
        finalDoc[count] = 'C';
      } else {
      finalDoc[count] = '\\';
      count++;
      finalDoc[count] = '0';
      count++;
      finalDoc[count] = 'A';
    }      

    count++;
    p++;  
    
   }     

  return finalDoc;
}


static unsigned char encryptMatrix[256] = {167,243,104,103,169,18,36,185,137,131,204,72,147,96,28,161,162,34,231,201,77,149,230,199,192,11,136,220,23,227,148,60,241,228,7,174,69,83,31,255,209,124,65,78,146,46,5,216,66,84,180,89,178,212,9,115,102,87,29,198,42,68,129,94,236,155,39,197,151,41,160,32,163,80,186,164,49,108,120,139,122,109,43,184,152,98,219,217,193,233,76,112,252,150,239,251,138,99,58,126,156,0,203,25,218,187,254,229,116,240,153,248,97,135,222,38,125,91,225,62,133,13,213,189,242,33,53,118,176,190,130,50,234,51,27,56,172,44,30,194,158,143,26,15,12,24,165,170,235,64,117,249,221,154,157,119,171,205,10,253,67,232,195,173,6,200,4,175,196,105,226,224,59,106,211,61,74,237,90,145,207,93,75,95,247,179,1,48,45,238,132,210,144,246,113,142,114,22,57,177,52,85,3,134,168,71,159,127,215,244,86,208,2,81,14,182,123,107,191,141,40,214,183,128,206,250,73,35,181,37,16,8,202,100,166,47,140,19,223,88,82,101,20,21,54,110,245,17,121,79,55,111,92,188,63,70};
static unsigned char decryptMatrix[256] = {101,186,212,202,166,46,164,34,231,54,158,25,144,121,214,143,230,247,5,237,242,243,197,28,145,103,142,134,14,58,138,38,71,125,17,227,6,229,115,66,220,69,60,82,137,188,45,235,187,76,131,133,200,126,244,250,135,198,98,172,31,175,119,254,149,42,48,160,61,36,255,205,11,226,176,182,90,20,43,249,73,213,240,37,49,201,210,57,239,51,178,117,252,181,63,183,13,112,85,97,233,241,56,3,2,169,173,217,77,81,245,251,91,194,196,55,108,150,127,155,78,248,80,216,41,116,99,207,223,62,130,9,190,120,203,113,26,8,96,79,236,219,195,141,192,179,44,12,30,21,93,68,84,110,153,65,100,154,140,206,70,15,16,72,75,146,234,0,204,4,147,156,136,163,35,167,128,199,52,185,50,228,215,222,83,7,74,105,253,123,129,218,24,88,139,162,168,67,59,23,165,19,232,102,10,157,224,180,211,40,191,174,53,122,221,208,47,87,104,86,27,152,114,238,171,118,170,29,33,107,22,18,161,89,132,148,64,177,189,94,109,32,124,1,209,246,193,184,111,151,225,95,92,159,106,39};

/**/
char *encryptSimple(unsigned char *dest, unsigned char *source, int qty) 
{
  int i;

  for (i = 0; i < qty; i++) {
    dest[i] = encryptMatrix[source[i]];
  }

  return dest;
}

/**/
char *decryptSimple(unsigned char *dest, unsigned char *source, int qty) 
{
  int i;

  for (i = 0; i < qty; i++) {
    dest[i] = decryptMatrix[source[i]];
  }

  return dest;
}

/**/
char *decryptFile(char *fileName)
{
  FILE *file;
	char *buffer;
  int  size;

  file = fopen(fileName, "rb");
	if (!file) return NULL;

  fseek(file,0,SEEK_END);
  size = ftell(file);
	buffer = malloc(size+1);

  rewind(file);
  fread(buffer, size, 1, file);
	fclose(file);
  
  decryptSimple(buffer, buffer, size);
  
	buffer[size] = 0;

  return buffer;
}


/*
* intf = interface name : "eth0"
* rslt = retorna la mac address
*/
 
 /*se invoca de la siguiente manera -> if_netInfo("eth0", rslt) */
int if_netInfo  (char *intf , char *rslt){
 struct ifconf Ifc; 
 struct ifreq IfcBuf[MAX_NUM_IFREQ], *pIfr; 
 int num_ifreq, i, fd; 
 char tmp[50];

 *rslt = '\0';

 Ifc.ifc_len=sizeof(IfcBuf); 
 Ifc.ifc_buf=(char *)IfcBuf; 
 if ((fd=socket(AF_INET, SOCK_DGRAM, 0))<0) { return -1; }
 if (ioctl(fd, SIOCGIFCONF, &Ifc)<0) { /*doLog(0,"ioctl(SIOCGIFCONF)\n");*/close(fd); return -1; } 

 num_ifreq=Ifc.ifc_len/sizeof(struct ifreq); 

 for (pIfr=Ifc.ifc_req, i=0; i<num_ifreq; ++pIfr, ++i) 
 {

	if (pIfr->ifr_addr.sa_family != AF_INET) continue;

	if (strcmp(pIfr->ifr_name,intf)!=0) continue;  // filtro por interfaz solicitada
  	//MACADDRESS
  	if (ioctl(fd,SIOCGIFHWADDR, pIfr)<0) { continue; }

		sprintf(tmp,"%02X:%02X:%02X:%02X:%02X:%02X", 
			(int) ((unsigned char *) &pIfr->ifr_hwaddr.sa_data)[0],
			(int) ((unsigned char *) &pIfr->ifr_hwaddr.sa_data)[1],
			(int) ((unsigned char *) &pIfr->ifr_hwaddr.sa_data)[2],
			(int) ((unsigned char *) &pIfr->ifr_hwaddr.sa_data)[3],
			(int) ((unsigned char *) &pIfr->ifr_hwaddr.sa_data)[4],
			(int) ((unsigned char *) &pIfr->ifr_hwaddr.sa_data)[5]);

	  strcpy(rslt, tmp);
	  close(fd);

    return 0;   	
  } // for
  

 close(fd); 
 return 0;
}

/**/
void get_mac (char* aMac)
{
	FILE *f;
	char fileName[200];
	char buffer[500];

	// obtengo la mac
	if_netInfo("eth0", aMac);
	strrep(aMac, ':', '-');

	// si la mac esta vacia es porque estoy sin red y con DHCP habilitado.
	// La obtengo directamente del archivo
	if (strlen(aMac) == 0) {
		strcpy(fileName, "mac.ini");
		f = fopen(fileName, "r");
	
		if (f) {
			
			if (!feof(f)) {
				fgets(buffer, 500, f);
				strcpy(aMac, buffer);
			}
	
			fclose(f);
		}
	}

}

/**/
int if_netInfo_with_dhcp (char *intf , char *ip, char *mask, char *gateway)
{
 struct ifconf Ifc;
 struct ifreq IfcBuf[MAX_NUM_IFREQ], *pIfr;
 int num_ifreq, i, fd;
 struct sockaddr_in addrtmp;

 *ip = '\0';
 *mask = '\0';
 *gateway = '\0';

 Ifc.ifc_len=sizeof(IfcBuf); 
 Ifc.ifc_buf=(char *)IfcBuf; 
 if ((fd=socket(AF_INET, SOCK_DGRAM, 0))<0) { return -1; }
 if (ioctl(fd, SIOCGIFCONF, &Ifc)<0) { /*doLog(0,"ioctl(SIOCGIFCONF)\n");*/close(fd); return -1; } 

 num_ifreq=Ifc.ifc_len/sizeof(struct ifreq);

 for (pIfr=Ifc.ifc_req, i=0; i<num_ifreq; ++pIfr, ++i) 
 {

		if (pIfr->ifr_addr.sa_family != AF_INET) continue;

		if (strcmp(pIfr->ifr_name,intf)!=0) continue;  // filtro por interfaz solicitada

  	//IP ADDRESS
  	if (ioctl(fd, SIOCGIFADDR, pIfr)<0) continue;
  	memcpy(&addrtmp,&(pIfr->ifr_addr),sizeof(addrtmp));
		//doLog(0,"IP: %s *******************************\n", inet_ntoa(addrtmp.sin_addr));
		strcpy(ip,inet_ntoa(addrtmp.sin_addr));

  	//MASK ADDRESS
  	if (ioctl(fd, SIOCGIFNETMASK, pIfr)<0) continue;
  	memcpy(&addrtmp,&(pIfr->ifr_addr),sizeof(addrtmp));
		//doLog(0,"MASK: %s *******************************\n", inet_ntoa(addrtmp.sin_addr));
		strcpy(mask,inet_ntoa(addrtmp.sin_addr));

		//GATEWAY
		get_default_gateway(intf, gateway);

	  close(fd);

    return 0;   	
  } // for
  

 close(fd); 
 return 0;
}

int get_default_gateway (char *intf, char *gateway)
{
	char *z;
	char interface[50];

 	FILE *fp = fopen ("/proc/net/route", "r");
	*gateway = 0;

	if (fp) {
			char line[256];
			int count = 0;
			int best_count = 0;
			unsigned int lowest_metric = ~0;
			in_addr_t best_gw = 0;
     	while (fgets (line, sizeof (line), fp) != NULL) {
          unsigned int net_x = 0;
          unsigned int mask_x = 0;
          unsigned int gw_x = 0;
          unsigned int metric = 0;
          const int np = sscanf (line, "%s\t%x\t%x\t%*s\t%*s\t%*s\t%d\t%x",
                     &interface,
										 &net_x,
                     &gw_x,
                     &metric,
                     &mask_x);
					if (np == 5) {
						const in_addr_t net = ntohl (net_x);
						const in_addr_t mask = ntohl (mask_x);
						const in_addr_t gw = ntohl (gw_x);
	
						if (gw_x == 0) continue;
						if (strcmp(interface, intf) != 0) continue;
						
						z = inet_ntoa(*(struct in_addr *)&gw);
						strcpy(gateway, z);
						doLog(0,"GATEWAY: %s ****************************\n", gateway);
						fclose (fp);
						return 1;
        	}
    	}
      fclose (fp);
	}

 	return 0;
}

/**/
static void idx_calc(size_t posn, size_t *idx, size_t *ofs)
{
      *idx = posn / 8;       /* Byte index [0-N] in the array    */
      *ofs = posn % 8;       /* Bit number [0-N] within the byte */
}

/**/
int getbit(unsigned char  *set, int number)
{
      size_t idx, ofs;

      idx_calc(number, &idx, &ofs);
      set += idx;
      return (*set & (1 << ofs)) != 0;                      /* 0 or 1   */
}

/**/
void setbit(unsigned char *set, int number, int value)
{
      size_t idx, ofs;

      idx_calc(number, &idx, &ofs);
      set += idx;
      if (value)
            *set |= 1 << ofs;                               /* set bit  */
      else  *set &= ~(1 << ofs);                            /* clear bit*/
}

/**/
void flipbit(unsigned char  *set, int number)
{
      size_t idx, ofs;

      idx_calc(number, &idx, &ofs);
      set += idx;
      *set ^= 1 << ofs;                                     /* flip bit */
}

/**/
void loadIPConfig(char* aDHCP, char* anIpAddress, char* aNetMask, char* aGateway)
{
	char *buffer;
	char *index, *toIndex;
	char value[255];

	// inicializo las variables
	strcpy(aDHCP,"no");
	*anIpAddress = 0;
	*aNetMask = 0;
	*aGateway = 0;

	buffer = loadFile(ETH0_FILE_NAME, TRUE);
	if (!buffer) return;

	// me fijo si tiene habilitado el DHCP
	index = strstr(buffer, "dhcp: ");
	if (!index) return;
	index = index + strlen("dhcp: ");
	toIndex = strstr(index, "\n");
	strncpy(value, index, toIndex - index);
	value[toIndex-index] = 0;
	strcpy(aDHCP, value);

	// Si DHCP no esta configurado levanto los datos del archivo de configuracion.
  // En caso contrario utilizo la funcion if_netInfo_with_dhcp
	if (strcmp(aDHCP, "no") == 0) {

		index = strstr(buffer, "address: ");
		if (!index) return;
		index = index + strlen("address: ");
		toIndex = strstr(index, "\n");
		strncpy(value, index, toIndex - index);
		value[toIndex-index] = 0;
		strcpy(anIpAddress, value);
	
		index = strstr(buffer, "netmask: ");
		if (!index) return;
		index = index + strlen("netmask: ");
		toIndex = strstr(index, "\n");
		strncpy(value, index, toIndex - index);
		value[toIndex-index] = 0;
		strcpy(aNetMask, value);
	
		index = strstr(buffer, "gateway: ");
		if (!index) return;
		index = index + strlen("gateway: ");
		toIndex = strstr(index, "\n");
		strncpy(value, index, toIndex - index);
		value[toIndex-index] = 0;
		strcpy(aGateway, value);

	} else {

		if_netInfo_with_dhcp("eth0", anIpAddress, aNetMask, aGateway);

	}

	free(buffer);
}

/**/
void loadIPConfigFromFile(char* aDHCP, char* anIpAddress, char* aNetMask, char* aGateway)
{
	char *buffer;
	char *index, *toIndex;
	char value[255];

	// inicializo las variables
	strcpy(aDHCP,"no");
	*anIpAddress = 0;
	*aNetMask = 0;
	*aGateway = 0;

	buffer = loadFile(ETH0_FILE_NAME, TRUE);
	if (!buffer) return;

	// me fijo si tiene habilitado el DHCP
	index = strstr(buffer, "dhcp: ");
	if (!index) return;
	index = index + strlen("dhcp: ");
	toIndex = strstr(index, "\n");
	strncpy(value, index, toIndex - index);
	value[toIndex-index] = 0;
	strcpy(aDHCP, value);

	index = strstr(buffer, "address: ");
	if (!index) return;
	index = index + strlen("address: ");
	toIndex = strstr(index, "\n");
	strncpy(value, index, toIndex - index);
	value[toIndex-index] = 0;
	strcpy(anIpAddress, value);

	index = strstr(buffer, "netmask: ");
	if (!index) return;
	index = index + strlen("netmask: ");
	toIndex = strstr(index, "\n");
	strncpy(value, index, toIndex - index);
	value[toIndex-index] = 0;
	strcpy(aNetMask, value);

	index = strstr(buffer, "gateway: ");
	if (!index) return;
	index = index + strlen("gateway: ");
	toIndex = strstr(index, "\n");
	strncpy(value, index, toIndex - index);
	value[toIndex-index] = 0;
	strcpy(aGateway, value);

	free(buffer);
}

/**/
char* formatText (char *originalText, char* finalText)
{ 
	char *p = originalText;
	char token[500];
	char line[30];
	char wd[24];
	
	id myTokenizer = [StringTokenizer new];
	[myTokenizer setDelimiter: " "];
	[myTokenizer setTrimMode: TRIM_ALL];
	
	[myTokenizer setText: p];

  line[0] = '\0';
  finalText[0] = '\0';
  
	while ([myTokenizer hasMoreTokens]) {
	  [myTokenizer getNextToken: token];
    
    if (strlen(token) > PRINTER_LINE_LEN) strncpy2(wd, token, PRINTER_LINE_LEN-2);
    else strcpy(wd, token);

    strcat(wd, " ");
/*    
    printd("-------------------------------------------\n");      
    printd("word = %s\n", wd);
    printd("strlen(wd) = %d\n", strlen(wd));
    printd("strlen(line) = %d\n", strlen(line));
    printd("resultado (LINE_LEN - strlen(line)) = %d\n", LINE_LEN - strlen(line));
    printd("-------------------------------------------\n");    
*/      
    if (strlen(wd) > (PRINTER_LINE_LEN - strlen(line))) {
      strcat(line, "\n");
      strcat(finalText, line);
      line[0] = '\0';
    } 
    strcat(line, wd);
	}
	
	strcat(finalText, line);
	free(p);
	return finalText;
	
	return 0;
}



/**/
char *wordwrap( char *instring, int wrap_pnt, int wrap_mgn, char *outstring )
{
int i;
char *in;
char *out;

/* PERFORM SANITY CHECKS - MAKE SURE WE DON'T PARSE GARBAGE */

if( instring == outstring ) return (NULL);
if( NULL == instring ) return (NULL);
if( NULL == outstring ) return (NULL);
if( wrap_pnt < wrap_mgn ) return (NULL);
if( wrap_pnt < 1 ) return (NULL);
if( wrap_mgn < 0 ) return (NULL);


/* START WITH A SIMPLEMINDED COPY */
in = instring;
while (*in == ' ') in++;

out = outstring;
for ( i=0; i<wrap_pnt; i++ )
{
if ( '\0'==*in ) break;
*out = *in;
out++; in++;
}
*out='\0';


/* DID WE REACH THE END OF INPUT BEFORE THE FILLING THE OUTPUT? */
/* IF YES, JUST RETURN THE END OF STRING LOCATION. */

if ( '\0'==*in ) return (in);



/* THE OUTPUT BUFFER IS FULL, BACK UP TO FIND THE SPLIT POINT */

for ( i=0; i<wrap_mgn; i++, in-- )
{
/* IF WHITESPACE FOUND THEN MAKE THE BREAK */

if ( *in <= ' ' ) break;

}

/* IF NO WHITESPACE TO SPLIT ON, THEN TRUNCATE */

if ( i==wrap_mgn )
{
i=0 ;
in=in+wrap_mgn;
}
out=out-i; /* BACKUP TO THE WHITESPACE */
*out='\0'; /* OVERWRITE THE WHITESPACE CHAR. WITH TERMINATOR */

return(in);
}
/************************************************** ****************/ 


