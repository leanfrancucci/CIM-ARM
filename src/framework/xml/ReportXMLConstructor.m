#include "ReportXMLConstructor.h"
#include "BillSettings.h"
#include "AmountSettings.h"
#include "RegionalSettings.h"
#include "UserManager.h"
#include "math.h"
#include "Round.h"
#include "TelesupervisionManager.h"
#include "Deposit.h"
#include "Extraction.h"
#include "User.h"
#include "Profile.h"
#include "ZClose.h"
#include "ResourceStringDefs.h"
#include "MessageHandler.h"
#include "DepositDetailReport.h"
#include "CurrencyManager.h"
#include "CimManager.h"
#include "Persistence.h"
#include "AuditDAO.h"
#include "Event.h"
#include "EventManager.h"
#include "PrinterSpooler.h"
#include "SafeBoxHAL.h"
#include "safeBoxMgr.h"
#include "ctversion.h"
#include "CimDefs.h"
#include "ZCloseDAO.h"
#include "ZCloseManager.h"
#include "CimGeneralSettings.h"
#include "ComPort.h"
#include "TelesupDefs.h"
#include <sys/vfs.h>
#include "TelesupScheduler.h"
#include "PrintingSettings.h"
#include "RepairOrder.h"
#include "RepairOrderItem.h"
#include "CommercialStateMgr.h"
#include "UICimUtils.h"
#include "BagTrack.h"
#include "G2ActivePIC.h"

#define BLOCK_SIZE_AUDIT 15 // cantidad de lineas a mostrar por bloque en el reporte de auditoria

//#define __DEBUG_XML		1
#undef __DEBUG_XML

static id singleInstance = NULL;

static void convertTime(datetime_t *dt, struct tm *bt)
{
#ifdef __UCLINUX
	localtime_r(dt, bt);
#else
	gmtime_r(dt, bt);
#endif
}

static char *formatBrokenDateTime(char *dest, struct tm *brokenTime)
{
	strftime(dest, 50, [[RegionalSettings getInstance] getDateTimeFormatString], brokenTime);
	return dest;
}

static char *formatBrokenDate(char *dest, struct tm *brokenTime)
{
	strftime(dest, 50, [[RegionalSettings getInstance] getDateFormatString], brokenTime);
	return dest;
}

@implementation ReportXMLConstructor

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
	[super initialize];
	return self;
}

/**/
- (void) concatGeneralInfo: (scew_element*) anElement isReprint: (BOOL) isReprint
{
	id billSettings = [BillSettings getInstance];
  datetime_t date;
  char dateStr[50];
  char buf[50];
  struct tm brokenTime;
  scew_element* element = NULL;
  USER user;
	id telesup;
 
  // header1
  element = scew_element_add(anElement, "vewHeader1");
  if (strlen(trim([billSettings getHeader1])) != 0){
    scew_element_set_contents(element, "TRUE");
    element = scew_element_add(anElement, "header1");
    scew_element_set_contents(element, trim([billSettings getHeader1]));
  }else
    scew_element_set_contents(element, "FALSE");
  
  // header2
  element = scew_element_add(anElement, "vewHeader2");
  if (strlen(trim([billSettings getHeader2])) != 0){
    scew_element_set_contents(element, "TRUE");
    element = scew_element_add(anElement, "header2");
    scew_element_set_contents(element, trim([billSettings getHeader2]));
  }else
    scew_element_set_contents(element, "FALSE");

  // header3 
  element = scew_element_add(anElement, "vewHeader3");
  if (strlen(trim([billSettings getHeader3])) != 0){
    scew_element_set_contents(element, "TRUE");
    element = scew_element_add(anElement, "header3");
    scew_element_set_contents(element, trim([billSettings getHeader3]));
  }else
    scew_element_set_contents(element, "FALSE");

  // header4
  element = scew_element_add(anElement, "vewHeader4");
  if (strlen(trim([billSettings getHeader4])) != 0){
    scew_element_set_contents(element, "TRUE");
    element = scew_element_add(anElement, "header4");
    scew_element_set_contents(element, trim([billSettings getHeader4]));
  }else
    scew_element_set_contents(element, "FALSE");

  // header5 
  element = scew_element_add(anElement, "vewHeader5");
  if (strlen(trim([billSettings getHeader5])) != 0){
    scew_element_set_contents(element, "TRUE");
    element = scew_element_add(anElement, "header5");
    scew_element_set_contents(element, trim([billSettings getHeader5]));
  }else
    scew_element_set_contents(element, "FALSE");

  // header6
  element = scew_element_add(anElement, "vewHeader6");
  if (strlen(trim([billSettings getHeader6])) != 0){
    scew_element_set_contents(element, "TRUE");
    element = scew_element_add(anElement, "header6");
    scew_element_set_contents(element, trim([billSettings getHeader6]));
  }else
    scew_element_set_contents(element, "FALSE");

  // footer1 
  element = scew_element_add(anElement, "vewFooter1");
  if (strlen(trim([billSettings getFooter1])) != 0){
    scew_element_set_contents(element, "TRUE");
    element = scew_element_add(anElement, "footer1");
    scew_element_set_contents(element, trim([billSettings getFooter1]));
  }else
    scew_element_set_contents(element, "FALSE");

  // footer2 
  element = scew_element_add(anElement, "vewFooter2");
  if (strlen(trim([billSettings getFooter2])) != 0){
    scew_element_set_contents(element, "TRUE");
    element = scew_element_add(anElement, "footer2");
    scew_element_set_contents(element, trim([billSettings getFooter2]));
  }else
    scew_element_set_contents(element, "FALSE");

  // footer3
  element = scew_element_add(anElement, "vewFooter3");
  if (strlen(trim([billSettings getFooter3])) != 0){
    scew_element_set_contents(element, "TRUE");
    element = scew_element_add(anElement, "footer3");
    scew_element_set_contents(element, trim([billSettings getFooter3]));
  }else
    scew_element_set_contents(element, "FALSE");
  
	// Id punto de venta tomado desde la PIMS - En el caso que no se encuentre la supervision a la PIMS el
	// id de sistema ira como "No definido"
/*	systemIdPIMS = [[TelesupervisionManager getInstance] getMainTelesupSystemId];
	element = scew_element_add(anElement, "systemIdPIMS");
	if ((systemIdPIMS == NULL) || (strlen(systemIdPIMS) == 0))
    scew_element_set_contents(element, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));
	else 
    scew_element_set_contents(element, systemIdPIMS);
*/
	telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];

	element = scew_element_add(anElement, "telesupSystemId");
	if ((telesup == NULL) || (strlen([telesup getSystemId] ) == 0))
    scew_element_set_contents(element, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));
	else 
    scew_element_set_contents(element, [telesup getSystemId]);

	element = scew_element_add(anElement, "systemIdPIMS");
	if ((telesup == NULL) || (strlen([telesup getRemoteSystemId] ) == 0))
    scew_element_set_contents(element, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));
	else 
    scew_element_set_contents(element, [telesup getRemoteSystemId]);

	// punto de venta
	element = scew_element_add(anElement, "systemId");
	scew_element_set_contents(element, [[CimGeneralSettings getInstance] getPOSId]);

  // Toma la fecha/hora desde la cual se solicito el reporte
  date = [SystemTime getLocalTime];
	convertTime(&date, &brokenTime);
	formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(anElement, "currentDate");
  scew_element_set_contents(element, dateStr);

  // Usuario
  user = [[UserManager getInstance] getUserLoggedIn];
  element = scew_element_add(anElement, "currentUserName");
	strcpy(buf, user != NULL ? [user str] : getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
	buf[17] = '\0';
  scew_element_set_contents(element, buf);

  // Usuario
  element = scew_element_add(anElement, "currentUserId");
  //sprintf(buf, "%05d", user != NULL ? [user getUserId] : 0);
  //scew_element_set_contents(element, buf);
	strcpy(buf, user != NULL ? [user getLoginName] : getResourceStringDef(RESID_UNKNOWN, " "));
	buf[10] = '\0';
  scew_element_set_contents(element, buf);


  
  // Is Reprint
  element = scew_element_add(anElement, "isReprint");
  if (isReprint)
    scew_element_set_contents(element, "TRUE");
  else
    scew_element_set_contents(element, "FALSE");
}

/**/
- (void) concatAuditDetailInfo: (scew_element*) anElement 
	entity: (id) anEntity 
	isReprint: (BOOL) isReprint
	param: (AuditReportParam *) anAuditParam
	tree: (scew_tree*) tree
{
    scew_element *element;
	scew_element *auditList;	
	scew_element *auditInfo;
    scew_element *detailList;
	scew_element *detailInfo;
	scew_element *generalInfo = NULL;
	scew_element *newElement = NULL;
    scew_tree* newTree;
	char buf[150], dateStr[50], buffer[50];
    int categId, count = 0;
    datetime_t date;
    datetime_t fromDate = 0;
    datetime_t toDate = 0;
    struct tm brokenTime;
    BOOL reportDetail = FALSE;
	BOOL oneBlock = TRUE;
	BOOL hasData = FALSE; 
    ABSTRACT_RECORDSET auditsRS = NULL;
	ABSTRACT_RECORDSET changeLogRS = NULL;
	CIM_CASH cimCash = NULL;
	USER user = NULL;
    USER userAudit;	
	EVENT event;
	EVENT_CATEGORY category = NULL;
	unsigned long printLogo;     // 0 = por defecto (muestra el logo) / 1 = (no muestra el logo) 
                               // 2 = (no muestra el logo, pero ademas imprime las lineas de separacion al final del reporte)

                               
// para el caso de la auditoria la logica es inversa. Ademas se utiliza otro posible valor que puede ser "2"
  if ([[CimGeneralSettings getInstance] getPrintLogo] == 1)
    printLogo = 0;
  else
    printLogo = 1;

  if (anAuditParam != NULL){
    reportDetail = anAuditParam->detailReport;
    fromDate = anAuditParam->fromDate;
    toDate = anAuditParam->toDate;
    cimCash = anAuditParam->device;
    user = anAuditParam->user;
    category = anAuditParam->eventCategory;
  }

  newTree = tree;

  // anEntity => [[Persistence getInstance] getAuditDAO]
	auditsRS = [[[Persistence getInstance] getAuditDAO] getNewAuditsRecordSet];
	auditList = scew_element_add(anElement, "auditList");

	// Recorro la lista de auditorias
	[auditsRS open];
	[auditsRS moveFirst];
	[auditsRS findFirstByDateTime: fromDate toDate: toDate];

	changeLogRS = [anEntity getNewChangeLogRecordSet];
	[changeLogRS open];
	[changeLogRS moveFirst];

	element = scew_element_add(auditList, "sectionHeader");
	scew_element_set_contents(element, "TRUE");

    element = scew_element_add(auditList, "sectionFooter");
	scew_element_set_contents(element, "FALSE");

    do {
		
		if ([auditsRS getDateTimeValue: "DATE"] >= fromDate && 
				[auditsRS getDateTimeValue: "DATE"] <= toDate) {

			// verifico el usuario
			if ( (user == NULL) || ( (user != NULL) && ([user getUserId] == [auditsRS getShortValue: "USER_ID"])) ){
				// verifico el device
				if ( (cimCash == NULL) || 
						( (cimCash != NULL) && ([cimCash getCimCashId] == [auditsRS getShortValue: "STATION"]) && (([auditsRS getShortValue: "EVENT_ID"] == EVENT_DELETE_CASH) || ([auditsRS getShortValue: "EVENT_ID"] == EVENT_EDIT_CASH) || 
								([auditsRS getShortValue: "EVENT_ID"] == AUDIT_CIM_DEPOSIT) || ([auditsRS getShortValue: "EVENT_ID"] == Event_AUTO_DROP)) ) ){
					
					categId = 0;
					event = [[EventManager getInstance] getEvent: [auditsRS getShortValue: "EVENT_ID"]];
					if (event != NULL)
						categId = [event getEventCategoryId];

					// verifico la categoria del evento
					if ( (category == NULL) || ( (category != NULL) && ([category getEventCategoryId] == categId)) ){

						  count++;
						  
						  // esta variable indica si hay datos o no
						  hasData = TRUE;
											
							// muestro las auditorias
							auditInfo = scew_element_add(auditList, "auditInfo");
							
							// nro auditoria
							element = scew_element_add(auditInfo, "auditId");
							sprintf(buf,"%05ld",[auditsRS getLongValue: "AUDIT_ID"]);
							scew_element_set_contents(element, buf);

							// nro auditoria
							element = scew_element_add(auditInfo, "userId");
							sprintf(buf,"%03d",[auditsRS getShortValue: "USER_ID"]);
							scew_element_set_contents(element, buf);
							
							// Fecha de la auditoria
							date = [auditsRS getLongValue: "DATE"];
							convertTime(&date, &brokenTime);
							formatBrokenDateTime(dateStr, &brokenTime);
							element = scew_element_add(auditInfo, "auditDate");
							scew_element_set_contents(element, dateStr);
							
							// Nombre del usuario    
							userAudit = [[UserManager getInstance] getUser: [auditsRS getShortValue: "USER_ID"]];
							if (userAudit != NULL)
								sprintf(buf, [userAudit str]);
							else
								sprintf(buf, getResourceStringDef(RESID_SYSTEM_EVENT, "Evento de Sistema"));
							
							element = scew_element_add(auditInfo, "userName");    
							buf[20] = '\0';
							scew_element_set_contents(element, buf);
							
							// Codigo y Descripcion del evento
							if (event != NULL){      
								sprintf(buf,"%04d-%s",[event getEventId],[event str]);
                //sprintf(buf, [event str]);
							}
							else
								sprintf(buf, getResourceStringDef(RESID_UNKNOWN_EVENT, "Evento Desconocido"));
								
							element = scew_element_add(auditInfo, "eventDescription");
							scew_element_set_contents(element, buf);            
							
            	// Tipo de reporte
            	element = scew_element_add(auditInfo, "reportDet");
            	if (reportDetail)
            	   scew_element_set_contents(element, "TRUE");
            	else 
                 scew_element_set_contents(element, "FALSE");							
							
							// detalle
							if (reportDetail) {                
                                element = scew_element_add(auditInfo, "additional");
								sprintf(buf, [auditsRS getStringValue: "ADDITIONAL" buffer: buffer]);      
								scew_element_set_contents(element, buf);
								
								element = scew_element_add(auditInfo, "viewAdditional");                  
								if (strlen(buf) == 0)
									scew_element_set_contents(element, "FALSE");
								else
									scew_element_set_contents(element, "TRUE");

								detailList = scew_element_add(auditInfo, "detailList");     
							}
							
							// Muestro el detalle cuando corresponda
							if (reportDetail && [auditsRS getCharValue: "HAS_CHANGE_LOG"]) {
								if ([changeLogRS eof] || [changeLogRS getLongValue: "AUDIT_ID"] != [auditsRS getLongValue: "AUDIT_ID"])
									[changeLogRS findFirstById: "AUDIT_ID" value: [auditsRS getLongValue: "AUDIT_ID"]];
							
		 							while ( (![changeLogRS eof]) && ([changeLogRS getLongValue: "AUDIT_ID"] == [auditsRS getLongValue: "AUDIT_ID"]) ) {
									detailInfo = scew_element_add(detailList, "detailInfo");
									
									// aca debo formatear/mostrar diferente la info dependiendo del tipo de evento
									// ver como resolverlo
									
									// campo
									element = scew_element_add(detailInfo, "field");
									//sprintf(buf, [changeLogRS getStringValue: "FIELD" buffer: buffer]);
									scew_element_set_contents(element, getResourceStringDef([changeLogRS getLongValue: "FIELD"], "No definido"));
									
									// nuevo valor
									element = scew_element_add(detailInfo, "newValue");
									sprintf(buf, [changeLogRS getStringValue: "NEW_VALUE" buffer: buffer]);
									scew_element_set_contents(element, buf);
					
									[changeLogRS moveNext];
								}
							}
							
					} // if categoria
				} // if device
			} // if user

			// imprimo por bloques el body del reporte
			if (count == BLOCK_SIZE_AUDIT){
        
                oneBlock = FALSE;
        
				[[PrinterSpooler getInstance] addPrintingJob: CIM_AUDIT_PRT copiesQty: 1 ignorePaperOut: FALSE tree: newTree additional: printLogo];
				count = 0;
				
				printLogo = 1;

				// creo nuevamente el tree
				newTree = scew_tree_create();

				// vuelvo a cargarlo
				newElement = scew_tree_add_root(newTree, "auditReport");

				//Informacion generalInfo      
				generalInfo = scew_element_add(newElement, "generalInfo");

				[self concatGeneralInfo: generalInfo isReprint: isReprint];

				auditList = scew_element_add(newElement, "auditList");
				
				element = scew_element_add(auditList, "sectionHeader");
				scew_element_set_contents(element, "FALSE");
				element = scew_element_add(auditList, "sectionFooter");
				scew_element_set_contents(element, "FALSE");
			}
			//

		}

//		[auditsRS moveNext];

	//}
	} while ([auditsRS findNextByDateTime: fromDate toDate: toDate]); 

  // si no hubo movimientos muestro el mensaje
	// No hay depositos para mostrar
	element = scew_element_add(auditList, "withOutValues");

    if (!hasData)
        scew_element_set_contents(element, "TRUE");
    else
        scew_element_set_contents(element, "FALSE");

  // imprimo lo que quedo pendiente del body ************************
  printLogo = 1;
  if (oneBlock){
    // para el caso de la auditoria la logica es inversa. Ademas se utiliza otro posible valor que puede ser "2"
    if ([[CimGeneralSettings getInstance] getPrintLogo] == 1)
      printLogo = 0;
  }

  [[PrinterSpooler getInstance] addPrintingJob: CIM_AUDIT_PRT copiesQty: 1 ignorePaperOut: FALSE tree: newTree additional: printLogo];

  // creo nuevamente el tree
  newTree = scew_tree_create();
  
  // vielvo a cargarlo
  newElement = scew_tree_add_root(newTree, "auditReport");
  
  //Informacion generalInfo      
  generalInfo = scew_element_add(newElement, "generalInfo");
  [self concatGeneralInfo: generalInfo isReprint: isReprint];
  auditList = scew_element_add(newElement, "auditList");
  element = scew_element_add(auditList, "sectionHeader");
  scew_element_set_contents(element, "FALSE");
  element = scew_element_add(auditList, "sectionFooter");
  scew_element_set_contents(element, "TRUE");

	// llamo nuevamente al addPrintingJob para imprimir el pie y las lineas de avance
	printLogo = 2;
	[[PrinterSpooler getInstance] addPrintingJob: CIM_AUDIT_PRT copiesQty: 1 ignorePaperOut: FALSE tree: newTree additional: printLogo];

	[auditsRS free];
	[changeLogRS free];
  
}

/**/
- (void) concatAuditGeneralInfo: (scew_element*) anElement 
	entity: (id) anEntity 
	isReprint: (BOOL) isReprint
	param: (AuditReportParam *) anAuditParam
{
  scew_element* generalInfo = NULL;
  scew_element* element = NULL;
  char dateStr[50];
  struct tm brokenTime;
  char buf[50];
	unsigned long auditNumber = 0;
  datetime_t auditDateTime = 0;
  BOOL reportDetail = FALSE;
  datetime_t fromDate = 0;
  datetime_t toDate = 0;
  char device[21];
  char user[100];
  char eventCategory[100];

	generalInfo = scew_element_add(anElement, "generalInfo");
	[self concatGeneralInfo: generalInfo isReprint: isReprint];

  if (anAuditParam != NULL){
    auditNumber = anAuditParam->auditNumber;
    auditDateTime = anAuditParam->auditDateTime;
    reportDetail = anAuditParam->detailReport;
    fromDate = anAuditParam->fromDate;
    toDate = anAuditParam->toDate;
    strcpy(device, anAuditParam->deviceStr);
    strcpy(user, anAuditParam->userStr);
    strcpy(eventCategory, anAuditParam->eventCategoryStr);
  }

	// Tipo de reporte
	element = scew_element_add(generalInfo, "reportDetail");
	if (reportDetail)
	   scew_element_set_contents(element, "TRUE");
	else 
     scew_element_set_contents(element, "FALSE");
	
  // Numero de transaccion (auditoria)
  element = scew_element_add(generalInfo, "trans");
  sprintf(buf, "%08ld", auditNumber);
  scew_element_set_contents(element, buf);

  // Fecha de transaccion (auditoria)
	convertTime(&auditDateTime, &brokenTime);
  formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "transTime");
  scew_element_set_contents(element, dateStr);	
	
  // Fecha desde
	convertTime(&fromDate, &brokenTime);
  formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "fromDate");
  scew_element_set_contents(element, dateStr);
  
  // Fecha hasta
	convertTime(&toDate, &brokenTime);
  formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "toDate");
  scew_element_set_contents(element, dateStr);
  
  // Device
  element = scew_element_add(generalInfo, "device");
  scew_element_set_contents(element, device);

  // User
  element = scew_element_add(generalInfo, "user");
  scew_element_set_contents(element, user);
  
  // Event Category
  element = scew_element_add(generalInfo, "eventCategory");
  scew_element_set_contents(element, eventCategory);
}

/**/
- (void) buildAuditXML: (id) anEntity
  isReprint: (BOOL) isReprint 
  tree: (scew_tree*) tree 
  param: (void *) aParam
{
  scew_element* root = NULL;  
  root = scew_tree_add_root(tree, "auditReport");

  //Informacion generalInfo
  [self concatAuditGeneralInfo: root entity: anEntity isReprint: isReprint param: (AuditReportParam*)aParam];
  
  //Datos del detalle
  [self concatAuditDetailInfo: root entity: anEntity isReprint: isReprint param: (AuditReportParam*)aParam tree: tree];
}

/*************************************************
*
* Archivo XML de ZClose
*
*************************************************/

