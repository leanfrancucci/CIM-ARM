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
#include <sys/ioctl.h>
#include <linux/serial.h>
#include <asm-generic/ioctls.h> /* TIOCGRS485 + TIOCSRS485 ioctl definitions */

/* Driver-specific ioctls: */
#define TIOCGRS485      0x542E
#define TIOCSRS485      0x542F

#define printd(args...)

/** @todo arrojar excepciones si no se puede abrir el puerto */

/* Convierte el BaudRate de la aplicacion al BaudRate de la api de linux. */
static int BaudRateMap[] =
{
	B0,	B50, B75, B110, B134, B150,	B200,	B300,	B600,	B1200,	B1800,	B2400,
	B4800, B9600,	B19200,	B38400,	B57600,	B115200,	B230400
};

/**/

int handle485;
int handleValidador;

#if 0

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
    if (portNumber != 8){
        printf(">>>>>>>>>>>>abrir puerto innerboard %d\n", portNumber);
        sprintf(name, "/dev/ttyUSB%d", portNumber - 1 );

        myHandle = open(name, O_RDWR | O_NOCTTY);
        if (myHandle == -1) {
            //doLog(0,"Error opening com port\n");
        }
        
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
        options.c_cflag |= CRTSCTS;
        
        
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
            //doLog(0,"Error setting port\n");
        }
        
        return myHandle;
        
    }else {
        sprintf(name, "/dev/ttyUSB1");
        
        myHandle = open(name, O_RDWR | O_NOCTTY);
        if (myHandle == -1) {
            //doLog(0,"Error opening com port\n");
        }
        
        tcgetattr(myHandle, &options);
        bzero(&options, sizeof(options));

    options.c_cflag  = BaudRateMap[config->baudRate];
        if (config->stopBits == 2 ) options.c_cflag |= CSTOPB;
        if (config->dataBits == 5) options.c_cflag |= CS5;
        if (config->dataBits == 6) options.c_cflag |= CS6;
        if (config->dataBits == 7) options.c_cflag |= CS7;
        if (config->dataBits == 8) options.c_cflag |= CS8;

        //if (config->parity == CT_PARITY_ODD) options.c_cflag |= PARODD;
        options.c_cflag &= ~PARODD;
        options.c_cflag |= PARENB;
        options.c_cflag |= CLOCAL;
        options.c_cflag |= CREAD;
        //options.c_cflag |= CRTSCTS;
        
        
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
            //doLog(0,"Error setting port\n");
        }
        
        return myHandle;
        
    }

	
}

#endif

