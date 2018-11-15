#include <stdio.h>
#include <stdlib.h>
#include "ReportController.h"
#include "ReportXMLConstructor.h"
#include "log.h"
#include "CimGeneralSettings.h"
#include "UserManager.h"
#include "ZCloseManager.h"
#include "ResourceStringDefs.h"
#include "Audit.h"
#include "UICimUtils.h"
#include "PrinterSpooler.h"
#include "Persistence.h"
#include "EventManager.h"
#include "CimManager.h"
#include "CashReferenceManager.h"
#include "TelesupervisionManager.h"

@implementation ReportController

static REPORT_CONTROLLER singleInstance = NULL;


+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}

+ getInstance
{
    return [self new];
}

/**/
- initialize
{
	[super initialize];
	return self;
    
    
}   

/**/
- (void) setObserver: (id) anObserver
{
    myObserver = anObserver;
}    


/**/
- (void) genOperatorReport: (int) aUserId detailed: (BOOL) aDetailed
{
    USER user = NULL;
    BOOL hasMovements = TRUE;

	if (![[CimGeneralSettings getInstance] getUseEndDay]) {
        THROW(RESID_USE_END_DAY_DISABLE);
    }

    if (aUserId>0)  {
        user = [[UserManager getInstance] getUser: aUserId];
    }

    if (user == NULL) {
        hasMovements = [[ZCloseManager getInstance] generateUserReports: aDetailed];
        
        if (!hasMovements) 
            THROW(RESID_MOVEMENTS_IN_PERIOD);
    } else {
        [[ZCloseManager getInstance] generateUserReport: user includeDetail: aDetailed];
    }
		  
}

/**/
- (void) genEndDay: (BOOL) aPrintOperatorReport
{
    if (![[CimGeneralSettings getInstance] getUseEndDay]) 
        THROW(RESID_USE_END_DAY_DISABLE);

    [[ZCloseManager getInstance] generateZClose: aPrintOperatorReport];
}    