/**/
- (void) concatZCloseGeneralInfo: (scew_element*) anElement 
	entity: (id) anEntity 
	entityType: (int) anEntityType 
	isReprint: (BOOL) isReprint
	param: (ZCloseReportParam *) aZCloseParam
{
  scew_element* generalInfo = NULL;
  scew_element* element = NULL;
  datetime_t date;
  char dateStr[50];
  struct tm brokenTime;
  char buf[50];
  char mSymbol[4];
	USER user;
	unsigned long auditNumber = 0;
  datetime_t auditDateTime = 0;

  strcpy(mSymbol, [[RegionalSettings getInstance] getMoneySymbol]);

	generalInfo = scew_element_add(anElement, "generalInfo");
	[self concatGeneralInfo: generalInfo isReprint: isReprint];

	// Tipo de reporte
	element = scew_element_add(generalInfo, "reportType");
	if (anEntityType == CIM_ZCLOSE_PRT) scew_element_set_contents(element, "1");
	else if (anEntityType == CIM_OPERATOR_PRT) scew_element_set_contents(element, "2");
	else scew_element_set_contents(element, "3");

	user = NULL;
	if (aZCloseParam != NULL) user = aZCloseParam->user;

	// Para el cierre Z el usuario es el del cierre
	if (anEntityType == CIM_ZCLOSE_PRT) {
		user = [anEntity getUser];
	}

  // Usuario
  element = scew_element_add(generalInfo, "userName");
	strcpy(buf, user != NULL ? [user str] : getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
	buf[17] = '\0';
  scew_element_set_contents(element, buf);

  // Usuario
  element = scew_element_add(generalInfo, "userId");
  sprintf(buf, "%05d", user != NULL ? [user getUserId] : 0);
  scew_element_set_contents(element, buf);

  // Cuenta bancaria del usuario
  element = scew_element_add(generalInfo, "account");
  scew_element_set_contents(element, user != NULL ? [user getBankAccountNumber] : "");

  // Fecha / hora del cierre
  date = [anEntity getCloseTime];
	convertTime(&date, &brokenTime);
	formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "closeTime");
  scew_element_set_contents(element, dateStr);

  // Fecha / hora de la apertura
  date = [anEntity getOpenTime];
	convertTime(&date, &brokenTime);
  formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "openTime");
  scew_element_set_contents(element, dateStr);

  // Cantidad de billetes rechazados
  element = scew_element_add(generalInfo, "rejectedQty");
  sprintf(buf, "%d", [anEntity getRejectedQty]);
  scew_element_set_contents(element, buf);

  // Numero de extraccion Z
  element = scew_element_add(generalInfo, "number");
  sprintf(buf, "%08ld", [anEntity getNumber]);
  scew_element_set_contents(element, buf);
  
  if (aZCloseParam != NULL){
    auditNumber = aZCloseParam->auditNumber;
    auditDateTime = aZCloseParam->auditDateTime;
  }
  
  // Numero de transaccion (auditoria)
  element = scew_element_add(generalInfo, "trans");
  sprintf(buf, "%08ld", auditNumber);
  scew_element_set_contents(element, buf);

  // Fecha de transaccion (auditoria)
	convertTime(&auditDateTime, &brokenTime);
  formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "transTime");
  scew_element_set_contents(element, dateStr);

  // Numero de extraccion Z anterior
  element = scew_element_add(generalInfo, "lastZ");
  if (anEntityType == CIM_ZCLOSE_PRT)
    sprintf(buf, "%08ld", [[[Persistence getInstance] getZCloseDAO] getPrevZCloseNumber]);
  else
    sprintf(buf, "%08ld", [[[Persistence getInstance] getZCloseDAO] getLastZCloseNumber]);
  scew_element_set_contents(element, buf);

  // Fecha/hora de extraccion Z anterior
  date = [[[Persistence getInstance] getZCloseDAO] getPrevZCloseCloseTime];
  convertTime(&date, &brokenTime);
	formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "lastDateZ");
  scew_element_set_contents(element, dateStr);

  // Desde deposito
  element = scew_element_add(generalInfo, "fromDepositNumber");
  sprintf(buf, "%08ld", [anEntity getFromDepositNumber]);
  scew_element_set_contents(element, buf);

  // Hasta deposito
  element = scew_element_add(generalInfo, "toDepositNumber");
  sprintf(buf, "%08ld", [anEntity getToDepositNumber]);
  scew_element_set_contents(element, buf);

  // Incluye detalles ?
  element = scew_element_add(generalInfo, "includeDetails");
  if (aZCloseParam != NULL && aZCloseParam->includeDetails )
    scew_element_set_contents(element, "TRUE");
  else
    scew_element_set_contents(element, "FALSE");


	// los siguientes 3 campos se utilizan para el reporte de operador
	// al emitir un Z

	// es resumido ?
  element = scew_element_add(generalInfo, "resumeReport");
  if (aZCloseParam != NULL && aZCloseParam->resumeReport )
    scew_element_set_contents(element, "TRUE");
  else
    scew_element_set_contents(element, "FALSE");

	// ve el encabezado ?
  element = scew_element_add(generalInfo, "vHeader");
	if (aZCloseParam != NULL && aZCloseParam->resumeReport ){
  	if (aZCloseParam != NULL && aZCloseParam->viewHeader )
    	scew_element_set_contents(element, "TRUE");
  	else
			scew_element_set_contents(element, "FALSE");
	}else
		scew_element_set_contents(element, "TRUE");

	// ve el pie ?
  element = scew_element_add(generalInfo, "vFooter");
	if (aZCloseParam != NULL && aZCloseParam->resumeReport ){
  	if (aZCloseParam != NULL && aZCloseParam->viewFooter )
    	scew_element_set_contents(element, "TRUE");
  	else
			scew_element_set_contents(element, "FALSE");
	}else
		scew_element_set_contents(element, "TRUE");

}


/**/
- (void) concatZExtractionDetailInfo: (scew_element*) anElement 
	entity: (id) anEntity 
	entityType: (int) anEntityType 
	isReprint: (BOOL) isReprint
	param: (ZCloseReportParam *) aZCloseParam
	details : (COLLECTION) aDetails
{
	scew_element *element;
	scew_element *extractionDetailsElement;
	scew_element *extractionDetailElement;
	scew_element *elementCimCashs;
	scew_element *elementCimCash;
	scew_element *elementAcceptor;
	scew_element *elementAcceptorList;
	scew_element *elementCurrency;
	scew_element *elementCurrencyList;
	EXTRACTION_DETAIL extractionDetail;
	int iCash, iAcceptor, iDetail, iCurrency;
	char buf[50];
	int totalDecimals = [[AmountSettings getInstance] getTotalRoundDecimalQty];
	COLLECTION detailsByCimCash, detailsByAcceptor, detailsByCurrency;
	COLLECTION cimCashs, currecies, acceptorSettingsList;
	ACCEPTOR_SETTINGS acceptorSettings;
	CIM_CASH cimCash;
	CURRENCY currency;

/*
	<cimcashs>
	 	<cimcash>
			<name>VERIFIED CASH BOX</name>	
				<acceptor>	
					<acceptorName>VALIDADOR xxx</acceptorName>
					<currency>
						<currencyCode>ARS</currencyCode>
						<qty>10</qty>
						<total>50.00</total>
						<extractionDetails>
							<extractionDetail>...</extractionDetail>
							<extractionDetail>...</extractionDetail>
							<extractionDetail>...</extractionDetail>
						</extractionDetails>
					</currency>
					<currency>
						<currencyCode>USD</currencyCode>
						<qty>10</qty>
						<total>50.00</total>
						<extractionDetails>
							<extractionDetail>...</extractionDetail>
							<extractionDetail>...</extractionDetail>
							<extractionDetail>...</extractionDetail>
						</extractionDetails>
					</currency>			
				</acceptor>

				<currency>
						<currencyCode>ARS</currencyCode>
						<total>50.00</total>
				</currency>
				
		</cimcash>
	</cimcashs>
	<currency>
			<currencyCode>ARS</currencyCode>
			<total>50.00</total>
	</currency>	
*/
	elementCimCashs = scew_element_add(anElement, "cimCashs");

	// Obtengo la lista de cashs
	cimCashs = [anEntity getCimCashs: aDetails];

	// Recorro la lista de cashs
	for (iCash = 0; iCash < [cimCashs size]; ++iCash) {

		cimCash = [cimCashs at: iCash];
		
		// Nombre de la caja
		elementCimCash = scew_element_add(elementCimCashs, "cimCash");
		element = scew_element_add(elementCimCash, "name");
		scew_element_set_contents(element, [cimCash getName]);

		// Tipo de caja (automatica / manual)
		element = scew_element_add(elementCimCash, "cimCashType");
		sprintf(buf, "%d", [cimCash getDepositType]);
		scew_element_set_contents(element, buf);

		// Obtengo los depositos para el cash actual
		detailsByCimCash = [anEntity getDetailsByCimCash: aDetails cimCash: cimCash];

		// Obtengo la lista  de validadores
		acceptorSettingsList = [anEntity getAcceptorSettingsList: detailsByCimCash];
		
		elementAcceptorList = scew_element_add(elementCimCash, "acceptorList");

		// Recorro la lista de validadores
		for (iAcceptor = 0; iAcceptor < [acceptorSettingsList size]; ++iAcceptor) {

			acceptorSettings = [acceptorSettingsList at: iAcceptor];
			elementAcceptor = scew_element_add(elementAcceptorList, "acceptor");

			// Nombre del aceptador
			element = scew_element_add(elementAcceptor, "acceptorName");
			scew_element_set_contents(element, [acceptorSettings getAcceptorName]);
	
			// Obtengo la lista de detalles para el validador en curso
			detailsByAcceptor = [anEntity getDetailsByAcceptorSettings: detailsByCimCash acceptorSettings: acceptorSettings];

			// Obtengo la lista de monedas
			currecies = [anEntity getCurrencies: detailsByAcceptor];

			elementCurrencyList = scew_element_add(elementAcceptor, "currencyList");

			// Recorro la lista de monedas
			for (iCurrency = 0; iCurrency < [currecies size]; ++iCurrency) {

				currency = [currecies at: iCurrency];
				detailsByCurrency = [anEntity getDetailsByCurrency: detailsByAcceptor currency: currency];

				elementCurrency = scew_element_add(elementCurrencyList, "currency");

				element = scew_element_add(elementCurrency, "currencyCode");
				scew_element_set_contents(element, [currency getCurrencyCode]);

				element = scew_element_add(elementCurrency, "qty");
				sprintf(buf, "%04d", [anEntity getQty: detailsByCurrency]);
				scew_element_set_contents(element, buf);
		
				element = scew_element_add(elementCurrency, "total");
				formatMoney(buf, "", [anEntity getTotalAmount: detailsByCurrency], totalDecimals, 20);
				scew_element_set_contents(element, buf);            
		
				extractionDetailsElement = scew_element_add(elementCurrency, "extractionDetails");
			
				for (iDetail = 0; iDetail < [detailsByCurrency size]; ++iDetail) {
			
					extractionDetail = [detailsByCurrency at: iDetail];
					extractionDetailElement = scew_element_add(extractionDetailsElement, "extractionDetail");
		
					// Cantidad
					element = scew_element_add(extractionDetailElement, "qty");
					sprintf(buf, "%04d" , [extractionDetail getQty]);
					scew_element_set_contents(element, buf);
			
					// Importe
					element = scew_element_add(extractionDetailElement, "amount");
					if ([extractionDetail isUnknownBill]) stringcpy(buf, getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
					else formatMoney(buf, "", [extractionDetail getAmount], totalDecimals, 20);
					scew_element_set_contents(element, buf);
			
					// Total
					element = scew_element_add(extractionDetailElement, "totalAmount");
					if ([extractionDetail isUnknownBill]) stringcpy(buf, getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
					else formatMoney(buf, "", [extractionDetail getTotalAmount], totalDecimals, 20);
					scew_element_set_contents(element, buf);

					// Nombre del tipo de valor
					element = scew_element_add(extractionDetailElement, "depositValueName");
					scew_element_set_contents(element, [extractionDetail getDepositValueName]);
				}

				[detailsByCurrency free];
				
			}
			
			[currecies free];
			[detailsByAcceptor free];

			
		}

		[acceptorSettingsList free];

    // Obtengo la lista de monedas para mostrar los totales por cash
		currecies = [anEntity getCurrencies: detailsByCimCash];
    for (iCurrency = 0; iCurrency < [currecies size]; ++iCurrency) {
        
        currency = [currecies at: iCurrency];
        
    		elementCurrency = scew_element_add(elementCimCash, "totalCurrency");

				element = scew_element_add(elementCurrency, "totalCurrencyCode");
				scew_element_set_contents(element, [currency getCurrencyCode]);
    		
				element = scew_element_add(elementCurrency, "totalCurr");
				formatMoney(buf, "", [anEntity getTotalAmountByCurreny: detailsByCimCash currency: currency], totalDecimals, 20);
				scew_element_set_contents(element, buf);        
    }

    [currecies free];
		[detailsByCimCash free];   
	}

	[cimCashs free];
	
  // Obtengo la lista de monedas para mostrar los totales por cash
	currecies = [anEntity getCurrencies: NULL];    	
  for (iCurrency = 0; iCurrency < [currecies size]; ++iCurrency) {
      
      currency = [currecies at: iCurrency];
      
      elementCurrency = scew_element_add(elementCimCashs, "totalCashCurrency");

			element = scew_element_add(elementCurrency, "totalCashCurrencyCode");
			scew_element_set_contents(element, [currency getCurrencyCode]);
  		
			element = scew_element_add(elementCurrency, "totalCashCurr");
			formatMoney(buf, "", [anEntity getTotalAmountByCurreny: NULL currency: currency], totalDecimals, 20);
			scew_element_set_contents(element, buf);
  }
  
  [currecies free];

}

/**/
- (COLLECTION) concatZCloseDetailInfo: (scew_element*) anElement 
	entity: (id) anEntity 
	entityType: (int) anEntityType 
	isReprint: (BOOL) isReprint
	param: (ZCloseReportParam *) aZCloseParam
{
	scew_element *element;
	scew_element *elementCurrency;
	scew_element *elementCurrencyList;
	scew_element *elementDetails;
	scew_element *manualDropsDetailsElement;
	scew_element *manualDropDetailElement;
	ZCLOSE_DETAIL detail;
	int iDetail, iCurrency;
	char buf[50];
	int totalDecimals = [[AmountSettings getInstance] getTotalRoundDecimalQty];
	COLLECTION detailsByCurrency;
	COLLECTION manualDrops, validatedDrops, currecies;
	CURRENCY currency;
	COLLECTION details = NULL;
	ReportDetailItem *item;
	int currencyId = 0;
	money_t amount;
	int i;
	CIM_CASH cimCash;
	CIM_MANAGER cimManager;
	/** @todo: Poner global esto */
	static char *depositValueTypeStr[] = {"UK", "CS", "CS", "CH", "TC", "CC", "OT", "BK"};
  COLLECTION zcloseDetails;
	
	cimManager = [CimManager getInstance];

/*
  <currencyList>
    <currency>
      <currencyCode></currencyCode>
      <totalManualDrop></totalManualDrop>
      <totalValidatedDrop></totalValidatedDrop>
      <total></total>
      <manualDropDetails>
        ...
      </manualDropDetails>    
    </currency>
  <currencyList>
*/

	if (anEntityType == CIM_OPERATOR_PRT) {
		details = [anEntity getZCloseDetailsByUser: aZCloseParam->user];
	} else {
		details = [anEntity getZCloseDetailsSummary];
	}

	// Obtengo la lista de monedas
	currecies = [anEntity getCurrencies: details];
	elementCurrencyList = scew_element_add(anElement, "currencyList");
  
	// Recorro la lista de monedas
	for (iCurrency = 0; iCurrency < [currecies size]; ++iCurrency) {

		currency = [currecies at: iCurrency];
		
    detailsByCurrency = [anEntity getDetailsByCurrency: details currency: currency];
    manualDrops = [anEntity getManualDetails: detailsByCurrency];
    validatedDrops = [anEntity getValidatedDetails: detailsByCurrency];
    
		elementCurrency = scew_element_add(elementCurrencyList, "currency");

		element = scew_element_add(elementCurrency, "currencyCode");
		scew_element_set_contents(element, [currency getCurrencyCode]);

		element = scew_element_add(elementCurrency, "qty");
		sprintf(buf, "%04d", [anEntity getQty: detailsByCurrency]);
		scew_element_set_contents(element, buf);

		element = scew_element_add(elementCurrency, "totalManualDrop");
		formatMoney(buf, "", [anEntity getTotalAmount: manualDrops], totalDecimals, 20);
		scew_element_set_contents(element, buf);
	
  	element = scew_element_add(elementCurrency, "totalValidatedDrop");
		formatMoney(buf, "", [anEntity getTotalAmount: validatedDrops], totalDecimals, 20);
		scew_element_set_contents(element, buf);
    	
		element = scew_element_add(elementCurrency, "total");
		formatMoney(buf, "", [anEntity getTotalAmount: detailsByCurrency], totalDecimals, 20);
		scew_element_set_contents(element, buf);

		manualDropsDetailsElement = scew_element_add(elementCurrency, "manualDropDetails");
	
		for (iDetail = 0; iDetail < [manualDrops size]; ++iDetail) {
	   

			detail = [manualDrops at: iDetail];
			manualDropDetailElement = scew_element_add(manualDropsDetailsElement, "manualDropDetail");

			// Cantidad
			element = scew_element_add(manualDropDetailElement, "qty");
			sprintf(buf, "%04d" , [detail getQty]);
			scew_element_set_contents(element, buf);
	
			// Importe
			element = scew_element_add(manualDropDetailElement, "amount");
			formatMoney(buf, "", [detail getAmount], totalDecimals, 20);
			scew_element_set_contents(element, buf);
	
			// Total
			element = scew_element_add(manualDropDetailElement, "totalAmount");
			formatMoney(buf, "", [detail getTotalAmount], totalDecimals, 20);
			scew_element_set_contents(element, buf);

			// Nombre del tipo de valor
			element = scew_element_add(manualDropDetailElement, "depositValueName");
			scew_element_set_contents(element, [detail getDepositValueName]);
		}	
		// Ver por acaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

    [detailsByCurrency free];
		[validatedDrops free];		
		[manualDrops free];
	}
	
	// No hay depositos para mostrar
  // Si es distinto de cero quiere decir que tenemos elementos para armar el reporte
	element = scew_element_add(elementCurrencyList, "withOutValues");
	if ([currecies size] == 0)
    scew_element_set_contents(element, "TRUE");
  else
    scew_element_set_contents(element, "FALSE");

	//ACA SI VA 
	element = scew_element_add(elementCurrencyList, "withNoInfoData");
	if (iDetail != 0)
    scew_element_set_contents(element, "TRUE");
  else
    scew_element_set_contents(element, "FALSE");

	[currecies free];

	zcloseDetails = details;
	
	// Si incluye el detalle tengo que generarlo ahora
  if (aZCloseParam == NULL || !aZCloseParam->includeDetails) return zcloseDetails;
  
  // Obtengo el detalle entre los numeros de depositos pasados
  // como parametro y para el usuario seleccionado
  details = [[DepositDetailReport getInstance] generateDepositDetailReport: [anEntity getFromDepositNumber]
    toDepositNumber: [anEntity getToDepositNumber]
    user: aZCloseParam->user];
  
  elementDetails = scew_element_add(anElement, "dropDetails");
  amount = 0;
  elementCurrency = NULL;
  
  /*
  <dropDetails>
      <currency>
         <currencyCode>ARS</currencyCode>
         <detail>
            <totalAmount>250.00</totalAmount>
            <depositValueName>CS</depositValueName>
            <cimCashName>VALIDATED CASH</cimCashName>
            <depDepositType_MANUALositNumber>V00001</depositNumber>
         </detail>
      </currency>
  </dropDetails>
  */
  for (i = 0; i < [details size]; ++i) {
    
    item = (ReportDetailItem *)[details at: i];
    
    // Si cambio la moneda tengo que generar otro
    if (item->currencyId != currencyId) {
      
      if (currencyId != 0) {
    		
        // Importe
  			element = scew_element_add(elementCurrency, "total");
  			formatMoney(buf, "", amount, totalDecimals, 20);
  			scew_element_set_contents(element, buf);
  			amount = 0;
  	
      }
      
    	elementCurrency = scew_element_add(elementDetails, "currency");
  		element = scew_element_add(elementCurrency, "currencyCode");
  		currency = [[CurrencyManager getInstance] getCurrencyById: item->currencyId];
  		scew_element_set_contents(element, [currency getCurrencyCode]);
      
      currencyId = item->currencyId;  
    }
    
    amount += item->amount;
  	
    manualDropDetailElement = scew_element_add(elementCurrency, "detail");

		// Total
		element = scew_element_add(manualDropDetailElement, "totalAmount");
		formatMoney(buf, "", item->amount, totalDecimals, 20);
		scew_element_set_contents(element, buf);

		// Nombre del tipo de valor
		element = scew_element_add(manualDropDetailElement, "depositValueName");
		scew_element_set_contents(element, depositValueTypeStr[item->depositValueType]);

		// Nombre del cash
		element = scew_element_add(manualDropDetailElement, "cimCashName");
		cimCash = [cimManager getCimCashById: item->cimCashId];
		scew_element_set_contents(element, [cimCash getName]);	
  
    // Numero de deposito (solo los 5 ultimos numeros)
		element = scew_element_add(manualDropDetailElement, "depositNumber");
		sprintf(buf, "%c%05ld", item->depositType == DepositType_MANUAL ? 'M' : 'V', item->number % 100000); 
		scew_element_set_contents(element, buf);
		
    // Visualiza Nro de sobre? solo si no esta vac�o.
		 if (strlen(item->envelopeNumber) > 0){
		//Numero de deposito (solo los 5 ultimos numeros)
	  	element = scew_element_add(manualDropDetailElement, "viewEnv");
	  	if (item->depositType == DepositType_MANUAL)
	    	 scew_element_set_contents(element, "TRUE");
	  	else 
      	 scew_element_set_contents(element, "FALSE");
		
	    // Numero de sobre
			element = scew_element_add(manualDropDetailElement, "env");
			scew_element_set_contents(element, item->envelopeNumber);
  	}
	}	
  
  if (currencyId != 0) {
    // Importe
		element = scew_element_add(elementCurrency, "total");
		formatMoney(buf, "", amount, totalDecimals, 20);
		scew_element_set_contents(element, buf);
  }

  [details freePointers];
  [details free];
     
	return zcloseDetails;
}


/**/
- (void) buildZCloseXML: (id) anEntity 
  entityType: (int) anEntityType 
  isReprint: (BOOL) isReprint 
  tree: (scew_tree*) tree 
  param: (void *) aParam
{
  scew_element* root = NULL;
	COLLECTION details;

  if (anEntityType == CIM_OPERATOR_PRT)
    root = scew_tree_add_root(tree, "operator");
  else
    root = scew_tree_add_root(tree, "zclose");

  //Informacion generalInfo
  [self concatZCloseGeneralInfo: root entity: anEntity entityType: anEntityType isReprint: isReprint param: (ZCloseReportParam*)aParam];

  //Datos de total
  details = [self concatZCloseDetailInfo: root entity: anEntity entityType: anEntityType isReprint: isReprint param: (ZCloseReportParam*)aParam];
  
  //Datos de cash detail
  if (anEntityType != CIM_OPERATOR_PRT) {
    [self concatZExtractionDetailInfo: root entity: anEntity entityType: anEntityType isReprint: isReprint param: (ZCloseReportParam*)aParam details: details];
	}

	if (anEntityType != CIM_OPERATOR_PRT) {
		// En el caso de que se haya llamada al metodo getZCloseDetailsSummary() se
		// debe realizar un freeContents() ya que se crearon nuevos detalles de depositos
		[details freeContents];
	}

	if (details) [details free];

}


/*************************************************
*
* Archivo XML de CashClose o X
*
*************************************************/

/**/
- (void) concatCashCloseGeneralInfo: (scew_element*) anElement 
	entity: (id) anEntity 
	isReprint: (BOOL) isReprint 
	param: (ZCloseReportParam *) aZCloseParam
{
  scew_element* generalInfo = NULL;
  scew_element* element = NULL;
  datetime_t date;
  char dateStr[50];
  struct tm brokenTime;
  char buf[50];
  char mSymbol[4];
	USER user;
	CIM_CASH cash;
	unsigned long auditNumber = 0;
  datetime_t auditDateTime = 0;

  strcpy(mSymbol, [[RegionalSettings getInstance] getMoneySymbol]);

	generalInfo = scew_element_add(anElement, "generalInfo");
	[self concatGeneralInfo: generalInfo isReprint: isReprint];

	// Para el cierre del Cash Close el usuario es el del cierre
	user = [anEntity getUser];
	
	// traigo el cash correspondiente
	cash = [anEntity getCimCash];

  // Cash name
  element = scew_element_add(generalInfo, "cashName");
	strcpy(buf, cash != NULL ? [cash getName] : getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
	buf[17] = '\0';
  scew_element_set_contents(element, buf);

  // UsuarioconcatZCloseGeneralInfo
  element = scew_element_add(generalInfo, "userName");
	strcpy(buf, user != NULL ? [user str] : getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
	buf[17] = '\0';
  scew_element_set_contents(element, buf);

  // id Usuario
  element = scew_element_add(generalInfo, "userId");
  sprintf(buf, "%05d", user != NULL ? [user getUserId] : 0);
  scew_element_set_contents(element, buf);

  // Cuenta bancaria del usuario
  element = scew_element_add(generalInfo, "account");
  scew_element_set_contents(element, user != NULL ? [user getBankAccountNumber] : "");

  // Fecha / hora del cierre
  date = [anEntity getCloseTime];
	convertTime(&date, &brokenTime);
	formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "closeTime");
  scew_element_set_contents(element, dateStr);

  // Fecha / hora de la apertura
  date = [anEntity getOpenTime];
	convertTime(&date, &brokenTime);
  formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "openTime");
  scew_element_set_contents(element, dateStr);

  // Cantidad de billetes rechazados
  element = scew_element_add(generalInfo, "rejectedQty");
  sprintf(buf, "%d", [anEntity getRejectedQty]);
  scew_element_set_contents(element, buf);

  // Numero de extraccion Z
  element = scew_element_add(generalInfo, "number");
  sprintf(buf, "%08ld", [anEntity getNumber]);
  scew_element_set_contents(element, buf);
  
  if (aZCloseParam != NULL){
    auditNumber = aZCloseParam->auditNumber;
    auditDateTime = aZCloseParam->auditDateTime;
  }
  
  // Numero de transaccion (auditoria)
  element = scew_element_add(generalInfo, "trans");
  sprintf(buf, "%08ld", auditNumber);
  scew_element_set_contents(element, buf);

  // Fecha de transaccion (auditoria)
	convertTime(&auditDateTime, &brokenTime);
  formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "transTime");
  scew_element_set_contents(element, dateStr);

  // Desde deposito
  element = scew_element_add(generalInfo, "fromDepositNumber");
  sprintf(buf, "%08ld", [anEntity getFromDepositNumber]);
  scew_element_set_contents(element, buf);

  // Hasta deposito
  element = scew_element_add(generalInfo, "toDepositNumber");
  sprintf(buf, "%08ld", [anEntity getToDepositNumber]);
  scew_element_set_contents(element, buf);

}

/**/
- (void) concatCashCloseDetailInfo: (scew_element*) anElement 
	entity: (id) anEntity  
	isReprint: (BOOL) isReprint 
	param: (ZCloseReportParam *) aZCloseParam
{
	scew_element *element;
	scew_element *elementCimCashs;
	scew_element *elementCimCash;
	scew_element *elementAcceptor;
	scew_element *elementAcceptorList;
	scew_element *elementCurrency;
	scew_element *elementCurrencyList;
	int iAcceptor, iCurrency;
	char buf[50];
	int totalDecimals = [[AmountSettings getInstance] getTotalRoundDecimalQty];
	COLLECTION detailsByCimCash, detailsByAcceptor, detailsByCurrency;
	COLLECTION currecies, acceptorSettingsList;
	ACCEPTOR_SETTINGS acceptorSettings;
	CIM_CASH cimCash;
	CURRENCY currency;
	int count;
	COLLECTION details = NULL;

/*
	<cimcashs>
	 	<cimcash>
			<name>VERIFIED CASH BOX</name>	
				<acceptor>	
					<acceptorName>VALIDADOR xxx</acceptorName>
					<currency>
						<currencyCode>ARS</currencyCode>
						<qty>10</qty>
						<total>50.00</total>
					</currency>
					<currency>
						<currencyCode>USD</currencyCode>
						<qty>10</qty>
						<total>50.00</total>
					</currency>			
				</acceptor>

				<currency>
						<currencyCode>ARS</currencyCode>
						<total>50.00</total>
				</currency>
				
		</cimcash>
	</cimcashs>
*/
	elementCimCashs = scew_element_add(anElement, "cimCashs");

	// Obtengo la cashs del CASH CLOSE
	cimCash = [anEntity getCimCash];
	
	details = [anEntity getZCloseDetails];
	
	// Nombre de la caja
	elementCimCash = scew_element_add(elementCimCashs, "cimCash");
  
  element = scew_element_add(elementCimCash, "name");
  scew_element_set_contents(element, [cimCash getName]);

	// Obtengo los depositos para el cash actual
	detailsByCimCash = [anEntity getDetailsByCimCash: details cimCash: cimCash];

	// Obtengo la lista  de validadores
	acceptorSettingsList = [anEntity getAcceptorSettingsList: detailsByCimCash];
	
	elementAcceptorList = scew_element_add(elementCimCash, "acceptorList");

  count = 0;

	// Recorro la lista de validadores
	for (iAcceptor = 0; iAcceptor < [acceptorSettingsList size]; ++iAcceptor) {

		acceptorSettings = [acceptorSettingsList at: iAcceptor];
		elementAcceptor = scew_element_add(elementAcceptorList, "acceptor");

		// Nombre del aceptador
		element = scew_element_add(elementAcceptor, "acceptorName");
		scew_element_set_contents(element, [acceptorSettings getAcceptorName]);

		// Obtengo la lista de detalles para el validador en curso
		detailsByAcceptor = [anEntity getDetailsByAcceptorSettings: detailsByCimCash acceptorSettings: acceptorSettings];

		// Obtengo la lista de monedas
		currecies = [anEntity getCurrencies: detailsByAcceptor];

		elementCurrencyList = scew_element_add(elementAcceptor, "currencyList");

		// Recorro la lista de monedas
		for (iCurrency = 0; iCurrency < [currecies size]; ++iCurrency) {
      count++;
            
			currency = [currecies at: iCurrency];
			detailsByCurrency = [anEntity getDetailsByCurrency: detailsByAcceptor currency: currency];

			elementCurrency = scew_element_add(elementCurrencyList, "currency");

    	element = scew_element_add(elementCurrency, "currencyCode");
      scew_element_set_contents(element, [currency getCurrencyCode]);

			element = scew_element_add(elementCurrency, "qty");
			sprintf(buf, "%04d", [anEntity getQty: detailsByCurrency]);
			scew_element_set_contents(element, buf);
	
			element = scew_element_add(elementCurrency, "total");
			if (isReprint)
				formatMoney(buf, "", [anEntity getCashCloseTotalAmount: detailsByCurrency], totalDecimals, 20);
			else
				formatMoney(buf, "", [anEntity getTotalAmount: detailsByCurrency], totalDecimals, 20);
			scew_element_set_contents(element, buf);            
	
			[detailsByCurrency free];
			
		}
		
		[currecies free];
		[detailsByAcceptor free];
		
	}

	[acceptorSettingsList free];

  // Obtengo la lista de monedas para mostrar los totales por cash
	currecies = [anEntity getCurrencies: detailsByCimCash];
  for (iCurrency = 0; iCurrency < [currecies size]; ++iCurrency) {
      
      currency = [currecies at: iCurrency];
      
  		elementCurrency = scew_element_add(elementCimCash, "totalCurrency");

			element = scew_element_add(elementCurrency, "totalCurrencyCode");
			scew_element_set_contents(element, [currency getCurrencyCode]);
  		
			element = scew_element_add(elementCurrency, "totalCurr");
			if (isReprint)
				formatMoney(buf, "", [anEntity getCashCloseTotalAmountByCurreny: detailsByCimCash currency: currency], totalDecimals, 20);
			else
				formatMoney(buf, "", [anEntity getTotalAmountByCurreny: detailsByCimCash currency: currency], totalDecimals, 20);
			scew_element_set_contents(element, buf);        
  }

	// No hay depositos para mostrar
	element = scew_element_add(elementCimCashs, "withOutValues");
	if (count == 0)
    scew_element_set_contents(element, "TRUE");
  else
    scew_element_set_contents(element, "FALSE");

  [currecies free];
	[detailsByCimCash free];

}


/**/
- (void) buildCashCloseXML: (id) anEntity 
  isReprint: (BOOL) isReprint 
  tree: (scew_tree*) tree 
  param: (void *) aParam
{

  scew_element* root = NULL;  
  root = scew_tree_add_root(tree, "cashCloseReport");

  //Informacion generalInfo
  [self concatCashCloseGeneralInfo: root entity: anEntity isReprint: isReprint param: (ZCloseReportParam*)aParam];
  //Datos del detalle
  [self concatCashCloseDetailInfo: root entity: anEntity isReprint: isReprint param: (ZCloseReportParam*)aParam];
}

/**/
- (void) addCommercialStateCode: (char*) aTextCode commState: (scew_element*) aCommState
{
	scew_element *element;
  STRING_TOKENIZER tokenizer;
  char token[10];
  int blockCount;
	int blockPos;
	char block[16];
  char blockaux[16];

	tokenizer = [[StringTokenizer new] initTokenizer: aTextCode delimiter: " "];

	blockCount = 0;
  blockPos = 0;
	block[0] = '\0';
  blockaux[0] = '\0';
	while ([tokenizer hasMoreTokens]) {

		[tokenizer getNextToken: token];

		blockCount++;

		if (blockCount == 4){
			blockCount = 0;
			blockPos++;

			if (strlen(token) != 0){
				blockaux[0] = '\0';
			  sprintf(blockaux, "  %s",token);
			  strcat(block, blockaux);
			}

			switch (blockPos) {
				case 1:  
	  			element = scew_element_add(aCommState, "code1");
  				scew_element_set_contents(element, block);
				  break;
				case 2:
	  			element = scew_element_add(aCommState, "code2");
  				scew_element_set_contents(element, block);
				  break;
				case 3:
	  			element = scew_element_add(aCommState, "code3");
  				scew_element_set_contents(element, block);
				  break;
				case 4:
	  			element = scew_element_add(aCommState, "code4");
  				scew_element_set_contents(element, block);
				  break;
				case 5:
	  			element = scew_element_add(aCommState, "code5");
  				scew_element_set_contents(element, block);
				  break;
				case 6:
	  			element = scew_element_add(aCommState, "code6");
  				scew_element_set_contents(element, block);
				  break;
				case 7:
	  			element = scew_element_add(aCommState, "code7");
  				scew_element_set_contents(element, block);
				  break;
				case 8:
	  			element = scew_element_add(aCommState, "code8");
  				scew_element_set_contents(element, block);
				  break;
				case 9:
	  			element = scew_element_add(aCommState, "code9");
  				scew_element_set_contents(element, block);
				  break;
				case 10:
	  			element = scew_element_add(aCommState, "code10");
  				scew_element_set_contents(element, block);
				  break;
				case 11:
	  			element = scew_element_add(aCommState, "code11");
  				scew_element_set_contents(element, block);
				  break;
				case 12:
	  			element = scew_element_add(aCommState, "code12");
  				scew_element_set_contents(element, block);
				  break;
				case 13:
	  			element = scew_element_add(aCommState, "code13");
  				scew_element_set_contents(element, block);
				  break;
		  }

			block[0] = '\0';

		}else{
			blockaux[0] = '\0';
			if (strlen(token) != 0){
			  sprintf(blockaux, "  %s",token);
			  strcat(block, blockaux);
			}
	  }

	}
	
	// esto es porque la ultima linea puede que no ocupe todo el largo del bloque
	if (strlen(block) > 0){
			if (blockPos == 11) {
	  			element = scew_element_add(aCommState, "code12");
  				scew_element_set_contents(element, block);
	  			element = scew_element_add(aCommState, "code13");
  				scew_element_set_contents(element, "");
		  }else{
	  			element = scew_element_add(aCommState, "code13");
  				scew_element_set_contents(element, block);
			}
	}

	[tokenizer free];
}

/**/
- (void) concatCommercialStateChangeInfo: (scew_element*) anElement 
	entity: (id) anEntity  
	isReprint: (BOOL) isReprint
{
	scew_element* generalInfo = NULL;
	scew_element *element;
	scew_element *commStateChange;
  char mac[100];
  datetime_t date;
	char dateStr[50];
  struct tm brokenTime;
	char originalText[200];
	char finalText[200];
	char *s;
	char part[200];
	char line[200];

	generalInfo = scew_element_add(anElement, "generalInfo");
	[self concatGeneralInfo: generalInfo isReprint: isReprint];

	commStateChange = scew_element_add(anElement, "commStateChange");


	originalText[0] = '\0';
	finalText[0] = '\0';
	part[0] = '\0';
	line[0] = '\0';

	// Resultado
  element = scew_element_add(commStateChange, "result");

	// resultado del cambio de estado
	//if ([anEntity getConfirmationResult] == 0)
	stringcpy(originalText, getResourceStringDef(RESID_CHANGE_STATE_RESULT_BASE + [anEntity getRequestResult], "DESCRIPCION NO DISPONIBLE"));
	//else 
	//	stringcpy(originalText, getResourceStringDef(RESID_CHANGE_STATE_RESULT_BASE + [anEntity getConfirmationResult], "DESCRIPCION NO DISPONIBLE"));

  s = originalText;
  do {
  	s = wordwrap(s, 25, 11, part);
    sprintf(line, "%s\n", part);
    strcat(finalText, line);
  } while ( *s!='\0' ); 


	scew_element_set_contents(element, finalText);

	// MAC Address
  element = scew_element_add(commStateChange, "macAddress");
	[[CimGeneralSettings getInstance] getMacAddress: mac];
  scew_element_set_contents(element, mac);

	// Fecha de solicitud
  element = scew_element_add(commStateChange, "requestDate");
  date = [anEntity getRequestDateTime];
	convertTime(&date, &brokenTime);
  formatBrokenDateTime(dateStr, &brokenTime);
  scew_element_set_contents(element, dateStr);

	// Estado anterior
  element = scew_element_add(commStateChange, "oldState");
  scew_element_set_contents(element, [anEntity getCommStateSTR: [anEntity getOldState]]);

	// Estado actual
  element = scew_element_add(commStateChange, "currentState");
  scew_element_set_contents(element, [anEntity getCommStateSTR: [anEntity getCommState]]);

}

/**/
- (void) buildCommercialStateChangeReportXML: (id) anEntity 
  isReprint: (BOOL) isReprint 
  tree: (scew_tree*) tree
{
  scew_element* root = NULL;  
  root = scew_tree_add_root(tree, "commercialStateChangeReport");

  //Datos del reporte
  [self concatCommercialStateChangeInfo: root entity: anEntity isReprint: isReprint];
}


/**/
- (void) concatModulesLicenceInfo: (scew_element*) anElement 
	entity: (id) anEntity  
	isReprint: (BOOL) isReprint
{
	scew_element* generalInfo = NULL;
	scew_element *element;
	scew_element *modulesList;
	scew_element *module;
	id mod;
	int i;
  datetime_t date;
	char dateStr[50];
  struct tm brokenTime;
	char buffer[50];
	id pimsTelesup;

	generalInfo = scew_element_add(anElement, "generalInfo");
	[self concatGeneralInfo: generalInfo isReprint: isReprint];

  modulesList = scew_element_add(anElement, "modulesList");

	// lista de modulos        
  for (i=0; i<[anEntity size]; ++i) {
    
    mod = [anEntity at: i];   

		module = scew_element_add(modulesList, "module");
				
		// Nombre del modulo
		element = scew_element_add(module, "name");
		scew_element_set_contents(element, [mod getModuleName]);

		// Fecha base
		element = scew_element_add(module, "baseDate");
		date = [mod getBaseDateTime];
		convertTime(&date, &brokenTime);
		formatBrokenDateTime(dateStr, &brokenTime);
		scew_element_set_contents(element, dateStr);

		// Fecha de expiracion
		element = scew_element_add(module, "expireDate");
		date = [mod getExpireDateTime];
		convertTime(&date, &brokenTime);
		formatBrokenDateTime(dateStr, &brokenTime);
		scew_element_set_contents(element, dateStr);

		// Cantidad de horas
		element = scew_element_add(module, "hoursQty");
		sprintf(buffer, "%d", [mod getHoursQty]);
		scew_element_set_contents(element, buffer);

		// Tiempo transcurrido
		element = scew_element_add(module, "elapsedTime");
		sprintf(buffer, "%d", abs([mod getElapsedTime] / 60));
		scew_element_set_contents(element, buffer);

		// Online
		element = scew_element_add(module, "online");

		if ([mod getOnline])
			scew_element_set_contents(element, getResourceStringDef(RESID_YES, "Si"));
		else
			scew_element_set_contents(element, getResourceStringDef(RESID_NO, "No"));

		// Enviar online
		element = scew_element_add(module, "sendOnline");

		pimsTelesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];
		if (pimsTelesup == NULL) scew_element_set_contents(element, getResourceStringDef(RESID_NO, "No"));
		else {
			if ([pimsTelesup sendOnline: [mod getModuleCode]]) 	
				scew_element_set_contents(element, getResourceStringDef(RESID_YES, "Si"));
			else
				scew_element_set_contents(element, getResourceStringDef(RESID_NO, "No"));
		}

		// Enable
		element = scew_element_add(module, "enable");
printf("16\n");
		if ([mod isEnable])
			scew_element_set_contents(element, getResourceStringDef(RESID_YES, "Si"));
		else
			scew_element_set_contents(element, getResourceStringDef(RESID_NO, "No"));

		// Expired
		element = scew_element_add(module, "expired");

		if ([mod hasExpired])
			scew_element_set_contents(element, getResourceStringDef(RESID_YES, "Si"));
		else
			scew_element_set_contents(element, getResourceStringDef(RESID_NO, "No"));

		// Never expires
		element = scew_element_add(module, "expires");
printf("17\n");
		if ( ([mod isEnable]) && ([mod getHoursQty] == 0) ) 
			scew_element_set_contents(element, getResourceStringDef(RESID_NO, "No"));
		else
			scew_element_set_contents(element, getResourceStringDef(RESID_YES, "Yes"));
		
	} 		

}

