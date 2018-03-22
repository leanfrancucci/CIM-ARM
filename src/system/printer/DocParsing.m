#include "DocParsing.h"
#include <unistd.h>
#include "util.h" 
#include "PrinterExcepts.h"


#define TICKET_FORMAT_FILE "ticket.vft"
#define USER_CASH_REGISTER_CLOSE_FORMAT_FILE "userCashRegisterClose.vft"
#define TOTALIZE_CASH_REGISTER_CLOSE_FORMAT_FILE "totalizeCashRegisterClose.vft"
#define COLLECTOR_TOTAL_FORMAT_FILE "collectorTotal.vft"
#define TARIFF_QUERY_FORMAT_FILE "tariffQuery.vft"
#define DETAIL_REPORT_FORMAT_FILE "detailReport.vft" 
#define TICKET_LIST_REPORT_FORMAT_FILE "ticketListReport.vft" 
#define TICKET_RESUME_REPORT_FORMAT_FILE "ticketResumeReport.vft" 
#define DETAIL_SALES_REPORT_FORMAT_FILE "detailSalesReport.vft" 
#define DEPOSIT_FORMAT_FILE "deposit.vft"
#define EXTRACTION_FORMAT_FILE "extraction.vft"
#define CURRENT_VALUES_FORMAT_FILE "currentValues.vft"
#define CIM_ZCLOSE_FORMAT_FILE "zclose.vft"
#define ENROLLED_USER_FORMAT_FILE "enrolledUsers.vft"
#define CIM_OPERATOR_FORMAT_FILE "operator.vft"
#define CIM_AUDIT_FORMAT_FILE "auditReport.vft"
#define SYSTEM_INFO_FORMAT_FILE "systemInfo.vft"
#define CASH_REFERENCE_FORMAT_FILE "cashReference.vft"
#define CONFIG_TELESUP_FORMAT_FILE "configTelesupReport.vft"
#define REPAIR_ORDER_FORMAT_FILE "repairOrderReport.vft"
#define CIM_X_CASH_CLOSE_FORMAT_FILE "partialDayClose.vft"
#define CIM_COMMERCIAL_STATE_FORMAT_FILE "commercialState.vft"
#define COMMERCIAL_STATE_CHANGE_REPORT_FORMAT_FILE "commercialStateChangeReport.vft"
#define MODULES_LICENCE_REPORT_FORMAT_FILE "modulesLicence.vft"
#define TRANS_BOX_MODE_EXTRACTION_FORMAT_FILE "transBoxModeExtraction.vft"
#define BAG_TRACKING_FORMAT_FILE "bagTracking.vft"
#define CLOSING_CODE_FILE "closingCode.vft"
#define BACKUP_INFO_FILE "backupInfo.vft"

#define OUT_OF_PAPER_PRT_ERROR -1

#define MAX_DOC_SIZE	65535

@implementation DocParsing

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
  myParser = NULL;
  myTree = NULL;
  myPendingTicketsObserver = NULL;
	doc = malloc(MAX_DOC_SIZE);
	return self;
}

/**/
- (void) setPrinterInterface: (PRINTER_INTERFACE) aPrinterInterface
{
  myPrinterInterface = aPrinterInterface;
}

/**/
- (void) printTicket: (char*) aFormatFileName copiesQty: (int) aCopiesQty tree: (scew_tree*) tree
{
  // No hace nada para los que no tienen configurada impresora
}

/**/
- (void) printX
{
  //No hace nada, para que si por error se visualiza esta opcion para impresora termica no explote todo
}

/**/
- (void) printZ
{
  //No hace nada, para que si por error se visualiza esta opcion para impresora termica no explote todo
}

/**/
- (char*) processDocument: (char*) aFormatFileName finalDoc: (char*) aFinalDoc tree: (scew_tree*) tree
{
  char formatPath[255];
  char driverPath[255];
  
  strcpy(formatPath, "");
  strcpy(aFinalDoc, "");
  strcpy(driverPath, "");
  
  [myPrinterInterface getFormatSubdirectory: driverPath];
    
  strcpy(formatPath, [[Configuration getDefaultInstance] getParamAsString: "FORMAT_FILES_PATH"]);
  strcat(formatPath, driverPath);
  strcat(formatPath, aFormatFileName);
  
  [[FormatParser getInstance] parseDocument: formatPath finalDoc: aFinalDoc tree: tree];
  
  if ( *aFinalDoc == 0 )
    THROW(ERROR_PARSING_DOCUMENT_EX);


  return aFinalDoc;
}

