#include "PrinterSpooler.h"
#include "PrinterInterface.h"
#include "Configuration.h"
#include <unistd.h>
#include "util.h"
#include "scew.h"
#include "assert.h"
  
static id singleInstance = NULL;

/**
 *	Define un trabajo de impresion.
 *	fileName es el nombre del archivo de trabajo
 *	type es el tipo de documento de trabajo
 */
typedef struct {
	int type;
  int copiesQty;
  BOOL ignorePaperOut;
	scew_tree* tree;
  unsigned long additional;
} PrintingJob;

typedef enum {
	LANGUAGE_NOT_DEFINED,
	SPANISH,
	ENGLISH,
	FRENCH
} LanguageType;

@implementation PrinterSpooler

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
- (BOOL) hasCancelJobs
{
	return myHasCancelJobs;	
}

/**/
- initialize
{
  //Inicializa la cola
	queue = [SyncQueue new];
  actionQueue = [[StaticSyncQueue new] initWithSize: sizeof(SpoolerAction) count: 1];  
  myHasCancelJobs = FALSE;
  myPrinterStateListener = NULL;
  myPrinterStateListeners = [Collection new];
  myPrinter = NULL;
	myAdvanceLineQty = 0;
	myReportPathByLanguage[0] = '\0';
	return self;
}


/**/
- (int) getJobCount
{
	return [queue getCount];
}

/**/
- (void) notifyPrinterState: (PrinterState) aPrinterState
{
  int i;
	//if (!myPrinterStateListener) return;
  
  for ( i=0; i<[myPrinterStateListeners size]; ++i)
    [[myPrinterStateListeners at: i] notifyPrinterState: aPrinterState];

}

/**/
- (void) setPrinterStateListener: (id) aListener
{
	//myPrinterStateListener = aListener;
	assert(aListener);
	
	[myPrinterStateListeners add: aListener];
}

/**/
- (void) addPrintingJob: (int) aType copiesQty: (int) aCopiesQty ignorePaperOut: (BOOL) aIgnorePaperOut tree: (scew_tree*) tree
{
	PrintingJob *job;

//	while ([self getJobCount] > 2) msleep(10);

 // doLog(0,"Agrego un trabajo\n");
	job = malloc(sizeof(PrintingJob));
	job->type = aType;
  job->copiesQty = aCopiesQty;
  job->ignorePaperOut = aIgnorePaperOut;
	job->tree = tree;
  job->additional = 0;
	[queue pushElement: job];

}

/**/
- (void) addPrintingJob: (int) aType copiesQty: (int) aCopiesQty ignorePaperOut: (BOOL) aIgnorePaperOut tree: (scew_tree*) tree additional: (unsigned long) anAdditional
{
	PrintingJob *job;

	//while ([self getJobCount] > 2) msleep(10);

//  doLog(0,"Agrego un trabajo\n");
	job = malloc(sizeof(PrintingJob));
	job->type = aType;
  job->copiesQty = aCopiesQty;
  job->ignorePaperOut = aIgnorePaperOut;
	job->tree = tree;
  job->additional = anAdditional;
	[queue pushElement: job];

}

/**/
- (void) reprintLastJob
{
	SpoolerAction action = SpoolerAction_REPRINT;
	[actionQueue pushElement: &action];
}

/**/
- (void) cancelLastJob
{
	SpoolerAction action = SpoolerAction_CANCEL;
	[actionQueue pushElement: &action];
}

/**/
- (void) setDocParsing: (DOC_PARSING) aDocParsing
{
  myDocParsing = aDocParsing;
}


/**/
- (void) deletePendingJobs
{
	int i;
  PrintingJob *job;
  int count = [self getJobCount];

	for (i = 0; i < count; ++i)
	{
		job = [queue popElement];
  	scew_tree_free(job->tree);

    free(job);
	}
  
}
 
