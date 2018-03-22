#include <stdio.h>
#include "CtSystem.h"
#include "ui/lcd/CTViewer.h"
#include "JSystem.h"
#include "OTimer.h"


/**/
#include "ConsoleAcceptor.h"

/**	
 *	Metodo principal.
class OTimer;
 */
void run(id system)
{
    /*
    id consoleAcceptor = [ConsoleAcceptor new];
    
    
    printf("arranca el ConsoleAcceptor\n");
    TRY
    
	printf("ConsoleAcceptor 1\n");
	[consoleAcceptor setPort: 9001];
    printf("ConsoleAcceptor 2\n");
    [consoleAcceptor setFreeOnExit:0];
    printf("ConsoleAcceptor 3\n");
	[consoleAcceptor start];
    printf("ConsoleAcceptor 4\n");
  //  [consoleAcceptor waitFor: consoleAcceptor];
    printf("ConsoleAcceptor 5\n");
    
    CATCH
        printf("ConsoleAcceptor 6\n");
        ex_call_default_handler();
        
    END_TRY;
    
    while (1) ;
    
    return;*/
	JSYSTEM jsys;
	
	TRY

    [[JVirtualScreen getInstance] initScreenWithHeight: 24];
    jsys = [JSystem new];
    [jsys startSystem];
	[[CtSystem getInstance] shutdownSystem];

    [jsys free];
                
	CATCH
		
	//	doLog(0,"Ha ocurrido una excepcion en el hilo principal\n");
		ex_call_default_handler();
				
	END_TRY	
	
	

}