/**/
- (void) genEnrolledUsersReport: (int) aStatus detailed: (BOOL) aDetailed
{
	scew_tree *tree;
	EnrollOperatorReportParam userStatusParam;
	unsigned long auditNumber = 0;
    datetime_t auditDateTime = 0;
  
  
    if (aStatus == 0) return;

    // Audito el evento
    auditDateTime = [SystemTime getLocalTime];
	auditNumber = [Audit auditEventCurrentUserWithDate: Event_ENROLLED_USER_REPORT additional: "" station: 0 datetime: auditDateTime logRemoteSystem: FALSE];

	userStatusParam.auditNumber = auditNumber;
	userStatusParam.auditDateTime = auditDateTime;
  //All 1 - Actives 2 - Inactives 3
	userStatusParam.userStatus = aStatus;
    userStatusParam.detailReport = aDetailed;
    
    tree = [[ReportXMLConstructor getInstance] buildXML: [UserManager getInstance] entityType: ENROLLED_USER_PRT isReprint: FALSE varEntity: &userStatusParam];
  	
  	[[PrinterSpooler getInstance] addPrintingJob: ENROLLED_USER_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
	
}	


/**/
- (void) genAuditReport: (datetime_t) aDateFrom dateTo: (datetime_t) aDateTo userId: (int) aUserId cashId: (int) aCashId eventCategoryId: (int) anEventCategoryId detailed:(BOOL) detailed
{
	scew_tree *tree;
	AuditReportParam auditParam;
	CIM_CASH cimCash = NULL;
	USER user;
	EVENT_CATEGORY category;
	unsigned long auditNumber = 0;
    datetime_t auditDateTime = 0;
    struct tm brokenTime;
    datetime_t encodeToDate;
    datetime_t encodeFromDate;

  
  // Fecha Desde
  [SystemTime decodeTime: aDateFrom brokenTime: &brokenTime];    
  
  brokenTime.tm_hour = 0;
  brokenTime.tm_min = 0;
  brokenTime.tm_sec = 0;

  encodeFromDate = [SystemTime encodeTime: brokenTime.tm_year + 1900 mon: brokenTime.tm_mon + 1 day: brokenTime.tm_mday
                    hour: brokenTime.tm_hour min: brokenTime.tm_min sec: brokenTime.tm_sec];
  
  // Fecha Hasta  
  [SystemTime decodeTime: aDateTo brokenTime: &brokenTime];    
  
  brokenTime.tm_hour = 23;
  brokenTime.tm_min = 59;
  brokenTime.tm_sec = 59;

  encodeToDate = [SystemTime encodeTime: brokenTime.tm_year + 1900 mon: brokenTime.tm_mon + 1 day: brokenTime.tm_mday
                    hour: brokenTime.tm_hour min: brokenTime.tm_min sec: brokenTime.tm_sec];	  

  
    /* CIM CASH */
    if (aCashId > 0) {
        cimCash = [[CimManager getInstance] getCimCashById: aCashId];
        stringcpy(auditParam.deviceStr, [cimCash getName]);
        auditParam.device = cimCash;
     } else {
        stringcpy(auditParam.deviceStr, getResourceStringDef(RESID_ALL_LABEL, "All"));
        auditParam.device = NULL;
    }

    
    // USERS
    if (aUserId > 0) {
        user = [[UserManager getInstance] getUser: aUserId];
        stringcpy(auditParam.userStr, [user str]);
        auditParam.user = user;
     } else {
        stringcpy(auditParam.userStr, getResourceStringDef(RESID_ALL_LABEL, "All"));
        auditParam.user = NULL;
    }
    
 
    // CATEGORY ID
    if (anEventCategoryId > 0) {
        category = [[EventManager getInstance] getEvent: anEventCategoryId];
        stringcpy(auditParam.eventCategoryStr, [category str]);
        auditParam.eventCategory = category;
     } else {
        stringcpy(auditParam.eventCategoryStr, getResourceStringDef(RESID_ALL_LABEL, "All"));
        auditParam.eventCategory = NULL;
    } 
    
    // TIPO DE IMPRESION
    auditParam.detailReport = detailed;
  

	// Audito el evento
	auditDateTime = [SystemTime getLocalTime];
	auditNumber = [Audit auditEventCurrentUserWithDate: AUDIT_REQUEST additional: "" station: 0 datetime: auditDateTime logRemoteSystem: FALSE];

	auditParam.auditNumber = auditNumber;
	auditParam.auditDateTime = auditDateTime;
	auditParam.fromDate = encodeFromDate;
	auditParam.toDate = encodeToDate;
  
    tree = [[ReportXMLConstructor getInstance] buildXML: [[Persistence getInstance] getAuditDAO] entityType: CIM_AUDIT_PRT isReprint: FALSE varEntity: &auditParam];
	
}

/**/
- (void) genCashReport: (int) aDoorId cashId: (int) aCashId detailed: (BOOL) aDetailed
{
	scew_tree *tree;
	EXTRACTION extraction;
	DOOR door;
	CashReportParam param;
	unsigned long auditNumber;
    datetime_t auditDateTime;
    char additional[20];
    id cash;

    id user;
    id profile;

    user = [[UserManager getInstance] getUserLoggedIn];
    profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
    
    
    if (![profile hasPermission: CASH_REPORT_OP]) 
        THROW(RESID_OP_NOT_ALLOWED);

    if (aDoorId > 0) {
  
        door = [[CimManager getInstance] getDoorById: aDoorId];
        
        if (door == NULL) return;

        extraction = [[ExtractionManager getInstance] getCurrentExtraction: door];
        if (!extraction) return;
        
        param.detailReport = aDetailed;


        // Audito el evento
        sprintf(additional, "%ld", [extraction getNumber]);
        auditDateTime = [SystemTime getLocalTime];
        auditNumber = [Audit auditEventCurrentUserWithDate: Event_CASH_REPORT additional: additional station: 0 datetime: auditDateTime logRemoteSystem: FALSE];	
	
        // Parametros del reporte
        param.cash = NULL;
        param.auditNumber = auditNumber;
        param.auditDateTime = auditDateTime;
        param.showBagNumber = FALSE;

        tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: CURRENT_VALUES_PRT isReprint: FALSE varEntity: &param];
        [[PrinterSpooler getInstance] addPrintingJob: CURRENT_VALUES_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
        
	}
	
	if (aCashId > 0) {

        cash = [[CimManager getInstance] getCimCashById: aCashId];
        if (cash == NULL) return;
  
        // obtener la door del cash seleccionado
        door = [cash getDoor]; // este cash va a ser pasado al buildXML en la variable varEntity 
        extraction = [[ExtractionManager getInstance] getCurrentExtraction: door];
        if (!extraction) return;
        
        param.detailReport = aDetailed;

        // Audito el evento
        sprintf(additional, "%ld", [extraction getNumber]);
        auditDateTime = [SystemTime getLocalTime];
        auditNumber = [Audit auditEventCurrentUserWithDate: Event_CASH_REPORT additional: additional station: 0 datetime: auditDateTime logRemoteSystem: FALSE];	
	
        // Parametros del reporte
        param.cash = cash;
        param.auditNumber = auditNumber;
        param.auditDateTime = auditDateTime;
        param.showBagNumber = FALSE;

        tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: CURRENT_VALUES_PRT isReprint: FALSE varEntity: &param];
        [[PrinterSpooler getInstance] addPrintingJob: CURRENT_VALUES_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
        
    }
	
}

/**/
- (void) genXCloseReport
{
	if (![[CimGeneralSettings getInstance] getUseEndDay]) 
        THROW(RESID_USE_END_DAY_DISABLE);

    [[ZCloseManager getInstance] generateCurrentZClose];
}


/**/
- (void) genCashReferenceReport: (int) aCashReferenceId detailed: (BOOL) aDetailed
{
	id reference = NULL;


    if (aCashReferenceId > 0) {
     reference = [[CashReferenceManager getInstance] getCashReferenceById: aCashReferenceId];
     if (reference == NULL) return;
     
    }

    [[ZCloseManager getInstance] generateCashReferenceSummary: aDetailed reference: reference];
    
}

/**/
- (void) genSystemInfoReport: (BOOL) aDetailed
{
    
	scew_tree *tree;
	EnrollOperatorReportParam param;
	unsigned long auditNumber;
    datetime_t auditDateTime;
    CIM cim;

    param.detailReport = aDetailed;
  
  
	// Audito el evento
	auditDateTime = [SystemTime getLocalTime];
	auditNumber = [Audit auditEventCurrentUserWithDate: Event_SYSTEM_INFO_REQUEST additional: "" station: 0 datetime: auditDateTime logRemoteSystem: FALSE];	
	
  // Parametros del reporte
	param.userStatus = 0; // no se usa
	param.auditNumber = auditNumber;
    param.auditDateTime = auditDateTime;

    cim = [[CimManager getInstance] getCim];
  
  	tree = [[ReportXMLConstructor getInstance] buildXML: cim entityType: SYSTEM_INFO_PRT isReprint: FALSE varEntity: &param];
  	[[PrinterSpooler getInstance] addPrintingJob: SYSTEM_INFO_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
}

/**/
- (void) genTelesupReport
{
	scew_tree *tree;
	EnrollOperatorReportParam param;
	unsigned long auditNumber;
    datetime_t auditDateTime;
    COLLECTION telesups;

  
	// Audito el evento
	auditDateTime = [SystemTime getLocalTime];
	auditNumber = [Audit auditEventCurrentUserWithDate: EVENT_SUPERVISION_REPORT additional: "" station: 0 datetime: auditDateTime logRemoteSystem: FALSE];
	
  // Parametros del reporte
	param.userStatus = 0; // no se usa
	param.auditNumber = auditNumber;
    param.auditDateTime = auditDateTime;

    telesups = [[TelesupervisionManager getInstance] getTelesups];

	tree = [[ReportXMLConstructor getInstance] buildXML: telesups entityType: CONFIG_TELESUP_PRT isReprint: FALSE varEntity: &param];
	[[PrinterSpooler getInstance] addPrintingJob: CONFIG_TELESUP_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
        
}

/**/
- (void) reprintDep: (BOOL) isLast fromId: (long) aFromId toId: (long) aToId
{
	scew_tree *tree;
	DEPOSIT deposit = NULL;
	unsigned long lastNumber, iBegin, iEnd, i;
	DepositReportParam depositParam;
	char additional[21];

  
    if (isLast) {
        deposit = [[[Persistence getInstance] getDepositDAO] loadLast];
        if (!deposit) return;

        depositParam.auditDateTime = [SystemTime getLocalTime];
        sprintf(additional, "%s %ld", getResourceStringDef(RESID_DROP_DESC, "Deposito"), [deposit getNumber]);
        depositParam.auditNumber = [Audit auditEventCurrentUserWithDate: Event_DROP_RECEIPT_REPRINT 
						  additional: additional station: 0  datetime: depositParam.auditDateTime logRemoteSystem: FALSE];	 
    	
        tree = [[ReportXMLConstructor getInstance] buildXML: deposit 
							entityType: DEPOSIT_PRT isReprint: TRUE varEntity: &depositParam];
        [[PrinterSpooler getInstance] addPrintingJob: DEPOSIT_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];

        [deposit free];
        
    } else {
        iBegin = aFromId;
        iEnd = aToId;
        // recorro los deposit y los mando a imprimir
        for (i = iBegin; i<= iEnd; i++) {
            deposit = [[[Persistence getInstance] getDepositDAO] loadById: i];
            if (deposit) {
                depositParam.auditDateTime = [SystemTime getLocalTime];
                sprintf(additional, "%s %ld", getResourceStringDef(RESID_DROP_DESC, "Deposito"), [deposit getNumber]);
                depositParam.auditNumber = [Audit auditEventCurrentUserWithDate: Event_DROP_RECEIPT_REPRINT 
									additional: additional station: 0  datetime: depositParam.auditDateTime logRemoteSystem: FALSE];

                tree = [[ReportXMLConstructor getInstance] buildXML: deposit 
									entityType: DEPOSIT_PRT isReprint: TRUE varEntity: &depositParam];
              	[[PrinterSpooler getInstance] addPrintingJob: DEPOSIT_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];

                [deposit free];
        
        
            } 
        }
    
    }
}

/**/
- (void) reprintExt: (BOOL) isLast fromId: (long) aFromId toId: (long) aToId
{
	scew_tree *tree;
	EXTRACTION extraction = NULL;
	char additional[20];
    int option;
	id form;
	unsigned long lastNumber, iBegin, iEnd, i;
    CashReportParam cashParam;

	cashParam.cash = NULL;
	cashParam.detailReport = FALSE;

    if (isLast) {
        extraction = [[ExtractionManager getInstance] loadLast];
        if (!extraction) return;
          
        // levanto el bag tracking
        [[[Persistence getInstance] getExtractionDAO] loadBagTrackingByExtraction: extraction];

        // Audito el evento
        cashParam.auditDateTime = [SystemTime getLocalTime];
        sprintf(additional, "%s %ld", getResourceStringDef(RESID_REPRINT_DEPOSIT_DESC, "Retiro"), [extraction getNumber]);

        cashParam.auditNumber = [Audit auditEventCurrentUserWithDate: Event_DEPOSIT_REPORT_REPRINT additional: additional station: [[extraction getDoor] getDoorId] datetime: cashParam.auditDateTime logRemoteSystem: FALSE];

        // si no hay bag tracking no muestro el campo BAG en el reporte
        cashParam.showBagNumber = [extraction hasBagTracking];

        if ([[[CimManager getInstance] getCim] isTransferenceBoxMode]) {
            tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: TRANS_BOX_MODE_EXTRACTION_PRT isReprint: TRUE  varEntity: &cashParam];
            [[PrinterSpooler getInstance] addPrintingJob: TRANS_BOX_MODE_EXTRACTION_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
        } else {
            tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: EXTRACTION_PRT isReprint: TRUE  varEntity: &cashParam];
            [[PrinterSpooler getInstance] addPrintingJob: EXTRACTION_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
        }

        // imprimo el bag tracking solo si corresponde
        if ([extraction hasBagTracking]) {

            if ([self getBagTrackingMode: [extraction getDoor]] == BagTrackingMode_AUTO || [self getBagTrackingMode: [extraction getDoor]] == BagTrackingMode_MIXED) {

            [extraction setBagTrackingMode: BagTrackingMode_AUTO];
            tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: BAG_TRACKING_PRT isReprint: TRUE varEntity: NULL];
            [[PrinterSpooler getInstance] addPrintingJob: BAG_TRACKING_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: ""];
            }
    
            if ([self getBagTrackingMode: [extraction getDoor]] == BagTrackingMode_MANUAL || [self getBagTrackingMode: [extraction getDoor]] == BagTrackingMode_MIXED) {
                [extraction setBagTrackingMode: BagTrackingMode_MANUAL];
                tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: BAG_TRACKING_PRT isReprint: TRUE varEntity: NULL];
                [[PrinterSpooler getInstance] addPrintingJob: BAG_TRACKING_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: ""];
            }

        }

        [extraction free];

    } else {
        iBegin = aFromId;
        iEnd = aToId;
                        
        // recorro los extraction y los mando a imprimir
        for (i = iBegin; i<= iEnd; i++) {
            extraction = [[ExtractionManager getInstance] loadById: i];
            if (extraction) {

                // levanto el bag tracking
                [[[Persistence getInstance] getExtractionDAO] loadBagTrackingByExtraction: extraction];

                // Audito el evento
                cashParam.auditDateTime = [SystemTime getLocalTime];
                sprintf(additional, "%s %ld", getResourceStringDef(RESID_REPRINT_DEPOSIT_DESC, "Retiro"), [extraction getNumber]);
                cashParam.auditNumber = [Audit auditEventCurrentUserWithDate: Event_DEPOSIT_REPORT_REPRINT additional: additional station: [[extraction getDoor] getDoorId] datetime: cashParam.auditDateTime logRemoteSystem: FALSE];

                // si no hay bag tracking no muestro el campo BAG en el reporte
                cashParam.showBagNumber = [extraction hasBagTracking];

                if ([[[CimManager getInstance] getCim] isTransferenceBoxMode]) {
                    tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: TRANS_BOX_MODE_EXTRACTION_PRT isReprint: TRUE  varEntity: &cashParam];
                    [[PrinterSpooler getInstance] addPrintingJob: TRANS_BOX_MODE_EXTRACTION_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] etPrintLogo]];
                } else {
                    tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: EXTRACTION_PRT isReprint: TRUE  varEntity: &cashParam];
                    [[PrinterSpooler getInstance] addPrintingJob: EXTRACTION_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
                }

                // imprimo el bag tracking solo si corresponde
                if ([extraction hasBagTracking]) {

                    if ([self getBagTrackingMode: [extraction getDoor]] == BagTrackingMode_AUTO || [self getBagTrackingMode: [extraction getDoor]] == BagTrackingMode_MIXED) {
		
                        [extraction setBagTrackingMode: BagTrackingMode_AUTO];
                        tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: BAG_TRACKING_PRT isReprint: TRUE varEntity: NULL];
                        [[PrinterSpooler getInstance] addPrintingJob: BAG_TRACKING_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: ""];
                    }
		
                    if ([self getBagTrackingMode: [extraction getDoor]] == BagTrackingMode_MANUAL || [self getBagTrackingMode: [extraction getDoor]] == BagTrackingMode_MIXED) {
                        [extraction setBagTrackingMode: BagTrackingMode_MANUAL];
                        tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: BAG_TRACKING_PRT isReprint: TRUE varEntity: NULL];
                        [[PrinterSpooler getInstance] addPrintingJob: BAG_TRACKING_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: ""];
                    }
                }

                [extraction free];
              } 
            }

    }
    
    
}    