/**/
- (char*) processTextFile: (char*) aFinalDoc tree: (scew_tree*) tree
{
	scew_element *element;
	
	element = scew_tree_root(tree);
	strcpy(aFinalDoc, scew_element_contents(element));
  
  return aFinalDoc;
}

/**/
- (void) processPrintingAction: (EntityPrintingType) aPrintingType copiesQty: (int) aCopiesQty tree: (scew_tree*) tree additional: (unsigned long) anAdditional
{

  // Si no esta seteada PrinterInterface quiere decir que no tiene impresora
  if ( !myPrinterInterface ) return;
  
  switch ( aPrintingType ) {
  
    case TICKET_PRT:
      [self printTicket: TICKET_FORMAT_FILE copiesQty: aCopiesQty tree: tree];
      break;
    
    case USER_CASH_REGISTER_CLOSE_PRT:
      [self processDocument: USER_CASH_REGISTER_CLOSE_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty];  
      break;
    
    case TOTALIZE_CASH_REGISTER_CLOSE_PRT:
      [self processDocument: TOTALIZE_CASH_REGISTER_CLOSE_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty];  
      break;
    
    case COLLECTOR_TOTAL_PRT:
      [self processDocument: COLLECTOR_TOTAL_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty];  
      break;
    
    case TARIFF_QUERY_PRT:
      [self processDocument: TARIFF_QUERY_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty];  
      break;
    
    case DETAIL_REPORT_PRT:
      [self processDocument: DETAIL_REPORT_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty];  
      break;

    case DEPOSIT_PRT:
      [self processDocument: DEPOSIT_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty printLogo: anAdditional];  
      break;

    case EXTRACTION_PRT:
      [self processDocument: EXTRACTION_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty printLogo: anAdditional];  
      break;

    case TRANS_BOX_MODE_EXTRACTION_PRT:
      [self processDocument: TRANS_BOX_MODE_EXTRACTION_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty printLogo: anAdditional];  
      break;

    case CURRENT_VALUES_PRT:
      [self processDocument: CURRENT_VALUES_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty printLogo: anAdditional];  
      break;

    case CIM_ZCLOSE_PRT:
      [self processDocument: CIM_ZCLOSE_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty printLogo: anAdditional];  
      break;
      
    case CIM_AUDIT_PRT:
      [self processDocument: CIM_AUDIT_FORMAT_FILE finalDoc: doc tree: tree];
      if (anAdditional == 0)
        [self printReport: doc copiesQty: aCopiesQty printLogo: TRUE];
      else //anAdditional == 1 o == 2 (no muestro el logo)
        [self printReport: doc copiesQty: aCopiesQty printLogo: FALSE];
      break;
      
    case CIM_OPERATOR_PRT:
      [self processDocument: CIM_OPERATOR_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty printLogo: anAdditional];  
      break;      

    case CLOSE_X_PRT:
      [self printX];
      break;
    
    case CLOSE_Z_PRT:
      [self printZ];
      break;
      
    case TEXT_PRT:
      [self processTextFile: doc tree: tree];
			[self printReport: doc copiesQty: aCopiesQty printLogo: anAdditional];  
      break;      

	  case ADVANCE_PAPER_PRT:
			if (anAdditional != 0) [myPrinterInterface advancePaper: anAdditional];              
			else [myPrinterInterface advancePaper];
     break; 
						
    case INIT_HEADERS_FOOTERS_PRT:
      [self setHeaders: TRUE];
      [self setHeadersExt];
      [self setFooters: TRUE];
      [self setFootersExt];                                                                                           
      break;       

    case PRINTER_STATUS:
      [myPrinterInterface getPrinterStatus];
      break;
      
    case RESET_VOUCHER:
      [myPrinterInterface resetVoucher];
      break;      
      
    case TICKET_LIST_REPORT_PRT:
      [self processDocument: TICKET_LIST_REPORT_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty];  
      break;      

    case TICKET_RESUME_REPORT_PRT:
      [self processDocument: TICKET_RESUME_REPORT_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty];  
      break;      
      
    case DETAIL_SALES_REPORT_PRT:
      [self processDocument: DETAIL_SALES_REPORT_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty];  
      break;    

    case Z_FISCAL_CLOSE_REPORT_PRT:
      [self zFiscalCloseReport: anAdditional];            
      break;

    case OPEN_CASH_DRAWER_PRT:
      [myPrinterInterface openCashDrawer];            
      break;
          
    case ENROLLED_USER_PRT:
      [self processDocument: ENROLLED_USER_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty printLogo: anAdditional];  
      break;

    case SYSTEM_INFO_PRT:
      [self processDocument: SYSTEM_INFO_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty printLogo: anAdditional];  
      break;
      
    case CONFIG_TELESUP_PRT:
      [self processDocument: CONFIG_TELESUP_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty printLogo: anAdditional];  
      break;

    case CASH_REFERENCE_PRT:
      [self processDocument: CASH_REFERENCE_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty printLogo: anAdditional];  
      break;

		case REPAIR_ORDER_PRT:
			[self processDocument: REPAIR_ORDER_FORMAT_FILE finalDoc: doc tree: tree];
			[self printReport: doc copiesQty: aCopiesQty printLogo: anAdditional];
			break;
          
    case CIM_X_CASH_CLOSE_PRT:
      [self processDocument: CIM_X_CASH_CLOSE_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty printLogo: anAdditional];  
      break;          

    case CIM_COMMERCIAL_STATE_PRT:
      [self processDocument: CIM_COMMERCIAL_STATE_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty printLogo: anAdditional];  
      break;

		case COMMERCIAL_STATE_CHANGE_REPORT_PRT:
      [self processDocument: COMMERCIAL_STATE_CHANGE_REPORT_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty printLogo: anAdditional];  
      break;

		case MODULES_LICENCE_PRT:
      [self processDocument: MODULES_LICENCE_REPORT_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty printLogo: anAdditional];  
      break;

		case BAG_TRACKING_PRT:
      [self processDocument: BAG_TRACKING_FORMAT_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty printLogo: anAdditional];  
      break;

		case CLOSING_CODE_PRT:
      [self processDocument: CLOSING_CODE_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty printLogo: anAdditional];  
      break;

		case BACKUP_INFO_PRT:
      [self processDocument: BACKUP_INFO_FILE finalDoc: doc tree: tree];
      [self printReport: doc copiesQty: aCopiesQty printLogo: anAdditional];  
      break;
		
    default:
      break;        
  }
}