/**/
- (void) buildModulesLicenceXML: (id) anEntity
  isReprint: (BOOL) isReprint 
  tree: (scew_tree*) tree
{
  scew_element* root = NULL;  
  root = scew_tree_add_root(tree, "modulesLicence");

  //Datos del reporte
  [self concatModulesLicenceInfo: root entity: anEntity isReprint: isReprint];
}

- (void) concatClosingCodeInfo: (scew_element*) anElement entity: (id) anEntity isReprint: (BOOL) isReprint 
{
  scew_element* generalInfo = NULL;
  scew_element* element = NULL;
  char buf[50];


	generalInfo = scew_element_add(anElement, "generalInfo");
	[self concatGeneralInfo: generalInfo isReprint: isReprint];

  // Usuario
	element = scew_element_add(generalInfo, "operatorName");
	strcpy(buf, [anEntity str] );
	scew_element_set_contents(element, buf);
  // Numero de extraccion Z anterior
  element = scew_element_add(generalInfo, "ClosingCode");
  strcpy(buf, [anEntity getClosingCode]);
  scew_element_set_contents(element, buf);

}


- (void) buildClosingCodeXML: (id) anEntity isReprint: (BOOL) isReprint tree: (scew_tree*) tree
{
  scew_element* root = NULL;  
  root = scew_tree_add_root(tree, "closingCode");

  //Datos del reporte
  [self concatClosingCodeInfo: root entity: anEntity isReprint: isReprint];
}
/**/
- (void) concatBagTrackingInfo: (scew_element*) anElement entity: (id) anEntity 
{
	scew_element* bagTrackingInfo;
	scew_element* element;
	scew_element* bagTracking;
	scew_element* bagTrackElement;

	char buf[50];		
	int qty = 0;
	int read = 0;
	int i;
	id bagTrack;
	COLLECTION doorAcceptors;

	COLLECTION bagTrackingCollection; 

	doorAcceptors = [[anEntity getDoor] getAcceptorSettingsList];
	//doorAcceptorSettings = [doorAcceptors at: 0];

	bagTrackingInfo = scew_element_add(anElement, "bagTrackingInfo");

	// Envelope qty
	element = scew_element_add(bagTrackingInfo, "qty");


	if ([anEntity getBagTrackingMode] == BagTrackingMode_MANUAL) {
 		bagTrackingCollection = [anEntity getEnvelopeTrackingCollection];
		qty = [[DepositDetailReport getInstance] getTicketsCountByDepositType: [anEntity getFromDepositNumber]
			toDepositNumber: [anEntity getToDepositNumber] depositType: DepositType_MANUAL];
	}

	if ([anEntity getBagTrackingMode] == BagTrackingMode_AUTO) {
 		bagTrackingCollection = [anEntity getBagTrackingCollection];
		qty = [doorAcceptors size];
	}

/*
	if ([doorAcceptorSettings getAcceptorType] == AcceptorType_MAILBOX) {
		qty = [[DepositDetailReport getInstance] getTicketsCountByDepositType: [anEntity getFromDepositNumber]
			toDepositNumber: [anEntity getToDepositNumber] depositType: DepositType_MANUAL];
	}
	
	if ([doorAcceptorSettings getAcceptorType] == DepositType_AUTO) {
		qty = [doorAcceptors size];
	}
*/

  sprintf(buf, "%d", qty);
  scew_element_set_contents(element, buf);

	// Envelope read
	element = scew_element_add(bagTrackingInfo, "read");
	
	read = [bagTrackingCollection size];

  sprintf(buf, "%d", read);
  scew_element_set_contents(element, buf);

	// tracking Mode
	element = scew_element_add(bagTrackingInfo, "trackingMode");
  sprintf(buf, "%d", [anEntity getBagTrackingMode]);
  scew_element_set_contents(element, buf);

	// lista de tracks
	bagTracking = scew_element_add(bagTrackingInfo, "bagTracking");

	// Recorro la lista de bag Track
	for (i=0; i<[bagTrackingCollection size]; ++i) {

		bagTrack = [bagTrackingCollection at: i];
		bagTrackElement = scew_element_add(bagTracking, "bagTrack");

		element = scew_element_add(bagTrackElement, "number");
		scew_element_set_contents(element, [bagTrack getBNumber]);
	}
		
}


/**/
- (void) buildBagTrackingXML: (id) anEntity isReprint: (BOOL) isReprint tree: (scew_tree*) tree param: (void *) aParam
{
  scew_element* root = NULL;

  root = scew_tree_add_root(tree, "bagTracking");

  //Informacion generalInfo
  [self concatExtractionGeneralInfo: root entity: anEntity isReprint: isReprint param: aParam];

  //Datos de total
  [self concatBagTrackingInfo: root entity: anEntity];

}

/*************************************************
*
* Archivo XML de deposito
*
*************************************************/

