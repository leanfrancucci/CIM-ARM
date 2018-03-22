/**
 *	@file:lcdlib.c
 *		This is the interface of LCD driver
 *		It is used as a user library.
 *		It is a wrapper over the driver functions
 */
#include <stdio.h>
#include <stdarg.h>
#include <assert.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include "log.h"

//#include "include/lcddrv/defines.h"
#include "lcddriver.h"
#include "lcdlib.h"
#include <lcd.h>
#include "unicodecvtr.h"

/**
 * Node definition
 */

#define LCD_DEVICE	"/dev/lcdnod11"

static int opened = 0;

static int fd;
static int dline = 1;

#define LCDBUFSIZE (MAX_BYTES_CHAR * MAX_LCD_CHARS * MAX_LCD_LINES)

static char buf[LCDBUFSIZE];
static char pbuf[LCDBUFSIZE];



/**
 *	lcd_open
 *  	    Open with default size, 2x20
 *
 */
int
lcd_open( void )
{

	if (opened) {
	//	doLog(0,"Library already opened!!\n");
		return 1;
	}

	//doLog(0,"ERROR %s\n", LCD_DEVICE);
	
	fd = open(LCD_DEVICE, O_WRONLY);
	if (fd < 0) {
		return fd;
	}
	
	opened = 1;
	return fd;
}



/**
 *  	lcd_initopen
 *  	    Receives the type of the lcd diplay (view lcd_types.h)
 */

int
lcd_initopen( int lcd_type )
{
	int ret;

	if((ret = lcd_open()) >= 0) return ret;
	    //if((ret2 = ioctl(fd, LCD_IOCTREOPEN, lcd_type)) < 0)
                //return ret2;

	return ret;
}

/**
 *      lcd_clear
 *	    Clear the display
 */
int 
lcd_clear(void)
{
	return ioctl(fd, LCD_IOCCLEARDISPLAY, 0);
}

/**
 *	lcd_putchar
 *	    Puts a char in cursor position
 *	    There is no error return
 */
int 
lcd_putchar( char *c )
{
    unsigned char x  = unicode_process_char(&c);
    return lcd_write( &x, 1);
}

/**
 *	lcd_write
 */
int
lcd_write(const char *str, int length)
{
	unicode_process_string( str , pbuf);
    
    //printf(" lcd_write str = %s pbuf = %s strlen (pbuf) = %d\n", str, pbuf, strlen(pbuf));
    
	return write(fd,pbuf, strlen(pbuf));
}

/**
 *	lcd_close
 *	    Closes LCD handler 
 */
int 
lcd_close()
{
	opened = 0;
	return close(fd);
}



/**
 * 	lcd_set_tabstop
 * 	    Sets Tab Stop positions
 *	    Must be between 1 and MAX_TS
 */
int
lcd_set_tabstop(int ts)
{
	return ioctl(fd, LCD_IOCTSETTABSTOP, ts);
}

/**
 *	lcd_set_cursorxy
 *	    Sets new cursor position
 *	    Cursor Position must not be out limits
 */
int
lcd_set_cursorxy(int x, int y)
{
	long xy;

	xy = (((y) << 8) | (x));
	return ioctl(fd, LCD_IOCTSETCURSORXY, xy);
}

/**
 *	lcd_settext_blink
 *	    Sets Text Blinking On or Off, 
 *	    depending on argument ToOn
 */
int 
lcd_set_text_blink(int toOn)
{
	return ioctl(fd,LCD_IOCTSETTEXTBLINK, toOn);
}

/**
 *	lcd_set_cursor_blink
 *	    Sets Cursor Blinking On or Off, 
 *	    depending on argument ToOn
 */
int
lcd_set_cursor_blink(int toOn)
{
	return ioctl(fd,LCD_IOCTSETCURSORBLINK, toOn);
}

/**
 *	lcd_set_cursor_state
 *	    Sets Cursor State (visible or not), 
 *	    depending on argument ToOn
 */
int
lcd_set_cursor_state(int toOn)
{
	return ioctl(fd,LCD_IOCTSETCURSORSTATE, toOn);
}

/**
 *	lcd_set_display_state
 *	    Sets Display State (visible or not), 
 *	    depending on argument ToOn
 */
int
lcd_set_display_state(int toOn)
{
	return ioctl(fd,LCD_IOCTSETDISPLAYSTATE, toOn);
}

/**
 * lcd_programchar
 */
int
lcd_programchar(int index_char, unsigned char *pfont )
{
	struct LCDProgramChar pc;

	pc.index_char = index_char;
	memcpy(pc.pfont, pfont, LCD_PROGCHAR_ROW_SIZE);
	pc.num_rows = LCD_PROGCHAR_ROW_SIZE;
	return ioctl(fd, LCD_IOCSPROGRAMCHAR, (long)&pc);
}

/**
 *      lcd_setfont
 *	    Sets a new font.
 *	    It causes an lcd_clear
 *	    (Not Impletemented)
 */
int 
lcd_setfont( int font )
{
	return ioctl(fd, LCD_IOCTFONT, font);
}

/**
 *	lcd_print
 *	    Prints an string at current position
 *	    fmt argument as in printf
 */
int 
lcd_print( const char *fmt, ... )
{
	int ret;
	va_list ap;	

	va_start(ap, fmt);	
	vsnprintf(buf, sizeof(buf), fmt, ap);
	unicode_process_string( buf , pbuf);
	ret = write(fd, pbuf, strlen(pbuf));
	va_end(ap);

	return ret;
}

/**
 *	lcd_printat
 *	    Prints an string at position set in x and y
 *	    fmt argument as in printf
 */
int
lcd_printat( int x, int y, const char *fmt, ... )
{
    int ret;
    va_list ap;

    va_start(ap, fmt);
    if ((ret = lcd_set_cursorxy(x, y)) < 0 ) return ret;
    vsnprintf(buf, sizeof(buf), fmt, ap);
    unicode_process_string( buf , pbuf);
    ret = write(fd, pbuf, strlen(pbuf));
    va_end(ap);

    return ret;
}

/**
 *      lcd_get_type
 * 	    Return the type number of the lcd device set 
 * 	    in lcd module driver.
 *
 */
int
lcd_get_type(void)
{
	return -1;
}

/**
 *      lcd_get_numlines
 * 	    Return the number of lines (rows) of 
 * 	    the actual device
 */
int
lcd_get_numlines(void)
{
	return ioctl(fd,LCD_IOCQNUMLINES, 0);
}

/**
 *      lcd_get_chars
 * 	    Return the number of characters per line (cols)
 * 	    of the actual device
 */
int
lcd_get_numchars(void)
{
	return ioctl(fd,LCD_IOCQNUMCHARS, 0);
}

/**/
void _dprintf(char *fmt, ...)
{		
	va_list ap;			
	
	//doLog(0,"%d: ", dline++);  
	
	va_start(ap, fmt);	
	vprintf (fmt, ap);	
	va_end(ap);

	fflush(stdout);
	
	return;	
}
