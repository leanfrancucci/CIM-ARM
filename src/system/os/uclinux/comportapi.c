#include <assert.h>
#include <string.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include "comportapi.h"
#include "OSExcepts.h"
#include "log.h"

#define printd(args...)
#define CRTSCTS   020000000000

/* Convierte el BaudRate de la aplicacion al BaudRate de la api de linux. */
static int BaudRateMap[] =
{
	B0,	B50, B75, B110, B134, B150,	B200,	B300,	B600,	B1200,	B1800,	B2400,
	B4800, B9600,	B19200,	B38400,	B57600,	B115200,	B230400
};

/**/
void com_bitChange( int fd, int bitWeights, int nioctl)
{
	int res;
	
	res = ioctl(fd, nioctl, &bitWeights);
/*	if( res )
		doLog(0,"Error en IOCTL: %d\n" , res);*/
}

/**/
OS_HANDLE com_open(int portNumber, ComPortConfig *config)
{
	char name[50];
	struct termios options;
	OS_HANDLE myHandle;
	
	assert(config->dataBits >= 5);
	assert(config->dataBits <= 8);
	assert(config->stopBits >= 1);
	assert(config->stopBits <= 2);
	assert(portNumber > 0);

	sprintf(name, "/dev/ttyS%d", portNumber - 1 );
//	sprintf(name, "/dev/ttyS%d", 2 );
	myHandle = open(name, O_RDWR | O_NOCTTY);
	//doLog(0,"Abriendo puerto %s\n", name);
//	myHandle = open(name, O_RDWR);

	if (myHandle == -1) {
		//doLog(0,"Error opening port %s\n", name);
		return -1;
	}
	
	tcgetattr(myHandle, &options);
	memset(&options, 0, sizeof(options));

	options.c_cflag  = BaudRateMap[config->baudRate];
	if (config->stopBits == 2 ) options.c_cflag |= CSTOPB;
	if (config->dataBits == 5) options.c_cflag |= CS5;
	if (config->dataBits == 6) options.c_cflag |= CS6;
	if (config->dataBits == 7) options.c_cflag |= CS7;
	if (config->dataBits == 8) options.c_cflag |= CS8;

	if (config->parity == CT_PARITY_ODD) options.c_cflag |= PARODD;
	else if (config->parity == CT_PARITY_EVEN) options.c_cflag |= PARENB;

	options.c_cflag |= CLOCAL;
	options.c_cflag |= CREAD;

	if (portNumber != 1 && portNumber != 2) options.c_cflag |= CRTSCTS;
	options.c_oflag = 0;

	/* set input mode (non-canonical, no echo,...) */
	options.c_lflag = 0;

	options.c_cc[VMIN]  = 0;
	options.c_cc[VTIME] = 1;		// 200 ms
//	timeout = config->readTimeout;
	
	tcflush(myHandle, TCIFLUSH);

	if ( tcsetattr(myHandle, TCSANOW, &options) != 0) {
		//doLog(0, "Error setting port %s\n", name);
		return -1;
	}
	
//	com_bitChange(myHandle, TIOCM_DTR | TIOCM_RTS, TIOCMBIS);
	if (portNumber == 3) ioctl(myHandle, 0xCAFE, 0);
	tcflush(myHandle, TCIOFLUSH);
	
	return myHandle;
	
}

#if 0
int com_read(OS_HANDLE handle, char *buffer, int qty)
{
	int n, i;
	n = read(handle, buffer, qty);
	//doLog(0,"----> %d bytes readed: ", n);
	for (i = 0; i < n; ++i) {
		//doLog(0,"%.2x ", (unsigned char) buffer[i]);
	}
	//doLog(0,"\n");
	return n;
}
#endif

//#if 0
/**/
int com_read(OS_HANDLE handle, char *buffer, int qty, int timeout)
{
	unsigned long ticks = getTicks();
	int nReaded = 0;
	int result;
	
	while ( getTicks() - ticks <= timeout ) {
		result = read(handle, &buffer[nReaded], qty - nReaded);
		if (result == -1) {
			//doLog(0,"Error reading com port\n");
			return 0;
		}
		nReaded += result;
		msleep(1);
		if (nReaded >= qty) return nReaded;
		//if (nReaded >= qty) break;
	}

//	result = read(handle, &buffer[nReaded], qty - nReaded);
//	nReaded += result;
/*	doLog(0,"%d bytes readed. ", nReaded);
	doLog(0,"READ: ");
	for (i = 0; i < nReaded; ++i) doLog(0,"%.2x ", (unsigned char)buffer[i]);
	doLog(0,"\n");
	*/		
	return nReaded;
	
}
//#endif

/**/
int com_write(OS_HANDLE handle, char *buffer, int qty)
{
	int n;
	//int i = 45000;
//	com_bitChange(handle, TIOCM_DTR | TIOCM_RTS, TIOCMBIS);

//	while (i--) ;
	//msleep(2);
	n = write(handle, buffer, qty);
	//if (n != qty) doLog(0,"com_write: write %d bytes of %d\n", n, qty);

//	tcdrain(handle);
	
//	com_bitChange(handle, TIOCM_DTR | TIOCM_RTS, TIOCMBIC);

//	close(handle);
//	handle = open("/dev/ttyS2", O_RDWR | O_NOCTTY | O_SYNC);
//	assert(handle != -1);
//	com_bitChange(handle, TIOCM_DTR | TIOCM_RTS, TIOCMBIC);
	
	return n;
}


/**/
void com_close(OS_HANDLE handle)
{
  tcflush(handle, TCIFLUSH);
	close(handle);
}


/**/
void com_flush(OS_HANDLE handle)
{
	tcflush(handle, TCIOFLUSH);
}