/**/
- (void) concatDepositGeneralInfo: (scew_element*) anElement entity: (id) anEntity isReprint: (BOOL) isReprint 
		isManualDropReceipt: (BOOL) aIsManualDropReceipt param: (DepositReportParam *) aParam
{
  scew_element* generalInfo = NULL;
  scew_element* element = NULL;
  datetime_t date;
  char dateStr[50];
  struct tm brokenTime;
  char buf[50];
  char mSymbol[4];
	int totalDecimals = [[AmountSettings getInstance] getTotalRoundDecimalQty];
	COLLECTION referenceList;
	CASH_REFERENCE reference;
	int i;
	unsigned long auditNumber = 0;
  BOOL viewTrans;	

  strcpy(mSymbol, [[RegionalSettings getInstance] getMoneySymbol]);
	
	generalInfo = scew_element_add(anElement, "generalInfo");
	[self concatGeneralInfo: generalInfo isReprint: isReprint];

  // Usuario
  element = scew_element_add(generalInfo, "userName");
	strcpy(buf, [anEntity getUser] != NULL ? [[anEntity getUser] str] : getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
	buf[17] = '\0';
  scew_element_set_contents(element, buf);

  // Id de usuario
  element = scew_element_add(generalInfo, "userId");
  sprintf(buf, "%05d", [[anEntity getUser] getUserId]);
  scew_element_set_contents(element, buf);

  // Fecha / hora del cierre
  date = [anEntity getCloseTime];
	convertTime(&date, &brokenTime);
  formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "closeTime");
  scew_element_set_contents(element, dateStr);

  // Fecha / hora de la apertura
  date = [anEntity getOpenTime];
	convertTime(&date, &brokenTime);
  formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "openTime");
  scew_element_set_contents(element, dateStr);

  // Transaccion
  viewTrans = FALSE;
  if (aParam != NULL){
    auditNumber = aParam->auditNumber;
    viewTrans = TRUE;

    // Numero de transaccion (auditoria)
    element = scew_element_add(generalInfo, "trans");
    sprintf(buf, "%08ld", auditNumber);
    scew_element_set_contents(element, buf);
  }
  
  // debo o no mostrar el numero de transaccion
	element = scew_element_add(generalInfo, "viewTrans");
	scew_element_set_contents(element, viewTrans ? "TRUE" : "FALSE");

  // Total
  element = scew_element_add(generalInfo, "total");
  formatMoney(buf, mSymbol, [anEntity getAmount], totalDecimals, 20);
  scew_element_set_contents(element, buf);

  // Cantidad de billetes rechazados
  element = scew_element_add(generalInfo, "rejectedQty");
  sprintf(buf, "%d", [anEntity getRejectedQty]);
  scew_element_set_contents(element, buf);

	// Tipo de deposito
  element = scew_element_add(generalInfo, "depositType");
  sprintf(buf, "%d", [anEntity getDepositType]);
  scew_element_set_contents(element, buf);

  // Numero de deposito
  element = scew_element_add(generalInfo, "number");
  sprintf(buf, "%08ld", [anEntity getNumber]);
  scew_element_set_contents(element, buf);

  // Visualiza Nro de sobre ?
  element = scew_element_add(generalInfo, "viewEnvelopeNumber");
  if (strlen([anEntity getEnvelopeNumber]) == 0)
    scew_element_set_contents(element, "FALSE");
  else
    scew_element_set_contents(element, "TRUE");

  // Numero de sobre
  element = scew_element_add(generalInfo, "envelopeNumber");
  scew_element_set_contents(element, [anEntity getEnvelopeNumber]);

  // Visualiza Aplicado a ?
  element = scew_element_add(generalInfo, "viewApplyTo");
  if (strlen([anEntity getApplyTo]) == 0)
    scew_element_set_contents(element, "FALSE");
  else
    scew_element_set_contents(element, "TRUE");

  // Aplicado a
  element = scew_element_add(generalInfo, "applyTo");
  scew_element_set_contents(element, [anEntity getApplyTo]);

  // Nombre de puerta
  element = scew_element_add(generalInfo, "doorName");
  scew_element_set_contents(element, [[anEntity getDoor] getDoorName]);

  // Nombre del cash
  element = scew_element_add(generalInfo, "cimCashName");
  scew_element_set_contents(element, [[anEntity getCimCash] getName]);

	// Cuenta bancaria
	element = scew_element_add(generalInfo, "bankAccountNumber");
	scew_element_set_contents(element, [anEntity getBankAccountNumber]);

	// Es el recibo manual ?
	element = scew_element_add(generalInfo, "isManualDropReceipt");
	if (aIsManualDropReceipt)	scew_element_set_contents(element, "TRUE");
	else scew_element_set_contents(element, "FALSE");

	// References (los ordeno de padre a hijo)
	referenceList = [Collection new];
	reference = [anEntity getCashReference];
	while (reference != NULL) {
		[referenceList at: 0 insert: reference];
		reference = [reference getParent];
	}

	element = scew_element_add(generalInfo, "hasReference");
	scew_element_set_contents(element, [referenceList size] == 0 ? "FALSE" : "TRUE");

	for (i = 0; i < [referenceList size]; ++i) {
		element = scew_element_add(generalInfo, "cashReference");
		element = scew_element_add(element, "referenceName");

		memset(buf, '-', i);
		buf[i] = '\0';
		strcat(buf, [[referenceList at: i] getName]);
		buf[26] = '\0';

		scew_element_set_contents(element, buf);
	}

	[referenceList free];

}

/**/
- (void) concatDepositDetailInfo: (scew_element*) anElement entity: (id) anEntity isReprint: (BOOL) isReprint
{
	scew_element *element;
	scew_element *elementDepositDetails;
	scew_element *elementDepositDetail;
	scew_element *elementAcceptors;
	scew_element *elementAcceptor;
	scew_element *elementCurrencyList;
	scew_element *elementCurrency;
	scew_element *elementTotalCurr;
	scew_element *elementTotalByCurrency;
	ACCEPTOR_SETTINGS acceptorSettings;
	COLLECTION acceptors;
	COLLECTION currencies;
	COLLECTION detailsByAcceptor;
	COLLECTION detailsByCurrency;
	CURRENCY currency;
	DEPOSIT_DETAIL depositDetail;
	int iAcceptor, iCurrency, iDetail;
	char buf[50];
	int totalDecimals = [[AmountSettings getInstance] getTotalRoundDecimalQty];

	/*
		
	<acceptorList>

		<acceptor>	
			
			<currencyList>
				<currency>
						<currencyCode>ARS</currencyCode>
						<qty>10</qty>
						<total>50.00</total>
							<depositDetails>
								<depositDetail>...</depositDetail>
								<depositDetail>...</depositDetail>
								<depositDetail>...</depositDetail>
							</depositDetails>
					</currency>
			</currencyList>

			<currencyList>
				<currency>
						<currencyCode>ARS</currencyCode>
						<qty>10</qty>
						<total>50.00</total>
							<depositDetails>
								<depositDetail>...</depositDetail>
								<depositDetail>...</depositDetail>
								<depositDetail>...</depositDetail>
							</depositDetails>
					</currency>
			</currencyList>

		</acceptor>

	</acceptorList>


	*/
	acceptors = [anEntity getAcceptorSettingsList: NULL];
	elementAcceptors = scew_element_add(anElement, "acceptorList");

	// Recorro la lista de aceptadores
	for (iAcceptor = 0; iAcceptor < [acceptors size]; ++iAcceptor) {

		acceptorSettings = [acceptors at: iAcceptor];
		elementAcceptor = scew_element_add(elementAcceptors, "acceptor");

		// Nombre del aceptador
		element = scew_element_add(elementAcceptor, "acceptorName");
		scew_element_set_contents(element, [acceptorSettings getAcceptorName]);

		// Obtengo la lista de detalles para el aceptador
		detailsByAcceptor = [anEntity getDetailsByAcceptor: NULL acceptorSettings: acceptorSettings];

		// Obtengo la lista de monedas utilizadas en este aceptador
		currencies = [anEntity getCurrencies: detailsByAcceptor];
		
		elementCurrencyList = scew_element_add(elementAcceptor, "currencyList");

		// Recorro las monedas
		for (iCurrency = 0; iCurrency < [currencies size]; ++iCurrency) {

			currency = [currencies at: iCurrency];

			// Creo el elemento moneda con los datos de la moneda y la info totalizada

			elementCurrency = scew_element_add(elementCurrencyList, "currency");
			detailsByCurrency = [anEntity getDetailsByCurrency: detailsByAcceptor currency: currency];

			element = scew_element_add(elementCurrency, "currencyCode");
			scew_element_set_contents(element, [currency getCurrencyCode]);

			element = scew_element_add(elementCurrency, "qty");
			sprintf(buf, "%04d", [anEntity getQty: detailsByCurrency]);
			scew_element_set_contents(element, buf);
	
			element = scew_element_add(elementCurrency, "total");
			formatMoney(buf, "", [anEntity getAmount: detailsByCurrency], totalDecimals, 20);
			scew_element_set_contents(element, buf);
	
			elementDepositDetails = scew_element_add(elementCurrency, "depositDetails");

			// Recorro el detalle de los depositos		
			for (iDetail = 0; iDetail < [detailsByCurrency size]; ++iDetail) {
		
				depositDetail = [detailsByCurrency at: iDetail];
				elementDepositDetail = scew_element_add(elementDepositDetails, "depositDetail");
		
				// Cantidad
				element = scew_element_add(elementDepositDetail, "qty");
				sprintf(buf, "%04d" , [depositDetail getQty]);
				scew_element_set_contents(element, buf);
		
				// Importe
				element = scew_element_add(elementDepositDetail, "amount");
				if ([depositDetail isUnknownBill]) stringcpy(buf, getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
				else formatMoney(buf, "", [depositDetail getAmount], totalDecimals, 20);
				scew_element_set_contents(element, buf);
		
				// Total
				element = scew_element_add(elementDepositDetail, "totalAmount");
				if ([depositDetail isUnknownBill]) stringcpy(buf, getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
				else formatMoney(buf, "", [depositDetail getTotalAmount], totalDecimals, 20);
				scew_element_set_contents(element, buf);

				// Nombre del tipo de valor
				element = scew_element_add(elementDepositDetail, "depositValueName");
				scew_element_set_contents(element, [depositDetail getDepositValueName]);

			}
			
			[detailsByCurrency free];

		}

		[detailsByAcceptor free];
		[currencies free];

	}

	[acceptors free];


  // Obtengo la lista de monedas para mostrar los totales
	currencies = [anEntity getCurrencies: NULL];
  elementTotalCurr = scew_element_add(anElement, "totalCurr");
  for (iCurrency = 0; iCurrency < [currencies size]; ++iCurrency) {
      
      currency = [currencies at: iCurrency];
      
      elementTotalByCurrency = scew_element_add(elementTotalCurr, "totalByCurrency");
			detailsByCurrency = [anEntity getDetailsByCurrency: NULL currency: currency];

			element = scew_element_add(elementTotalByCurrency, "totalCurrencyCode");
			scew_element_set_contents(element, [currency getCurrencyCode]);
  		
			element = scew_element_add(elementTotalByCurrency, "totalCurrency");
			formatMoney(buf, "", llabs([anEntity getAmount: detailsByCurrency]), totalDecimals, 20);
			scew_element_set_contents(element, buf);

			[detailsByCurrency free];
  }
	[currencies free];

}


/**/
- (void) buildDepositXML: (id) anEntity isReprint: (BOOL) isReprint tree: (scew_tree*) tree 
	isManualDropReceipt: (BOOL) aIsManualDropReceipt param: (void *) aParam
{
  scew_element* root = NULL;

  root = scew_tree_add_root(tree, "deposit");

  //Informacion generalInfo
  [self concatDepositGeneralInfo: root entity: anEntity isReprint: isReprint isManualDropReceipt: aIsManualDropReceipt param: (DepositReportParam*)aParam];

  //Datos de total
  [self concatDepositDetailInfo: root entity: anEntity isReprint: isReprint];

}


/**/
- (void) concatEnrolledUserInfo: (scew_element*) anElement entity: (id) anEntity isReprint: (BOOL) isReprint param: (EnrollOperatorReportParam *) aParam
{
	scew_element* generalInfo = NULL;
  scew_element *element;
	scew_element *userList;	
	scew_element *userInfo;
	scew_element *operationInfo;
	scew_element *operationList;
	
	USER user;
	PROFILE profile;
	OPERATION operation;
	COLLECTION users;
	int iUser, iOperation;
	char buf[50];
	datetime_t date;
	struct tm brokenTime;
	char enrolledDateStr[50];
	char lastLoginDateStr[50];
	char dateStr[50];
	unsigned long auditNumber = 0;
  datetime_t auditDateTime = 0;
  BOOL detailReport = TRUE;
  int userStatus = 1;
  int userNameLen;
  int iUserName;
  BOOL withOutValues = TRUE;
  char bufUser[17];
  unsigned char myOperationsList[15];
  int count;

	generalInfo = scew_element_add(anElement, "generalInfo");
	[self concatGeneralInfo: generalInfo isReprint: isReprint];

  if (aParam != NULL){
    auditNumber = aParam->auditNumber;
    userStatus = aParam->userStatus; //All 1 - Actives 2 - Inactives 3
    auditDateTime = aParam->auditDateTime;
    detailReport = aParam->detailReport;
  }

  // indico si es Detallado o resumido  
  element = scew_element_add(generalInfo, "detailReport");  
  if (detailReport)
    scew_element_set_contents(element, "TRUE");
  else
    scew_element_set_contents(element, "FALSE");

  // Status
  element = scew_element_add(generalInfo, "statusDescription");
  if (userStatus == 1)
    scew_element_set_contents(element, getResourceStringDef(RESID_ALL_LABEL, "Todos"));
  else if (userStatus == 2)
          scew_element_set_contents(element, getResourceStringDef(RESID_ACTIVE_LABEL, "Activos"));
       else
          scew_element_set_contents(element, getResourceStringDef(RESID_INACTIVE_LABEL, "Inactivos"));
  
  // Numero de transaccion (auditoria)
  element = scew_element_add(generalInfo, "trans");
  sprintf(buf, "%08ld", auditNumber);
  scew_element_set_contents(element, buf);

  // Fecha de transaccion (auditoria)
	convertTime(&auditDateTime, &brokenTime);
  formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "transTime");
  scew_element_set_contents(element, dateStr);

	users = [anEntity getUsers];
	userList = scew_element_add(anElement, "userList");

	// Recorro la lista de usuarios
	for (iUser = 0; iUser < [users size]; ++iUser) {

		user = [users at: iUser];
		
		// muestro los usuarios que corresponda
		if (![user isSpecialUser]) {
      if ( (userStatus == 1) || ((userStatus == 2) && ([user isActive])) || ((userStatus == 3) && (![user isActive])) ){
  		
      		userInfo = scew_element_add(userList, "userInfo");
      		
      		withOutValues = FALSE;
      		
      		// user id
          element = scew_element_add(userInfo, "userId");
          sprintf(buf,"%d",[user getUserId]);    
          scew_element_set_contents(element, buf);
          
      		// Name and Surname
          element = scew_element_add(userInfo, "userName");
          bufUser[0] = '\0';
          strcpy(bufUser, [user str]);
          userNameLen = strlen(bufUser);
          if (userNameLen < 16){
            userNameLen = 16 - userNameLen;
            for (iUserName = 0; iUserName < userNameLen ; ++iUserName)
              strcat(bufUser," ");
          } 
          scew_element_set_contents(element, bufUser);
      
      		// Enrolled Date
          date = [user getEnrollDateTime];
      	  convertTime(&date, &brokenTime);
      	 	formatBrokenDateTime(enrolledDateStr, &brokenTime);
          element = scew_element_add(userInfo, "enrolledDate");
          scew_element_set_contents(element, enrolledDateStr);
      
      		// Personal ID number
          element = scew_element_add(userInfo, "personalId");
          scew_element_set_contents(element, [user getLoginName]);
      
      		// Status
          element = scew_element_add(userInfo, "status");
          if ([user isActive])
            scew_element_set_contents(element, getResourceStringDef(RESID_ACTIVE_STATUS, "ACTIVO"));
          else
            scew_element_set_contents(element, getResourceStringDef(RESID_INACTIVE_STATUS, "INACTIVO"));
      
      		// User Level (profile)    
          profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
          element = scew_element_add(userInfo, "profile");
          scew_element_set_contents(element, [profile str]);
          
      		// Enrolled Date
          date = [user getLastLoginDateTime];
      	  convertTime(&date, &brokenTime);
  				formatBrokenDateTime(lastLoginDateStr, &brokenTime);
          element = scew_element_add(userInfo, "lastLogin");
          scew_element_set_contents(element, lastLoginDateStr);        
          
          // Key
          element = scew_element_add(userInfo, "key");
          if ((strlen([user getKey]) == 0) || (strcmp([user getKey],"0") == 0))
             scew_element_set_contents(element, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));
          else
             scew_element_set_contents(element, [user getKey]);
  
          // Account
          element = scew_element_add(userInfo, "account");
          scew_element_set_contents(element, [user getBankAccountNumber]);
      
      		// Recorro las operaciones de usuario
      		memset(myOperationsList, 0, 14);
          memcpy(myOperationsList, [profile getOperationsList], 14);
      		
      		operationList = scew_element_add(userInfo, "opList");
      		count = 0;
          for (iOperation = 1; iOperation <= OPERATION_COUNT; ++iOperation) {
          			
                if (getbit(myOperationsList, iOperation) == 1){
                  count++;
                  operation = [[UserManager getInstance] getOperation: iOperation];
            
                  operationInfo = scew_element_add(operationList, "opInfo");
            
                  // Operation Name
                  element = scew_element_add(operationInfo, "operationName");
                  strcpy(buf,"    ");
                  strcat(buf,[operation str]);
                  scew_element_set_contents(element, buf);
                }
      		}
      		// si no habia operaciones muestro una raya
      		if (count == 0){
      		   operationInfo = scew_element_add(operationList, "opInfo");
      		   element = scew_element_add(operationInfo, "operationName");
             scew_element_set_contents(element, "---");        
          }    		
      }
    }
	}
	
	// verifico si no se mostro ningun usuario
	element = scew_element_add(generalInfo, "withOutValues");
	if (withOutValues)
    scew_element_set_contents(element, "TRUE");
  else
    scew_element_set_contents(element, "FALSE");

}

/**/
- (void) concatConfigTelesupReportInfo: (scew_element*) anElement entity: (id) anEntity isReprint: (BOOL) isReprint param: (EnrollOperatorReportParam *) aParam
{
	scew_element* generalInfo = NULL;
  scew_element *element;
	scew_element *elementTelesupList;
	scew_element *elementTelesupInfo;
	
	int iTelesup;
	char buf[50];
	datetime_t date;
	struct tm brokenTime;
	char dateStr[50];
	unsigned long auditNumber = 0;
  datetime_t auditDateTime = 0;
  TELESUP_SETTINGS telesup;
	BOOL hasData = FALSE;

	generalInfo = scew_element_add(anElement, "generalInfo");
	[self concatGeneralInfo: generalInfo isReprint: isReprint];

  if (aParam != NULL){
    auditNumber = aParam->auditNumber;
    auditDateTime = aParam->auditDateTime;
  }
  
  // Numero de transaccion (auditoria)
  element = scew_element_add(generalInfo, "trans");
  sprintf(buf, "%08ld", auditNumber);
  scew_element_set_contents(element, buf);

  // Fecha de transaccion (auditoria)
	convertTime(&auditDateTime, &brokenTime);
  formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "transTime");
  scew_element_set_contents(element, dateStr);
            	
  elementTelesupList = scew_element_add(anElement, "telesupList");
        
  // Recorro la lista de telesups
  for (iTelesup = 0; iTelesup < [anEntity size]; ++iTelesup) {
    
    telesup = [anEntity at: iTelesup];    		

		if ( ([telesup getTelcoType] != CMP_TSUP_ID) && 
				 ([telesup getTelcoType] != CMP_OUT_TSUP_ID) ) {

			hasData = TRUE;

			elementTelesupInfo = scew_element_add(elementTelesupList, "telesupInfo");
					
			// Nombre de telesup
			element = scew_element_add(elementTelesupInfo, "name");
			scew_element_set_contents(element, [telesup getTelesupDescription]);
			
			// Fecha ultima telesup		
			date = [telesup getLastSuceedTelesupDateTime];
			element = scew_element_add(elementTelesupInfo, "last");
			if (date > 1){
				convertTime(&date, &brokenTime);
				formatBrokenDateTime(dateStr, &brokenTime);
				scew_element_set_contents(element, dateStr);
			}else
				scew_element_set_contents(element, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));
			
			// Fecha ultimo reintento
			date = [telesup getLastAttemptDateTime];
			element = scew_element_add(elementTelesupInfo, "lastTry");
			if (date > 1){
				convertTime(&date, &brokenTime);
				formatBrokenDateTime(dateStr, &brokenTime);
				scew_element_set_contents(element, dateStr);    
			}else
				scew_element_set_contents(element, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));
	
			// Fecha proximo reintento
			date = [telesup getNextTelesupDateTime];
			element = scew_element_add(elementTelesupInfo, "next");
			if (date > 1){
				convertTime(&date, &brokenTime);
				formatBrokenDateTime(dateStr, &brokenTime);
				scew_element_set_contents(element, dateStr);
			}else
				scew_element_set_contents(element, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));
			
			// Frame
			element = scew_element_add(elementTelesupInfo, "frame");
			sprintf(buf, "%d", [telesup getTelesupFrame]);
			scew_element_set_contents(element, buf);
			
			// Retrys
			element = scew_element_add(elementTelesupInfo, "retrys");
			sprintf(buf, "%d", [telesup getAttemptsQty]);
			scew_element_set_contents(element, buf);
			
			// Retrys Time
			element = scew_element_add(elementTelesupInfo, "retryTime");
			sprintf(buf, "%d", [telesup getTimeBetweenAttempts]);
			scew_element_set_contents(element, buf);
	
			// EB From
			element = scew_element_add(elementTelesupInfo, "eBFrom");
			sprintf(buf, "%d", [telesup getFromHour]);
			scew_element_set_contents(element, buf);
	
			// EB To
			element = scew_element_add(elementTelesupInfo, "eBTo");
			sprintf(buf, "%d", [telesup getToHour]);
			scew_element_set_contents(element, buf);
		}
  }
  
	// verifico si no se mostro ninguna supervision
	element = scew_element_add(generalInfo, "withOutValues");
	if (!hasData)
    scew_element_set_contents(element, "TRUE");
  else
    scew_element_set_contents(element, "FALSE");  

}

/**/
- (int) getSignalPercent
{
	int i=0,n=0,j=0;
	char response[300];	
	char connectScript[200];
	char percent[5];
	char sys[30];
	int result = -1; 
	id pimsTelesup;
	long connectionId;
	id connectionSettings;
  FILE *f;
	int status;
	int comPort;

	if ([[TelesupScheduler getInstance] inTelesup]) return -2;

	pimsTelesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];
	if (pimsTelesup == NULL) return -2;

	connectionId = [pimsTelesup getConnectionId1];
	connectionSettings = [[TelesupervisionManager getInstance] getConnection: connectionId];
	if ([connectionSettings getConnectionType] != ConnectionType_GPRS) return -2;

	// Si el COM esta tomado lo desconecto
  status = system(BASE_PATH "/bin/ppptest");
  //doLog(0,"Valor retornado %d\n",status);

  if (status) {

		sprintf(sys, BASE_PATH "/bin/colgar %s", "gprs");
   	system(sys);

		for (i = 0; i < 10; ++i) {
    	msleep(1);
      status = system(BASE_PATH "/bin/ppptest");
			if (status == 0) break;
    }
  }      

	//doLog(0,"TEST PPPD\n");
	system("rm " BASE_VAR_PATH "/log/messages");

	// Por default es /dev/ttyS3
	comPort = [connectionSettings getConnectionPortId];
	if (comPort == 0) comPort = 4;
	comPort = comPort-1;

	sprintf(connectScript, "/bin/pppd '/dev/ttyS%d' %d connect '/bin/chat -v -f " BASE_PATH "/etc/ppp/connect.script'", comPort, [connectionSettings getConnectionSpeed]);
	//sprintf(connectScript, "/bin/pppd '/dev/ttyS3' %d connect '/bin/chat -v -f " BASE_PATH "/etc/ppp/connect.script'", [connectionSettings getConnectionSpeed]);

	system(connectScript);
	msleep(2);
  
	f = fopen(BASE_VAR_PATH "/log/messages", "r");

	if (!f) return result;
	
	while (!feof(f)) {
		if (!fgets(response, 255, f)) return result;
   	if (strstr(response,"+CSQ:")) break;	
	}

	fclose(f);

	//doLog(0,"RESULTADO %s\n", response); 

	//evaluo la respuesta
	if (strstr(response,"+CSQ:")!=0) {

		j=0;

		while (response[j] != '+') ++j;
		while (!isdigit(response[j])) ++j;

		n=j;

		//doLog(0,"response[n] = %c\n", response[n]);
		while(response[n]!=','){
			percent[n-j]=response[n];
			++n;
		}

		percent[n-j]=0;
		result = (atoi(percent)*32)/10;


		//doLog(0,"result = %d\n", result);

	}

  return result;

}