/**/
- (void) run
{
	PrintingJob *job;
  int pType;
  int pCopiesQty;
  int result;
  unsigned long add;
  BOOL pIgnorePaperOut;
  SpoolerAction action;
	scew_tree *tree;

//	doLog(0,"spooler priority\n");
	threadSetPriority(1);

	TRY

		while (TRUE)
		{
			// Obtiene el elemento de la cola
      result = -1;
			job = [queue getElement];
    	pType = job->type;
      pCopiesQty = job->copiesQty;
      pIgnorePaperOut = job->ignorePaperOut;
      add = job->additional;
			myHasCancelJobs = FALSE;

      //doLog(0,"Procesa un trabajo \n");
        
      TRY
        [myDocParsing setAdvanceLineQty: myAdvanceLineQty];
				[myDocParsing processPrintingAction: pType copiesQty: pCopiesQty tree: job->tree additional: add];

        // para el caso del reporte de auditoria el procesamiento es diferente.
  			if ((pType != CIM_AUDIT_PRT) || ((pType == CIM_AUDIT_PRT) && (add == 2) ) ){
          if (pType != ADVANCE_PAPER_PRT && myAdvanceLineQty > 0) {
					  [myDocParsing processPrintingAction: ADVANCE_PAPER_PRT copiesQty: 0 tree: NULL additional: myAdvanceLineQty];
          }
        }

        result = 0;

      CATCH

        //doLog(0,"-------------> PRINTER EXCEPTION <----------------- \n");
        ex_printfmt();

        switch (ex_get_code()) {
        
          case PRINTER_OUT_OF_LINE_EX:

            if ( !pIgnorePaperOut ) {
              
              [myDocParsing clean];
              [self notifyPrinterState: PrinterState_OUT_OF_LINE];
              [actionQueue popBuffer: &action];
              result = -1;

            } else result = 0;
              
              break;
          
          case PRINTER_OUT_OF_PAPER_EX:

            if ( !pIgnorePaperOut ) {
              
              [myDocParsing clean];
              [self notifyPrinterState: PrinterState_PAPER_OUT];
              [actionQueue popBuffer: &action];
              result = -1;
            
            } else result = 0;
            
            break;
            
          case PRINTER_NEEDS_CLOSE_Z_EX:

            [myDocParsing clean];
            [self notifyPrinterState: PrinterState_PRINTER_NEEDS_CLOSE_Z];
            [actionQueue popBuffer: &action];
            result = -1;
            
            break;
            
          
          case PRINTER_FATAL_ERROR_EX:            

            if ( !pIgnorePaperOut ) {

							[myDocParsing clean];
							[self notifyPrinterState: PrinterState_PRINTER_FATAL_ERROR];
							[actionQueue popBuffer: &action];
							result = -1;
                        
            } else result = 0;

            break;
          
          case PRINTER_INTERNAL_FATAL_ERROR_EX:                        

            if ( !pIgnorePaperOut ) {
              
							[myDocParsing clean];
							// Modificacion para que reintente imprimir
							[self notifyPrinterState: PrinterState_PRINTER_INTERNAL_FATAL_ERROR];
							[actionQueue popBuffer: &action];
							result = -1;
            
            } else result = 0;
            
            break;

          case PRINTER_MAX_RETRIES_QTY_EX:                        

            [myDocParsing clean];
            [self notifyPrinterState: PrinterState_PRINTER_NOT_RESPONDING_BERIGUEL];
            [actionQueue popBuffer: &action];
            result = -1;
          
            break;
        
          
          default:

            RETHROW();
            break;
        
      }
        
      END_TRY        

      if ( result == 0 ) {
				//doLog(0,"Spooler -> eliminando elemento de la cola\n");
				tree = job->tree;
				//scew_tree_free(job->tree);
				[queue popElement];
				free(job);
				scew_tree_free(tree);
      } else {
        
        //doLog(0,"Spooler-> result == -1 \n");
      
        if ( action == SpoolerAction_CANCEL ) {
					//doLog(0,"PrinterSpooler -> Cancelando impresiones pendientes\n");
          [self deletePendingJobs];
					myHasCancelJobs = TRUE;
				}
      }
      
	}

	CATCH

		//doLog(0,"Ha ocurrido un error grave en el spooler de impresion\n");
		ex_printfmt();
		RETHROW();
	
	END_TRY
	
}
 
/**/
- free
{
	[queue free];
	return [super free];
}

/**/
- (void) setHeaderFooterInfo: (char*) aHeader1 header2: (char*) aHeader2 header3: (char*) aHeader3 header4: (char*) aHeader4
                                               header5: (char*) aHeader5 header6: (char*) aHeader6 footer1: (char*) aFooter1
																							 footer2: (char*) aFooter2 footer3: (char*) aFooter3
{
                                              
}

/**/
- (void) setPrinterType: (int) aType
{
  myPrinterType = aType;
}


