/*
 *	lcdlib.c
 */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <assert.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <stdio.h>
#include <unistd.h>

#include <lcd.h>
#include <lcddriver.h>
#include <lcdlib.h>

#define LCD_DEVICE	"/dev/lcd_0"

static int opened = 0;
static int fd;
static int dline = 1;

int
lcd_open( void )
{
	if (opened) {
		//doLog(0,"Library already opened!!\n");
		return 1;
	}
	fd = open(LCD_DEVICE, O_WRONLY);
	if (fd < 0)
		return fd;

	opened = 1;
	return fd;
}

int
lcd_initopen( int lcd_type )
{
	int ret;
	
	if ((ret = lcd_open()) < 0) return ret;	
	//if ((ret2 = ioctl(fd, LCD_IOCTREOPEN, lcd_type)) < 0) return ret2;
	return ret;
}
	

int 
lcd_clear(void)
{
	int ret = 0;
//	//ret = ioctl(fd, LCD_IOCCLEARDISPLAY, 0);
//	ret = ioctl(fd, OLD_LCD_IOCCLEARDISPLAY, 0);
	lcd_printat( 1, 1, "%s", "                    ");
	lcd_printat( 1, 2, "%s", "                    ");
	lcd_printat( 1, 3, "%s", "                    ");
	lcd_printat( 1, 4, "%s", "                    ");
	return ret;
}

int lcd_putchar( int c )
{
	return lcd_write( (char *)&c, 1);
}

int
lcd_write(const char *str, int length)
{
	int ret = write(fd,str, length);
	return ret;
}

int 
lcd_close()
{
	return close(fd);
}

int
lcd_set_tabstop(int ts)
{
	int ret = 0;
	ret = ioctl(fd, LCD_IOCTSETTABSTOP, ts);
	return ret;
}

int
lcd_set_cursorxy(int x, int y)
{
	int ret;
	long xy;
	
	xy = (((y) << 8) | (x));
	ret = ioctl(fd, LCD_IOCTSETCURSORXY, xy);
	
	//doLog(0,"lcd_set_cursorxy(x=%d, y=%d) ret=%d\n", x, y, ret);	
	
	return ret;
}

int 
lcd_set_text_blink(int toOn)
{
	int ret = ioctl(fd,LCD_IOCTSETTEXTBLINK, toOn);
	return ret;
}

int
lcd_set_cursor_blink(int toOn)
{
	int ret = ioctl(fd,LCD_IOCTSETCURSORBLINK, toOn);
	
	//doLog(0,"lcd_set_cursor_blink(on=%d) ret=%d\n", toOn, ret);
	
	return ret;
}

int
lcd_set_cursor_state(int toOn)
{
	int ret = ioctl(fd,LCD_IOCTSETCURSORSTATE, toOn);
	
	//doLog(0,"lcd_set_cursor_state(on=%d) ret=%d\n", toOn, ret);
	
	return ret;
}

int
lcd_set_display_state(int toOn)
{
	int ret = ioctl(fd,LCD_IOCTSETDISPLAYSTATE, toOn);
	return ret;
}


int 
lcd_programchar(int index_char, unsigned char *pfont )
{
	struct LCDProgramChar pc;
	int ret;

	pc.index_char = index_char;
	memcpy(pc.pfont, pfont, LCD_PROGCHAR_ROW_SIZE);
	pc.num_rows = LCD_PROGCHAR_ROW_SIZE;
	ret = ioctl(fd, LCD_IOCSPROGRAMCHAR, (long)&pc);
	return ret;
}


int 
lcd_setfont( int font )
{
	int ret = ioctl(fd, LCD_IOCTFONT, font);
	return ret;
}

int 
lcd_print( const char *fmt, ... )
{
	int ret;
	char buf[MAX_LCD_CHARS * MAX_LCD_LINES];
	va_list ap;	

	va_start(ap, fmt);	
	vsnprintf(buf, sizeof(buf), fmt, ap);
	ret = lcd_write(buf, strlen(buf));	
	va_end(ap);
	return ret;
}

int 
lcd_printat( int x, int y, const char *fmt, ... )
{
	int ret;
	char buf[MAX_LCD_CHARS * MAX_LCD_LINES];
	va_list ap;

	va_start(ap, fmt);	
	if ((ret = lcd_set_cursorxy(x, y)) < 0 ) return ret;
	vsnprintf(buf, sizeof(buf), fmt, ap);
	ret = lcd_write(buf, strlen(buf));	
	va_end(ap);
	return ret;
}

int 
lcd_get_type(void)
{
	return -1;
}

int lcd_get_numlines(void)
{
	int ret = ioctl(fd,LCD_IOCQNUMLINES, 0);
	return ret;
}

int lcd_get_numchars(void)
{
	int ret = ioctl(fd,LCD_IOCQNUMCHARS, 0);
	return ret;
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