/**/
- (void) concatSystemInfo: (scew_element*) anElement entity: (id) anEntity isReprint: (BOOL) isReprint param: (EnrollOperatorReportParam *) aParam
{
	scew_element* generalInfo = NULL;
	scew_element* software = NULL;
	scew_element* hardware = NULL;
	scew_element* commStateChange = NULL;
  scew_element *element;
	scew_element *elementAcceptorList;
	scew_element *elementAcceptor;
	scew_element *elementDoor;
	scew_element *elementDoorList;
	int sPercent;
	
	char buf[50];
	char bufBloque1[50];
	char bufBloque2[50];
	struct tm brokenTime;
	char dateStr[50];
	unsigned long auditNumber = 0;
  datetime_t auditDateTime = 0;
  BOOL detailReport = TRUE;
	long total, free;
	float percUsed;
	COLLECTION acceptorsList;
	COLLECTION doorList;
	int iAcceptor;
	int iDoor;
	ACCEPTOR_SETTINGS acceptorSettings;
  int qtyUse;
  float usePercent;
  CIM_CASH cimCash;
	char ipAddress[20];
	char netMask[20];
	char gateway[20];
	char dhcp[20];
  char *kernelVersion = getKernelVersion();
	char status[50];
  char mac[100];
  datetime_t date;
	id commercialState;
	id door;
	char originalText[200];
	char finalText[200];
	char *s;
	char part[200];
	char line[200];
	G2_ACTIVE_PIC pic;
	char PTSDVersion[10];

	generalInfo = scew_element_add(anElement, "generalInfo");
	[self concatGeneralInfo: generalInfo isReprint: isReprint];

  if (aParam != NULL){
    auditNumber = aParam->auditNumber;
    auditDateTime = aParam->auditDateTime;
    detailReport = aParam->detailReport;
  }

  // indico si es Detallado o resumido  
  element = scew_element_add(generalInfo, "detailReport");
  if (detailReport)
    scew_element_set_contents(element, "TRUE");
  else
    scew_element_set_contents(element, "FALSE");
  
  // Numero de transaccion (auditoria)
  element = scew_element_add(generalInfo, "trans");
  sprintf(buf, "%08ld", auditNumber);
  scew_element_set_contents(element, buf);

  // Fecha de transaccion (auditoria)
	convertTime(&auditDateTime, &brokenTime);
  formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "transTime");
  scew_element_set_contents(element, dateStr);

  // Modelo del box
  element = scew_element_add(generalInfo, "cashModel");
  buf[0] = '\0';
	originalText[0] = '\0';
	finalText[0] = '\0';
	part[0] = '\0';
	line[0] = '\0';
	stringcpy(originalText, [[[CimManager getInstance] getCim] getBoxModel]);

  s = originalText;
  do {
  	s = wordwrap(s, 29, 11, part);
    sprintf(line, "%s\n", part);
    strcat(finalText, line);
  } while ( *s!='\0' );

  scew_element_set_contents(element, finalText);
  
  //********** Software ************/  
  software = scew_element_add(anElement, "software");
  
  // Version
  element = scew_element_add(software, "version");
  scew_element_set_contents(element, APP_VERSION_STR);

  // Release
  element = scew_element_add(software, "release");
  scew_element_set_contents(element, APP_RELEASE_DATE);

  // OS Version
  element = scew_element_add(software, "osVersion");  
  strcpy(buf, kernelVersion != NULL ? kernelVersion: getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));
  scew_element_set_contents(element, buf);

	// Espacio disponible en flash
  element = scew_element_add(software, "flashUse");  
	if ( getFileSystemInfo(BASE_PATH "", &total, &free) == 0 ) {
		percUsed = (float)(total-free)/(float)total*100.0;
		sprintf(buf, "%.1f%%", percUsed );
	}	else
	  formatResourceStringDef(buf, RESID_NOT_AVAILABLE, "NO DISPONIBLE");
	scew_element_set_contents(element, buf);

	// versiones PTSD soportadas
	pic = [G2ActivePIC new];

  element = scew_element_add(software, "maxPTSDVersion");
  scew_element_set_contents(element, [pic getPTSDVersion]);

  element = scew_element_add(software, "pimsPTSDVersion");
  scew_element_set_contents(element, [pic getSystemVersionByTelcoType: PIMS_TSUP_ID]);

  element = scew_element_add(software, "cmpPTSDVersion");
  scew_element_set_contents(element, [pic getSystemVersionByTelcoType: CMP_TSUP_ID]);

  element = scew_element_add(software, "cmpOutPTSDVersion");
  scew_element_set_contents(element, [pic getSystemVersionByTelcoType: CMP_OUT_TSUP_ID]);

	[pic free];

	/*stringcpy(PTSDVersion, [pic getPTSDVersion]);
	stringcpy(PTSDVersion, [pic getSystemVersionByTelcoType: PIMS_TSUP_ID]);
	stringcpy(PTSDVersion, [pic getSystemVersionByTelcoType: CMP_TSUP_ID]);
	stringcpy(PTSDVersion, [pic getSystemVersionByTelcoType: CMP_OUT_TSUP_ID]);*/

  //********** Hardware ************/  
  hardware = scew_element_add(anElement, "hardware");
  
  //**** BOX CONTROLLER  
  // Version HW/SW
  element = scew_element_add(hardware, "versionHW");
  [SafeBoxHAL getCimVersion: buf];
  if (strlen(buf) > 0)
    scew_element_set_contents(element, buf);
  else
    scew_element_set_contents(element, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));

  // Power Status
  element = scew_element_add(hardware, "powerStatus");
	switch ([SafeBoxHAL getPowerStatus])
	{ 
		case PowerStatus_EXTERNAL:
					strcpy(buf, getResourceStringDef(RESID_POWERSTATUS_EXTERNAL, "Externa"));
					break;
		case PowerStatus_BACKUP:
					strcpy(buf, getResourceStringDef(RESID_POWERSTATUS_BACKUP, "De respaldo"));
					break;
		default: strcpy(buf, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE")); break;
  }
  scew_element_set_contents(element, buf);

  // System Status
  element = scew_element_add(hardware, "systemStatus");
	switch ([SafeBoxHAL getHardwareSystemStatus])
	{ 
		case HardwareSystemStatus_PRIMARY:
					strcpy(buf, getResourceStringDef(RESID_SYSTEMSTATUS_PRIMARY, "Primaria"));
					break;
		case HardwareSystemStatus_SECONDARY:
					strcpy(buf, getResourceStringDef(RESID_SYSTEMSTATUS_SECONDARY, "Secundaria"));
					break;
		default: strcpy(buf, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE")); break;
  }
  scew_element_set_contents(element, buf);

  // Battery Status
  element = scew_element_add(hardware, "batteryStatus");
	switch ([SafeBoxHAL getBatteryStatus])
	{ 
		case BatteryStatus_LOW:
					strcpy(buf, getResourceStringDef(RESID_BATTERYSTATUS_LOW, "Baja"));
					break;
		case BatteryStatus_REMOVED:
					strcpy(buf, getResourceStringDef(RESID_BATTERYSTATUS_REMOVED, "Removida"));
					break;
		case BatteryStatus_OK:
					strcpy(buf, getResourceStringDef(RESID_BATTERYSTATUS_OK, "OK"));
					break;
		default: strcpy(buf, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE")); break;
  }
  scew_element_set_contents(element, buf);


	// Estado comercial
	commStateChange = scew_element_add(anElement, "commStateChange");

	commercialState = [[CommercialStateMgr getInstance] getCurrentCommercialState];

	// MAC Address
  element = scew_element_add(commStateChange, "macAddress");
	[[CimGeneralSettings getInstance] getMacAddress: mac];
  scew_element_set_contents(element, mac);

	// Fecha de solicitud
  element = scew_element_add(commStateChange, "requestDate");
  date = [commercialState getRequestDateTime];
	convertTime(&date, &brokenTime);
  formatBrokenDateTime(dateStr, &brokenTime);
  scew_element_set_contents(element, dateStr);

	// Estado anterior
  element = scew_element_add(commStateChange, "oldState");
  scew_element_set_contents(element, [commercialState getCommStateSTR: [commercialState getOldState]]);

	// Estado actual
  element = scew_element_add(commStateChange, "currentState");
  scew_element_set_contents(element, [commercialState getCommStateSTR: [commercialState getCommState]]);

  if (detailReport){
    
      // GSM MODULE
      // IMEI
      /*element = scew_element_add(hardware, "imei");
      scew_element_set_contents(element, "xxxxxxx");
    	*/
      // Signal
      element = scew_element_add(hardware, "signal");

			sPercent = [self getSignalPercent];
		
			// -2 NO DISPONIBLE
			// -1 SIN SENIAL
			// > 0 PORCENTAJE DE SENIAL
			if ( sPercent == -2 ) {
      	scew_element_set_contents(element, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));
			} else if ( sPercent == -1 ) {
      		scew_element_set_contents(element, getResourceStringDef(RESID_NO_SIGNAL, "SIN SENAL"));
			} else { 
					sprintf(buf, "%d%s", sPercent, "%");
					scew_element_set_contents(element, buf);
			}

      // ETHERNET
      // IP
			//loadIPConfig(dhcp, ipAddress, netMask, gateway);

			// MAC Address
			element = scew_element_add(hardware, "macAddress");
			[[CimGeneralSettings getInstance] getMacAddress: mac];
			scew_element_set_contents(element, mac);

      element = scew_element_add(hardware, "dhcp");
			[[CimGeneralSettings getInstance] getDhcp: dhcp];
			if (strcmp(dhcp, "no") == 0)
				scew_element_set_contents(element, getResourceStringDef(RESID_NO, "No"));
			else
				scew_element_set_contents(element, getResourceStringDef(RESID_YES, "Si"));

      element = scew_element_add(hardware, "ip");
			[[CimGeneralSettings getInstance] getIpAddress: ipAddress];
      scew_element_set_contents(element, ipAddress);
      
      // Mask
      element = scew_element_add(hardware, "mask");
			[[CimGeneralSettings getInstance] getNetMask: netMask];
      scew_element_set_contents(element, netMask);
    
      // Gateway
      element = scew_element_add(hardware, "gateway");
			[[CimGeneralSettings getInstance] getGateway: gateway];
      scew_element_set_contents(element, gateway);
    
      /*
			// Status
      element = scew_element_add(hardware, "status");
      scew_element_set_contents(element, gateway);  
      
      
      --> poner esto en el archivo systemInfo.vft
      Name      : GSM MODULE\n
      IMEI      : @/hardware/imei@\n
      Signal    : @/hardware/signal@\n
      GPRS State: @/hardware/gprsState@\n
      -----------------------------\n
      Name    : ETHERNET (eth0)\n
      IP      : @/hardware/ip@\n
      Mask    : @/hardware/mask@\n
      Gateway : @/hardware/gateway@\n
      Status  : @/hardware/status@\n
      -----------------------------\n      
      */
    
            	
      // Obtengo la lista de validadores
      acceptorsList = [anEntity getAcceptors];
      elementAcceptorList = scew_element_add(anElement, "acceptorList");
        
    	// Recorro la lista de validadores
    	for (iAcceptor = 0; iAcceptor < [acceptorsList size]; ++iAcceptor) {
    
    		acceptorSettings = [[acceptorsList at: iAcceptor] getAcceptorSettings];
    		
    		if ([acceptorSettings getAcceptorType] == AcceptorType_VALIDATOR){
    		
        		elementAcceptor = scew_element_add(elementAcceptorList, "acceptor");
        
        		// Nombre del aceptador
        		element = scew_element_add(elementAcceptor, "name");
        		scew_element_set_contents(element, [acceptorSettings getAcceptorName]);
    
        		// Currency
        		element = scew_element_add(elementAcceptor, "currency");
        		scew_element_set_contents(element, [[acceptorSettings getDefaultCurrency] getCurrencyCode]);
        		
        		// Cash
        		element = scew_element_add(elementAcceptor, "cash");
        		cimCash = [anEntity getCimCashByAcceptorId: [acceptorSettings getAcceptorId]];
        		if (cimCash != NULL)
        		  scew_element_set_contents(element, [cimCash getName]);
        		else
        		  scew_element_set_contents(element, getResourceStringDef(RESID_NULL, "NINGUNA"));
            
        		// Door
        		element = scew_element_add(elementAcceptor, "door");
        		scew_element_set_contents(element, [[acceptorSettings getDoor] getDoorName]);

						// proveedor
						element = scew_element_add(elementAcceptor, "provider");
						switch ([acceptorSettings getAcceptorBrand]) {
							case BrandType_UNDEFINED:
									scew_element_set_contents(element, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));
								break;

							case BrandType_JCM:
									scew_element_set_contents(element, getResourceStringDef(RESID_Acceptor_JCM, "JCM"));
								break;

							case BrandType_CASH_CODE:
									scew_element_set_contents(element, getResourceStringDef(RESID_Acceptor_CASH_CODE, "Cash Code"));
								break;

							case BrandType_MEI:
									scew_element_set_contents(element, getResourceStringDef(RESID_Acceptor_MEI, "MEI"));
								break;
							case BrandType_CDM:
									scew_element_set_contents(element, "CDM");
								break;
							case BrandType_RDM:
									scew_element_set_contents(element, getResourceStringDef(RESID_UNDEFINED, "RDM"));
								break;
                                
						}

        		// Version        		
						strcpy(buf, [[acceptorsList at: iAcceptor] getVersion]);
            if (strlen(buf) > 0){
        		  bufBloque1[0] = '\0';
        		  bufBloque2[0] = '\0';
        		  
              if (strlen(buf) > 19){
                memcpy( bufBloque1, buf, 19 );
          		  bufBloque1[19] = '\0';
          		  
          		  memcpy( bufBloque2, &buf[19], (strlen(buf) - 19) );
          		  bufBloque2[strlen(buf)-19] = '\0';
        		  }else 
                strcpy(bufBloque1, buf);
              
              element = scew_element_add(elementAcceptor, "version1");
              scew_element_set_contents(element, bufBloque1);
                
              if (strlen(bufBloque2) > 0){  
                element = scew_element_add(generalInfo, "viewVersion2");
                scew_element_set_contents(element, "TRUE");                
                element = scew_element_add(elementAcceptor, "version2");
                scew_element_set_contents(element, bufBloque2);                  
                
              }else{
                element = scew_element_add(generalInfo, "viewVersion2");
                scew_element_set_contents(element, "FALSE");
                element = scew_element_add(elementAcceptor, "version2");
                scew_element_set_contents(element, "");                
              }
            }else{
              element = scew_element_add(elementAcceptor, "version1");
              scew_element_set_contents(element, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));
              element = scew_element_add(generalInfo, "viewVersion2");
              scew_element_set_contents(element, "FALSE");
              element = scew_element_add(elementAcceptor, "version2");
              scew_element_set_contents(element, "");                
            }

        		// Staker Size
        		element = scew_element_add(elementAcceptor, "stakerSize");
        		sprintf(buf,"%d",[acceptorSettings getStackerSize]);
        		scew_element_set_contents(element, buf);

        		// Staker Use
        		element = scew_element_add(elementAcceptor, "stakerUse");
            qtyUse = [[[ExtractionManager getInstance] getCurrentExtraction: [acceptorSettings getDoor]] getQtyByAcceptor: acceptorSettings];

            if ([acceptorSettings getStackerSize] != 0)
               usePercent = ((float)qtyUse / (float)[acceptorSettings getStackerSize]) * 100.0;
            else
               usePercent = 0;

            sprintf(buf,"%d (%4.0f %%)",qtyUse, usePercent);
        		scew_element_set_contents(element, buf);    

        		// Status
        		element = scew_element_add(elementAcceptor, "status");
						strcpy(status, [[acceptorsList at: iAcceptor] getCurrentErrorDescription]);
						status[16] = '\0';
        		scew_element_set_contents(element, status);
        }
    	}

      // Obtengo la lista de puertas
			doorList = [[[CimManager getInstance] getCim] getDoors];
      elementDoorList = scew_element_add(anElement, "doorList");

    	// Recorro la lista de puertas
    	for (iDoor = 0; iDoor < [doorList size]; ++iDoor) {

    		door = [doorList at: iDoor];

				elementDoor = scew_element_add(elementDoorList, "door");

				// Nombre de la puerta
				element = scew_element_add(elementDoor, "name");
				scew_element_set_contents(element, [door getDoorName]);

				// Sensor type
				element = scew_element_add(elementDoor, "sensorType");

				switch ([door getSensorType]) {
					case SensorType_NONE:
							scew_element_set_contents(element, getResourceStringDef(RESID_Door_SENSOR_TYPE_NONE, "Ninguno"));
						break;
					case SensorType_LOCKER:
							scew_element_set_contents(element, getResourceStringDef(RESID_Door_SENSOR_TYPE_LOCKER, "Plunger"));
						break;
					case SensorType_PLUNGER:
							scew_element_set_contents(element, getResourceStringDef(RESID_Door_SENSOR_TYPE_PLUNGER, "Locker"));
						break;
					case SensorType_BOTH:
							scew_element_set_contents(element, getResourceStringDef(RESID_Door_SENSOR_TYPE_BOTH, "Ambos"));
						break;
					case SensorType_PLUNGER_EXT:
							scew_element_set_contents(element, getResourceStringDef(RESID_Door_SENSOR_TYPE_PLUNGER_EXT, "Plunger-Ext"));
							break;

				}

				// Locker state
				element = scew_element_add(elementDoor, "lockerState");
				switch ([door getLockState]) {
					case LockState_UNDEFINED:
							scew_element_set_contents(element, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));
						break;
					case LockState_UNLOCK:
							scew_element_set_contents(element, getResourceStringDef(RESID_OPENED_LOCKER, "Abierta"));
						break;
					case LockState_LOCK:
							scew_element_set_contents(element, getResourceStringDef(RESID_CLOSED_LOCKER, "Cerrada"));
						break;
				}

				// Plunger state
				element = scew_element_add(elementDoor, "plungerState");
				switch ([door getDoorState]) {
					case DoorState_UNDEFINED:
							scew_element_set_contents(element, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));
						break;
					case DoorState_OPEN:
							scew_element_set_contents(element, getResourceStringDef(RESID_OPENED_PLUNGER, "Abierto"));
						break;
					case DoorState_CLOSE:
							scew_element_set_contents(element, getResourceStringDef(RESID_CLOSED_PLUNGER, "Cerrado"));
						break;
				}
    	}

  }

}


/**/
- (void) concatBackupInfo: (scew_element*) anElement entity: (id) anEntity isReprint: (BOOL) isReprint param: (EnrollOperatorReportParam *) aParam
{
	scew_element* generalInfo = NULL;
	scew_element* backup = NULL;
  scew_element *element;
	char buf[50];
	struct tm brokenTime;
	char dateStr[50];
  datetime_t date;

	generalInfo = scew_element_add(anElement, "generalInfo");
	[self concatGeneralInfo: generalInfo isReprint: isReprint];

  backup = scew_element_add(anElement, "backup");

  //********** Transacciones ************/
	// fecha de backup de transacciones
	element = scew_element_add(backup, "backupTransDate");
  date = [anEntity getBackupTransDate];
	if (date != 0) {
		convertTime(&date, &brokenTime);
		formatBrokenDateTime(dateStr, &brokenTime);
	} else strcpy(dateStr, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));
  scew_element_set_contents(element, dateStr);

  // ultimo id de auditoria
  element = scew_element_add(backup, "lastAuditId");
	sprintf(buf, "%ld", [anEntity getLastAuditId]);
  scew_element_set_contents(element, buf);

  // ultimo id de detalle de auditoria
  element = scew_element_add(backup, "lastAuditDetailId");
	sprintf(buf, "%ld", [anEntity getLastAuditDetailId]);
  scew_element_set_contents(element, buf);

  // ultimo id de deposito
  element = scew_element_add(backup, "lastDropId");
	sprintf(buf, "%ld", [anEntity getLastDropId]);
  scew_element_set_contents(element, buf);

  // ultimo id de detalle de deposito
  element = scew_element_add(backup, "lastDropDetailId");
	sprintf(buf, "%ld", [anEntity getLastDropDetailId]);
  scew_element_set_contents(element, buf);

  // ultimo id de extraccion
  element = scew_element_add(backup, "lastDepositId");
	sprintf(buf, "%ld", [anEntity getLastDepositId]);
  scew_element_set_contents(element, buf);

  // ultimo id de detalle de extraccion
  element = scew_element_add(backup, "lastDepositDetailId");
	sprintf(buf, "%ld", [anEntity getLastDepositDetailId]);
  scew_element_set_contents(element, buf);

  // ultimo id de extraccion
  element = scew_element_add(backup, "lastZcloseId");
	sprintf(buf, "%ld", [anEntity getLastZcloseId]);
  scew_element_set_contents(element, buf);


  //********** Seteos ************/
	// fecha de backup de seteos
	element = scew_element_add(backup, "backupSettDate");
  date = [anEntity getBackupSettDate];
	if (date != 0) {
		convertTime(&date, &brokenTime);
		formatBrokenDateTime(dateStr, &brokenTime);
	} else strcpy(dateStr, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));
  scew_element_set_contents(element, dateStr);


  //********** Usuarios ************/
	// fecha de backup de usuarios
	element = scew_element_add(backup, "backupUserDate");
  date = [anEntity getBackupUserDate];
	if (date != 0) {
		convertTime(&date, &brokenTime);
		formatBrokenDateTime(dateStr, &brokenTime);
	} else strcpy(dateStr, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));
  scew_element_set_contents(element, dateStr);

}

/**/
- (void) buildEnrolledUserXML: (id) anEntity isReprint: (BOOL) isReprint tree: (scew_tree*) tree param: (void *) aParam
{
  scew_element* root = NULL;

  root = scew_tree_add_root(tree, "enrolledUsers");

  //Informacion de los usuarios
  [self concatEnrolledUserInfo: root entity: anEntity isReprint: isReprint param: (EnrollOperatorReportParam*)aParam];

}

/**/
- (void) buildConfigTelesupReportXML: (id) anEntity isReprint: (BOOL) isReprint tree: (scew_tree*) tree param: (void *) aParam
{
  scew_element* root = NULL;

  root = scew_tree_add_root(tree, "configTelesupReport");

  //Informacion de las telesuperviciones
  [self concatConfigTelesupReportInfo: root entity: anEntity isReprint: isReprint param: (EnrollOperatorReportParam*)aParam];

}

/**/
- (void) buildSystemInfoXML: (id) anEntity isReprint: (BOOL) isReprint tree: (scew_tree*) tree param: (void *) aParam
{
  scew_element* root = NULL;

  root = scew_tree_add_root(tree, "systemInfo");

  //Informacion de sistema
  [self concatSystemInfo: root entity: anEntity isReprint: isReprint param: (EnrollOperatorReportParam*)aParam];

}

/**/
- (void) buildBackupInfoXML: (id) anEntity isReprint: (BOOL) isReprint tree: (scew_tree*) tree param: (void *) aParam
{
  scew_element* root = NULL;

  root = scew_tree_add_root(tree, "backupInfo");

  //Informacion de backup
  [self concatBackupInfo: root entity: anEntity isReprint: isReprint param: (EnrollOperatorReportParam*)aParam];

}

/*************************************************
*
* Archivo XML de deposito
*
*************************************************/

