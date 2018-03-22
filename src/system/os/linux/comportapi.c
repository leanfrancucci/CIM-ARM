#include <assert.h>
#include <string.h>
#include <stdio.h>
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include "comportapi.h"
#include <strings.h>
#include "OSExcepts.h"
#include "log.h"

#define printd(args...)

/** @todo arrojar excepciones si no se puede abrir el puerto */

/* Convierte el BaudRate de la aplicacion al BaudRate de la api de linux. */
static int BaudRateMap[] =
{
	B0,	B50, B75, B110, B134, B150,	B200,	B300,	B600,	B1200,	B1800,	B2400,
	B4800, B9600,	B19200,	B38400,	B57600,	B115200,	B230400
};

/**/
OS_HANDLE com_open(int portNumber, ComPortConfig *config)
{
	char name[40];
	struct termios options;
	OS_HANDLE myHandle;
	
	assert(config->dataBits >= 5);
	assert(config->dataBits <= 8);
	assert(config->stopBits >= 1);
	assert(config->stopBits <= 2);
	assert(portNumber > 0);

	// modificado para que funcione con la inner conectada a un puerto usb
	sprintf(name, "/dev/ttyUSB%d", portNumber - 1 );
	//sprintf(name, "/dev/ttyS%d", portNumber - 1 );
	myHandle = open(name, O_RDWR | O_NOCTTY);
	if (myHandle == -1) {
		//doLog(0,"Error opening com port\n");
		printf("1\n");
	}
	
	printf("2\n");
	tcgetattr(myHandle, &options);
	bzero(&options, sizeof(options));

  options.c_cflag  = BaudRateMap[config->baudRate];
	if (config->stopBits == 2 ) options.c_cflag |= CSTOPB;
	if (config->dataBits == 5) options.c_cflag |= CS5;
	if (config->dataBits == 6) options.c_cflag |= CS6;
	if (config->dataBits == 7) options.c_cflag |= CS7;
	if (config->dataBits == 8) options.c_cflag |= CS8;

	if (config->parity == CT_PARITY_ODD) options.c_cflag |= PARODD;

	options.c_cflag |= CLOCAL;
	options.c_cflag |= CREAD;
  options.c_oflag = 0;

  /* set input mode (non-canonical, no echo,...) */
  options.c_lflag = 0;

  options.c_cc[VMIN]  = 0;
	/*options.c_cc[VTIME] = config->readTimeout / 100;
	if (options.c_cc[VTIME] == 0) options.c_cc[VTIME] = 1;
	*/
	options.c_cc[VTIME] = 1;
  tcflush(myHandle, TCIFLUSH);

	if ( tcsetattr(myHandle, TCSAFLUSH, &options) != 0) {
	//	doLog(0,"Error setting port\n");
	}
	
	return myHandle;
	
}

/**/
int com_read(OS_HANDLE handle, char *buffer, int qty, int timeout)
{
	unsigned long ticks = getTicks();
	int i;
	int nReaded = 0;
	int result;
	
	while ( getTicks() - ticks <= timeout ) {
		result = read(handle, &buffer[nReaded], qty - nReaded);
		if (result == -1) {
//			doLog(0,"Error reading com port\n");
			return 0;
		}
		nReaded += result;
		if (nReaded >= qty) return nReaded;
		//if (nReaded >= qty) break;
	}

//	result = read(handle, &buffer[nReaded], qty - nReaded);
//	nReaded += result;
	//doLog(0,"%d bytes readed\n", nReaded);
	//doLog(0,"READ: ");
	for (i = 0; i < nReaded; ++i) ;//doLog(0,"%.2x ", (unsigned char)buffer[i]);
	//doLog(0,"\n");
			
	return nReaded;

}


/**/
int com_write(OS_HANDLE handle, char *buffer, int qty)
{
	int n = write(handle, buffer, qty);
	tcdrain(handle);
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
	tcflush(handle, TCIFLUSH);
}

