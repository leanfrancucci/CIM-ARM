#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>

#include <keypadlib.h>
#include <keypad.h>

#define KEYPAD_CONF_FILE		"keypad.conf"


typedef enum {
	 SPACE = 0
	,NEW_LINE
	,BACK_SLASH
	,DIGIT
	,LETTER
	,CARDINAL
	,OPEN_BRACKET
} TransitionChars ;
	
typedef int(handler_t)(char);

struct State {
	handler_t	*handler;
	int			next_state;		
};

static int none(char);
static int make_sc(char);
static int end_sc(char);
static int make_chars(char);
static int begin_spchar(char);
static int make_spchar(char);
static int make_spchar2(char);
static int make_spchar3(char);
static int make_spchar4(char);
static int do_success(char);
static int do_exit(char);
static int do_error(char);

/* The state machine */
static struct State parse_machine[10][10] = 
{
 /*		 	STATE 0		 				 */
  	  { 	 {none, 0}			/* SPACE */
	 		,{do_exit, -1}			/* NEW_LINE */
			,{do_error, -1}		/* BACK_SLASH */
		    ,{make_sc, 1}		/* DIGIT */
			,{do_error, -1}		/* LETTER */
			,{do_exit, -1}	/* CARDINAL */
			,{do_exit, -1}	/* OPEN_BRACKET */
			
	  }
	  
 /*		 	STATE 1		 				 */
	 ,{ 	 {end_sc, 3}
		 	,{do_error, -1}
			,{do_error, -1}	
			,{make_sc, 2}
			,{do_error, -1}
			,{do_error, -1}		/* CARDINAL */
			,{do_error, -1}		/* OPEN_BRACKET */
	  }
 /*		 	STATE 2		 				 */
	 ,{ 	 {end_sc, 3}
		 	,{do_error, -1}
			,{do_error, -1}
			,{do_error, -1}
			,{do_error, -1}
			,{do_error, -1}		/* CARDINAL */
			,{do_error, -1}		/* OPEN_BRACKET */
	  }
 /*		 	STATE 3		 				 */
	 ,{ 	 {none, 3}
		 	,{do_success, -1}
			,{none, 4}
			,{make_chars, 3}
			,{make_chars, 3}
			,{do_error, -1}		/* CARDINAL */
			,{do_error, -1}		/* OPEN_BRACKET */
	  }
 /*		 	STATE 4		 				 */
	 ,{ 	 {do_error, -1}
		 	,{do_error, -1}
			,{begin_spchar, 5}
			,{do_error, -1}
			,{do_error, -1}
			,{do_error, -1}		/* CARDINAL */
			,{do_error, -1}		/* OPEN_BRACKET */
	  }
 /*		 	STATE 5		 				 */
	 ,{ 	 {do_error, -1}
		 	,{do_error, -1}
			,{do_error, -1}
			,{make_spchar, 6}
			,{do_error, -1}
			,{do_error, -1}		/* CARDINAL */
			,{do_error, -1}		/* OPEN_BRACKET */
	  }
 /*		 	STATE 6		 				 */
 	 ,{ 	 	{make_spchar4, 3}	/* SPACE */
		 	,{make_spchar4, 3}	/* NEW_LINE */
			,{make_spchar4, 4}	/* BACK_SLASH */
			,{make_spchar2, 3}	/* DIGIT */
			,{make_spchar3, 3}	/* LETTER */
			,{do_error, -1}		/* CARDINAL */
			,{do_error, -1}		/* OPEN_BRACKET */
	  }
};



/* Default mapping numeric mode */
static struct KPMapScancode def_map_num[] = 
{
	 {1, 	"1"}
	,{5, 	"2"}
	,{9, 	"3"}
	,{2, 	"4"}
	,{6, 	"5"}
	,{10, 	"6"}
	,{3, 	"7"}
	,{7,	"8"}
	,{11, 	"9"}
	,{4, 	"0"}
};

/* Default mapping alphanumeric mode */
static struct KPMapScancode def_map_alphanum[] =
{
	 {1, "ABC1"}
	,{2, "JKL2"}
	,{3, "STU3"}
	,{4, " 0"}
	,{5, "DEF2"}
	,{6, "MNO5"}
	,{7, "VWX8"}
	,{8, "YZ9"}
	,{9, "GHI3"}
	,{10,"PQR6"}
};


