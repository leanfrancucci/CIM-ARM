#include "UserInterfaceExcepts.h"
#include "JAuditReportDateEditForm.h"
#include "SystemTime.h"
#include "JMessageDialog.h"
#include "JExceptionForm.h"
#include "cttypes.h"
#include "CimGeneralSettings.h"
#include "EventCategory.h"
#include "Event.h"
#include "Audit.h"
#include "CimDefs.h"
#include "CimCash.h"
#include "scew.h"
#include "PrinterSpooler.h"
#include "ReportXMLConstructor.h"
#include "UICimUtils.h"
#include "MessageHandler.h"
#include "Persistence.h"
#include "RegionalSettings.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation  JAuditReportDateEditForm
static char myCaption2[] = "entrar";

/**/
- (void) onCreateForm
{
  char buff[10];
  [super onCreateForm];

  myLabelDate = [JLabel new];  
  [myLabelDate setCaption: getResourceStringDef(RESID_DATE_TITLE, "FECHA")];
  [self addFormComponent: myLabelDate];
  
  [self addFormEol];
  
  // Fecha desde
  myLabelFromDate = [JLabel new];
  strcpy(buff,getResourceStringDef(RESID_FROM_DATE_LABEL, "Desde:"));
  strcat(buff," ");
  [myLabelFromDate setCaption: buff];
  [self addFormComponent: myLabelFromDate];
    
	myDateFromDateText = [JDate new];
	[myDateFromDateText setJDateFormat: [[RegionalSettings getInstance] getDateFormat]];
	[myDateFromDateText setSystemTimeMode:FALSE];
  [myDateFromDateText setDateValue: [SystemTime getLocalTime]];  
	[self addFormComponent: myDateFromDateText];
    
  [self addFormEol];
  
  // Fecha hasta
  myLabelToDate = [JLabel new];
  strcpy(buff,getResourceStringDef(RESID_TO_DATE_LABEL, "Hasta:"));
  strcat(buff," ");  
  [myLabelToDate setCaption: buff];
  [self addFormComponent: myLabelToDate];
  
	myDateToDateText = [JDate new];
	[myDateToDateText setJDateFormat: [[RegionalSettings getInstance] getDateFormat]];
	[myDateToDateText setSystemTimeMode:FALSE];
  [myDateToDateText setDateValue: [SystemTime getLocalTime]];  
	[self addFormComponent: myDateToDateText];

}

/**/
- (char *) getCaptionX
{
	return NULL;
}

