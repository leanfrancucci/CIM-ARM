#ifndef __KEYPAD_H__
#define __KEYPAD_H__

//#include <sys/ioctl.h>
#include "mysysconf.h"

#define MAX_ROWS						8
#define MAX_COLS						MAX_ROWS

/* keypad modes */
enum 
{
	 KP_RAW = 0
	,KP_XLATE
};

/* Scancode configuration  */
#define KP_ONKEYPRESSED					0x01
#define KP_ONKEYRELEASED				0x02	
#define KP_SEND_XLATESPECIALKEY			0x04

#define KP_DEFAULT_MODE					KP_XLATE

#define KP_DEFAULT_TIMEOUT_XLATE		1000
#define KP_DEFAULT_SPECIALKEY_XLATE		'>'

#define KP_MIN_TIMEOUT_VAL				250	
	
#define	KP_MAX_CHARS_PER_SCANCODE		12


struct KPMapScancode 
{
	int		scancode;
	char	keychars[KP_MAX_CHARS_PER_SCANCODE + 1];
};

/* keypad magic number */
#define KP_IOC_MAGIC		'l' /* 'L' */

/* ioctl commands */
#define KP_IOCTMODE			_IO (KP_IOC_MAGIC, 1)
#define KP_IOCQMODE			_IO (KP_IOC_MAGIC, 2)

#define KP_IOCSMAPSCANCODE		_IOW(KP_IOC_MAGIC, 3, struct KPMapScancode)
#define KP_IOCXMAPSCANCODE		_IOR(KP_IOC_MAGIC, 4, struct KPMapScancode)
#define KP_IOCTXLATETIMEOUT		_IO (KP_IOC_MAGIC, 5)
#define KP_IOCQXLATETIMEOUT		_IO (KP_IOC_MAGIC, 6)
#define KP_IOCTXLATESPECIALKEY		_IO (KP_IOC_MAGIC, 7)
#define KP_IOCQXLATESPECIALKEY		_IO (KP_IOC_MAGIC, 8)

#define KP_IOCTRAWONKEYPRESSED_ON	_IO (KP_IOC_MAGIC, 9)
#define KP_IOCTRAWONKEYPRESSED_OFF	_IO (KP_IOC_MAGIC, 10)
#define KP_IOCQRAWISONKEYPRESSED_ON	_IO (KP_IOC_MAGIC, 11)
#define KP_IOCTRAWONKEYRELEASED_ON	_IO (KP_IOC_MAGIC, 12)
#define KP_IOCTRAWONKEYRELEASED_OFF		_IO (KP_IOC_MAGIC, 13)
#define KP_IOCQRAWISONKEYRELEASED_ON	_IO (KP_IOC_MAGIC, 14)

#define KP_IOCTSENDXLATESPECIALKEY_ON	_IO (KP_IOC_MAGIC, 15)
#define KP_IOCTSENDXLATESPECIALKEY_OFF	_IO (KP_IOC_MAGIC, 16)
#define KP_IOCQSENDXLATESPECIALKEY	_IO (KP_IOC_MAGIC, 17)


#define KP_IOC_MAXNR_CMD		17


#endif
