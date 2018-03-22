#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>

#include <keypadlib.h>
#include <keypad.h>
#include <kpdriver.h>

#include "keypadconf.h"
#include "log.h"

#define KEYPAD_NODE_NAME		"/dev/kpnod"

static int fd = -1;


/* The current mapping of the numeric mode */
static struct KPMapScancode map_scancode_to_num[MAX_NUMERIC_KEYS]; 

//CURRENT_ROWS * MAX_COLS

/* The current mapping of the alpha numeric mode */
static struct KPMapScancode map_scancode_to_alphanum[MAX_ALPHANUMERIC_KEYS];

/* The current mapping of the navigation mode */
static struct KPMapScancode map_scancode_to_nav[MAX_NAVIGATION_KEYS];

/* The global error number var */
static int kp_errno = 0;

/* The error codes */
enum {
 	  KP_NO_ERROR
	,KPLIB_GLOBAL_ERROR
	,KPLIB_ALREADY_OPEN
	,KPLIB_ALREADY_CLOSED
	,KPLIB_INVALID_ARGUMENT
	,KPLIB_EAGAIN
};

/* The error messages */
static char *errmsgs[] =
{
		 NULL
		,"Keypadlib: general error!"	
		,"Keypadlib: already opened!"	
		,"Keypadlib: not opened!"	
		,"Keypadlib: invalid argument!"	
		,"Keypadlib: no hay datos disponibles!"	
};


/**
 * 
 * Static Functions
 *
 **/
	
/*
 * Returns the errno map to a keypad error
 *
 */
static
int
map_file_error(void)
{
	switch (errno) {
		case EAGAIN:
			return KPLIB_EAGAIN;
		case EBUSY:
			return KPLIB_ALREADY_OPEN;
		case EINVAL:
			return KPLIB_INVALID_ARGUMENT;
		case ENOTTY:
			return KPLIB_GLOBAL_ERROR;
	}
	return KPLIB_GLOBAL_ERROR;
}



/**
 * 
 * Public Functions
 * 
 */
	
	
/*
 *	kp_init_open
 * 		Opens the keypad driver
 * 		If mode = O_NONBLOCK the drivers opens in non blocking mode.
 */
int 
kp_init_open(int mode)
{
	kp_errno = 0;
				
	if (fd != -1) {
	//	doLog(0,"El keypad driver ya se encuentra abierto!\n");
		kp_errno = KPLIB_ALREADY_OPEN;
		return -kp_errno;
	}
	if ((fd = open(KEYPAD_NODE_NAME, O_RDWR | mode)) < 0) {
	//	doLog(0,"Error al intentar abrir el keypad driver\n");
		kp_errno = map_file_error();
		return -kp_errno;	
	}

	memset(map_scancode_to_num, 0, sizeof(map_scancode_to_num));
	memset(map_scancode_to_alphanum, 0, sizeof(map_scancode_to_alphanum));
	memset(map_scancode_to_nav, 0, sizeof(map_scancode_to_nav));

	init_conf_modes(map_scancode_to_num, map_scancode_to_alphanum, map_scancode_to_nav);

	kp_set_xlate_mode();
	kp_set_alphanum_mode();	
	kp_set_navigation_mode();
	
	return 0;
}


/*
 *	kp_nonblock_open
 * 		Opens the keypad driver in non block mode
 */
int 
kp_nonblock_open(void)
{
	return kp_init_open(O_NONBLOCK);
}

/*
 *	kp_open
 * 		Opens the keypad driver
 */
int 
kp_open(void)
{
	return kp_init_open(0);
}

/*
 * kp_close
 * 		Closes the keypad driver
 */
int 
kp_close(void)
{
	int ret;
	
	kp_errno = 0;
	
	if (fd == -1) {
	//	doLog(0,"El keypad driver ya se encuentra cerrado!\n");
		kp_errno = KPLIB_ALREADY_CLOSED;
		return -kp_errno;
	}
	if ((ret = close(fd)) < 0) { 
	//	doLog(0,"Error al intentar cerrar el keypad driver\n");
		kp_errno = map_file_error();
		return -kp_errno;	
	}
	fd = -1;
	return 0;
}