/**/
- (void) printReport: (char*) aReport copiesQty: (int) aCopiesQty
{
  // No hace nada por si no tiene impresora configurada
}

/**/
- (void) printReport: (char*) aReport copiesQty: (int) aCopiesQty printLogo: (BOOL) aPrintLogo
{
  // No hace nada por si no tiene impresora configurada
}

/**/
- (void) clean
{
  
}

/**/
- (void) setHeaders: (BOOL) withContent
{

}

/**/
- (void) setHeadersExt
{

}

/**/
- (void) setFooters: (BOOL) withContent
{

}

/**/
- (void) setFootersExt
{

}

/**/
- (void) resetVoucher
{

}

/**/
- (void) zFiscalCloseReport: (unsigned long) fiscalNumber
{

}

/**/
- (void) setPendingTicketsObserver: (id) anObserver
{
  myPendingTicketsObserver = anObserver;
}

/**/
- (void) setFiscalCloseObserver: (id) anObserver
{
  myFiscalCloseObserver = anObserver;
}


/**/
- (void) notifyPrintedTicket: (unsigned long) aTicketId fiscalTicketNumber: (unsigned long) aFiscalTicketNumber
{
  if (myPendingTicketsObserver)
    [myPendingTicketsObserver setTicketPrinted: aTicketId];
    
  if (myFiscalCloseObserver)   
    [myFiscalCloseObserver notifyFiscalTicketInfo: aTicketId fiscalTicketNumber: aFiscalTicketNumber];
}

/**/
- (int) getAdvanceLineQty
{
  return myAdvLineQty;
}

/**/
- (void) setAdvanceLineQty: (int) aLineQty
{
  myAdvLineQty = aLineQty;
}

@end
