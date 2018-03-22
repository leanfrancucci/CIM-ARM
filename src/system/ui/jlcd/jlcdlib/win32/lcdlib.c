/*
 *	lcdlib.c
 */
#include <stdarg.h>
#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <windows.h>

#include "lcdlib.h"

#define LCD_WIDTH				20
#define LCD_HEIGHT				4

#define X_INIT_POS				3
#define Y_INIT_POS				3

#define SCROLL_TO_LINE			11
#define BOTTOM_LINE				30			


#define printd(args...) //doLog(0,args)
//#define printd(args...)


static char buffer[512];
static char blankBuffer[80];
static int opened = 0;
static int xpos = 1, ypos = 1;
static int dline;

static void w_init(void);
static void w_clrscr(void);
static void w_gotoxy(int x, int y);
static void w_print_display(void);
//static void w_scroll_up(int);
static void w_blink_cursor(int);


int
lcd_open( void )
{
	if (opened) {
		printd("Library already opened!!\n");
		return 1;
	}
	xpos = ypos = 1;
	opened = 1;

	w_init();	
	lcd_clear();
	return 1;
}

int
lcd_initopen( int lcd_type )
{
	return 1;
}
	

int 
lcd_clear(void)
{
	int i;
	
	for (i = 0; i < LCD_HEIGHT - 1; i++) {		
		lcd_set_cursorxy(1, i + 1);	
		lcd_write(blankBuffer, LCD_WIDTH);
	}
	
	return 1;
}

int lcd_putchar( int c )
{
	printd("%c", c);
	lcd_set_cursorxy(xpos, ypos);	
	return 1;
}

int
lcd_write(const char *str, int length)
{
	strncpy(buffer, str, length);
	buffer[length] = '\0';
	
	printd("%s", buffer);
	lcd_set_cursorxy(xpos, ypos);
	return 1;
}

int 
lcd_close()
{
	return 1;
}

int
lcd_set_tabstop(int ts)
{
	return 1;
}

int
lcd_set_cursorxy(int x, int y)
{	
	assert(x > 0 && x <= LCD_WIDTH);
	assert(y > 0 && y <= LCD_HEIGHT);
	
	xpos = x;
	ypos = y;

	w_gotoxy(xpos + X_INIT_POS, ypos + Y_INIT_POS);
	return 1;
}

int 
lcd_set_text_blink(int toOn)
{
	toOn = toOn;
	return 1;
}

int
lcd_set_cursor_blink(int toOn)
{
	w_blink_cursor(toOn);

	return 1;
}

int
lcd_set_cursor_state(int toOn)
{
	toOn = toOn;
	return 1;
}

int
lcd_set_display_state(int toOn)
{
	toOn = toOn;
	return 1;
}


int 
lcd_programchar(int index_char, unsigned char *pfont )
{
	index_char = index_char;
	pfont = pfont;

	return 1;
}


int 
lcd_setfont( int font )
{
	font = font;
	return 1;
}

int 
lcd_print( const char *fmt, ... )
{
	va_list ap;

	va_start(ap, fmt);
	sprintf(buffer, fmt, ap);	
	lcd_write(buffer, strlen(buffer));
	va_end(ap);
	return 1;
}

int 
lcd_printat( int x, int y, const char *fmt, ... )
{	
	va_list ap;

	lcd_set_cursorxy(x, y);

	va_start(ap, fmt);
	lcd_print( fmt, ap );
	va_end(ap);
	return 1;
}

int 
lcd_get_type(void)
{
	return 11;
}

int lcd_get_numlines(void)
{	
	return 4;
}

int lcd_get_numchars(void)
{	
	return 20;
}

void w_print_display(void)
{	
	//doLog(0,"                         \n");
	//doLog(0,"                         \n");
	//doLog(0,"   ---------------------                    EL OJO[q]\n");
	//doLog(0,"  |                     |          \n");
	//doLog(0,"  |                     |            		ARRIBA[w]\n");
	//doLog(0,"  |                     |      IZQUIERDA[a]               DERECHA[s]\n");         
	//doLog(0,"  |                     |                   ABAJO[s]\n");     
	//doLog(0,"   --------------------- \n");
	//doLog(0,"   ['z']  ['x']   ['c']                     SALIR [escape]\n");		
}	
	
void w_init(void)
{	
	dline = 1;
	
	memset(blankBuffer, ' ', sizeof(blankBuffer) - 1);
	blankBuffer[78] = '\0';

	w_clrscr();

	w_print_display();	
}

