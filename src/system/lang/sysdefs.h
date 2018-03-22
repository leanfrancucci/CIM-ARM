#ifndef _SSYSDEFS_H__
#define _SSYSDEFS_H__


/******************************************************************************
* M A C R O S
******************************************************************************/
#ifndef NULL
#define NULL (void*)0
#endif

#define CONST const
/******************************************************************************
* T I P O S    D E    D A T O S    S T A N D A R D
******************************************************************************/

#define COLLECTION id

typedef unsigned long datetime_t;	
//typedef double money_t;
typedef long long money_t;
typedef long percent_t;

#define MONEY_DECIMAL_DIGITS 7

typedef struct
{
	int		exp;
	long	mantise;

} decimal_fp;

typedef struct {
	int		exp;
	long	mantise;
} decimal_t;

#ifndef Int
typedef int  Int;      /** el int definido por la plataforma */
#endif
#ifndef UInt8
typedef unsigned  char  UInt8;      /** un char sin signo */
#endif
#ifndef UInt16
typedef unsigned  short UInt16;     /** un entero sin signo */
#endif
#ifndef UInt24
typedef unsigned  int   UInt24;     /** un entero sin signo */
#endif
#ifndef UInt32
typedef unsigned  long  UInt32;     /** un entero sin signo */
#endif
#ifndef Int8
typedef           char  Int8;       /** un char con signo */
#endif
#ifndef Int16
typedef           short Int16;      /** un entero con signo */
#endif
#ifndef Int24
typedef           int   Int24;      /** un entero con signo */
#endif
#ifndef Int32
typedef           long  Int32;      /** un entero con signo */
#endif
#ifndef Char
typedef           char  Char;       /** un char */
#endif
#ifndef UChar
typedef unsigned  char  UChar;      /** un char */
#endif
#ifndef Money
typedef           long  Money;      /** Moneda */
#endif
#ifndef Perc
typedef           int   Perc;       /** Porcentajes */
#endif
#ifndef Long
typedef           long  Long;       /** Long */
#endif

/**
typedef enum { FALSE, TRUE } Bool;
*/
#define FALSE		0
#define TRUE 		1
typedef int Bool;


#define ON  TRUE
#define OFF FALSE

#ifndef BOOL_DEFINED_
#define BOOL_DEFINED_
#ifndef BOOL
typedef char BOOL;
#endif
#endif

/** Funcion de debugging */
void _dprintf(char *fmt, ...);


#endif

