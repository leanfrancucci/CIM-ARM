/*
 *	lcd.h	
 */

#ifndef  __LCD_H__
#define  __LCD_H__ 


/*
 *	Maximum display size
 */

#define LCD_MAX_CHARS			20
#define LCD_MAX_LINES			4

/*
 *	Maximum Tab Stop Size
 */

#define LCD_MAX_TS			8

/*
 *	The size of the rows to program chars
 */
#define LCD_PROGCHAR_ROW_SIZE		8
	
struct LCDProgramChar {
	int	index_char;
	char	pfont[LCD_PROGCHAR_ROW_SIZE];
	int 	num_rows;
};

/* ioctl defs */
#define LCD_IOC_MAGIC 'x'
#define LCD_OK 0

#define LCD_IOCTSETTABSTOP	 	_IO(LCD_IOC_MAGIC, 1)
#define LCD_IOCTSETCURSORXY	 	_IO(LCD_IOC_MAGIC, 2)
#define LCD_IOCSPROGRAMCHAR	 	_IOW(LCD_IOC_MAGIC, 3, struct LCDProgramChar) 
#define LCD_IOCTSETTEXTBLINK 		_IO(LCD_IOC_MAGIC, 4)
#define LCD_IOCTSETCURSORBLINK 		_IO(LCD_IOC_MAGIC, 5)
#define LCD_IOCTSETCURSORSTATE 		_IO(LCD_IOC_MAGIC, 6)
#define LCD_IOCTSETDISPLAYSTATE		_IO(LCD_IOC_MAGIC, 7)
#define LCD_IOCTREOPEN		_IO(LCD_IOC_MAGIC, 8)
#define LCD_IOCTFONT			_IO(LCD_IOC_MAGIC, 9)
#define LCD_IOCQNUMLINES		_IO(LCD_IOC_MAGIC, 10)
#define LCD_IOCQNUMCHARS		_IO(LCD_IOC_MAGIC, 11)
#define LCD_IOCCLEARDISPLAY		_IO(LCD_IOC_MAGIC, 12)

#define LCD_IOC_MAXNR			13 


/*
 * The list of the lcd types defined in lcddisp.c
 *
 */
enum 
{
/* type  1:   8 x  1 */	 LCD_TYPE_1 = 1	
/* type  2:   8 x  2 */	,LCD_TYPE_2
/* type  3:  12 x  2 */	,LCD_TYPE_3
/* type  4:  12 x  3 */	,LCD_TYPE_4
/* type  5:  12 x  3 */	,LCD_TYPE_5
/* type  6:  16 x  1 */	,LCD_TYPE_6
/* type  7:  16 x  1 */	,LCD_TYPE_7
/* type  8:  16 x  2 */	,LCD_TYPE_8
/* type  9:  16 x  4 */	,LCD_TYPE_9
/* type 10:  20 x  2 */	,LCD_TYPE_10
/* type 11:  20 x  4 */	,LCD_TYPE_11
/* type 12:  24 x  2 */	,LCD_TYPE_12
/* type 13:  40 x  2 */	,LCD_TYPE_13
};

/* The default type of the lcd: 16x2 */
#define LCD_DEFAULT_TYPE	LCD_TYPE_11

#endif

