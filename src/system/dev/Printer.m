#include "Printer.h"
#include "tprinter.h"
#include "system/os/all.h"
#include "log.h"

static PRINTER singleInstance = NULL;

// Define la maxima cantidad de lineas enviar a la impresora cada vez.
// Si esta definido como 0 envia todo el texto de una
#define MAX_LINES			20

@implementation Printer

/**/
+ new
{
	if (!singleInstance) singleInstance = [[super new] initialize];
	return singleInstance;	
}

/**/
- initialize
{

    
#ifdef __ARM_LINUX
    
    printf("****************************************************\n");
    printf("Printer tprinter_open\n");
	tprinter_open();
#endif
	return self;
}

/**/
- free
{
#ifndef __LINUX
	tprinter_close();
#endif
	return [super free];
}

/**/
+ getInstance
{
	return [self new];
}

/**/
- (int) print: (char*) aBuffer
{

#ifndef __LINUX
	int size;
	char *to;
	char *p = aBuffer;
	char *from = aBuffer;
	int count = 0;

	// Intenta poner la impresora en linea
	//doLog(0,"before try printing\n");
	tprinter_try_printing();
	//doLog(0,"after try printing\n");
	
	if ( tprinter_has_paper() == 1 ) return OUT_OF_PAPER_ERR;

	// Si lo hago asi imprime mas rapido que dividiendolo en lineas,
	// pero pierdo el control de hasta donde se escribio
	/*tprinter_write(p, strlen(p));
	while ( tprinter_queue_qty() != 0 && tprinter_has_paper() != 1 ) msleep(10);
*/

	// Este es el codigo viejo, donde se dividia por linea el texto a imprimir.
	while ( *from != '\0' ) {

      
		// Encuentro el proximo fin de linea
		to = strchr(p, '\n');

		// Si no existe, busco el fin de cadena
		if (to == NULL || MAX_LINES == 0) {
			to = strchr(p, '\0');
			count = MAX_LINES;
		}
		else to++;

		// Escribo en la impresora
		p = to;

		count++;

		if (count >= MAX_LINES) {
			size = to - from;
			tprinter_write(from, size);
			from  = to;
			count = 0;
		}

		// Espero hasta que la cola sea 0, con lo cual se imprimio todo
		// o hubo un error por falta de papel
		/** @todo: no deberia haber un msleep(10) en este lugar, quitar */
		while ( tprinter_queue_qty() != 0 && tprinter_has_paper() != 1 ) sched_yield();
			//msleep(10);
	}

	tprinter_write("\0",1);

	if ( tprinter_has_paper() == 1 ) return OUT_OF_PAPER_ERR;

#else
	FILE *f;
	f = fopen("printer.out", "a+");
	if (f) {
		fprintf(f, "%s", aBuffer);
		fclose(f);
	}
	doLog(0,"%s", aBuffer);
	
#endif

	return 0;	
}

/**/
- (int) getQueueQty
{
#ifndef __LINUX
	return tprinter_queue_qty();
#endif
	return 0;
}


/**/
- (BOOL) hasPaper
{
#ifndef __LINUX
	return tprinter_has_paper();
#endif
	return 0;
}


/**/
- (void) waitForPaper
{
#ifndef __LINUX
	tprinter_wait_for_paper();
#endif
	return;
}

/**/
- (BOOL) tryPrinting
{
#ifndef __LINUX
	return tprinter_try_printing() != 1;
#endif 
	return 0;
}

/**/
- (void) cleanQueue
{
#ifndef __LINUX
	tprinter_clean_queue();
#endif 
	return;
}

/**/
- (void) printerOnLine
{
	[self tryPrinting];
}

/**/
- (void) startAdvancePaper
{
#ifndef __LINUX
	tprinter_start_advance_paper();
#endif
	return;
}

/**/
- (void) stopAdvancePaper
{
#ifndef __LINUX
	tprinter_stop_advance_paper();
#endif 
	return;
}

/**/
- (void) printLogo: (char*) aFileName
{
#ifndef __LINUX
   tprinter_print_logo(aFileName);
#endif
}

@end