/*
 * kp_read
 * 		Reads data from the driver.
 *		Blocks the proccess if no data is available.
 *		If there is data available in the driver queue (or when data is available)
 *		then the driver copies the data in buf, and the functions returns the
 *		size of the data copied.
  * 	Returns the number of bytes read if success or a negative value if fail.
 * 		(the driver stores the chars received in a 16 bytes queue)
 */
int kp_read(char *buf, int count)
{	
	int ret_val;

	kp_errno = 0;
	ret_val = read(fd, buf, count); 
	if (ret_val < 0) kp_errno = map_file_error();
	return ret_val;	
}


/*
 * kp_getc
 * 	Reads one char from the device.
 * 	If no data available blocks the caller.
 * 	
 */
int 
kp_getc(void)
{
	char c;
	int ret_val;
	kp_errno = 0;
	
	ret_val = read(fd, &c, 1);
	if (ret_val < 0) { kp_errno = map_file_error(); return EOF; }
	return c;
}

/*
 * kp_kbhit
 *	Test the keypad for available data.
 *	If data available then returns 1, otherwise returns 0.
 */
int 
kp_kbhit(void)
{
	fd_set rdfd;
	struct timeval tv;
	int ret_val;
	
	kp_errno = 0;

	FD_ZERO(&rdfd);
	FD_SET(fd, &rdfd);
	/* No blocking */
	tv.tv_sec = 0;
	tv.tv_usec = 0;
	ret_val = select(fd + 1, &rdfd, NULL, NULL, &tv);
	if (ret_val < 0) { kp_errno = map_file_error(); return EOF; }
	return  ret_val > 0; 	
}


/*
 * kp_gets
 * 	Reads size - 1 characteres from the driver until EOF or '/n' is found.
 * 	Stores '\0' in size - 1.
 */
char *
kp_gets(char *dst, int size)
{
	char c;
	int ok = 0;
	char *s = dst;
	int ret_val = 0;
	
	kp_errno = 0;
	while (--size && (ret_val = read(fd, &c, 1)) == 1) {
		ok = 1;
		*s++ = c;
		if (c == '\n') 	break;	
	}
	if (ret_val < 0) { kp_errno = map_file_error(); return NULL; }
	if (ok) {	
		*s = '\0';	
		return dst;
	}
	return  NULL;
}

/*
 * kp_getsitring
 * 	Reads size - 1 characteres from the driver.
 * 	Stores '\0' in size - 1.
 */
char *
kp_getstring(char *dst, int size)
{
	char c;
	int ok = 0;
	char *s = dst;
	int ret_val = 0;
	
	kp_errno = 0;
	while (--size && (ret_val = read(fd, &c, 1)) == 1) {
		ok = 1;
		*s++ = c;
	}
	if (ret_val < 0) { kp_errno = map_file_error(); return NULL; }
	if (ok) {	
		*s = '\0';	
		return dst;
	}
	return  NULL;
}

/*
 * kp_write
 * 		Writes commands to the driver.
 */
int 
kp_write(const char *buf, int count)
{
	int ret_val;

	kp_errno = 0;
	ret_val = write(fd, buf, count); 
	if (ret_val < 0) kp_errno = map_file_error();
	return ret_val;
}

/*
 * kp_set_mode
 * 		Sets the mode of use of the driver.
 * 		mode is KP_RAW or KP_XLATE
 */
int 
kp_set_mode(int mode)
{
	int ret_val;
	
	kp_errno = 0;
	ret_val = ioctl(fd, KP_IOCTMODE, mode);
	if (ret_val < 0) kp_errno = map_file_error();
	return ret_val;
}

/*
 * kp_get_mode
 * 		Gets the actual mode of use of the driver.
 */
int 
kp_get_mode(void)
{
	int ret_val;
	
	kp_errno = 0;
	ret_val = ioctl(fd, KP_IOCQMODE, 0);
	if (ret_val < 0) kp_errno = map_file_error();
	return ret_val;
}

/*
 * kp_set_rawmode
 * 		Sets the driver in KP_RAW mode
 */
