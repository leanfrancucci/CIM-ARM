#include "CTViewer.h"
#include "Cabin.h"
#include "lcdlib.h"
#include "CtSystem.h"

//#define printd(args...) doLog(args)
#define printd(args...)

/**
 *	Elimina la linea "y" a partir de la posicion "x"
 */
void lcd_clearline(int x, int y)
{
	char s[50];
	int i;
	strcpy(s,"");
	for (i = 0; i < lcd_get_numchars() - x + 1; i++) strcat(s," ");
	
	lcd_printat(x,y,"%s", s);
}


@implementation CTViewer

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	int i;
	int max;
		
	max = [[CtSystem getInstance] getCabinQuantity];
	if (max > 3) max = 3;
	
//	lcd_open();
	lcd_clear();
	for (i = 0; i < max; i++) { 
		[[[CtSystem getInstance] getCabinAt: i] addObserver: self];
		lcd_printat(1,i+1,"%d:", i+1);
	}

	myTimer = [OTimer new];
	[myTimer initTimer: PERIODIC period: 1000 object: self callback: "updateTime"];
	[myTimer start];
	
	return self;
}

/**/
- (void) updateTime
{
	char buffer[50];
	struct tm brokenTime;
	time_t now = time(NULL);
	
	localtime_r(&now, &brokenTime);
	strftime(buffer, 20, "%H:%M:%S %a", &brokenTime);
	lcd_printat(1, 4, "%s", buffer);
}

/**/
- (void) update: (id) aSender change : (int) aChange
{
	
	char outS[100];
	int hour, min, sec;
	int secondsPassed;
	char *number;
	char duration[16] = "";
	
	int y = [aSender getCabinNumber];

	if (y > 3) return;

	switch (aChange) {

	case ( AMOUNT_CHANGE ) : {
						
		sprintf( outS, "$ %.2f", [aSender getCurrentCallAmount] );

		lcd_printat(10, y, "%s", outS);
		//[lcdVisor printAt: outS x:8 y:2] ;
		
		break;
	}

	case ( NUMBER_DIALED_CHANGE ) : {
		if (strlen([[aSender getDigitManager] getNumberDialed]) == 1) {
//			[lcdVisor clear];
			lcd_clearline(4,y);
			strcpy(myNumber, "");
		}

		number = [[aSender getDigitManager] getNumberDialed] + strlen(myNumber);
		strcpy(myNumber, [[aSender getDigitManager] getNumberDialed]);

		if ( strlen([[aSender getDigitManager]getNumberDialed]) <= 16 )
			lcd_printat(4, y, "%s", myNumber);

		break;
	}

	case ( SECONDS_PASSED_CHANGE ) : {
		if ([aSender getCabinState] == TARIFYING) {
			secondsPassed = [aSender getSecondsPassed] ;
			min = secondsPassed / 60;
			sec = secondsPassed % 60;
			sprintf(duration, "%02ld:%02ld", min, sec);
			lcd_printat(4, y, "%s", duration); 
			break;
		}
	}

	case ( STATE_CHANGE ) : {
		printd("Notifica el cambio de estado de la cabina: %d \n", [aSender getCabinNumber]); 
		switch ([aSender getCabinState]) {
			
			case DISABLE : {
				lcd_printat(4,y,"%s", "INHABILITADA");
				break;
			}
			case PICK_UP : {
				lcd_clearline(4,y);
				lcd_printat(4,y,"%s", "DESCOLGADO");
				strcpy(myLocation, "");
				break;
			}
			case HANG_UP: case ENABLE : {
				lcd_clearline(4,y);
				lcd_printat(4,y,"%s", "COLGADO");

				if ([aSender getCallClass] == VALUED_CALL_T) {
					sprintf( outS, "SALDO $%.2f", [aSender getMaxAmountCall] - (money_t) [[aSender getCurrentConsumption] getSaleTotal] ); 
				} else {
					sprintf( outS, "TOTAL $%.2f", (money_t) [[aSender getCurrentConsumption] getSaleTotal] ); 
				}
//				[lcdVisor printAt: outS x:1 y:2];
				break;
			}
			case BLOCKED : {
				lcd_clearline(4,y);
				lcd_printat(4,y,"%s", "BLOQUEADO");
				break;
			}
			case TARIFYING : {
				lcd_clearline(4,y);		
				break;
			}
			case CABIN_DISCONNECTED:{
				lcd_clearline(4,y);
				lcd_printat(4,y,"%s", "SIN CONEXION");
				break;
			} 

		}
		break;
	}
} /*Switch*/
	
}


@end
