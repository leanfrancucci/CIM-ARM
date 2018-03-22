#include "WincabViewer.h"
#include "Cabin.h"
#include "ExportsDll.h"

@implementation WincabViewer

- (void) update: (id) aSender change : (int) aChange
{
	char number[16] = "";
	char duration[16] = "";
	char outS[16] = "";
	char buffer[17];

	if ( [aSender isKindOf:[Cabin class]] == TRUE ) {
		switch (aChange) {
			case ( AMOUNT_CHANGE ) : {
				sprintf( outS, "%.2f",[[aSender getCall] getAmount] ); 
				pFunctionChangeAmount([aSender getCabinNumber],outS);				
				break;
			}
	 
			case ( NUMBER_DIALED_CHANGE ) : {

				strcpy(number, [[aSender getDigitManager] getNumberDialed]);
				//doLog(0,"NumberDialedViewerWincab = %s\n", number);
  			pFunctionDialingNumber([aSender getCabinNumber],number);

				//doLog(0,"Actualizo el buffer \n");
				memset(buffer, ' ', 16);
				memcpy(buffer, [[aSender getCall] getLocation], strlen([[aSender getCall] getLocation]) );
				buffer[15] = 0;

				//doLog(0,"Copio la localidad \n");
				// solo actualizo si realmente se modifico la localidad
				if (strcmp(myLocation, buffer) != 0) {
					//doLog(0,"Llamo a actualizar la localidad \n");
					pFunctionChangeLocation([aSender getCabinNumber],buffer);
					strcpy(myLocation, buffer);

				}

				break;
			}
	
			case ( SECONDS_PASSED_CHANGE ) : {
				if ([aSender getCabinState] == TARIFYING) {
					sprintf(duration, "%02ld:%02ld", ([aSender getSecondsPassed]) / 60, ([aSender getSecondsPassed]) % 60);
					pFunctionChangeTime([aSender getCabinNumber],duration);
					break;
				}
			}

			case ( STATE_CHANGE ) : {
				pFunctionChangeState([aSender getCabinNumber], [aSender getCabinState]);
				switch ([aSender getCabinState]) {

					case ENABLE :
					case DISABLE : {
						break;
					}
					case PICK_UP : {
						strcpy(myLocation, "");
						break;
					}
					case HANG_UP : {
						sprintf( outS, "%.2f", (money_t) [[aSender getCurrentConsumption] getSaleTotal] ); 
						pFunctionChangeTotal([aSender getCabinNumber], outS);
						break;
					}
					case BLOCKED : {
						break;
					}
				}				
			break;
			}
		} /*Switch*/
	}	
}

@end