/**/
- (void) reprintEndD: (BOOL) isLast fromId: (long) aFromId toId: (long) aToId
{
	scew_tree *tree;
	ZCLOSE zclose = NULL;
	char additional[20];
	ZCloseReportParam param;
	datetime_t auditDateTime;
	unsigned long auditNumber;
	volatile JFORM processForm = NULL;
  	unsigned long lastNumber, iBegin, iEnd, i;
	BOOL printOperatorReport = FALSE;

    if (![[CimGeneralSettings getInstance] getUseEndDay]) 
        THROW(RESID_USE_END_DAY_DISABLE);

    
    if (isLast) {
        zclose = [[ZCloseManager getInstance] loadLastZClose];
        if (zclose!= NULL) {
        
            // Audito el evento
            sprintf(additional, "%s %ld", getResourceStringDef(RESID_REPRINT_Z_DESC, "Z"), [zclose getNumber]);
            auditDateTime = [SystemTime getLocalTime];
            auditNumber = [Audit auditEventCurrentUserWithDate: Event_GRAND_Z_REPRINT additional: additional station: 0 datetime: auditDateTime logRemoteSystem: FALSE];
        
            // Imprimo el reporte X
            param.user = NULL;
            param.includeDetails = FALSE;
            param.auditNumber = auditNumber;
            param.auditDateTime = auditDateTime;
        
                        if (printOperatorReport)
                            [[ZCloseManager getInstance] generateUserReports: zclose includeDetail: FALSE];

            // Genero el reporte  
            tree = [[ReportXMLConstructor getInstance] buildXML: zclose 
                entityType: CIM_ZCLOSE_PRT isReprint: TRUE varEntity: &param];
        
            [[PrinterSpooler getInstance] addPrintingJob: CIM_ZCLOSE_PRT 
                copiesQty: 1
                ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
        
            [zclose free];
        }
        
    } else {
        
        iBegin = aFromId;
        iEnd = aToId;
        
        // recorro los cierres Z y los mando a imprimir
        for (i = iBegin; i<= iEnd; i++){
        zclose = [[ZCloseManager getInstance] loadZCloseById: i];
            if (zclose!= NULL) {
            
                            if (printOperatorReport)
                                [[ZCloseManager getInstance] generateUserReports: zclose includeDetail: FALSE];

                // Audito el evento
                sprintf(additional, "%s %ld", getResourceStringDef(RESID_REPRINT_Z_DESC, "Z"), [zclose getNumber]);
                auditDateTime = [SystemTime getLocalTime];
                auditNumber = [Audit auditEventCurrentUserWithDate: Event_GRAND_Z_REPRINT additional: additional station: 0 datetime: auditDateTime logRemoteSystem: FALSE];	
            
                // Imprimo el reporte Z
                param.user = NULL;
                param.includeDetails = FALSE;
                param.auditNumber = auditNumber;
                param.auditDateTime = auditDateTime;
            
                // Genero el reporte  
                tree = [[ReportXMLConstructor getInstance] buildXML: zclose 
                    entityType: CIM_ZCLOSE_PRT isReprint: TRUE varEntity: &param];
            
                [[PrinterSpooler getInstance] addPrintingJob: CIM_ZCLOSE_PRT 
                    copiesQty: 1
                    ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
            
                [zclose free];
            }             	 
        }
        
    }

}

/**/
- (void) reprintPartialD: (BOOL) isLast fromId: (long) aFromId toId: (long) aToId
{
	scew_tree *tree;
	ZCLOSE zclose = NULL;
	char additional[20];
	ZCloseReportParam param;
	datetime_t auditDateTime;
	unsigned long auditNumber;
	unsigned long lastNumber, iBegin, iEnd, i;

    if (![[CimGeneralSettings getInstance] getUseEndDay]) 
        THROW(RESID_USE_END_DAY_DISABLE);

    if (isLast) {
        
        zclose = [[ZCloseManager getInstance] loadLastCashClose];
        if (zclose!= NULL) {
        
            // Audito el evento
            sprintf(additional, "%s %ld", getResourceStringDef(RESID_REPRINT_PARTIAL_DESC, "Parcial"), [zclose getNumber]);
            auditDateTime = [SystemTime getLocalTime];
            auditNumber = [Audit auditEventCurrentUserWithDate: Event_GRAND_X_REPRINT additional: additional station: 0 datetime: auditDateTime logRemoteSystem: FALSE];	
        
            // Imprimo el reporte X
            param.user = NULL;
            param.includeDetails = FALSE;
            param.auditNumber = auditNumber;
            param.auditDateTime = auditDateTime;
        
            // Genero el reporte  
            tree = [[ReportXMLConstructor getInstance] buildXML: zclose 
                entityType: CIM_X_CASH_CLOSE_PRT isReprint: TRUE varEntity: &param];
        
            [[PrinterSpooler getInstance] addPrintingJob: CIM_X_CASH_CLOSE_PRT 
                copiesQty: 1
                ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
        
            [zclose free];
        }
        
    } else {
        
        iBegin = aFromId;
        iEnd = aToId;
    
        // recorro los cierres X y los mando a imprimir
        for (i = iBegin; i<= iEnd; i++) {
        zclose = [[ZCloseManager getInstance] loadCashCloseById: i];
            if (zclose!= NULL) {

                // Audito el evento
                sprintf(additional, "%s %ld", getResourceStringDef(RESID_REPRINT_PARTIAL_DESC, "Parcial"), [zclose getNumber]);
                auditDateTime = [SystemTime getLocalTime];
                auditNumber = [Audit auditEventCurrentUserWithDate: Event_GRAND_X_REPRINT additional: additional station: 0 datetime: auditDateTime logRemoteSystem: FALSE];
            
                // Imprimo el reporte X
                param.user = NULL;
                param.includeDetails = FALSE;
                param.auditNumber = auditNumber;
                param.auditDateTime = auditDateTime;
            
                // Genero el reporte  
                tree = [[ReportXMLConstructor getInstance] buildXML: zclose 
                    entityType: CIM_X_CASH_CLOSE_PRT isReprint: TRUE varEntity: &param];
            
                [[PrinterSpooler getInstance] addPrintingJob: CIM_X_CASH_CLOSE_PRT 
                    copiesQty: 1
                    ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
            
                [zclose free];
            }             	 
        }
        
    }
	
    
}


@end