OS_HANDLE com_open(int portNumber, ComPortConfig *config)
{
	char name[40];
	struct termios options;
    struct serial_rs485 rs485conf;
 
	OS_HANDLE myHandle;
	
	assert(config->dataBits >= 5);
	assert(config->dataBits <= 8);
	assert(config->stopBits >= 1);
	assert(config->stopBits <= 2);
	assert(portNumber > 0);

	// modificado para que funcione con la inner conectada a un puerto usb
    if (portNumber == 8){
        printf(">>>>>>>>>>>>abrir puerto innerboard 485\n");
        sprintf(name, "/dev/ttymxc2");

        myHandle = open(name, O_RDWR );
        handle485 = myHandle;
        if (myHandle == -1) {
            printf("Error opening com port /dev/ttymxc2\n");
            return -1;
        }
        

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
        //options.c_cflag |= CRTSCTS;
        
        
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
            //doLog(0,"Error setting port\n");
        }


        if (ioctl (myHandle, TIOCGRS485, &rs485conf) < 0) {
            printf("Error: TIOCGRS485 ioctl not supported.\n");
        }

        /* Enable RS-485 mode: */
        //printf("\nflags: %x\n",rs485conf.flags);
        rs485conf.flags |= SER_RS485_ENABLED;
        rs485conf.flags |= SER_RS485_RTS_AFTER_SEND;
        rs485conf.flags &= ~SER_RS485_RTS_ON_SEND;
        rs485conf.flags &= ~SER_RS485_RX_DURING_TX;
        
        //printf("\nafter flags: %x\n",rs485conf.flags);

        /* Set rts/txen delay before send, if needed: (in microseconds) */
        rs485conf.delay_rts_before_send = 100;

        /* Set rts/txen delay after send, if needed: (in microseconds) */
        rs485conf.delay_rts_after_send = 100;

        if (ioctl (myHandle, TIOCSRS485, &rs485conf) < 0) {
            printf("Error: TIOCSRS485 ioctl not supported.\n");
        }

        fcntl(myHandle, F_SETFL, 0);

      
        return myHandle;
        
    }else {
        //sprintf(name, "/dev/ttyUSB%d", portNumber - 1);
        sprintf(name, "%s%d", config->ttyStr , portNumber - 1);
        printf(">>>>>>>>>>>>abrir puerto TTYx %s\n", name);

        
        myHandle = open(name, O_RDWR | O_NOCTTY);
        if (myHandle == -1) {
            //doLog(0,"Error opening com port\n");
            return -1;
        }
        if (!strcmp(config->ttyStr, "/dev/ttyACM")){
            handleValidador = myHandle;
            printf("TCDRAIN + FLUJO>>>>>>>>>>>>Handle validador detectado %d\n", myHandle);
        }
        tcgetattr(myHandle, &options);
        bzero(&options, sizeof(options));

    options.c_cflag  = BaudRateMap[config->baudRate];
        if (config->stopBits == 2 ) options.c_cflag |= CSTOPB;
        if (config->dataBits == 5) options.c_cflag |= CS5;
        if (config->dataBits == 6) options.c_cflag |= CS6;
        if (config->dataBits == 7) options.c_cflag |= CS7;
        if (config->dataBits == 8) options.c_cflag |= CS8;

//        if (config->parity == CT_PARITY_ODD) options.c_cflag |= PARODD;
	if (config->parity == CT_PARITY_ODD) options.c_cflag |= PARODD;
	else if (config->parity == CT_PARITY_EVEN) options.c_cflag |= PARENB;
        //options.c_cflag &= ~PARODD;
        //options.c_cflag |= PARENB;
        options.c_cflag |= CLOCAL;
        options.c_cflag |= CREAD;

        if ( handleValidador != myHandle )
            options.c_cflag &= ~CRTSCTS;
        else
            options.c_cflag |= CRTSCTS;
        //options.c_cflag |= CRTSCTS;
        
        
    options.c_oflag = 0;

    /* set input mode (non-canonical, no echo,...) */
    options.c_lflag = 0;
    options.c_iflag &= ~(IXON | IXOFF | IXANY);

    
    options.c_cc[VMIN]  = 0;
        /*options.c_cc[VTIME] = config->readTimeout / 100;
        if (options.c_cc[VTIME] == 0) options.c_cc[VTIME] = 1;
        */
        options.c_cc[VTIME] = 1;
    tcflush(myHandle, TCIFLUSH);

        if ( tcsetattr(myHandle, TCSAFLUSH, &options) != 0) {
            //doLog(0,"Error setting port\n");
        }
        
        return myHandle;
        
    }

	
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
    if (handle == handle485){
        int n = write(handle, buffer, qty);
        if (n <= 0){
           return n;
        }
        tcdrain(handle);
        return n;
    } else {
        if (handle == handleValidador){
        //    printf("ACM com_write before tcdrain!!!! %d HANDLE %d\n", qty, handle);
        //    tcdrain(handle);
        //    printf("ACM com_write!!!! %d HANDLE %d\n", qty, handle);
            int n = write(handle, buffer, qty);
            if (n <= 0){
               return n;
            }
        //   printf("ACM after com_write!!!! %d HANDLE %d\n", n, handle);
           tcdrain(handle);
        //   printf("com_write Sali del tcdrain!!!! HANDLE %d\n", handle);
            return n;
        } else{
           // printf("USB com_write!!!! %d HANDLE %d\n", qty, handle);
            int n = write(handle, buffer, qty);
            if (n <= 0){
                return n;
            }
        //  printf("before tcdrain com_write!!!! %d HANDLE %d\n", n, handle);
            tcdrain(handle);
        //   printf("com_write Sali del tcdrain!!!! HANDLE %d\n", handle);
            
        }
    }
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