int 
kp_set_raw_mode(void)
{
	int ret_val;

	kp_errno = 0;
	ret_val = kp_set_mode(KP_RAW);
	if (ret_val < 0) kp_errno = map_file_error();
	return ret_val;
}


/*
 * kp_set_scancode_event
 * 		Sets OnKeyPressed event or OnKeyReleased event for scancode.
 */
int 
kp_set_scancode_evt(int scancode, int event)
{
	int ret_val;
	
	kp_errno = 0;
	
	/* OnKeyPRessed Event */
	if (event & KP_ONKEYPRESSED)
		ret_val = kp_set_onpressed_evt_on(scancode);
	else
		ret_val = kp_set_onpressed_evt_off(scancode);
	
	if (ret_val < 0)  return ret_val;
	/* OKeyReleased Event */
	if (event & KP_ONKEYRELEASED)
		ret_val = kp_set_onreleased_evt_on(scancode);
	else
		ret_val = kp_set_onreleased_evt_off(scancode);

	return ret_val;		
}

/*
 *
 */
int 
kp_set_onreleased_evt_on(int scancode)
{
	int ret_val;

	kp_errno = 0;
	ret_val = ioctl(fd, KP_IOCTRAWONKEYRELEASED_ON, scancode);
	if (ret_val < 0) kp_errno = map_file_error();
	return ret_val;
}

/*
 *
 */
int 
kp_set_onreleased_evt_off(int scancode)
{
	int ret_val;

	kp_errno = 0;
	ret_val = ioctl(fd, KP_IOCTRAWONKEYRELEASED_OFF, scancode);
	if (ret_val < 0) kp_errno = map_file_error();
	return ret_val;
}

/*
 *
 */
int 
kp_is_onreleased_evt_on(int scancode)
{
	int ret_val;

	kp_errno = 0;
	ret_val = ioctl(fd, KP_IOCQRAWISONKEYRELEASED_ON, scancode);
	if (ret_val < 0) kp_errno = map_file_error();
	return ret_val;
}

/*
 *
 */
int 
kp_set_onpressed_evt_on(int scancode)
{
	int ret_val;
	
	kp_errno = 0;
	ret_val = ioctl(fd, KP_IOCTRAWONKEYPRESSED_ON, scancode);
	if (ret_val < 0) kp_errno = map_file_error();
	return ret_val;
}

/*
 *
 */
int 
kp_set_onpressed_evt_off(int scancode)
{
	int ret_val;

	kp_errno = 0;
	ret_val = ioctl(fd, KP_IOCTRAWONKEYPRESSED_OFF, scancode);
	if (ret_val < 0) kp_errno = map_file_error();
	return ret_val;
}

/*
 *
 */
int 
kp_is_onpressed_evt_on(int scancode)
{
	int ret_val;
		
	kp_errno = 0;
	ret_val = ioctl(fd, KP_IOCQRAWISONKEYPRESSED_ON, scancode);
	if (ret_val < 0) kp_errno = map_file_error();
	return ret_val;
}

/*
 * kp_set_xlatemode
 * 		Sets the driver in KP_XLATE mode
 */
int 
kp_set_xlate_mode(void)
{
	int ret_val;
	
	kp_errno = 0;
	ret_val = kp_set_mode(KP_XLATE);
	if (ret_val < 0) kp_errno = map_file_error();
	return ret_val;
}

/*
 * kp_set_numericmode
 * 		Sets the driver to generates numeric  and navigation chars only.
 * 		The chars generated by the driver are:
 * 			numeric group: 			'0'..'9' and
 * 			navigation group: 	'\x1B' (escape) ,
 *						'\n' (enter) ,
 *						'\8' (delete),
 *						'<' (left arrow),
 *						'>' (right arrow) and
 *						'\1' PRG key.
 */
