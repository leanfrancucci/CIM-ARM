/* System defines */


#undef 	__DOS__
#undef 	__QY1__


/*
 * Timers defines 
 *
 */
#define CTIMERS
#undef  USEC_CTIMERS
#define MAX_CTIMERS			4 

/*
 * If the main program is an unconditional forever loop then undefine this macros.
 * If the macro are undefined then the cleanup_...() and close_..() functiones are not defined.
 */
#define CLEANUP_DRIVERS
#define CLOSE_DRIVERS


/*
 * Keypad defines 
 *
 */
#define CURRENT_ROWS		8 
#define CURRENT_COLS		8

/* 
 * LCD defines 
 *
 */

/* Max number of display allowed */
#define MAX_LCD_DEVICES		4
/* Number of display installed on the system */
#define NUM_LCD_DEVICES		4

/* The max numbers of rows and cols of the lcd installed */
#define LCD_MAX_CHARS		40
#define LCD_MAX_LINES		4

/* Define __LCDIMAGE if the project uses lcdimage.c module or
   define __LCDDMAP if the project uses lcddmap.c */
#define __LCDIMAGE
/* #define __LCDDMAP  */


/* If the macro is defined the drivers checks the lcd identifier
   argument of each function.
   If not defined the drivers saves aprox. 200 bytes of ROM. */
#define CHECK_LCDID
/* Check if the lcd display is opened or not */
#define CHECK_LCD_OPENED

/* If tiny proc then blinking text not defined (dont touch this definition )*/
#ifdef __TINY_PROC__
  #define LCD_TINY_DRIVER
#else
  #undef LCD_TINY_DRIVER
#endif  

/* If no cursor needed undefine the macro. 
   If the macro is undefined the cursor is always off.*/
#define LCD_CURSOR

/* 	The lcd font functionality.
	The lcd sets the default font.  */
#define LCD_FONT

/* Undefine the macro if char programming functionalitty is no nedeed. */
#define LCD_PROGRAM_CHAR

/* If tab stop setting is no needed undef the macro.
	The driver will set LCD_DEFAULT_TS for all devices . 
	The driver accepts a '\t' escape character to print a LCD_DEFAULT_TS tabstop. */
#define LCD_TABSTOP

/* Undef the macro if the functions get_display_num_chars() and get_display_num_lines()
	are no nedded.*/
#define LCD_GETSIZE


/* The driver accepts multiple dinamic types.
   For small projects undefine the macro */
#define LCD_MULTIPLE_TYPES

/* If the types of the devices are defined at compilation time then
   you must define the size and the map ram adress of each device */
#ifndef 	LCD_MULTIPLE_TYPES
	
	/*				 	  num_chars , 	num_lines 	, map_address 	*/
	#define	LCD_0_DEFS	 {16 	, 	2 		, { 0x00, 0x040 } }
	#define	LCD_1_DEFS	,{16 	,	2 		, { 0x00, 0x040 } }
	#define	LCD_2_DEFS
	#define LCD_3_DEFS
	
#endif