/* Default mapping navigation mode */
static struct KPMapScancode def_map_nav[] =
{
	 {11, "\x1b"}   /* ESCAPE */
	,{16, "\n"}    /* ENTER */
	,{13, "\x01"}    /* ASCII 1: program key */
	,{14, "\x08"}    /* BACLSPACE */
	,{15, "<"}     /* LEFT CURSOR */
	,{8, ">"}     /* RIGHT CURSOR */
};

#define FILE_BUF_SIZE	128
static char file_buf[FILE_BUF_SIZE];

static int curr_scancode;
static char curr_scancode_str[4];
static char *curr_scancode_ptr;
static char curr_kchars_str[10];
static char *curr_kchars_ptr;
static char curr_spchar_str[5];
static char *curr_spchar_ptr;
static int  parse_error;
static int parse_copy_data;	
	

/**
 *  S t a t i c   F u n c t i o n s
 **/

static
int
none(char c)
{
	//doLog("none\n");
	return 1;
}

static
int
make_sc(char c)
{
	//doLog("make_sc\n");
	*curr_scancode_ptr++ = c;  
	return 1;
}
	

static
int
end_sc(char c)
{
	//doLog("end_sc\n");
	curr_scancode = atoi(curr_scancode_str);  
	if (curr_scancode <= 0 || curr_scancode > CURRENT_ROWS * CURRENT_COLS) return 0;
	return 1;
}

static
int
make_chars(char c)
{
	//doLog("make_chars\n");
	if (curr_kchars_ptr - curr_kchars_str == sizeof(curr_kchars_str)) return 0;
	*curr_kchars_ptr++ = c;  
	return 1;
}

static
int
begin_spchar(char c)
{
	//doLog("begin_spchar\n");
	if (curr_kchars_ptr - curr_kchars_str == sizeof(curr_kchars_str)) return 0;
	memset(curr_spchar_str, 0, sizeof(curr_spchar_str));
	curr_spchar_ptr = curr_spchar_str;

	return 1;
}

static
int
make_spchar(char c)
{
	//doLog("make_spchar\n");
	*curr_spchar_ptr++ = c;  
	return 1;
}

static
int
make_spchar2(char c)
{
	int schar;

	//doLog("make_spchar2\n");
	*curr_spchar_ptr++ = c;  
	schar = atoi(curr_spchar_str);
	if (schar) 	*curr_kchars_ptr++ = schar;  

	return 1;
}

static
int
make_spchar3(char c)
{
	int schar;
	
	//doLog("make_spchar2\n");
	schar = atoi(curr_spchar_str);
	if (schar) 	*curr_kchars_ptr++ = schar;  
	*curr_kchars_ptr++ = c;
	
	return 1;
}


static
int
make_spchar4(char c)
{
	int schar;
	
    //doLog("make_spcharr4\n");
	schar = atoi(curr_spchar_str);
	if (schar) 	*curr_kchars_ptr++ = schar;  
	
	return 1;
}


static
int
do_exit(char c)
{
	//doLog("do_exit\n");
	parse_error = 0;
	parse_copy_data = 0;	
	return 0;
}

static
int
do_success(char c)
{
	//doLog("do_success\n");
	*curr_kchars_ptr++ = '\0';  
	parse_error = 0;
	parse_copy_data = 1;	
	return 0;
}

static
int
do_error(char c)
{
	//doLog("do_error\n");
	parse_error = 1;
	return 0;
}

/*
 *
 *
 */
static
int
map_char(char c)
{
	if (c == ' ') return SPACE;
	if (c == '\n') return NEW_LINE;
	if (c == '\\') return BACK_SLASH;
	if (c == '[') return OPEN_BRACKET;
	if (c == '#') return CARDINAL;
	if (isdigit(c)) return DIGIT;
	return LETTER;
}

/*
 *
 */