int 
kp_set_numeric_mode(void)
{
	struct KPMapScancode *mapsc;
	int ret_val;
	
	kp_errno = 0;
	
	for (mapsc = &map_scancode_to_num[0];
		 mapsc < &map_scancode_to_num[sizeof(map_scancode_to_num) / sizeof(map_scancode_to_num[0]) - 1];
		 mapsc++)
	{
		if (strlen(mapsc->keychars) > 0) {
		
//			doLog(0,"lib: sc=%d - k=\"%s\"\n", mapsc->scancode, mapsc->keychars);
		
			if ((ret_val = kp_set_mapscancode(mapsc->scancode, mapsc->keychars)) < 0) {
				kp_errno = map_file_error();
				return ret_val;
			}
			if ((ret_val = kp_set_sendxlatespecialkey(mapsc->scancode, 1)) < 0) { 
				kp_errno = map_file_error();
				return ret_val;
			}
		}
	}
	return 0;
}

/*
 * kp_set_alphanummode
 * 		Sets the driver to generates alphanumeric and navigation chars.
 * 		The chars generated by the driver are:
 * 			alpha group:			'A-Z' and ' ';
 * 			numeric group: 		'0'-'9' and
 * 			navigation group: see kp_set_numericmode
 */
int 
kp_set_alphanum_mode(void)
{
	struct KPMapScancode *mapsc;
	int ret_val;

	
	kp_errno = 0;
	for (mapsc = &map_scancode_to_alphanum[0];
		 mapsc < &map_scancode_to_alphanum[sizeof(map_scancode_to_alphanum) / sizeof(map_scancode_to_alphanum[0]) - 1];
		 mapsc++)
	{
		if (strlen(mapsc->keychars) > 0) {
			if ((ret_val = kp_set_mapscancode(mapsc->scancode, mapsc->keychars)) < 0) {
				kp_errno = map_file_error();
				return ret_val;
			}
			if ((ret_val = kp_set_sendxlatespecialkey(mapsc->scancode, 1)) < 0) { 
				kp_errno = map_file_error();
				return ret_val;
			}
		}		
	}
	return 0;	
}

/*
 * kp_set_navigation_mode
 * 	Sets navigation group mode:
 * 			navigation group: 	'\x1B' (escape) ,
 * 						'\n' (enter) ,
 * 						'\8' (delete),
 * 						'<' (left arrow),
 * 						'>' (right arrow) and
 * 						'\1' PRG key.
 */
int
kp_set_navigation_mode(void)
{
	struct KPMapScancode *mapsc;
	int ret_val;
	
	kp_errno = 0;

	
	for (mapsc = &map_scancode_to_nav[0];
		 mapsc < &map_scancode_to_nav[sizeof(map_scancode_to_nav) / sizeof(map_scancode_to_nav[0]) - 1];
		 mapsc++)
	{
		if (strlen(mapsc->keychars) > 0) {
			if ((ret_val = kp_set_mapscancode(mapsc->scancode, mapsc->keychars)) < 0) {
				kp_errno = map_file_error();
				return ret_val;
			}
			if ((ret_val = kp_set_sendxlatespecialkey(mapsc->scancode, 0)) < 0) { 
				kp_errno = map_file_error();
				return ret_val;
			}
		}
	}	
	return 0;
}

/*
 * kp_set_mapscancode
 * 		Maps the keychars characters and the scancode argument.
 * 		The driver will generate each character in keychars on every keypressed event
 * 		of the scancode arg.
 */
int 
kp_set_mapscancode(int scancode, char *keychars)
{
	struct KPMapScancode mapsc;
	int ret_val;
		
	kp_errno = 0;
	mapsc.scancode = scancode;
	strncpy(mapsc.keychars, keychars, KP_MAX_CHARS_PER_SCANCODE);
	*(mapsc.keychars + KP_MAX_CHARS_PER_SCANCODE) = '\0';
	//doLog(0,"Map scan code %d, keychars %s\n", mapsc.scancode, mapsc.keychars);
	ret_val = ioctl(fd, KP_IOCSMAPSCANCODE, (long)&mapsc);
	if (ret_val < 0) kp_errno = map_file_error();
	return ret_val;
}

/*
 * kp_get_mapscancode
 * 		Gets the scancode mapping.
 */
