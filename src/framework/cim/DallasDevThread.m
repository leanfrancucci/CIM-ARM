#include "DallasDevThread.h"
#include "system/util/all.h"
#include "MessageHandler.h"
#include "Buzzer.h"
#include <unistd.h>
#include "CimGeneralSettings.h"
#include "ownet.h"

#define CONTROL_CHECK_TIME						1000000		
#define MAXDEVICES         10

//#define printd(args...) doLog(0,args)
#define printd(args...)


/**/
@implementation DallasDevThread

static DALLAS_DEV_THREAD singleInstance = NULL; 

// Avoid warning
- (void) onExternalLoginKey: (char *) aKeyNumber { }

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}
 
/**/
- initialize
{
  myObserver = NULL;
  myIsEnable = FALSE;
	return self;
}

/**/
+ getInstance
{
  return [self new];
}

/**/
- (void) setObserver: (id) anObserver
{
  myObserver = anObserver;
}

/**/
- (void) enable 
{ 
  //doLog(0,"DallasDevThread -> enable\n");
  myIsEnable = TRUE;
}

/**/
- (void) disable
{
  //doLog(0,"DallasDevThread -> disable\n");
  myIsEnable = FALSE;
}

/**/
- (BOOL) isDeviceId: (char*) aNumber
{
	int len = strlen(aNumber);

    
    //************************* logcoment
	//doLog(0,"len = %d\n", len);

	if ((aNumber[len-1] == '8') && (aNumber[len-2] == '0')) {
    //************************* logcoment
        //doLog(0,"no es id de dispositivo\n");
		return FALSE;
	}

    //************************* logcoment
	//doLog(0,"es id de dispositivo\n");

	return TRUE;
}

/**
 * Display information about the 1-Wire device
 *
 * portnum port number for the device
 * SNum    serial number for the device
 */
- (void) processDallasKey: (unsigned char *) SNum
{
  int i;
  char number[30];
  char aux[10];
	unsigned char digest[16];
	unsigned char md5Dallas[50];

	//if (strcmp(owGetName(&SNum[0]), "DS1982") == 0) return;

  strcpy(number, "");
  for(i=7;i>=0;i--) {
    sprintf(aux, "%02X",SNum[i]);
    strcat(number, aux);
  }

	// verifica si es un identificador de dispositivo o una llave.
	if ([self isDeviceId: number]) return;

	[[Buzzer getInstance] buzzerBeep: 200];
	
    //************************* logcoment
	//doLog(0,"* Device Address: %s\n", number);
		
	md5_buffer(number, strlen(number), digest);
  strcpy(md5Dallas, "");
	for (i = 0; i < 9; ++i) {
    sprintf(aux, "%02X",digest[i]);
    strcat(md5Dallas, aux);
	}

//	doLog(0,"* MD5 Device Address: %s\n", md5Dallas);

  if (myObserver) [myObserver onExternalLoginKey: md5Dallas];
}

/**/
- (void) run 
{
	int i;
	int portnum = -1;
	unsigned char AllSN[MAXDEVICES][8];
  int count, result;
  volatile int dallasKeyCount = 0;
	char comPort[50];

    //************************* logcoment
	//doLog(0,"Iniciando hilo de control de dallas...\n");

	threadSetPriority(5);

	sprintf(comPort, "/dev/ttyS%d", ([[CimGeneralSettings getInstance] getLoginDevComPort]-1));

	while (portnum < 0) {
		portnum = owAcquireEx(comPort);
		if(portnum < 0) {
			msleep(5000);
		}
	}


	    //************************* logcoment
    //doLog(0,"DallasDevThread -> Lector Dallas encontrado\n");

  // El proceso es el siguiente:
  // Si esta habilitado el polling de la Dallas me quedo esperando hasta que lleguen por lo menos 2 llaves 
  // (una corresponde siempre al lector y la otra a la llave en si)
  // Cuando llegan dos llaves notifico al observer en caso que haya uno registrado
  // No vuelvo a notificar hasta que no cambie la cantidad de Dallas nuevamente

	while (TRUE) {

    TRY

      msleep(100);

      if (!myIsEnable) {
        EXIT_TRY;
        continue;
      }

      // 
      // find all parts
      // loop to find all of the devices up to MAXDEVICES
      count = 0;
//      doLog(0,"DallasDevThread -> checking dallas\n");
      // find the first device (all devices not just alarming)
      result = owFirst(portnum, TRUE, FALSE);
      while (result) {

        // print the device number
        count++;
  
        // print the Serial Number of the device just found
        owSerialNum(portnum, AllSN[count - 1], TRUE);
        //PrintSerialNum(&SNum[0]);
  
        // find the next device
        result = owNext(portnum, TRUE, FALSE);
    
        msleep(100);  // Por las dudas

      }

//      doLog(0,"DallasDevThread -> count = %d, dallasKeyCount = %d\n", count, dallasKeyCount);

      if (dallasKeyCount != count) {
        
				for (i = 0; i < count; ++i)
          [self processDallasKey: AllSN[i]];

				
      }

      dallasKeyCount = count;

	CATCH

    //************************* logcoment
	   //doLog(0,"Excepcion en el hilo de Dallas Key...\n");
	   ex_printfmt();

	 END_TRY

	}

}



@end