/**/
- (void) initSpooler
{
  id docParsing = NULL;
  id driver= NULL;
  id myPort = NULL;
  id writer = NULL;
  id reader = NULL;
  BOOL printerDefined = TRUE;
  
  
  printf("------------> INIT SPOOLERRRRRRRRRRRRRR<----------------\n");
  
  switch ( myPrinterType ) {

      case PRINTER_NOT_DEFINED:
        printf("------------> PRINTER NOT DEFINED <----------------\n");
        docParsing = [DummyDocParsing new];
        printerDefined = FALSE;
        break;
        
    	case INTERNAL:
        printf("------------> INTERNAL (THERMAL PRINTER) <---------------\n");
        docParsing = [NonFiscalDocParsing new];
        driver = [ThermalDriver new];
        break;

    	case EXTERNAL:
        printf("------------> EXTERNAL (SERIAL PRINTER) <---------------\n");
        
        myPort = [ComPort new];
        [myPort setBaudRate: BR_115200];
        [myPort setStopBits: 1];
        [myPort setDataBits: 8];
        [myPort setParity: CT_PARITY_NONE];
        [myPort setPortNumber:	myPrinterCOMPort];
        [myPort setReadTimeout: 1000];
                
        docParsing = [NonFiscalDocParsing new];
        
        writer = [myPort getWriter];
				reader = [myPort getReader];
				
        driver = [SerialDriver new];
        [driver setWriter: writer];
        [driver setReader: reader];
        
        break;

    	/*case PARALLEL:
        doLog(0,"------------> PARALLEL PRINTER <---------------\n");
#ifdef CT_INCLUDE_PARALLEL_PRINTER
        
        myPort = [ParallelPort new];
        docParsing = [NonFiscalDocParsing new];
        writer = [myPort getWriter];
				reader = [myPort getReader];
				
        driver = [ParallelDriver new];
        [driver setWriter: writer];
        [driver setReader: reader];
        
#else
				doLog(0,"ERROR: No compilado para puerto paralelo\n");fflush(stdout);
				assert(TRUE);
#endif        
        break;*/

      default: 
        break;
  
  }

  [self setDocParsing: docParsing];  

  if (myPort) [myPort open];
  
  // Solo setea la interface de la impresora en el caso que haya impresora configurada
  if ( printerDefined ) {
  
    myPrinter = [PrinterInterface new];  
    [myPrinter initWithDriver: driver];
  
    [[FormatParser getInstance] setPrinterDefinition: driver];
    [docParsing setPrinterInterface: myPrinter];
    [driver initDriver];    
  } 
  
//  [super start];
}

/**/
- (void) setPrinterCOMPort: (int) aCOMPort
{
  myPrinterCOMPort = aCOMPort;
}

/**/
- (void) getPrinterStatus
{
  [self addPrintingJob: PRINTER_STATUS copiesQty: 0 ignorePaperOut: FALSE tree: NULL];
}

/**/
- (void) resetVoucher
{
  [self addPrintingJob: RESET_VOUCHER copiesQty: 0 ignorePaperOut: FALSE tree: NULL];
}

/**/
- (void) setPendingTicketsObserver: (id) anObserver
{
  [myDocParsing setPendingTicketsObserver: anObserver];
}

/**/
- (void) setFiscalCloseObserver: (id) anObserver
{
  [myDocParsing setFiscalCloseObserver: anObserver];
	if (myPrinter) [myPrinter setFiscalCloseObserver: anObserver];
}

/**/
- (unsigned long) getLastZFiscalCloseNumber 
{
  return [myPrinter getLastZFiscalCloseNumber];
}


/**/
- (void) setLinesQtyBetweenTickets: (int) aValue
{
 // Para impresoras fiscales no configuro el avance de linea
 if (myPrinterType == INTERNAL || myPrinterType == EXTERNAL)
       myAdvanceLineQty = aValue;
} 

/**/
- (void) setReportPathByLanguage: (int) aValue
{
	char buff[10];
	
  // seteo la ruta para ir a buscar los archivos de formato de los reportes segun el idioma
  buff[0] = '\0';
  switch (aValue) {
		case SPANISH:	strcpy(buff, "es/");
									break;
		case ENGLISH: strcpy(buff, "en/");
									break;
		case FRENCH: strcpy(buff, "fr/");
									break;
		default: strcpy(buff, "es/"); // por defecto va al espaniol
	}
  strcpy(myReportPathByLanguage, buff);
}

/**/
- (char *) getReportPathByLanguage
{
   return myReportPathByLanguage;
}

@end
