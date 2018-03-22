/*
 * 		lcdlib.h
 * 			This is the interface of LCD driver
 *			It is used as a user library.
 *			It is a wrapper over the driver functions
 */


/*
 *	Module constants
 */

/*
 *	Maximum display size
 */

#define MAX_LCD_CHARS	40
#define MAX_LCD_LINES	4

/*
 *	Maximum Tab Stop Size
 */

#define MAX_LCD_TS		8

/*
 * 		Module public functions
 */

/*
 *			Unless otherwise stated, functions
 *			returns 0 on success, -1 on error
 *			errno has code of error
 */
/*
 *		lcd_open
 *			Open with default size, 2x20
 *
 */
int lcd_open( void );
/*
 *  	lcd_initopen
 *  		Receives the type of the lcd diplay (view lcd_types.h)
 */

int lcd_initopen( int lcd_type );

/*
 *----- 	Functions accesed through ioctl
 *-----
 */

/*
 * lcd_clear
 *	Clear the display
 */
int lcd_clear(void);


/*
 *	lcd_setfont
 *		Sets a new font.
 *		It causes an lcd_clear
 */

int lcd_setfont( int font );		/*	EAM: no esta hecha en el driver aun */

/*
 * 	lcd_set_tabstop
 * 		Sets Tab Stop positions
 *	Must be between 1 and MAX_TS
 */

int lcd_set_tabstop( int ts );

/*
 *	lcd_set_cursorxy
 *		Sets new cursor position
 *		Cursor Position must not be out limits
 */

int lcd_set_cursorxy( int x, int y );

/*
 *	lcd_settext_blink
 *		Sets Text Blinking On or Off, depending on
 *		argument ToOn
 */

int lcd_set_text_blink( int ToOn );

/*
 *	lcd_set_cursor_blink
 *		Sets Cursor Blinking On or Off, depending on
 *		argument ToOn
 */

int lcd_set_cursor_blink( int ToOn );

/*
 *	lcd_set_cursor_state
 *		Sets Cursor State (visible or not), depending on
 *		argument ToOn
 */

int lcd_set_cursor_state( int ToOn );

/*
 *	lcd_set_display_state
 *		Sets Display State (visible or not), depending on
 *		argument ToOn
 */

int lcd_set_display_state( int ToOn );

/*
 *	lcd_putchar
 *		Puts a char in cursor position
 *		There is no error return
 */

int lcd_putchar( int c );

/*
 *	lcd_print
 *		Prints an string at current position
 *		fmt argument as in doLog
 */

int lcd_print( const char *fmt, ... );

/*
 *	lcd_printat
 *		Prints an string at position set in x and y
 *		fmt argument as in doLog
 */

int lcd_printat( int x, int y, const char *fmt, ... );

/*
 *	lcd_close
 *		Closes LCD workings
 *
 */

int lcd_close( void );

/*
 *	lcd_write
 *
 */
int lcd_write(const char *str, int length);

/*
 * lcd_get_type
 * 	Return the type number of the lcd device set in lcd module driver.
 *
 */
int lcd_get_type(void);

/*
 * lcd_get_numlines
 * 	Return the number of lines (rows) of the actual device
 */
int lcd_get_numlines(void);

/*
 * lcd_get_chars
 * 	Return the number of characters per line (cols) of the actual device
 */
int lcd_get_numchars(void);