/**/
- (void) concatExtractionGeneralInfo: (scew_element*) anElement entity: (id) anEntity isReprint: (BOOL) isReprint param: (CashReportParam *) aCashParam
{
  scew_element* generalInfo = NULL;
  scew_element* element = NULL;
  datetime_t date;
  char dateStr[50];
  struct tm brokenTime;
  char buf[50];
  char mSymbol[4];
	unsigned long auditNumber = 0;
  datetime_t auditDateTime = 0;
  CIM_CASH cash;
  char reportType[1];
  BOOL detail = FALSE;
	BOOL showBagNumber = FALSE;

  strcpy(mSymbol, [[RegionalSettings getInstance] getMoneySymbol]);

	generalInfo = scew_element_add(anElement, "generalInfo");
	[self concatGeneralInfo: generalInfo isReprint: isReprint];

  // Recaudador
  if ([anEntity getCollector] != NULL){
  	element = scew_element_add(generalInfo, "viewCollectorName");
  	scew_element_set_contents(element, "TRUE");
  	
  	strcpy(buf, [[anEntity getCollector] str]);
  	buf[17] = '\0';
  	element = scew_element_add(generalInfo, "collectorName");
  	scew_element_set_contents(element, buf);
	}else{
  	element = scew_element_add(generalInfo, "viewCollectorName");
  	scew_element_set_contents(element, "FALSE");      
  }

  // Usuario
  element = scew_element_add(generalInfo, "operatorName");
	strcpy(buf, [anEntity getOperator] != NULL ? [[anEntity getOperator] str] : getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
	buf[17] = '\0';
  scew_element_set_contents(element, buf);

  // Fecha / hora de la extraccion
  date = [anEntity getDateTime];
	convertTime(&date, &brokenTime);
  formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "dateTime");
  scew_element_set_contents(element, dateStr);

  // Cantidad de billetes rechazados
  element = scew_element_add(generalInfo, "rejectedQty");
  sprintf(buf, "%d", [anEntity getRejectedQty]);
  scew_element_set_contents(element, buf);

  // Numero de extraccion
  element = scew_element_add(generalInfo, "number");
  sprintf(buf, "%08ld", [anEntity getNumber]);
  scew_element_set_contents(element, buf);

  // Desde deposito
  element = scew_element_add(generalInfo, "fromDepositNumber");
  sprintf(buf, "%08ld", [anEntity getFromDepositNumber]);
  scew_element_set_contents(element, buf);
  
  // Hasta deposito
  element = scew_element_add(generalInfo, "toDepositNumber");
  if ([anEntity getToDepositNumber] == 0)
    sprintf(buf, "%08ld", [anEntity getFromDepositNumber]);
  else
    sprintf(buf, "%08ld", [anEntity getToDepositNumber]);
  scew_element_set_contents(element, buf);

  // Nombre de puerta
  element = scew_element_add(generalInfo, "doorName");
  scew_element_set_contents(element, [[anEntity getDoor] getDoorName]);

  strcpy(reportType,"1"); //(byDoor)
  if (aCashParam != NULL){
    auditNumber = aCashParam->auditNumber;
    auditDateTime = aCashParam->auditDateTime;
    detail = aCashParam->detailReport;
		showBagNumber = aCashParam->showBagNumber;
    if (aCashParam->cash != NULL){
       cash = aCashParam->cash;
       // Numero de transaccion (auditoria)
       element = scew_element_add(generalInfo, "cashName");
       scew_element_set_contents(element, [cash getName]);
       strcpy(reportType,"2"); //(byCash)
    }      
  }
  
  // Tipo de reporte
  element = scew_element_add(generalInfo, "reportType");
  scew_element_set_contents(element, reportType);  
  
  // Numero de transaccion (auditoria)
  element = scew_element_add(generalInfo, "trans");
  sprintf(buf, "%08ld", auditNumber);
  scew_element_set_contents(element, buf);

  // Fecha de transaccion (auditoria)
	convertTime(&auditDateTime, &brokenTime);
	formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "transTime");
  scew_element_set_contents(element, dateStr);

  // Numero de extraccion Z anterior
  element = scew_element_add(generalInfo, "lastZ");
  sprintf(buf, "%08ld", [[[Persistence getInstance] getZCloseDAO] getLastZCloseNumber]);
  scew_element_set_contents(element, buf);

  // Fecha/hora de extraccion Z anterior
  date = [[[Persistence getInstance] getZCloseDAO] getPrevZCloseCloseTime];
  convertTime(&date, &brokenTime);
  formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "lastDateZ");
  scew_element_set_contents(element, dateStr);
    
  element = scew_element_add(generalInfo, "detailReport");
  if (detail)
    scew_element_set_contents(element, "TRUE");
  else
    scew_element_set_contents(element, "FALSE");

  // Numero de cuenta bancaria
  element = scew_element_add(generalInfo, "bankAccountInfo");
  scew_element_set_contents(element, [anEntity getBankAccountInfo]);

  // Numero de bolsa
  element = scew_element_add(generalInfo, "showBagNumber");
  if (showBagNumber)
    scew_element_set_contents(element, "TRUE");
  else
    scew_element_set_contents(element, "FALSE");

  element = scew_element_add(generalInfo, "bagNumber");
  scew_element_set_contents(element, [anEntity getBagNumber]);

}

