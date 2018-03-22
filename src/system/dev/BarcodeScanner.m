#include "BarcodeScanner.h"
#include "log.h"

@implementation BarcodeScanner

static BARCODE_SCANNER singleInstance = NULL; 

// Avoid Warning
- (void) onBarcodeScanned: (char *) aBarcode { }

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}
 
/**/
+ getInstance
{
  return [self new];
}

/**/
- initialize
{
	myComPortNumber = 2;
	myBaudRate = BR_9600;
	myComPort = NULL;
	myReadTimeout = 0;
	myObserver = NULL;
	myIsEnable = FALSE;
	return self;
}

/**/
- (void) setObserver: (id) anObserver { myObserver = anObserver; }
- (void) removeObserver { myObserver = NULL; }

/**/
- (void) enable 
{ 
  //doLog(0,"BarcodeScanner -> enable\n");
	if (myComPort) [myComPort flush];
  myIsEnable = TRUE;
}

/**/
- (void) disable
{
  //doLog(0,"BarcodeScanner -> disable\n");
  myIsEnable = FALSE;
}

/**/
- (void) setComPortNumber: (int) aValue { myComPortNumber = aValue; }

/**/
- (void) setBaudRate: (BaudRateType) aValue { myBaudRate = aValue; }

/**/
- (void) setReadTimeout: (int) aValue { myReadTimeout = aValue; }

/**/
- (void) open
{
	myComPort = [ComPort new];
	[myComPort setBaudRate: myBaudRate];
	[myComPort setStopBits: 1];
	[myComPort setPortNumber: myComPortNumber];
	[myComPort open];
 	[myComPort flush];
}

/**/
- (void) close
{
	[myComPort close];
}

/**/
- (int) readBarcode: (char *) aBuffer
{
	int n;
	int nRead = 0;

	*aBuffer = '\0';

	while (1) {

		n = [myComPort read: &aBuffer[nRead] qty: 1];
		if (n <= 0) return nRead;

	//	printf("[%c] - [%d]\n", aBuffer[nRead], aBuffer[nRead]);

		if (aBuffer[nRead] == 13) {
			aBuffer[nRead] = 0;
			return nRead;
		}

		nRead += n;	

	}
	return nRead;
}

/**/
- (void) run 
{
	char barcode[512];
	int n;

	//doLog(0,"comienzo del hilo de scanner de barras\n");

	TRY

		[self open];

		while (TRUE) {

      if (!myIsEnable) {
				msleep(100);
        continue;
      }

			n = [self readBarcode: barcode];
			
			if (n > 0 && myObserver != NULL) {
			//	doLog(0,"CODIGO (%d) = |%s|\n", n, barcode);
				[myObserver onBarcodeScanned: barcode];
			}
		}

	CATCH

		//doLog(0,"Ha ocurrido un error en el hilo del codigo de barras\n");
		ex_printfmt();
		
	END_TRY

	[self close];
}

@end