int
kp_get_mapscancode(int scancode, char *keychars)
{
	int ret_val;
	struct KPMapScancode mapsc;
	
	kp_errno = 0;
	mapsc.scancode = scancode;
	mapsc.keychars[0] = '\0';
	ret_val = ioctl(fd, KP_IOCXMAPSCANCODE, (long)&mapsc);
	strcpy(keychars, mapsc.keychars);
	if (ret_val < 0) kp_errno = map_file_error();
	return ret_val;
}

/*
 * kp_set_sendxlatespecialkey
 *	Sets the scancode to send the xlate special key char
 *
 */
int 
kp_set_sendxlatespecialkey(int scancode, int on)
{
	int ret_val;
	
	kp_errno = 0;
	if (on)
		ret_val = ioctl(fd, KP_IOCTSENDXLATESPECIALKEY_ON, (long)scancode);
	else
		ret_val = ioctl(fd, KP_IOCTSENDXLATESPECIALKEY_OFF, (long)scancode);
	if (ret_val < 0) kp_errno = map_file_error();
	return ret_val;
}

/*
 * kp_set_sendxlatespecialkey_on;
 *	Sets on the scancode to send xlate special key
 *
 */
int 
kp_set_sendxlatespecialkey_on(int scancode)
{
	return kp_set_sendxlatespecialkey(scancode, 1);
}	

/*
 * kp_set_sendxlatespecialkey_off;
 *	Sets off the scancode to send xlate special key
 *
 */
int 
kp_set_sendxlatespecialkey_off(int scancode)
{	
	return kp_set_sendxlatespecialkey(scancode, 0);
}

/*
 *  kp_get_sendxlatespecialkey
 *  	Returns 1 if the scancode must send the special xlate key char
 *
 */
int 
kp_get_sendxlatespecialkey(int scancode)
{
	int ret_val;
	
	kp_errno = 0;
	ret_val = ioctl(fd, KP_IOCQSENDXLATESPECIALKEY, (long)scancode);
	if (ret_val < 0) kp_errno = map_file_error();
	return ret_val;
}

/*
 * kp_set_xlatetimeout
 * 		Sets the timeout, in miliseconds,  for xlate use mode.
 */
int 
kp_set_xlatetimeout(int timeout)
{
	int ret_val;
	
	kp_errno = 0;
	ret_val = ioctl(fd, KP_IOCTXLATETIMEOUT, (long)timeout);
	if (ret_val < 0) kp_errno = map_file_error();
	return ret_val;
}

/*
 * kp_get_xlatetimeout
 * 		Gets the timeout of the xlate use mode.
 * 		Returns the xlate timeout value if success or a negative value if fail.
 */
int 
kp_get_xlatetimeout(void)
{
	int ret_val;
	
	kp_errno = 0;
	
	ret_val = ioctl(fd, KP_IOCQXLATETIMEOUT, 0);
	if (ret_val < 0) kp_errno = map_file_error();
	return ret_val;
}

/*
 * kp_set_xlatespecialkey
 * 		Sets the special key of the xlate use mode.
 */
int 
kp_set_xlatespecialkey(int specialkey)
{
	int ret_val;
	
	kp_errno = 0;
	ret_val = ioctl(fd, KP_IOCTXLATESPECIALKEY, (long)specialkey);
	if (ret_val < 0) kp_errno = map_file_error();
	return ret_val;
}

/*
 * kp_get_xlatespecialkey
 * 		Gets the special key of the xlate use mode.
 * 		Returns the xlate special key value if success or a negative value if fail.
 */
int 
kp_get_xlatespecialkey(void)
{
	int ret_val;
	
	kp_errno = 0;
	ret_val = ioctl(fd, KP_IOCQXLATESPECIALKEY, 0);
	if (ret_val < 0) kp_errno = map_file_error();
	return ret_val;
}


/*
 *
 *
 */
int
kp_get_error(void)
{
	return kp_errno;
}

/*
 *
 *
 */
char *
kp_get_error_msg(int err)
{
	if (err < 0 || err >= sizeof(errmsgs) / sizeof(errmsgs[0])) return NULL;
	return errmsgs[err];
}

  