void w_clrscr(void)
{
	HANDLE hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);
	COORD coord = {0, 0};
	DWORD count;  
	CONSOLE_SCREEN_BUFFER_INFO csbi;
	
	GetConsoleScreenBufferInfo(hStdOut, &csbi);
	
	FillConsoleOutputCharacter(hStdOut, ' ', csbi.dwSize.X * csbi.dwSize.Y, coord, &count);
		
	SetConsoleCursorPosition(hStdOut, coord);
}

void w_gotoxy(int x, int y)
{
	  HANDLE hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);
	  COORD coord = {x - 1, y - 1};	  
	  CONSOLE_SCREEN_BUFFER_INFO csbi;
	  
	  GetConsoleScreenBufferInfo(hStdOut, &csbi);	
	  SetConsoleCursorPosition(hStdOut, coord);  
}
	
/**/
void w_blink_cursor(int toOn)
{
	HANDLE hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);
	CONSOLE_CURSOR_INFO lpConsoleCursorInfo;
	
	BOOL WINAPI SetConsoleCursorInfo(HANDLE,const CONSOLE_CURSOR_INFO*);
		
	lpConsoleCursorInfo.dwSize = 100;
	lpConsoleCursorInfo.bVisible = toOn;
  	
	SetConsoleCursorInfo(hStdOut, &lpConsoleCursorInfo);
}	

	
/**/
void _dprintf(char *fmt, ...)
{		
#if 0
	int xx, yy;
	va_list ap;			
	
	xx = xpos;
	yy = ypos;
	
	/* scrollea para arriba la vntana de (1,10) a (1, 20) */
	w_scroll_up(SCROLL_TO_LINE); 
		
	/* Imprime una linea en blanco */
	w_gotoxy(1, BOTTOM_LINE);	
	//doLog(0, "%s", blankBuffer);
	
	/* Escribe en la ultima linea */
	w_gotoxy(1, BOTTOM_LINE);
	
	//doLog(0,"%d: ", dline++);  
	
	va_start(ap, fmt);	
	vprintf (fmt, ap);	
	va_end(ap);

	/* Restaura el cursor */
	w_gotoxy(xx, yy);

	fflush(stdout);
#endif
	
	va_list ap;			
	
	va_start(ap, fmt);	
	vprintf (fmt, ap);	
	va_end(ap);

	fflush(stdout);
	
	return;	
}

/**/
void w_scroll_up(int scrollTo)
{
	HANDLE hStdout; 
	CONSOLE_SCREEN_BUFFER_INFO csbiInfo; 
	SMALL_RECT srctScrollRect, srctClipRect; 
	CHAR_INFO chiFill; 
	COORD coordDest;  
	
	hStdout = GetStdHandle(STD_OUTPUT_HANDLE); 
	
	if (hStdout == INVALID_HANDLE_VALUE) {
	   //doLog(0,"GetStdHandle failed with %ld\n", GetLastError()); 
	   return;
	}
	 
	// Get the screen buffer size. 	 
	if (!GetConsoleScreenBufferInfo(hStdout, &csbiInfo))	{
	   //doLog(0,"GetConsoleScreenBufferInfo failed %ld\n", GetLastError()); 
	   return;
	}
	 
	// The scrolling rectangle is the bottom x rows of the screen buffer. 	 
	srctScrollRect.Top = scrollTo;//csbiInfo.dwSize.Y - 10; 
	srctScrollRect.Bottom = csbiInfo.dwSize.Y - 1; 
	srctScrollRect.Left = 0; 
	srctScrollRect.Right = csbiInfo.dwSize.X - 1; 
	 
	// The destination for the scroll rectangle is one row up.	 
	coordDest.X = 0; 
	coordDest.Y = scrollTo - 1;//csbiInfo.dwSize.Y - 11; 
	 
	// The clipping rectangle is the same as the scrolling rectangle. 
	// The destination row is left unchanged. 	 
	srctClipRect = srctScrollRect; 
	 
	// Fill the bottom row with green blanks. 	 
	chiFill.Attributes = BACKGROUND_INTENSITY  | FOREGROUND_INTENSITY; 
	chiFill.Char.AsciiChar = (char)' '; 
	 
	// Scroll up one line. 	 
	if(!ScrollConsoleScreenBuffer(  
		hStdout,         // screen buffer handle 
		&srctScrollRect, // scrolling rectangle 
		&srctClipRect,   // clipping rectangle 
		coordDest,       // top left destination cell 
		&chiFill))       // fill character and color 
	{
	   //doLog(0,"ScrollConsoleScreenBuffer failed %ld\n", GetLastError()); 
	   return;
	}
}