static
int
parse_line(struct KPMapScancode *m, char *s)
{
	int state = 0;
	int  c;
	//char *ss = s;
	
	curr_scancode = 0;
	memset(curr_scancode_str, 0, sizeof(curr_scancode_str));
	curr_scancode_ptr = curr_scancode_str;
	memset(curr_kchars_str, 0, sizeof(curr_kchars_str));
	curr_kchars_ptr = curr_kchars_str;
	memset(curr_spchar_str, 0, sizeof(curr_spchar_str));
	curr_spchar_ptr = curr_spchar_str;
	parse_error = 1;
	
	/* Init the state machine */
	while (*s != '\0') {
		c = map_char(*s); 
		if (!parse_machine[state][c].handler(*s)) break; 
		state = parse_machine[state][c].next_state;		
		if (state == -1) break;
		s++;
	}

	if (!parse_error && parse_copy_data) {	
		m->scancode = curr_scancode;
		strcpy(m->keychars, curr_kchars_str);
	}

	//doLog("ParseLine: %s", ss);
	return !parse_error;
}

/*
 *
 */
static
int
is_blank_line(void)
{
	char *s = file_buf;
	
	while(isspace(*s++)) ;
	if (*s == '\0' || *s == '#') return 1;
	return 0;
}

/*
 *  Position the pointer of the file in the first line after the
 *  "[numeric]", "[alphanumeric]" or "[navigation]" sections
 *
 */
static
int
pos_in_first_line(FILE *f, const char *mode)
{
	char *s;
	
	/* Begin of file */
	fseek(f, 0, SEEK_SET); 
	while (fgets(file_buf, sizeof(file_buf), f)) {
		s = file_buf;
		/* Deberia controlar que este mode solito solito sin otros caracteres extraños */
		if (strncmp(file_buf, mode, strlen(mode)) == 0) return 1;
	}	
	return 0;
}
			
/*
 * Configures the mode reading the configuration file.
 * If the file does not exists or it has an error configures with default configuration.
 * Returns 0 if default configuration nad returns 1 if file configuration OK.
 */
static
int
conf_mode(FILE *f, 
		  struct KPMapScancode *map_sc, 
		  struct KPMapScancode *def_map_sc, 
		  int def_count, 
		  const char *mode)
{
	struct KPMapScancode *dst = map_sc;
	int len;
	int ok = 0;

	if (f) {
		if (pos_in_first_line(f, mode)) {
			ok = 1;
			while (fgets(file_buf, sizeof(file_buf), f)) {
				if (is_blank_line()) continue;
				/* Adding a \n to the end of line makes it easier */
				len = strlen(file_buf);
				strcat(file_buf, "\n");
				if (!parse_line(dst++, file_buf)) {
					ok = 0;
					break;
				}
				if (dst - map_sc >= CURRENT_ROWS * CURRENT_COLS) break;
			}
		} 
	}
	/* Error... */	
	if (!ok) {
		memcpy(map_sc, def_map_sc, def_count); 
		return 1;
	}
	return 0;	
}



/**
 *
 *  P u b l ic   F u n c t i o ns
 *
 **/


/*
 * Initialize the library with default configuration.
 * Mode of use: xlate and alphanumeric mode.
 * Reads th /etc/ct8016/keypad.conf and configures the library.
 * If the file does not exists or is bas formated then configures 
 * with default configuration.
 */
void
init_conf_modes(struct KPMapScancode *map_num, 
				struct KPMapScancode *map_alphanum, 
				struct KPMapScancode *map_nav)
{
	FILE *conff;
	
	conff = fopen(KEYPAD_CONF_FILE, "r"); 	
	conf_mode(conff, map_num, def_map_num, sizeof(def_map_num), "[numeric]");
	conf_mode(conff, map_alphanum, def_map_alphanum, sizeof(def_map_alphanum), "[alphanumeric]");
	conf_mode(conff, map_nav, def_map_nav, sizeof(def_map_nav), "[navigation]");		
	if (conff) 	fclose(conff);	

	/* Avoid warnings: functions not used */
	if (0) {
		none(0);
		make_sc(0);
		end_sc(0);
		make_chars(0);
		begin_spchar(0);
		make_spchar(0);
		make_spchar2(0);
		make_spchar3(0);
		do_success(0);
		do_error(0);
	}
}


	




