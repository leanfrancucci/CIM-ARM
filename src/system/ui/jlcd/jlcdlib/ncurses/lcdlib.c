/*
 *	lcdlib.c
 */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <assert.h>
#include <curses.h>

static int fd = 1;
static WINDOW *wnd = NULL;
static WINDOW *dbgWnd = NULL;
static int initialized = 0;
static WINDOW *helpWnd = NULL;

#define MAX_LCD_CHARS 20
#define MAX_LCD_LINES 4

/**/
static void ncurses_init(void) 
{
	initscr(); 

	start_color(); 

	init_pair(1, COLOR_GREEN, COLOR_BLACK); 
	init_pair(2, COLOR_YELLOW, COLOR_BLACK); 
	init_pair(3, COLOR_WHITE, COLOR_BLUE);
 	
	cbreak(); 
	noecho();
}

/**/
void printKeyHelp(char *key, char *help)
{
	wattron(helpWnd, COLOR_PAIR(1));
	wprintw (helpWnd, key);
	wattroff(helpWnd, COLOR_PAIR(1));
	wprintw (helpWnd, ":");
	wprintw (helpWnd, help);
	wprintw (helpWnd, " ");
}

/**/
void showHelpScreen(void)
{
	int y=0;

	helpWnd = newwin(6, 46, 0, 24);
	box(helpWnd, 0, 0);

	wmove(helpWnd,y++, 1);
	wattron(helpWnd, COLOR_PAIR(2));
	
	wprintw (helpWnd, " REFERENCE ");
	wattroff(helpWnd, COLOR_PAIR(2));
	
	wmove(helpWnd,y++, 1);
	printKeyHelp("q","fnc1 ");
	printKeyHelp("w","up   ");
	printKeyHelp("e","fnc2 ");
	
	wmove(helpWnd,y++, 1);
	printKeyHelp("a","left ");
	printKeyHelp("s","down ");
	printKeyHelp("d","right");

	wmove(helpWnd,y++, 1);
	printKeyHelp("z","menu1");
	printKeyHelp("x","menux");
	printKeyHelp("c","menu2");

	wmove(helpWnd,y++, 1);
	printKeyHelp("u","manual");
	printKeyHelp("i","extraction");
	printKeyHelp("o","reports");
	printKeyHelp("p","validated");

	wrefresh(helpWnd);
}

/**/
int lcd_open( void )
{
	if (wnd) return fd;

	if (!initialized) {
		ncurses_init();	
		initialized = 1;
	}
	
	wnd = newwin(6, 23, 0, 0);
	box(wnd, 0, 0);	

	showHelpScreen();
	
	return fd;
}

int 
lcd_clear(void)
{
	wclear(wnd);
	wbkgd(wnd, COLOR_PAIR(3));
	box(wnd, 0, 0);	
	wrefresh(wnd);	
	return 1;
}

int lcd_putchar( int c )
{
	wprintw(wnd, "%c", c);
	wrefresh(wnd);
	return 1;
}

int
lcd_write(const char *str, int length)
{
	wprintw(wnd, "%s", str);
	wrefresh(wnd);	
	return 1;	
}

int 
lcd_close()
{
	delwin(wnd);
	return 1;	
}


int
lcd_set_cursorxy(int x, int y)
{
	wmove(wnd,y,x);
	wrefresh(wnd);	
	return 0;
}

int 
lcd_set_text_blink(int toOn)
{
		return 1;
}

int
lcd_set_cursor_blink(int toOn)
{
	curs_set(toOn);
	wrefresh(wnd);	
		return 1;
}

int
lcd_set_cursor_state(int toOn)
{
	curs_set(toOn);
	wrefresh(wnd);	
		return 1;
}

int
lcd_set_display_state(int toOn)
{
	return 1;
}


int 
lcd_programchar(int index_char, unsigned char *pfont )
{
	return 1;
}


int 
lcd_setfont( int font )
{
	return 1;
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
	return 4;
}

int lcd_get_numchars(void)
{
	return 20;
}

/**/
void _dprintf(char *fmt, ...)
{		
	va_list ap;			
	char *output = getenv("CT_OUT_FILE");
	FILE *file;
	
	if (!initialized) {
		ncurses_init();
		initialized = 1;
	}
		
	if (!dbgWnd) {
		dbgWnd	= newwin(20, 74, 7, 0);
		scrollok(dbgWnd, 1);
	}

	va_start(ap, fmt);
	if (output == NULL || strcmp(output, "stdout") == 0)
		vwprintw (dbgWnd, fmt, ap);
	else {
		file = fopen(output, "a+");
		assert(file);
		vfprintf(file, fmt, ap);
		fclose(file);
	}
	
	va_end(ap);
	
	wrefresh(dbgWnd);

	return;	
}