/**/
- (void) onMenu2ButtonClick
{
	scew_tree *tree;
	AuditReportParam auditParam;
	CIM_CASH cimCash;
	USER user;
	EVENT_CATEGORY category;
	unsigned long auditNumber = 0;
  datetime_t auditDateTime = 0;
  int device;
  int usr;
  int categ;
  struct tm brokenTime;
  datetime_t encodeToDate;
  datetime_t encodeFromDate;
  JFORM processForm;
  int printType;
  int step = 0;
  
  // Fecha Desde
  [SystemTime decodeTime: [myDateFromDateText getDateValue] brokenTime: &brokenTime];    
  
  brokenTime.tm_hour = 0;
  brokenTime.tm_min = 0;
  brokenTime.tm_sec = 0;

  encodeFromDate = [SystemTime encodeTime: brokenTime.tm_year + 1900 mon: brokenTime.tm_mon + 1 day: brokenTime.tm_mday
                    hour: brokenTime.tm_hour min: brokenTime.tm_min sec: brokenTime.tm_sec];
  
  // Fecha Hasta  
  [SystemTime decodeTime: [myDateToDateText getDateValue] brokenTime: &brokenTime];    
  
  brokenTime.tm_hour = 23;
  brokenTime.tm_min = 59;
  brokenTime.tm_sec = 59;

  encodeToDate = [SystemTime encodeTime: brokenTime.tm_year + 1900 mon: brokenTime.tm_mon + 1 day: brokenTime.tm_mday
                    hour: brokenTime.tm_hour min: brokenTime.tm_min sec: brokenTime.tm_sec];	  

  // valido las fechas
  if ( (![myDateFromDateText isDateCorrect] ) || (![myDateToDateText isDateCorrect] ) )
		THROW(UI_INVALID_DATE_TIME_EX);
      
  if ( [myDateFromDateText getDateValue] > [myDateToDateText getDateValue] )
    THROW(UI_WRONG_DATE_EX);
  
  step = 0; 
  while (step >= 0 && step < 3) {
  
		// Paso 1
		if (step == 0) {
      // selecciono el Device *****************
      device = [UICimUtils selectCollectorSelection: self title: getResourceStringDef(RESID_CASHS_LABEL, "Cashs:")];
      	
    	switch (device) {
    		case ITEM_BACK: return;
    		case ITEM_ALL:
                strcpy(auditParam.deviceStr, getResourceStringDef(RESID_ALL_LABEL, "All"));
                auditParam.device = NULL;
                step = 1;
    						break;
    								
    		case ITEM_SELECT:
                cimCash = [UICimUtils selectCimCash: self];
                if (cimCash == NULL) return;
                strcpy(auditParam.deviceStr, [cimCash getName]);
                auditParam.device = cimCash;
                step = 1;
    						break;
    	}
  	}
    
		// Paso 2
		if (step == 1) {       	
    	// Selecciono el Usuario *****************
    	usr = [UICimUtils selectCollectorSelection: self title: getResourceStringDef(RESID_USERS_LABEL, "Users:")];
    	
    	switch (usr) {
    		case ITEM_BACK: step = 0; break;
    		case ITEM_ALL:
                strcpy(auditParam.userStr, getResourceStringDef(RESID_ALL_LABEL, "All"));
                auditParam.user = NULL;
                step = 2;
    						break;
    								
    		case ITEM_SELECT:
                user = [UICimUtils selectVisibleUser: self];
                if (user == NULL)
                  step = 0;
                else{
                  strcpy(auditParam.userStr, [user str]);
                  auditParam.user = user;
                  step = 2;
                }
    						break;
    	}
  	}
      
		// Paso 3
		if (step == 2) {
    	// Selecciono la Categoria *****************
    	categ = [UICimUtils selectCollectorSelection: self title: getResourceStringDef(RESID_EVENTS_CATEGORY_LABEL, "Events Category:")];
    	
    	switch (categ) {
    		case ITEM_BACK: step = 1; break;
    		case ITEM_ALL:
                strcpy(auditParam.eventCategoryStr, getResourceStringDef(RESID_ALL_LABEL, "All"));
                auditParam.eventCategory = NULL;
                step = 3;
    						break;
    								
    		case ITEM_SELECT:
                category = [UICimUtils selectEventCategory: self];
                if (category == NULL)
                  step = 1;
                else{
                  strcpy(auditParam.eventCategoryStr, [category str]);
                  auditParam.eventCategory = category;
                  step = 3;
                }
    						break;
    	}
  	}
  
		// Paso 4
		if (step == 3) {  
      // selecciono el tipo de impresion (detallado o resumido) *****************
      printType = [UICimUtils selectPrintType: self title: getResourceStringDef(RESID_PRINT_TYPE_LABEL, "Tipo de impresion:")];
    	switch (printType) {
    		case ITEM_BACK_PRT_TYPE: step = 2; break;
    		case ITEM_SUMMARY_PRT_TYPE:
    						auditParam.detailReport = FALSE;
    						break;
    		case ITEM_DETAILED_PRT_TYPE:
    		        auditParam.detailReport = TRUE;
    						break;
    	}
  	}
	
	}

	// Audito el evento
	auditDateTime = [SystemTime getLocalTime];
	auditNumber = [Audit auditEventCurrentUserWithDate: AUDIT_REQUEST additional: "" station: 0 datetime: auditDateTime logRemoteSystem: FALSE];

	auditParam.auditNumber = auditNumber;
	auditParam.auditDateTime = auditDateTime;
	auditParam.fromDate = encodeFromDate;
	auditParam.toDate = encodeToDate;
  
  processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_GENERATING_AUDIT_REPORT, "Generando Reporte de Auditoria...")];
  
  TRY
    tree = [[ReportXMLConstructor getInstance] buildXML: [[Persistence getInstance] getAuditDAO] entityType: CIM_AUDIT_PRT isReprint: FALSE varEntity: &auditParam];
	FINALLY	  
		[processForm closeProcessForm];
		[processForm free];
	END_TRY
	
}

/**/
/*
- (char*) getCaptionX
{
  return NULL;
}
*/

/**/
- (char*) getCaption2
{
  return getResourceStringDef(RESID_ENTER, myCaption2);
}


@end