/**/
- (void) concatTransBoxModeExtractionDetailInfo: (scew_element*) anElement entity: (id) anEntity isReprint: (BOOL) isReprint param: (CashReportParam *) aCashParam
{
	scew_element *element;
	scew_element *extractionDetailsElement;
	scew_element *extractionDetailElement;
	scew_element *elementCimCashs;
	scew_element *elementCimCash;
	scew_element *elementAcceptor;
	scew_element *elementAcceptorList;
	scew_element *elementCurrency;
	scew_element *elementCurrencyList;
	scew_element *elementCashClose;
	scew_element *elementCashCloseDetails;
	scew_element *elementBreakdown;
	scew_element *elementCashCloseDetail;
	scew_element *elementEndOfDay;
	scew_element *elementReference;
	EXTRACTION_DETAIL extractionDetail;
	int iCash, iAcceptor, iDetail, iCurrency, iCashClose, iCashCloseDetail, iEndOfDay;
	char buf[50], dateStr[50];
	int totalDecimals = [[AmountSettings getInstance] getTotalRoundDecimalQty];
	COLLECTION detailsByCimCash, detailsByAcceptor, detailsByCurrency;
	COLLECTION cimCashs, currecies, acceptorSettingsList;
	ACCEPTOR_SETTINGS acceptorSettings;
	CIM_CASH cimCash;
	CURRENCY currency;
	CIM_CASH cash;
	COLLECTION cashCloses;
	COLLECTION cashCloseDetails;
	ZCLOSE_DETAIL cashCloseDetail;
	ZCLOSE cashClose;
	datetime_t date;
	struct tm brokenTime;
	COLLECTION endOfDayList;
	unsigned long endOfDayNumber;
	ZCLOSE zClose;
	BOOL isPartial = FALSE;
	int envelopeQty;
	COLLECTION references = NULL;
	COLLECTION referenceSumaries = NULL;
	id reference;
	int iReference;
	money_t totalReferenceSumary = 0;
	BOOL isAddedCurrency = FALSE;
	BOOL isAddedRefName = FALSE;
	money_t totSumRef;
	COLLECTION depositValueTypes = NULL;
	int iDepValType;
	int depositValueType;
	BOOL showReferenceTitle = TRUE;

/*
	<cimcashs>
	 	<cimcash>
			<name>VERIFIED CASH BOX</name>	
				<acceptor>	
					<acceptorName>VALIDADOR xxx</acceptorName>
					<currency>
						<currencyCode>ARS</currencyCode>
						<qty>10</qty>
						<total>50.00</total>
						<extractionDetails>
							<extractionDetail>...</extractionDetail>
							<extractionDetail>...</extractionDetail>
							<extractionDetail>...</extractionDetail>
						</extractionDetails>
					</currency>
					<currency>
						<currencyCode>USD</currencyCode>
						<qty>10</qty>
						<total>50.00</total>
						<extractionDetails>
							<extractionDetail>...</extractionDetail>
							<extractionDetail>...</extractionDetail>
							<extractionDetail>...</extractionDetail>
						</extractionDetails>
					</currency>			
				</acceptor>

				<currency>
						<currencyCode>ARS</currencyCode>
						<total>50.00</total>
				</currency>
				
		</cimcash>
	</cimcashs>
	<currency>
			<currencyCode>ARS</currencyCode>
			<total>50.00</total>
	</currency>	

	<breakdown>
		<endOfDay>
			<number>xxxx</number>
			<date>ddddddd</date>
			<cashClose>
				<number>0001</number>
				<date>10/10/07</date>
				<cashCloseDetails>
					<cashCloseDetail>
						<currency>USD</currency>
						<amount>50.00</amount>
					</cashCloseDetail>
				</cashCloseDetails>
			</cashClose>
		</endOfDay>
	</breakdown>

*/
	elementCimCashs = scew_element_add(anElement, "cimCashs");

	// Obtengo la lista de cashs
	cimCashs = [anEntity getCimCashs: NULL];
  
  // Si cash != NULL muestro solo esa cash 
  // en caso contrario muestro todas las del door seleccionado
  cash = NULL;
  if (aCashParam != NULL)
    if (aCashParam->cash != NULL)
       cash = aCashParam->cash;

  
  // Recorro la lista de cashs
	for (iCash = 0; iCash < [cimCashs size]; ++iCash) {

		cimCash = [cimCashs at: iCash];

		if ( (cash == NULL) || ((cash != NULL) && ([cash getCimCashId] == [cimCash getCimCashId])) ){
    		// Nombre de la caja
    		elementCimCash = scew_element_add(elementCimCashs, "cimCash");
    		element = scew_element_add(elementCimCash, "name");
    		scew_element_set_contents(element, [cimCash getName]);
    
    		// Tipo de caja (automatica / manual)
    		element = scew_element_add(elementCimCash, "cimCashType");
    		sprintf(buf, "%d", [cimCash getDepositType]);
    		scew_element_set_contents(element, buf);

				// obtengo la cantidad de sobres en el acceptor manual
				envelopeQty = 0;
				if ([cimCash getDepositType] == DepositType_MANUAL) {

	  			envelopeQty = [[DepositDetailReport getInstance] getTicketsCountByDepositType: [anEntity getFromDepositNumber]
						toDepositNumber: [anEntity getToDepositNumber] depositType: DepositType_MANUAL];

				}
    		element = scew_element_add(elementCimCash, "envelopeQty");
    		sprintf(buf, "%d", envelopeQty);
    		scew_element_set_contents(element, buf);
    
    		// Obtengo los depositos para el cash actual
    		detailsByCimCash = [anEntity getDetailsByCimCash: NULL cimCash: cimCash];
    
    		// Obtengo la lista  de validadores
    		acceptorSettingsList = [anEntity getAcceptorSettingsList: detailsByCimCash];
    		
    		elementAcceptorList = scew_element_add(elementCimCash, "acceptorList");
    
    		// Recorro la lista de validadores
    		for (iAcceptor = 0; iAcceptor < [acceptorSettingsList size]; ++iAcceptor) {
    
    			acceptorSettings = [acceptorSettingsList at: iAcceptor];
    			elementAcceptor = scew_element_add(elementAcceptorList, "acceptor");
    
    			// Nombre del aceptador
    			element = scew_element_add(elementAcceptor, "acceptorName");
    			scew_element_set_contents(element, [acceptorSettings getAcceptorName]);

					if ([cimCash getDepositType] == DepositType_MANUAL) {
    				element = scew_element_add(elementAcceptor, "viewManualDetail");
						if ([[anEntity getAllCashReferences] size] > 0)
							scew_element_set_contents(element, "FALSE");
						else
    					scew_element_set_contents(element, "TRUE");
					}

    			// Obtengo la lista de detalles para el validador en curso
    			detailsByAcceptor = [anEntity getDetailsByAcceptorSettings: detailsByCimCash acceptorSettings: acceptorSettings];
    
    			// Obtengo la lista de monedas
    			currecies = [anEntity getCurrencies: detailsByAcceptor];
    
    			elementCurrencyList = scew_element_add(elementAcceptor, "currencyList");
    
    			// Recorro la lista de monedas
    			for (iCurrency = 0; iCurrency < [currecies size]; ++iCurrency) {
    
    				currency = [currecies at: iCurrency];
    				detailsByCurrency = [anEntity getDetailsByCurrency: detailsByAcceptor currency: currency];
    
    				elementCurrency = scew_element_add(elementCurrencyList, "currency");
    
    				element = scew_element_add(elementCurrency, "currencyCode");
    				scew_element_set_contents(element, [currency getCurrencyCode]);
    
    				element = scew_element_add(elementCurrency, "qty");
    				sprintf(buf, "%04d", [anEntity getQty: detailsByCurrency]);
    				scew_element_set_contents(element, buf);

    				element = scew_element_add(elementCurrency, "total");
    				formatMoney(buf, "", [anEntity getTotalAmount: detailsByCurrency], totalDecimals, 20);
    				scew_element_set_contents(element, buf);
    		
    				extractionDetailsElement = scew_element_add(elementCurrency, "extractionDetails");
    			
    				for (iDetail = 0; iDetail < [detailsByCurrency size]; ++iDetail) {
    			
    					extractionDetail = [detailsByCurrency at: iDetail];
    					extractionDetailElement = scew_element_add(extractionDetailsElement, "extractionDetail");
    		
    					// Cantidad
    					element = scew_element_add(extractionDetailElement, "qty");
    					sprintf(buf, "%04d" , [extractionDetail getQty]);
    					scew_element_set_contents(element, buf);
    			
    					// Importe
    					element = scew_element_add(extractionDetailElement, "amount");
							if ([extractionDetail isUnknownBill]) stringcpy(buf, getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
							else formatMoney(buf, "", [extractionDetail getAmount], totalDecimals, 20);
    					scew_element_set_contents(element, buf);
    			
    					// Total
    					element = scew_element_add(extractionDetailElement, "totalAmount");
    					if ([extractionDetail isUnknownBill]) stringcpy(buf, getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
							else formatMoney(buf, "", [extractionDetail getTotalAmount], totalDecimals, 20);
    					scew_element_set_contents(element, buf);
    
    					// Nombre del tipo de valor
    					element = scew_element_add(extractionDetailElement, "depositValueName");
    					scew_element_set_contents(element, [extractionDetail getDepositValueName]);
    			
    				}
    
    				[detailsByCurrency free];
    				
    			}
    			
    			[currecies free];
    			[detailsByAcceptor free];

    		}
    		[acceptorSettingsList free];

        // Obtengo la lista de references para el cash validado *********
				if ([cimCash getDepositType] == DepositType_AUTO) {
					showReferenceTitle = TRUE;
					currecies = [anEntity getCurrenciesByDepType: DepositType_AUTO];
					references = [anEntity getCashReferences: DepositType_AUTO];
					if ([references size] > 0) {

						for (iCurrency = 0; iCurrency < [currecies size]; ++iCurrency) {
							currency = [currecies at: iCurrency];
							isAddedCurrency = FALSE;
							totSumRef = 0;
		
							for (iReference = 0; iReference < [references size]; ++iReference) {
								reference = [references at: iReference];

								referenceSumaries = [anEntity getCashReferenceSummaries: reference];
								totalReferenceSumary = [anEntity getCashReferenceTotalAmountByCurrenyByDepType: referenceSumaries currency: currency reference: reference depositType: DepositType_AUTO];

								elementReference = scew_element_add(elementCimCash, "totalValReference");

								element = scew_element_add(elementReference, "showReferenceTitle");
								if (showReferenceTitle)
									scew_element_set_contents(element, "TRUE");
								else
									scew_element_set_contents(element, "FALSE");
								showReferenceTitle = FALSE;

								element = scew_element_add(elementReference, "showCurrencyCode");
								if (!isAddedCurrency) {
									scew_element_set_contents(element, "TRUE");
		
									element = scew_element_add(elementReference, "currencyCode");
									scew_element_set_contents(element, [currency getCurrencyCode]);
									isAddedCurrency = TRUE;
								} else scew_element_set_contents(element, "FALSE");

								element = scew_element_add(elementReference, "showReference");
								if (totalReferenceSumary > 0)
									scew_element_set_contents(element, "TRUE");
								else
									scew_element_set_contents(element, "FALSE");

								element = scew_element_add(elementReference, "referenceName");
								scew_element_set_contents(element, [reference getName]);
	
								element = scew_element_add(elementReference, "totalReference");
								formatMoney(buf, "", totalReferenceSumary, totalDecimals, 20);
								scew_element_set_contents(element, buf);
								totSumRef += totalReferenceSumary;

								element = scew_element_add(elementReference, "showCurrencyTot");
								if ((iReference + 1) == [references size]) {
									scew_element_set_contents(element, "TRUE");
	
									element = scew_element_add(elementReference, "totalCurrRef");
									formatMoney(buf, "", totSumRef, totalDecimals, 20);
									scew_element_set_contents(element, buf);
								} else scew_element_set_contents(element, "FALSE");
							}
						}
					}
					[currecies free];
					[references free];
				}

        // Obtengo la lista de references para el cash manual *********
				if ([cimCash getDepositType] == DepositType_MANUAL) {
					currecies = [anEntity getCurrenciesByDepType: DepositType_MANUAL];

					if ([currecies size] > 0) {
						for (iCurrency = 0; iCurrency < [currecies size]; ++iCurrency) {
							currency = [currecies at: iCurrency];
							references = [anEntity getCashReferencesByCurr: DepositType_MANUAL currency: currency];
							isAddedCurrency = FALSE;
							totSumRef = 0;
		
							for (iReference = 0; iReference < [references size]; ++iReference) {
								reference = [references at: iReference];
								isAddedRefName = FALSE;

								depositValueTypes = [anEntity getDepositValueTypes: reference depositType: DepositType_MANUAL];
								for (iDepValType = 0; iDepValType < [depositValueTypes size]; ++iDepValType) {
									depositValueType = [[depositValueTypes at: iDepValType] intValue];

									referenceSumaries = [anEntity getCashReferenceSummaries: reference];
									totalReferenceSumary = [anEntity getCashReferenceTotalAmountByCurrenyByDepTypeByValType: referenceSumaries currency: currency reference: reference depositType: DepositType_MANUAL depositValueType: depositValueType];

									if (totalReferenceSumary > 0) {
										elementReference = scew_element_add(elementCimCash, "totalManualReference");
				
										element = scew_element_add(elementReference, "showCurrencyCode");
										if (!isAddedCurrency) {
											scew_element_set_contents(element, "TRUE");
				
											element = scew_element_add(elementReference, "currencyCode");
											scew_element_set_contents(element, [currency getCurrencyCode]);
											isAddedCurrency = TRUE;
										} else scew_element_set_contents(element, "FALSE");

										element = scew_element_add(elementReference, "showReferenceName");
										if (!isAddedRefName) {
											scew_element_set_contents(element, "TRUE");
				
											element = scew_element_add(elementReference, "referenceName");
											scew_element_set_contents(element, [reference getName]);
											isAddedRefName = TRUE;
										} else scew_element_set_contents(element, "FALSE");

										element = scew_element_add(elementReference, "showReference");
										if (totalReferenceSumary > 0)
											scew_element_set_contents(element, "TRUE");
										else
											scew_element_set_contents(element, "FALSE");
	
										element = scew_element_add(elementReference, "depValType");
										scew_element_set_contents(element, [UICimUtils getDepositName: depositValueType]);
			
										element = scew_element_add(elementReference, "totalReference");
										formatMoney(buf, "", totalReferenceSumary, totalDecimals, 20);
										scew_element_set_contents(element, buf);
										totSumRef += totalReferenceSumary;

										element = scew_element_add(elementReference, "showCurrencyTot");
										scew_element_set_contents(element, "FALSE");
									}
								}
								[depositValueTypes freeContents];
								[depositValueTypes free];
							}

							if (totSumRef > 0) {
								// pongo el total de la moneda
								elementReference = scew_element_add(elementCimCash, "totalManualReference");
								element = scew_element_add(elementReference, "showCurrencyCode");
								scew_element_set_contents(element, "FALSE");
								element = scew_element_add(elementReference, "showReferenceName");
								scew_element_set_contents(element, "FALSE");
								element = scew_element_add(elementReference, "showReference");
								scew_element_set_contents(element, "FALSE");
								element = scew_element_add(elementReference, "showCurrencyTot");
								scew_element_set_contents(element, "TRUE");
								element = scew_element_add(elementReference, "totalCurrRef");
								formatMoney(buf, "", totSumRef, totalDecimals, 20);
								scew_element_set_contents(element, buf);
							}

							[references free];
						}
					}
					[currecies free];
				}

				if (referenceSumaries) [referenceSumaries free];

        // Obtengo la lista de monedas para mostrar los totales por cash
    		currecies = [anEntity getCurrencies: detailsByCimCash];
        for (iCurrency = 0; iCurrency < [currecies size]; ++iCurrency) {
            
            currency = [currecies at: iCurrency];
            
        		elementCurrency = scew_element_add(elementCimCash, "totalCurrency");
    
    				element = scew_element_add(elementCurrency, "totalCurrencyCode");
    				scew_element_set_contents(element, [currency getCurrencyCode]);
        		
    				element = scew_element_add(elementCurrency, "totalCurr");
    				formatMoney(buf, "", [anEntity getTotalAmountByCurreny: detailsByCimCash currency: currency], totalDecimals, 20);
    				scew_element_set_contents(element, buf);
        }
    
        [currecies free];
    		[detailsByCimCash free];    
      }
      
	}
	
	// No hay depositos para mostrar
	element = scew_element_add(elementCimCashs, "withOutValues");
	if ([cimCashs size] == 0)
    scew_element_set_contents(element, "TRUE");
  else
    scew_element_set_contents(element, "FALSE");	

	
	[cimCashs free];

  // Obtengo la lista de monedas para mostrar los totales por cash
	currecies = [anEntity getCurrencies: NULL];    	
  for (iCurrency = 0; iCurrency < [currecies size]; ++iCurrency) {
      
      currency = [currecies at: iCurrency];
      
      elementCurrency = scew_element_add(elementCimCashs, "totalCashCurrency");

			element = scew_element_add(elementCurrency, "totalCashCurrencyCode");
			scew_element_set_contents(element, [currency getCurrencyCode]);
  		
			element = scew_element_add(elementCurrency, "totalCashCurr");
			formatMoney(buf, "", [anEntity getTotalAmountByCurreny: NULL currency: currency], totalDecimals, 20);
			scew_element_set_contents(element, buf);
  }
  
  [currecies free];
/*
	<breakdown>
		<endOfDay>
			<number>xxxx</number>
			<date>ddddddd</date>
			<cashClose>
				<number>0001</number>
				<date>10/10/07</date>
				<cashCloseDetails>
					<cashCloseDetail>
						<currency>USD</currency>
						<amount>50.00</amount>
					</cashCloseDetail>
				</cashCloseDetails>
			</cashClose>
		</endOfDay>
	</breakdown>
*/

	// Muestro la lista de cashCloses
	elementBreakdown = scew_element_add(anElement, "breakdown");

	endOfDayList = [anEntity getEndOfDayNumbers];
	if ([endOfDayList size] > 0) {
		endOfDayNumber = [[endOfDayList at: 0] intValue];
		//doLog(0,"Cargando EndOfDay %ld\n", endOfDayNumber);
		if (endOfDayNumber != 0) {
			zClose = [[[Persistence getInstance] getZCloseDAO] loadById: endOfDayNumber];
			//if (zClose) 
			//	doLog(0,"FromDepositNumber = %ld, %ld\n", [zClose getFromDepositNumber], [anEntity getFromDepositNumber]);
			if (zClose && [zClose getFromDepositNumber] != [anEntity getFromDepositNumber])
				isPartial = TRUE;
		}
	}

	for (iEndOfDay = 0; iEndOfDay < [endOfDayList size]; iEndOfDay++) {

		endOfDayNumber = [[endOfDayList at: iEndOfDay] intValue];
		
		elementEndOfDay = scew_element_add(elementBreakdown, "endOfDay");

		// Numero de End of day
		element = scew_element_add(elementEndOfDay, "number");
		if (endOfDayNumber == 0) {
			sprintf(buf, "%05ld", [[ZCloseManager getInstance] getLastZNumber] + 1);
			strcat(buf, getResourceStringDef(RESID_NEXT_END_DAY, "S"));
		}
		else {
			sprintf(buf, "%05ld", endOfDayNumber);
			if (isPartial) strcat(buf, "P");
		}
		scew_element_set_contents(element, buf);

		// Fecha de cash close
		date = [anEntity getEndDayCloseTime: endOfDayNumber];
		if (date == 0 || endOfDayNumber == 0) {
			strcpy(dateStr, "");
		} else {
			convertTime(&date, &brokenTime);
			formatBrokenDate(dateStr, &brokenTime);
		}
		element = scew_element_add(elementEndOfDay, "date");
		scew_element_set_contents(element, dateStr);

		cashCloses = [anEntity getCashClosesForEndOfDay: endOfDayNumber];

		isPartial = FALSE;

		for (iCashClose = 0; iCashClose < [cashCloses size]; ++iCashClose) {
	
			cashClose = [cashCloses at: iCashClose];		
			elementCashClose = scew_element_add(elementEndOfDay, "cashClose");
	
			// Numero de cash close
			element = scew_element_add(elementCashClose, "number");
			if ([cashClose getNumber] == 0)
 			   sprintf(buf, "%s  ",getResourceStringDef(RESID_N_A, "N/D"));
			else 
  			   sprintf(buf, "%05ld", [cashClose getNumber]);
			scew_element_set_contents(element, buf);
	
			// Fecha de cash close
			date = [cashClose getCloseTime];
			if (date == 0) date = [SystemTime getLocalTime];
			convertTime(&date, &brokenTime);
			formatBrokenDate(dateStr, &brokenTime);
			element = scew_element_add(elementCashClose, "date");
			scew_element_set_contents(element, dateStr);
	
			elementCashCloseDetails = scew_element_add(elementCashClose, "cashCloseDetails");
	
			cashCloseDetails = [cashClose getZCloseDetails];
	
			// Genero un falso detalle con moneda vacia y monto 0 sino hay ningun detalle para que
			// en el reporte quede lindo
			if ([cashCloseDetails size] == 0) {

				elementCashCloseDetail = scew_element_add(elementCashCloseDetails, "cashCloseDetail");
	
				// Nombre del cash
				element = scew_element_add(elementCashCloseDetail, "cimCashName");
				scew_element_set_contents(element, [[cashClose getCimCash] getName]);
	
				// Currency
				element = scew_element_add(elementCashCloseDetail, "currencyCode");
				scew_element_set_contents(element, "");
	
				// Amount
				element = scew_element_add(elementCashCloseDetail, "amount");
				formatMoney(buf, "", 0, totalDecimals, 20);
				scew_element_set_contents(element, buf);

			} else {
			
				for (iCashCloseDetail = 0; iCashCloseDetail < [cashCloseDetails size]; ++iCashCloseDetail) {
		
					cashCloseDetail = [cashCloseDetails at: iCashCloseDetail];
					elementCashCloseDetail = scew_element_add(elementCashCloseDetails, "cashCloseDetail");
		
					// Nombre del cash
					element = scew_element_add(elementCashCloseDetail, "cimCashName");
					scew_element_set_contents(element, [[cashClose getCimCash] getName]);
		
					// Currency
					element = scew_element_add(elementCashCloseDetail, "currencyCode");
					scew_element_set_contents(element, [[cashCloseDetail getCurrency] getCurrencyCode]);
		
					// Amount
					element = scew_element_add(elementCashCloseDetail, "amount");
					formatMoney(buf, "", [cashCloseDetail getTotalAmount], totalDecimals, 20);
					scew_element_set_contents(element, buf);
		
				}
			}
		}
		[cashCloses free];
	}
	[endOfDayList freeContents];
	[endOfDayList free];

}

/**/
- (void) concatExtractionDetailInfo: (scew_element*) anElement entity: (id) anEntity isReprint: (BOOL) isReprint param: (CashReportParam *) aCashParam
{
	scew_element *element;
	scew_element *extractionDetailsElement;
	scew_element *extractionDetailElement;
	scew_element *elementCimCashs;
	scew_element *elementCimCash;
	scew_element *elementAcceptor;
	scew_element *elementAcceptorList;
	scew_element *elementCurrency;
	scew_element *elementCurrencyList;
	scew_element *elementCashClose;
	scew_element *elementCashCloseDetails;
	scew_element *elementBreakdown;
	scew_element *elementCashCloseDetail;
	scew_element *elementEndOfDay;
	EXTRACTION_DETAIL extractionDetail;
	int iCash, iAcceptor, iDetail, iCurrency, iCashClose, iCashCloseDetail, iEndOfDay;
	char buf[50], dateStr[50];
	int totalDecimals = [[AmountSettings getInstance] getTotalRoundDecimalQty];
	COLLECTION detailsByCimCash, detailsByAcceptor, detailsByCurrency;
	COLLECTION cimCashs, currecies, acceptorSettingsList;
	ACCEPTOR_SETTINGS acceptorSettings;
	CIM_CASH cimCash;
	CURRENCY currency;
	CIM_CASH cash;
	COLLECTION cashCloses;
	COLLECTION cashCloseDetails;
	ZCLOSE_DETAIL cashCloseDetail;
	ZCLOSE cashClose;
	datetime_t date;
	struct tm brokenTime;
	COLLECTION endOfDayList;
	unsigned long endOfDayNumber;
	ZCLOSE zClose;
	BOOL isPartial = FALSE;
	int envelopeQty;
	BOOL hasManualCimCash = FALSE;
	BOOL hasAutoCimCash = FALSE;

/*
	<cimcashs>
	 	<cimcash>
			<name>VERIFIED CASH BOX</name>	
				<acceptor>	
					<acceptorName>VALIDADOR xxx</acceptorName>
					<currency>
						<currencyCode>ARS</currencyCode>
						<qty>10</qty>
						<total>50.00</total>
						<extractionDetails>
							<extractionDetail>...</extractionDetail>
							<extractionDetail>...</extractionDetail>
							<extractionDetail>...</extractionDetail>
						</extractionDetails>
					</currency>
					<currency>
						<currencyCode>USD</currencyCode>
						<qty>10</qty>
						<total>50.00</total>
						<extractionDetails>
							<extractionDetail>...</extractionDetail>
							<extractionDetail>...</extractionDetail>
							<extractionDetail>...</extractionDetail>
						</extractionDetails>
					</currency>			
				</acceptor>

				<currency>
						<currencyCode>ARS</currencyCode>
						<total>50.00</total>
				</currency>
				
		</cimcash>
	</cimcashs>
	<currency>
			<currencyCode>ARS</currencyCode>
			<total>50.00</total>
	</currency>	

	<breakdown>
		<endOfDay>
			<number>xxxx</number>
			<date>ddddddd</date>
			<cashClose>
				<number>0001</number>
				<date>10/10/07</date>
				<cashCloseDetails>
					<cashCloseDetail>
						<currency>USD</currency>
						<amount>50.00</amount>
					</cashCloseDetail>
				</cashCloseDetails>
			</cashClose>
		</endOfDay>
	</breakdown>

*/
	elementCimCashs = scew_element_add(anElement, "cimCashs");

	// Obtengo la lista de cashs
	cimCashs = [anEntity getCimCashs: NULL];
  
  // Si cash != NULL muestro solo esa cash 
  // en caso contrario muestro todas las del door seleccionado
  cash = NULL;
  if (aCashParam != NULL)
    if (aCashParam->cash != NULL)
       cash = aCashParam->cash;

  
  // Recorro la lista de cashs
	for (iCash = 0; iCash < [cimCashs size]; ++iCash) {

		cimCash = [cimCashs at: iCash];
		
		if ([cimCash getDepositType] == DepositType_MANUAL) hasManualCimCash = TRUE;
		if ([cimCash getDepositType] == DepositType_AUTO) hasAutoCimCash = TRUE;

		if ( (cash == NULL) || ((cash != NULL) && ([cash getCimCashId] == [cimCash getCimCashId])) ){
    		// Nombre de la caja
    		elementCimCash = scew_element_add(elementCimCashs, "cimCash");
    		element = scew_element_add(elementCimCash, "name");
    		scew_element_set_contents(element, [cimCash getName]);
    
    		// Tipo de caja (automatica / manual)
    		element = scew_element_add(elementCimCash, "cimCashType");
    		sprintf(buf, "%d", [cimCash getDepositType]);
    		scew_element_set_contents(element, buf);

				// obtengo la cantidad de sobres en el acceptor manual
				envelopeQty = 0;
				if ([cimCash getDepositType] == DepositType_MANUAL) {

	  			envelopeQty = [[DepositDetailReport getInstance] getTicketsCountByDepositType: [anEntity getFromDepositNumber]
						toDepositNumber: [anEntity getToDepositNumber] depositType: DepositType_MANUAL];

				}
    		element = scew_element_add(elementCimCash, "envelopeQty");
    		sprintf(buf, "%d", envelopeQty);
    		scew_element_set_contents(element, buf);
    
    		// Obtengo los depositos para el cash actual
    		detailsByCimCash = [anEntity getDetailsByCimCash: NULL cimCash: cimCash];
    
    		// Obtengo la lista  de validadores
    		acceptorSettingsList = [anEntity getAcceptorSettingsList: detailsByCimCash];
    		
    		elementAcceptorList = scew_element_add(elementCimCash, "acceptorList");
    
    		// Recorro la lista de validadores
    		for (iAcceptor = 0; iAcceptor < [acceptorSettingsList size]; ++iAcceptor) {
    
    			acceptorSettings = [acceptorSettingsList at: iAcceptor];
    			elementAcceptor = scew_element_add(elementAcceptorList, "acceptor");
    
    			// Nombre del aceptador
    			element = scew_element_add(elementAcceptor, "acceptorName");
    			scew_element_set_contents(element, [acceptorSettings getAcceptorName]);
    	
    			// Obtengo la lista de detalles para el validador en curso
    			detailsByAcceptor = [anEntity getDetailsByAcceptorSettings: detailsByCimCash acceptorSettings: acceptorSettings];
    
    			// Obtengo la lista de monedas
    			currecies = [anEntity getCurrencies: detailsByAcceptor];
    
    			elementCurrencyList = scew_element_add(elementAcceptor, "currencyList");
    
    			// Recorro la lista de monedas
    			for (iCurrency = 0; iCurrency < [currecies size]; ++iCurrency) {
    
    				currency = [currecies at: iCurrency];
    				detailsByCurrency = [anEntity getDetailsByCurrency: detailsByAcceptor currency: currency];
    
    				elementCurrency = scew_element_add(elementCurrencyList, "currency");
    
    				element = scew_element_add(elementCurrency, "currencyCode");
    				scew_element_set_contents(element, [currency getCurrencyCode]);
    
    				element = scew_element_add(elementCurrency, "qty");
    				sprintf(buf, "%04d", [anEntity getQty: detailsByCurrency]);
    				scew_element_set_contents(element, buf);
    		
    				element = scew_element_add(elementCurrency, "total");
    				formatMoney(buf, "", [anEntity getTotalAmount: detailsByCurrency], totalDecimals, 20);
    				scew_element_set_contents(element, buf);            
    		
    				extractionDetailsElement = scew_element_add(elementCurrency, "extractionDetails");
    			
    				for (iDetail = 0; iDetail < [detailsByCurrency size]; ++iDetail) {
    			
    					extractionDetail = [detailsByCurrency at: iDetail];
    					extractionDetailElement = scew_element_add(extractionDetailsElement, "extractionDetail");
    		
    					// Cantidad
    					element = scew_element_add(extractionDetailElement, "qty");
    					sprintf(buf, "%04d" , [extractionDetail getQty]);
    					scew_element_set_contents(element, buf);
    			
    					// Importe
    					element = scew_element_add(extractionDetailElement, "amount");
							if ([extractionDetail isUnknownBill]) stringcpy(buf, getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
							else formatMoney(buf, "", [extractionDetail getAmount], totalDecimals, 20);
    					scew_element_set_contents(element, buf);
    			
    					// Total
    					element = scew_element_add(extractionDetailElement, "totalAmount");
    					if ([extractionDetail isUnknownBill]) stringcpy(buf, getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
							else formatMoney(buf, "", [extractionDetail getTotalAmount], totalDecimals, 20);
    					scew_element_set_contents(element, buf);
    
    					// Nombre del tipo de valor
    					element = scew_element_add(extractionDetailElement, "depositValueName");
    					scew_element_set_contents(element, [extractionDetail getDepositValueName]);
    			
    				}
    				[detailsByCurrency free];
    			}
    			[currecies free];
    			[detailsByAcceptor free];
    		} 
    
    		[acceptorSettingsList free];
    
        // Obtengo la lista de monedas para mostrar los totales por cash
    		currecies = [anEntity getCurrencies: detailsByCimCash];
        for (iCurrency = 0; iCurrency < [currecies size]; ++iCurrency) {
            
            currency = [currecies at: iCurrency];
            
        		elementCurrency = scew_element_add(elementCimCash, "totalCurrency");
    
    				element = scew_element_add(elementCurrency, "totalCurrencyCode");
    				scew_element_set_contents(element, [currency getCurrencyCode]);
        		
    				element = scew_element_add(elementCurrency, "totalCurr");
    				formatMoney(buf, "", [anEntity getTotalAmountByCurreny: detailsByCimCash currency: currency], totalDecimals, 20);
    				scew_element_set_contents(element, buf);        
        }

        [currecies free];
    		[detailsByCimCash free];    
      }
	}
	
	// No hay depositos para mostrar
	element = scew_element_add(elementCimCashs, "withOutValues");
	if ([cimCashs size] == 0)
    scew_element_set_contents(element, "TRUE");
  else
    scew_element_set_contents(element, "FALSE");	

	// Hay cash manuales
	element = scew_element_add(elementCimCashs, "hasManualCash");
	if (hasManualCimCash)
    scew_element_set_contents(element, "TRUE");
  else
    scew_element_set_contents(element, "FALSE");	

	// Hay cash auto
	element = scew_element_add(elementCimCashs, "hasAutoCash");
	if (hasAutoCimCash)
    scew_element_set_contents(element, "TRUE");
  else
    scew_element_set_contents(element, "FALSE");	

	
	[cimCashs free];

  // Obtengo la lista de monedas para mostrar los totales por cash
	currecies = [anEntity getCurrencies: NULL];    	
  for (iCurrency = 0; iCurrency < [currecies size]; ++iCurrency) {
      
      currency = [currecies at: iCurrency];
      
      elementCurrency = scew_element_add(elementCimCashs, "totalCashCurrency");

			element = scew_element_add(elementCurrency, "totalCashCurrencyCode");
			scew_element_set_contents(element, [currency getCurrencyCode]);
  		
			element = scew_element_add(elementCurrency, "totalCashCurr");
			formatMoney(buf, "", [anEntity getTotalAmountByCurreny: NULL currency: currency], totalDecimals, 20);
			scew_element_set_contents(element, buf);
  }
  
  [currecies free];
/*
	<breakdown>
		<endOfDay>
			<number>xxxx</number>
			<date>ddddddd</date>
			<cashClose>
				<number>0001</number>
				<date>10/10/07</date>
				<cashCloseDetails>
					<cashCloseDetail>
						<currency>USD</currency>
						<amount>50.00</amount>
					</cashCloseDetail>
				</cashCloseDetails>
			</cashClose>
		</endOfDay>
	</breakdown>
*/

	// Muestro la lista de cashCloses
	elementBreakdown = scew_element_add(anElement, "breakdown");

	endOfDayList = [anEntity getEndOfDayNumbers];
	if ([endOfDayList size] > 0) {
		endOfDayNumber = [[endOfDayList at: 0] intValue];
		//doLog(0,"Cargando EndOfDay %ld\n", endOfDayNumber);
		if (endOfDayNumber != 0) {
			zClose = [[[Persistence getInstance] getZCloseDAO] loadById: endOfDayNumber];
			//if (zClose) 
				//doLog(0,"FromDepositNumber = %ld, %ld\n", [zClose getFromDepositNumber], [anEntity getFromDepositNumber]);
			if (zClose && [zClose getFromDepositNumber] != [anEntity getFromDepositNumber])
				isPartial = TRUE;
		}
	}

	for (iEndOfDay = 0; iEndOfDay < [endOfDayList size]; iEndOfDay++) {

		endOfDayNumber = [[endOfDayList at: iEndOfDay] intValue];
		
		elementEndOfDay = scew_element_add(elementBreakdown, "endOfDay");

		// Numero de End of day
		element = scew_element_add(elementEndOfDay, "number");
		if (endOfDayNumber == 0) {
			sprintf(buf, "%05ld", [[ZCloseManager getInstance] getLastZNumber] + 1);
			strcat(buf, getResourceStringDef(RESID_NEXT_END_DAY, "S"));
		}
		else {
			sprintf(buf, "%05ld", endOfDayNumber);
			if (isPartial) strcat(buf, "P");
		}
		scew_element_set_contents(element, buf);

		// Fecha de cash close
		date = [anEntity getEndDayCloseTime: endOfDayNumber];
		if (date == 0 || endOfDayNumber == 0) {
			strcpy(dateStr, "");
		} else {
			convertTime(&date, &brokenTime);
			formatBrokenDate(dateStr, &brokenTime);
		}
		element = scew_element_add(elementEndOfDay, "date");
		scew_element_set_contents(element, dateStr);

		cashCloses = [anEntity getCashClosesForEndOfDay: endOfDayNumber];

		isPartial = FALSE;

		for (iCashClose = 0; iCashClose < [cashCloses size]; ++iCashClose) {
	
			cashClose = [cashCloses at: iCashClose];		
			elementCashClose = scew_element_add(elementEndOfDay, "cashClose");
	
			// Numero de cash close
			element = scew_element_add(elementCashClose, "number");
			if ([cashClose getNumber] == 0)
 			   sprintf(buf, "%s  ",getResourceStringDef(RESID_N_A, "N/D"));
			else 
  			   sprintf(buf, "%05ld", [cashClose getNumber]);
			scew_element_set_contents(element, buf);
	
			// Fecha de cash close
			date = [cashClose getCloseTime];
			if (date == 0) date = [SystemTime getLocalTime];
			convertTime(&date, &brokenTime);
			formatBrokenDate(dateStr, &brokenTime);
			element = scew_element_add(elementCashClose, "date");
			scew_element_set_contents(element, dateStr);
	
			elementCashCloseDetails = scew_element_add(elementCashClose, "cashCloseDetails");
	
			cashCloseDetails = [cashClose getZCloseDetails];
	
			// Genero un falso detalle con moneda vacia y monto 0 sino hay ningun detalle para que
			// en el reporte quede lindo
			if ([cashCloseDetails size] == 0) {

				elementCashCloseDetail = scew_element_add(elementCashCloseDetails, "cashCloseDetail");
	
				// Nombre del cash
				element = scew_element_add(elementCashCloseDetail, "cimCashName");
				scew_element_set_contents(element, [[cashClose getCimCash] getName]);
	
				// Currency
				element = scew_element_add(elementCashCloseDetail, "currencyCode");
				scew_element_set_contents(element, "");
	
				// Amount
				element = scew_element_add(elementCashCloseDetail, "amount");
				formatMoney(buf, "", 0, totalDecimals, 20);
				scew_element_set_contents(element, buf);

			} else {
			
				for (iCashCloseDetail = 0; iCashCloseDetail < [cashCloseDetails size]; ++iCashCloseDetail) {
		
					cashCloseDetail = [cashCloseDetails at: iCashCloseDetail];
					elementCashCloseDetail = scew_element_add(elementCashCloseDetails, "cashCloseDetail");
		
					// Nombre del cash
					element = scew_element_add(elementCashCloseDetail, "cimCashName");
					scew_element_set_contents(element, [[cashClose getCimCash] getName]);
		
					// Currency
					element = scew_element_add(elementCashCloseDetail, "currencyCode");
					scew_element_set_contents(element, [[cashCloseDetail getCurrency] getCurrencyCode]);
		
					// Amount
					element = scew_element_add(elementCashCloseDetail, "amount");
					formatMoney(buf, "", [cashCloseDetail getTotalAmount], totalDecimals, 20);
					scew_element_set_contents(element, buf);
		
				}
			}
		}
		[cashCloses free];
	}
	[endOfDayList freeContents];
	[endOfDayList free];

}


/**/
- (void) buildExtractionXML: (id) anEntity isReprint: (BOOL) isReprint tree: (scew_tree*) tree param: (void *) aParam
{
  scew_element* root = NULL;

  root = scew_tree_add_root(tree, "extraction");

  //Informacion generalInfo
  [self concatExtractionGeneralInfo: root entity: anEntity isReprint: isReprint param: (CashReportParam*)aParam];

  //Datos de total
  [self concatExtractionDetailInfo: root entity: anEntity isReprint: isReprint param: (CashReportParam*)aParam];

}

/**/
- (void) buildTransBoxModeExtractionXML: (id) anEntity isReprint: (BOOL) isReprint tree: (scew_tree*) tree param: (void *) aParam
{
  scew_element* root = NULL;

  root = scew_tree_add_root(tree, "transBoxModeExtraction");

  //Informacion generalInfo
  [self concatExtractionGeneralInfo: root entity: anEntity isReprint: isReprint param: (CashReportParam*)aParam];

  //Datos de total
  [self concatTransBoxModeExtractionDetailInfo: root entity: anEntity isReprint: isReprint param: (CashReportParam*)aParam];

}


/*************************************************
*
* Archivo XML de CASH REFERENCE
*
*************************************************/

/**/
- (void) concatCashReferenceGeneralInfo: (scew_element*) anElement 
	entity: (id) anEntity 
	isReprint: (BOOL) isReprint
	param: (CashReferenceReportParam *) aCashReferenceParam
{
  scew_element* generalInfo = NULL;
  scew_element* element = NULL;
  datetime_t date;
  char dateStr[50];
  struct tm brokenTime;
  char buf[50];
  char mSymbol[4];
	unsigned long auditNumber = 0;
  datetime_t auditDateTime = 0;
  BOOL includeDetails = FALSE;

  strcpy(mSymbol, [[RegionalSettings getInstance] getMoneySymbol]);

	generalInfo = scew_element_add(anElement, "generalInfo");
	[self concatGeneralInfo: generalInfo isReprint: isReprint];

	auditNumber = aCashReferenceParam->auditNumber;
	auditDateTime = aCashReferenceParam->auditDateTime;
	includeDetails = aCashReferenceParam->includeDetails;

  // Fecha / hora de la apertura
  date = [anEntity getOpenTime];
	convertTime(&date, &brokenTime);
 	formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "openTime");
  scew_element_set_contents(element, dateStr);

  // Numero de extraccion Z
  element = scew_element_add(generalInfo, "number");
  sprintf(buf, "%08ld", [anEntity getNumber]);
  scew_element_set_contents(element, buf);
  
  // Numero de transaccion (auditoria)
  element = scew_element_add(generalInfo, "trans");
  sprintf(buf, "%08ld", auditNumber);
  scew_element_set_contents(element, buf);

  // Fecha de transaccion (auditoria)
	convertTime(&auditDateTime, &brokenTime);
  formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "transTime");
  scew_element_set_contents(element, dateStr);

  // Cash reference listado
	element = scew_element_add(generalInfo, "cashReferenceFilter");
	if (aCashReferenceParam->cashReference == NULL) {
 		scew_element_set_contents(element, getResourceStringDef(RESID_ALL_LABEL, "Todas"));
	} else {
		scew_element_set_contents(element, [aCashReferenceParam->cashReference getName]);
	}
 
  // Numero de extraccion Z anterior
  element = scew_element_add(generalInfo, "lastZ");
  sprintf(buf, "%08ld", [[[Persistence getInstance] getZCloseDAO] getLastZCloseNumber]);
  scew_element_set_contents(element, buf);

  // Detallado ?
  element = scew_element_add(generalInfo, "detailReport");
  if (includeDetails)
    scew_element_set_contents(element, "TRUE");
  else
    scew_element_set_contents(element, "FALSE");

}


/**/
- (void) concatCashReferenceDetailInfo: (scew_element*) anElement 
	entity: (id) anEntity 
	isReprint: (BOOL) isReprint
	param: (CashReferenceReportParam *) aCashReferenceParam
{
	scew_element *element;
	scew_element *elementCurrency;
	scew_element *elementCurrencyList;
	scew_element *elementCashReferenceList;
	scew_element *elementCashReference;
	scew_element *manualDropDetailElement;	
	CASH_REFERENCE_SUMMARY cashReferenceSummary;
	COLLECTION cashReferenceSummaries, cashReferences, currecies;
	CASH_REFERENCE cashReference;
	CASH_REFERENCE cashReferenceAux;
	int iCashReferenceSummary, iCashReference, iCurrency;
	char buf[50];
	int totalDecimals = [[AmountSettings getInstance] getTotalRoundDecimalQty];
	char cashReferenceName[290];
	char newName[300];
	char *p, *q;
	CURRENCY currency;
	ReportDetailItem *item;
	static char *depositValueTypeStr[] = {"UK", "CS", "CS", "CH", "TC", "CC", "OT", "BK"};
	COLLECTION details = NULL;
	money_t amount;
	int i, currencyId;
	CIM_CASH cimCash;
	CIM_MANAGER cimManager;
	money_t totalMoney;
	BOOL hasData = FALSE;


	money_t referenceAmountVal;
	money_t referenceAmountManual;
	int referenceManQty;

	money_t totalRefAmountVal;
	money_t totalRefAmountManual;
	int referenceTotalManQty;
	

/*
	<cashReferenceList>
		<cashReference>
			<cashReferenceName>PPPPP</cashReferenceName>
			<currencyList>
				<currency>
					<currencyCode>ARS</currencyCode>
					<amount>20.34</amount>
				</currency>
		</cashReference>
	</cashReferenceList>
*/

	
	cashReferences = [anEntity getCashReferences];
	elementCashReferenceList = scew_element_add(anElement, "cashReferenceList");
	
	// cargo el cash reference que selecciono el usuario
  cashReferenceAux = aCashReferenceParam->cashReference;	

	for (iCashReference = 0; iCashReference < [cashReferences size]; ++iCashReference) {

		cashReference = [cashReferences at: iCashReference];
    
    if ( (cashReferenceAux == NULL) || ((cashReferenceAux != NULL) && ([cashReferenceAux getCashReferenceId] == [cashReference getCashReferenceId])) ){    
        elementCashReference = scew_element_add(elementCashReferenceList, "cashReference");
    		
    		element = scew_element_add(elementCashReference, "cashReferenceName");
    		strcpy(cashReferenceName, "");
    		[cashReference getCompleteName: cashReferenceName];
    		
    		p = cashReferenceName;
    		q = newName;
    
    		//// PPPPPPPPPPPPPPPPPPPPPPPPPPPPPrrrrrrrrrrrrrrrrrrrr
    		//// QQQQQQQQQQQQQQQQQQQQQQQQQQQQQn
    		///  0123456789012345678901234567890123456789
    		while (strlen(p) > 24) {
    			strncpy(q, p, 24);
    			q[24] = '\n';
    			p += 24;
    			q += 25;
    		}
    
    		strcpy(q, p);
    
    		scew_element_set_contents(element, newName);
    
    		cashReferenceSummaries = [anEntity getCashReferenceSummaries: cashReference];
    
    		// Obtengo la lista de monedas
    		elementCurrencyList = scew_element_add(elementCashReference, "currencyList");
    		
    		//************* Resumido ***************************
    		if (!aCashReferenceParam->includeDetails) {



          // Recorro la lista de monedas
/*
      		for (iCashReferenceSummary = 0; iCashReferenceSummary < [cashReferenceSummaries size]; ++iCashReferenceSummary) {
      	
      			hasData = TRUE;
            
            cashReferenceSummary = [cashReferenceSummaries at: iCashReferenceSummary];
      						
      			elementCurrency = scew_element_add(elementCurrencyList, "currency");
      	
      			element = scew_element_add(elementCurrency, "currencyCode");
      			scew_element_set_contents(element, [[cashReferenceSummary getCurrency] getCurrencyCode]);
      	
      			element = scew_element_add(elementCurrency, "amount");
      			formatMoney(buf, "", [cashReferenceSummary getAmount], totalDecimals, 20);
      			scew_element_set_contents(element, buf); 
					}
*/


						///IMPLEMENTACION DE DETALLE POR DEPOSIT VALUE TYPE (VAL/MANUAL)


						totalRefAmountVal;
						totalRefAmountManual;
						referenceTotalManQty;

          	details = [[DepositDetailReport getInstance] generateDepositDetailReport: [anEntity getFromDepositNumber]
            	toDepositNumber: [anEntity getToDepositNumber]
            	referenceId: [cashReference getCashReferenceId]];

						currencyId = 0;
          	elementCurrency = NULL;
	
						i = 0;	        


						if ([details size] > 0) { 
							hasData = TRUE;
							item = (ReportDetailItem *)[details at: i];
						}

//					doLog(0,"i: %d\n", i);
//					doLog(0,"Cantidad de detalles: %d\n", [details size]);
	
						while (i<[details size]) {
 	  	      
							currencyId = item->currencyId;

							referenceAmountVal = 0;
							referenceAmountManual = 0;
							referenceManQty = 0;
							
//						doLog(0,"CurrencyId: %d\n", currencyId);	
							
							while (item->currencyId == currencyId) {

								if (item->depositType == DepositType_MANUAL) {
									referenceAmountManual += item->amount;
									referenceManQty += 1;

								} else {
									referenceAmountVal += item->amount;
								}
								
								++i;

								if (i<[details size]) {
									item = (ReportDetailItem *)[details at: i];

									//doLog(0,"i2: %d\n", i);		
									//doLog(0,"item->currencyId: %d\n", item->currencyId);									
								} else break;
							}

							// 
          		elementCurrency = scew_element_add(elementCurrencyList, "currency");	
              element = scew_element_add(elementCurrency, "currencyCode");
          		currency = [[CurrencyManager getInstance] getCurrencyById: currencyId];
              scew_element_set_contents(element, [currency getCurrencyCode]);

		      		element = scew_element_add(elementCurrency, "referenceAmountVal");
    		  		formatMoney(buf, "", referenceAmountVal, totalDecimals, 20);
      				scew_element_set_contents(element, buf);

		      		element = scew_element_add(elementCurrency, "referenceAmountManual");
    		  		formatMoney(buf, "", referenceAmountManual, totalDecimals, 20);
      				scew_element_set_contents(element, buf);

    					element = scew_element_add(elementCurrency, "referenceManQty");
    					sprintf(buf, "%d", referenceManQty);
    					scew_element_set_contents(element, buf);


							totalRefAmountVal += referenceAmountVal; 
							totalRefAmountManual += referenceAmountManual;
							referenceTotalManQty += referenceManQty;
		
						}
							
							
					}

/*********************************/
/*
         	 // Obtengo el detalle
          	details = [[DepositDetailReport getInstance] generateDepositDetailReport: [anEntity getFromDepositNumber]
            	toDepositNumber: [anEntity getToDepositNumber]
            	referenceId: [cashReference getCashReferenceId]];
          
          	elementCurrency = NULL;
          
	          for (i = 0; i < [details size]; ++i) {
  	          item = (ReportDetailItem *)[details at: i];
            
    	        hasData = TRUE;



			
      	      // Si cambio la moneda tengo que generar otro
        	    if (item->currencyId != currencyId) {
              
              if (currencyId != 0) {
            		
                // Importe
                element = scew_element_add(elementCurrency, "total");
          			formatMoney(buf, "", amount, totalDecimals, 20);
          			scew_element_set_contents(element, buf);
          			amount = 0;
          	
              }
              
          		elementCurrency = scew_element_add(elementCurrencyList, "currency");	
              element = scew_element_add(elementCurrency, "currencyCode");
          		currency = [[CurrencyManager getInstance] getCurrencyById: item->currencyId];
              scew_element_set_contents(element, [currency getCurrencyCode]);
              
              currencyId = item->currencyId;  
            }
            
            amount += item->amount;
          	
            manualDropDetailElement = scew_element_add(elementCurrency, "detail");
        
        		// Total
        		element = scew_element_add(manualDropDetailElement, "totalAmount");
        		formatMoney(buf, "", item->amount, totalDecimals, 20);
        		scew_element_set_contents(element, buf);
        
        		// Nombre del tipo de valor
        		element = scew_element_add(manualDropDetailElement, "depositValueName");
        		scew_element_set_contents(element, depositValueTypeStr[item->depositValueType]);
        
        		// Nombre del cash
        		element = scew_element_add(manualDropDetailElement, "cimCashName"); 
            cimCash = [cimManager getCimCashById: item->cimCashId];
        		scew_element_set_contents(element, [cimCash getName]);
          
            // Numero de deposito (solo los 5 ultimos numeros)
        		element = scew_element_add(manualDropDetailElement, "depositNumber");
        		sprintf(buf, "%c%05ld", item->depositType == DepositType_MANUAL ? 'M' : 'V', item->number % 100000); 
        		scew_element_set_contents(element, buf);
        
          }
          
          if (currencyId != 0) {
            // Importe
        		element = scew_element_add(elementCurrency, "total");
        		formatMoney(buf, "", amount, totalDecimals, 20);
        		scew_element_set_contents(element, buf);
          }
        
          [details freePointers];
          [details free];
						

      	
      		}
    		}
*/
/****************************************/


    		
        //********************** Detallado ***************************
        if (aCashReferenceParam->includeDetails) {
          cimManager = [CimManager getInstance];
          currencyId = 0;

          // Obtengo el detalle
          details = [[DepositDetailReport getInstance] generateDepositDetailReport: [anEntity getFromDepositNumber]
            toDepositNumber: [anEntity getToDepositNumber]
            referenceId: [cashReference getCashReferenceId]];
          
          amount = 0;
          elementCurrency = NULL;
          
          for (i = 0; i < [details size]; ++i) {
            item = (ReportDetailItem *)[details at: i];
            
            hasData = TRUE;
            
            // Si cambio la moneda tengo que generar otro
            if (item->currencyId != currencyId) {
              
              if (currencyId != 0) {
            		
                // Importe
                element = scew_element_add(elementCurrency, "total");
          			formatMoney(buf, "", amount, totalDecimals, 20);
          			scew_element_set_contents(element, buf);
          			amount = 0;
          	
              }
              
          		elementCurrency = scew_element_add(elementCurrencyList, "currency");	
              element = scew_element_add(elementCurrency, "currencyCode");
          		currency = [[CurrencyManager getInstance] getCurrencyById: item->currencyId];
              scew_element_set_contents(element, [currency getCurrencyCode]);
              
              currencyId = item->currencyId;  
            }
            
            amount += item->amount;
          	
            manualDropDetailElement = scew_element_add(elementCurrency, "detail");
        
        		// Total
        		element = scew_element_add(manualDropDetailElement, "totalAmount");
        		formatMoney(buf, "", item->amount, totalDecimals, 20);
        		scew_element_set_contents(element, buf);
        
        		// Nombre del tipo de valor
        		element = scew_element_add(manualDropDetailElement, "depositValueName");
        		scew_element_set_contents(element, depositValueTypeStr[item->depositValueType]);
        
        		// Nombre del cash
        		element = scew_element_add(manualDropDetailElement, "cimCashName"); 
            cimCash = [cimManager getCimCashById: item->cimCashId];
        		scew_element_set_contents(element, [cimCash getName]);
          
            // Numero de deposito (solo los 5 ultimos numeros)
        		element = scew_element_add(manualDropDetailElement, "depositNumber");
        		sprintf(buf, "%c%05ld", item->depositType == DepositType_MANUAL ? 'M' : 'V', item->number % 100000); 
        		scew_element_set_contents(element, buf);
        
          }
          
          if (currencyId != 0) {
            // Importe
        		element = scew_element_add(elementCurrency, "total");
        		formatMoney(buf, "", amount, totalDecimals, 20);
        		scew_element_set_contents(element, buf);
          }
        
          [details freePointers];
          [details free];
        }
        
		    [cashReferenceSummaries free];        		
		}
		
	}

	// No hay depositos para mostrar
	element = scew_element_add(elementCashReferenceList, "withOutValues");
	if (!hasData)
    scew_element_set_contents(element, "TRUE");
  else
    scew_element_set_contents(element, "FALSE");

	[cashReferences free];
	
  // Obtengo la lista de monedas para mostrar los totales por cash
	currecies = [anEntity getCurrencies: NULL];    	
  for (iCurrency = 0; iCurrency < [currecies size]; ++iCurrency) {
      
      currency = [currecies at: iCurrency];
      
      totalMoney = [anEntity getCashReferenceTotalAmountByCurreny: NULL currency: currency reference: cashReferenceAux totalManual: &totalRefAmountManual totalVal: &totalRefAmountVal manualQty: &referenceTotalManQty];
      
      if (totalMoney > 0){
        elementCurrency = scew_element_add(elementCashReferenceList, "totalCashCurrency");
  
  			element = scew_element_add(elementCurrency, "totalCashCurrencyCode");
  			scew_element_set_contents(element, [currency getCurrencyCode]);
    		
  			element = scew_element_add(elementCurrency, "totalCashCurr");
        formatMoney(buf, "", totalMoney, totalDecimals, 20);
  			scew_element_set_contents(element, buf);

  			element = scew_element_add(elementCurrency, "totalCashVal");
        formatMoney(buf, "", totalRefAmountVal, totalDecimals, 20);
  			scew_element_set_contents(element, buf);

  			element = scew_element_add(elementCurrency, "totalCashManual");
        formatMoney(buf, "", totalRefAmountManual, totalDecimals, 20);
  			scew_element_set_contents(element, buf);

  			element = scew_element_add(elementCurrency, "totalCashManQty");
				sprintf(buf, "%d", referenceTotalManQty);
  			scew_element_set_contents(element, buf);
			}
  }
  
  [currecies free];	
     
}


/**/
- (void) buildCashReferenceXML: (id) anEntity isReprint: (BOOL) isReprint tree: (scew_tree*) tree param: (void *) aParam
{
  scew_element* root = NULL;

  root = scew_tree_add_root(tree, "cashReferenceReport");

  //Informacion generalInfo
  [self concatCashReferenceGeneralInfo: root entity: anEntity isReprint: isReprint param: (CashReferenceReportParam*)aParam];

  //Datos de total
  [self concatCashReferenceDetailInfo: root entity: anEntity isReprint: isReprint param: (CashReferenceReportParam*)aParam];

}

/**/
- (void) concatRepairOrderReportInfo: (scew_element*) anElement entity: (id) anEntity isReprint: (BOOL) isReprint param: (void*) aCashReferenceParam
{
	scew_element* repairOrder = NULL;
	scew_element* element = NULL;
	datetime_t date; 
  char dateStr[50];
  struct tm brokenTime;
	id user;
	char buf[50];
	id orderItemList;
	char fileName[200];
	char contactTel[50];
	FILE *f;


	orderItemList = [anEntity getRepairOrderItemList];

	repairOrder = scew_element_add(anElement, "repairOrderInfo");
  element = scew_element_add(repairOrder, "State");

	if ([anEntity getRepairOrderState] == RepairOrderState_ERROR) {
		scew_element_set_contents(element, "ERROR");
  	element = scew_element_add(repairOrder, "StateDsc");
		scew_element_set_contents(element, getResourceStringDef(RESID_REPAIR_ORDER_ERROR, "ERROR EN ENVIO DE ORDEN"));
	}

	if ([anEntity getRepairOrderState] == RepairOrderState_OK) {
		scew_element_set_contents(element, "OK");
  	element = scew_element_add(repairOrder, "StateDsc");
		scew_element_set_contents(element, getResourceStringDef(RESID_REPAIR_ORDER_OK, "ENVIO DE ORDEN EXITOSO"));

		date = [anEntity getDateTime];
		convertTime(&date, &brokenTime);
		formatBrokenDateTime(dateStr, &brokenTime);
		element = scew_element_add(repairOrder, "DateTime");
		scew_element_set_contents(element, dateStr);

		element = scew_element_add(repairOrder, "OrderNumber");  
		scew_element_set_contents(element, [anEntity getRepairOrderNumber]);

	  element = scew_element_add(repairOrder, "Repair");  
		stringcpy(buf, [[orderItemList at: 0] getItemDescription]);
		buf[20] = '\0';
		scew_element_set_contents(element, buf);
		
		element = scew_element_add(repairOrder, "Priority");
		stringcpy(buf, getResourceString(RESID_REPAIR_ORDER_PRIORITY + [anEntity getPriority]));
		scew_element_set_contents(element, buf);

		element = scew_element_add(repairOrder, "Contact");    
		scew_element_set_contents(element, [anEntity getTelephoneNumber]);

		element = scew_element_add(repairOrder, "User");  
		user = [[UserManager getInstance] getUser: [anEntity getUserId]];
		strcpy(buf, user != NULL ? [user str] : getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
		buf[17] = '\0';
  	scew_element_set_contents(element, buf);

		strcpy(fileName, "supportContact.txt");

		f = fopen(fileName, "r");
		if (!f) {
			//doLog(0,"Error al abrir el archivo de contacto de soporte: %s\n", fileName);
			stringcpy(buf, "");
		} else {
			fscanf(f, "%s", contactTel);
			stringcpy(buf, contactTel);	
			fclose(f);
		}

		element = scew_element_add(repairOrder, "SupportContact");
    scew_element_set_contents(element, buf);
	}
}


/**/
- (void) buildRepairOrderReoportXML: (id) anEntity isReprint: (BOOL) isReprint tree: (scew_tree*) tree param: (void*) aParam
{
  scew_element* root = NULL;

  root = scew_tree_add_root(tree, "repairOrderReport");

  [self concatRepairOrderReportInfo: root entity: anEntity isReprint: isReprint param: aParam];
}

/**/
- (scew_tree*) buildXML: (id) anEntity entityType: (int) anEntityType isReprint: (BOOL) isReprint
{
  return [self buildXML: anEntity entityType: anEntityType isReprint: isReprint varEntity: NULL];
}

/* Sobrecarga del metodo
 * se agrego el campo varEntity de tipo ID para utilizar con lo que se quiera
 */
- (scew_tree*) buildXML: (id) anEntity entityType: (int) anEntityType isReprint: (BOOL) isReprint varEntity: (void *) aVarEntity
{
	scew_tree* tree;

	tree = scew_tree_create();

  	switch ( anEntityType ) {

		case DEPOSIT_PRT:
			[self buildDepositXML: anEntity isReprint: isReprint tree: tree isManualDropReceipt: FALSE param: aVarEntity];

#ifdef __DEBUG_XML
			scew_writer_tree_file(tree, BASE_VAR_PATH "/deposit.xml");
#endif

			return tree;

		case MANUAL_DEPOSIT_RECEIPT_PRT:
			[self buildDepositXML: anEntity isReprint: isReprint tree: tree isManualDropReceipt: TRUE param: aVarEntity];

#ifdef __DEBUG_XML
			scew_writer_tree_file(tree, BASE_VAR_PATH "/deposit.xml");
#endif

			return tree;

		case EXTRACTION_PRT:
			[self buildExtractionXML: anEntity isReprint: isReprint tree: tree param: aVarEntity];

#ifdef __DEBUG_XML
			scew_writer_tree_file(tree, BASE_VAR_PATH "/extraction.xml");
#endif

			return tree;

		case TRANS_BOX_MODE_EXTRACTION_PRT:
			[self buildTransBoxModeExtractionXML: anEntity isReprint: isReprint tree: tree param: aVarEntity];

#ifdef __DEBUG_XML
			scew_writer_tree_file(tree, BASE_VAR_PATH "/extraction.xml");
#endif

			return tree;

		case CIM_ZCLOSE_PRT:
			[self buildZCloseXML: anEntity entityType: CIM_ZCLOSE_PRT isReprint: isReprint tree: tree param: aVarEntity];

#ifdef __DEBUG_XML
			scew_writer_tree_file(tree, BASE_VAR_PATH "/zclose.xml");
#endif
			return tree;

		case CIM_XCLOSE_PRT:
			[self buildZCloseXML: anEntity entityType: CIM_XCLOSE_PRT isReprint: isReprint tree: tree param: aVarEntity];

#ifdef __DEBUG_XML
			scew_writer_tree_file(tree, BASE_VAR_PATH "/zclose.xml");
#endif
			return tree;

		case CIM_OPERATOR_PRT:
			[self buildZCloseXML: anEntity entityType: CIM_OPERATOR_PRT isReprint: isReprint tree: tree param: aVarEntity];

#ifdef __DEBUG_XML
			scew_writer_tree_file(tree, BASE_VAR_PATH "/operator.xml");
#endif
			return tree;

		case CURRENT_VALUES_PRT:		  
			 [self buildExtractionXML: anEntity isReprint: isReprint tree: tree param: aVarEntity];

#ifdef __DEBUG_XML
			scew_writer_tree_file(tree, BASE_VAR_PATH "/extraction.xml");
#endif

			return tree;
			
		case ENROLLED_USER_PRT:
			 [self buildEnrolledUserXML: anEntity isReprint: isReprint tree: tree param: aVarEntity];

#ifdef __DEBUG_XML
			scew_writer_tree_file(tree, BASE_VAR_PATH "/extraction.xml");
#endif

			return tree;

		case SYSTEM_INFO_PRT:
			 [self buildSystemInfoXML: anEntity isReprint: isReprint tree: tree param: aVarEntity];

#ifdef __DEBUG_XML
			scew_writer_tree_file(tree, BASE_VAR_PATH "/systemInfo.xml");
#endif

			return tree;
			
		case CIM_AUDIT_PRT:		  
			 [self buildAuditXML: anEntity isReprint: isReprint tree: tree param: aVarEntity];

#ifdef __DEBUG_XML
			scew_writer_tree_file(tree, BASE_VAR_PATH "/auditReport.xml");
#endif

			return tree;
      
		case CONFIG_TELESUP_PRT:
			 [self buildConfigTelesupReportXML: anEntity isReprint: isReprint tree: tree param: aVarEntity];

#ifdef __DEBUG_XML
			scew_writer_tree_file(tree, BASE_VAR_PATH "/ConfigTelesupReport.xml");
#endif

			return tree;		

		case CASH_REFERENCE_PRT:		  
			 [self buildCashReferenceXML: anEntity isReprint: isReprint tree: tree param: aVarEntity];

			scew_writer_tree_file(tree, BASE_VAR_PATH "/cashReference.xml");

#ifdef __DEBUG_XML
			scew_writer_tree_file(tree, BASE_VAR_PATH "/cashReference.xml");
#endif

			return tree;

		case REPAIR_ORDER_PRT:
				[self buildRepairOrderReoportXML: anEntity isReprint: isReprint tree: tree param: aVarEntity];

#ifdef __DEBUG_XML
			scew_writer_tree_file(tree, BASE_VAR_PATH "/repairOrder.xml");
#endif

			return tree;

		case CIM_X_CASH_CLOSE_PRT:
			[self buildCashCloseXML: anEntity isReprint: isReprint tree: tree param: aVarEntity];

#ifdef __DEBUG_XML
			scew_writer_tree_file(tree, BASE_VAR_PATH "/cashclose.xml");
#endif
			return tree;

		case COMMERCIAL_STATE_CHANGE_REPORT_PRT:
			[self buildCommercialStateChangeReportXML: anEntity isReprint: isReprint tree: tree];

#ifdef __DEBUG_XML
			scew_writer_tree_file(tree, BASE_VAR_PATH "/commercialStateChangeReport.xml");
#endif
			return tree;

		case MODULES_LICENCE_PRT:
			[self buildModulesLicenceXML: anEntity isReprint: isReprint tree: tree];

#ifdef __DEBUG_XML
			scew_writer_tree_file(tree, BASE_VAR_PATH "/modulesLicence.xml");
#endif
			return tree;

		case CLOSING_CODE_PRT:
			[self buildClosingCodeXML: anEntity isReprint: isReprint tree: tree];


#ifdef __DEBUG_XML
			scew_writer_tree_file(tree, BASE_VAR_PATH "/closingCode.xml");
#endif
			return tree;

		case BAG_TRACKING_PRT:
			[self buildBagTrackingXML: anEntity isReprint: isReprint tree: tree param: aVarEntity];

#ifdef __DEBUG_XML
			scew_writer_tree_file(tree, BASE_VAR_PATH "/bagTracking.xml");
#endif
			return tree;

		case BACKUP_INFO_PRT:
			 [self buildBackupInfoXML: anEntity isReprint: isReprint tree: tree param: aVarEntity];

#ifdef __DEBUG_XML
			scew_writer_tree_file(tree, BASE_VAR_PATH "/backupInfo.xml");
#endif

			return tree;

    default:
      return NULL;   
      
  }		  
  
  return NULL;
}  


 
@end
