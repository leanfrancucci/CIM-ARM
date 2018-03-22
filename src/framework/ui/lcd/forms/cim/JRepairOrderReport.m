#include "JRepairOrderReport.h"
#include "util.h"
#include "MessageHandler.h"
#include "system/util/all.h"
#include "JMessageDialog.h"
#include "RepairOrder.h"
#include "scew.h"
#include "ReportXMLConstructor.h"
#include "PrinterSpooler.h"
#include "CimGeneralSettings.h"

#define printd(args...)// doLog(0, args)
//#define printd(args...)

#define MAX_TEXT_SIZE 4096

@implementation  JRepairOrderReport


/**/
- (void) onCreateForm
{
	[super onCreateForm];

	// Tipo de reparacion
	myRepairReport = [JLabel new];
	[myRepairReport setCaption: ""];
	[self addFormComponent: myRepairReport];

}

/**/
- (void) onMenu1ButtonClick
{
  
}

/**/
- (char*) getCaption1
{
  return NULL;
}

/**/
- (char*) getCaptionX
{
	return getResourceStringDef(RESID_PRINT, "imprime");
}

/**/
- (char*) getCaption2
{
  return getResourceStringDef(RESID_OK_UPPER, "OK");
}

/**/
- (void) onMenuXButtonClick
{
	scew_tree *tree;

  tree = [[ReportXMLConstructor getInstance] buildXML: myRepairOrder entityType: REPAIR_ORDER_PRT isReprint: FALSE varEntity: NULL];

	[[PrinterSpooler getInstance] addPrintingJob: REPAIR_ORDER_PRT
			copiesQty: 1
			ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];

}

/**/
- (void) onMenu2ButtonClick
{
	[self closeForm];
}

/**/
- (void) onOpenForm
{
	char buffer[50];

	if ([myRepairOrder getRepairOrderState] == RepairOrderState_ERROR) {
		[myRepairReport setCaption: getResourceStringDef(RESID_REPAIR_ORDER_ERROR, "ERROR EN ENVIO DE ORDEN")];
	}

	if ([myRepairOrder getRepairOrderState] == RepairOrderState_OK) {
		sprintf(buffer, "%s %s", getResourceStringDef(RESID_REPAIR_ORDER_OK_ORDER_NUMBER, "ENVIO DE ORDEN EXITOSO. Order Number:"), [myRepairOrder getRepairOrderNumber]);
	
		[myRepairReport setCaption: buffer];
	}

/*
	tree = [[XMLConstructor getInstance] buildXML: p];
	[[PrinterSpooler getInstance] addPrintingJob: TEXT_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree];
*/	
	
}

/**/
- (void) setRepairOrder: (id) aRepairOrder
{
	myRepairOrder = aRepairOrder;
}

@end

