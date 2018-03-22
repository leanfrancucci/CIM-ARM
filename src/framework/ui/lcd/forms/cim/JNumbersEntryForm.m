#include "JNumbersEntryForm.h"
#include "util.h"
#include "MessageHandler.h"
#include "system/util/all.h"
#include "JMessageDialog.h"
#include "SystemTime.h"
#include "UICimUtils.h"
#include "Audit.h"
#include "BarcodeScanner.h"
#include "BagTrack.h"
#include "Buzzer.h"
#include "ExtractionManager.h"
#include "CimGeneralSettings.h"
#include "PrinterSpooler.h"
#include "ReportXMLConstructor.h"
#include "Persistence.h"
#include "ExtractionDAO.h"

#define printd(args...) dprintf(args)
//#define printd(args...)


@implementation  JNumbersEntryForm

/**/
- (void) onCreateForm
{
	[super onCreateForm];
	
	// Nuevo Estado comercial
	myLabelNumbersEntry = [JLabel new];
	[myLabelNumbersEntry setCaption: getResourceStringDef(RESID_REMOVED_BAG_ID, "Id bolsa removida:")];
	[myLabelNumbersEntry setWidth: 20];
	[self addFormComponent: myLabelNumbersEntry];

	[self addEol];

	myLabelQtyRead = [JLabel new];
	[myLabelQtyRead setCaption: "0/0"];
	[self addFormComponent: myLabelQtyRead];

	myNumber = [JText new];
	[myNumber setWidth: 20];
	if ([[CimGeneralSettings getInstance] getAcceptorsCodeType] == KeyPadOperationMode_NUMERIC)
		[myNumber setNumericMode: TRUE];

/* segun configuracion
	[myNumber setNumericMode: myNumericMode];
*/
	
	[self addFormComponent: myNumber];

	myQtyRead = 0;
	myTotalToRead = 0;

	if ([[CimGeneralSettings getInstance] getUseBarCodeReader]) {
		[[BarcodeScanner getInstance] setObserver: self];
		[[BarcodeScanner getInstance] enable];
	}

	myBagTracking	= [Collection new];
	myAcceptorSettingsList	= [Collection new];

	myCurrentExtraction = NULL;
	myBagTrackingParentId = 0;
	myBagTrackingMode = BagTrackingMode_NONE;

	myPreviousNumber[0] = '\0';
	isConfirmation = FALSE;

	isShowingError = FALSE;
}

- (void) setAcceptorSettingsList: (COLLECTION) anAcceptorSettingsList
{
	myAcceptorSettingsList = anAcceptorSettingsList;
}

/**/
- (BOOL) existsNumberInCollection: (char*) aNumber
{
	int i;

	assert(myBagTracking);

	printf("number = %s\n", aNumber);
	
	for (i=0; i<[myBagTracking size]; ++i) {
		if (strcmp([[myBagTracking at: i] getBNumber], aNumber) == 0) return TRUE;
	}

	printf("no existe\n");
	return FALSE;
}

/**/
- (void) debugBagTrack
{
	int i;
	id bagTrack;

	printf("BagTrack JNumbersEntryForm \n");
	printf("Extraction          Number 			  ParentId  Type\n");
	
	for (i=0; i<[myBagTracking size]; ++i) {
		bagTrack = [myBagTracking at: i];
		printf("%ld              %s              %ld       %d\n", [bagTrack getExtractionNumber], [bagTrack getBNumber], [bagTrack getBParentId], [bagTrack getBType]);
	}
}

/**/
- (void) finishBagTracking
{
	scew_tree *tree;

	if ([[CimGeneralSettings getInstance] getUseBarCodeReader]) {
		[[BarcodeScanner getInstance] removeObserver];
		[[BarcodeScanner getInstance] disable];
	}

	// almacena el bagTracking
	[[ExtractionManager getInstance] storeBagTrackingCollection: myBagTracking bagTrackingMode: myBagTrackingMode];	

	if (myBagTrackingMode == BagTrackingMode_MANUAL) {
		// setea la coleccion de bag tracking a la extraccion
		[myCurrentExtraction setEnvelopeTrackingCollection: myBagTracking];
		[myCurrentExtraction setBagTrackingMode: BagTrackingMode_MANUAL];
	
		tree = [[ReportXMLConstructor getInstance] buildXML: myCurrentExtraction entityType: BAG_TRACKING_PRT isReprint: FALSE varEntity: NULL];
	
		[[PrinterSpooler getInstance] addPrintingJob: BAG_TRACKING_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: 0];
		
		[myCurrentExtraction free];
	}


	[myBagTracking freeContents];
	[myBagTracking free];

	
	//[self closeForm];

}

/**/
- (char*) getEnterNumberDescription: (char*) aDescription
{
	strcpy(aDescription, "");	

 	if (myBagTrackingMode == BagTrackingMode_AUTO) 
		strcpy(aDescription, getResourceStringDef(RESID_BAG_CASS_ID, "Id Bolsa/Cass:"));
	else
		strcpy(aDescription, getResourceStringDef(RESID_ENVELOPE_ID, "Id sobre:"));

	return aDescription;
}

/**/
- (void) onMenu1ButtonClick
{
	char desc[50];


	if (isConfirmation) {	
		[myNumber setText: myPreviousNumber];
		isConfirmation = FALSE;
		[myLabelNumbersEntry setCaption: [self getEnterNumberDescription: desc]];
		[myGraphicContext setBlinkCursor: TRUE];
		[self paintComponent];
		[self doChangeStatusBarCaptions];
		[myScrollPanel drawCursor];
		return;
	}

	if (isConfirmation) {
  	[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_CONFIRM_NUMBER, "Confirme el numero.")];   
		return;
	}

	[self finishBagTracking];
	[self closeForm];
	//[self debugBagTrack];

}

/**/
- (void) onMenuXButtonClick
{
	if (![[CimGeneralSettings getInstance] getUseBarCodeReader])
		[super onMenuXButtonClick];
}

/**/
- (char*) getCaption1
{

	if (isShowingError) return NULL;

	if (([[CimGeneralSettings getInstance] getConfirmCode]) && (isConfirmation)) {	
		return getResourceStringDef(RESID_BACK_KEY, "atras");		
	}

	if ((![[CimGeneralSettings getInstance] getConfirmCode]) && 
			(myBagTrackingMode == BagTrackingMode_AUTO) && 
			(myQtyRead == myTotalToRead)) { 
		return NULL;
	}

	return getResourceStringDef(RESID_DONE, "listo");
}

/**/
- (char*) getCaptionX
{
	if (isShowingError) return NULL;

	if (![[CimGeneralSettings getInstance] getUseBarCodeReader])
		return getResourceStringDef(RESID_DELETE_KEY, "borrar");
	else
		return NULL;
}

/**/
- (char*) getCaption2
{

	printf("myBagTrackingMode= %d\n", myBagTrackingMode);
	printf("isConfirmation = %d\n", isConfirmation);
	printf("myQtyRead = %d\n", myQtyRead);
	printf("myTotalToRead = %d\n", myTotalToRead);
	
	if (isShowingError) return NULL;

	if ((isConfirmation) && 
			(myBagTrackingMode == BagTrackingMode_AUTO) && 
			(myQtyRead == myTotalToRead)) {	
		return getResourceStringDef(RESID_DONE, "listo");
	}

	if ((![[CimGeneralSettings getInstance] getConfirmCode]) && 
			(myBagTrackingMode == BagTrackingMode_AUTO) && 
			(myQtyRead == myTotalToRead)) { 
		return getResourceStringDef(RESID_DONE, "listo");
	}

	return getResourceStringDef(RESID_NEXT_KEY, "sig.");
}

/**/
- (void) showInvalidDataEntry: (char*) anError 
{
	char title1[30];
	char title2[30];
	char title3[30];

	isShowingError = TRUE;

	[self doChangeStatusBarCaptions];

	// Guarda los titulos para poder restarurarlos despues
	stringcpy(title1, [myLabelNumbersEntry getCaption]);
	stringcpy(title2, [myLabelQtyRead getCaption]);
	stringcpy(title3, [myNumber getText]);

	// Muestra el mensaje de error
	[myLabelNumbersEntry setCaption: "  * INVALID DATA *"];
	[myLabelQtyRead setCaption: anError];
	[myNumber setText: "                    "];

	// Suena el Buzzer un par de veces
	msleep(1000);
	[[Buzzer getInstance] buzzerBeep: 100];
	msleep(1000);
	[[Buzzer getInstance] buzzerBeep: 100];

	// Restaura los titulos y el cursor
	[myLabelNumbersEntry setCaption: title1];
	[myLabelQtyRead setCaption: title2];
	[myNumber setText: ""];
	[self paintComponent];

	isShowingError = FALSE;
	[self doChangeStatusBarCaptions];


}

/**/
- (void) onMenu2ButtonClick
{
	id bagTrack;
	char qtyRead[20];
	char error[40];
	BOOL process = FALSE;


	if (strlen([myNumber getText]) == 0) {
		stringcpy(error, getResourceStringDef(RESID_ENTER_NUMBER, "Ingrese un numero.")); 
		[self showInvalidDataEntry: error];
		return;
	}

	if (!isConfirmation) {

		if ([self existsNumberInCollection: [myNumber getText]]) {
			stringcpy(error, getResourceStringDef(RESID_NUMBER_EXISTS, "Numero existente.")); 
			[self showInvalidDataEntry: error];
			return;
		}

		if ([[CimGeneralSettings getInstance] getConfirmCode]) {
			stringcpy(myPreviousNumber, [myNumber getText]);
			isConfirmation = TRUE;
			process = FALSE;
			[myLabelNumbersEntry setCaption: getResourceStringDef(RESID_CONFIRM_NEW_BAG_CASSETTE_ID, "Confirme id Bolsa/Cass:")];
			[myNumber setText: ""];
			[self doChangeStatusBarCaptions];
			[self paintComponent];
			return;
		}

		isConfirmation = FALSE;
		process = TRUE;

	} else {

		printf("myPreviousNumber = %s\n", myPreviousNumber);
		printf("text             = %s\n", [myNumber getText]);
	

		if (strcmp(myPreviousNumber, [myNumber getText]) != 0) {
			stringcpy(error, getResourceStringDef(RESID_NUMBER_DOESNT_MATCH, "El numero no coincide.")); 
			[self showInvalidDataEntry: error];
			return;
		}

		//[myLabelNumbersEntry setCaption: getResourceStringDef(RESID_NEW_BAG_CASSETTE_ID, "Nuevo id Bolsa/Cass:")];
		[myLabelNumbersEntry setCaption: getResourceStringDef(RESID_BAG_CASS_ID, "Id Bolsa/Cass:")];
		isConfirmation = FALSE;
		process = TRUE;
		myPreviousNumber[0] = '\0';
	}

	if (process) {
		++myQtyRead;
		
		if (myQtyRead < [myAcceptorSettingsList size])
			sprintf(qtyRead, "%d/%d (%s)", myQtyRead + 1 , myTotalToRead, [[myAcceptorSettingsList at: myQtyRead] getAcceptorName]);
		else
			sprintf(qtyRead, "%d/%d", myQtyRead + 1 , myTotalToRead);
		[myLabelQtyRead setCaption: qtyRead];
	
		bagTrack = [BagTrack new];
	
		if (myBagTrackingMode == BagTrackingMode_MANUAL) {
			[bagTrack setExtractionNumber: [myCurrentExtraction getNumber]];
			[bagTrack setBType: BagTrackingMode_MANUAL];
		}

		if (myBagTrackingMode == BagTrackingMode_AUTO) {
			[bagTrack setBType: BagTrackingMode_AUTO];
			if (myQtyRead <= [myAcceptorSettingsList size])
				[bagTrack setAcceptorId: [[myAcceptorSettingsList at: myQtyRead-1] getAcceptorId]];
		}
	
		[bagTrack setBNumber: [myNumber getText]];
		[bagTrack setBParentId: myBagTrackingParentId];
	
		[myBagTracking add: bagTrack]; 

		if ((myBagTrackingMode == BagTrackingMode_AUTO) && (myQtyRead == myTotalToRead)) { 
			[self finishBagTracking];
			[self closeForm];
			return;
		}

		[myNumber setText: ""];

		[self paintComponent];

		process = FALSE;

	}

	[self doChangeStatusBarCaptions];
	[self paintComponent];
}

/**/
- (void) setTotalToRead: (int) aValue
{
	printf("totalToRead = %d\n", aValue);
	myTotalToRead = aValue;
}

/**/
- (void) onBarcodeScanned: (char *) aBarcode
{
	char data[50];

	stringcpy(data, aBarcode);

	// el codigo de barras nunca puede ser mayor al definido en el edit
	if (strlen(data) > 20)
		data[20] = '\0';

	[myNumber setText: data];

	[self onMenu2ButtonClick];
	
}

/**/
- (void) onOpenForm
{
	id bagTrack;
	char qtyRead[30];

	if ([myAcceptorSettingsList size] > 0)  
		sprintf(qtyRead, "%d/%d (%s)", myQtyRead + 1 , myTotalToRead, [[myAcceptorSettingsList at: 0] getAcceptorName]);
	else
		sprintf(qtyRead, "%d/%d", myQtyRead + 1 , myTotalToRead);

	[myLabelQtyRead setCaption: qtyRead];

	if (myBagTrackingMode == BagTrackingMode_MANUAL) {
		//[myLabelNumbersEntry setCaption: getResourceStringDef(RESID_REMOVED_BAG_ID, "Id sobre:")];
		[myLabelNumbersEntry setCaption: getResourceStringDef(RESID_ENVELOPE_ID, "Id sobre:")];
		myBagTrackingParentId = [[[Persistence getInstance] getExtractionDAO] loadBagTrackParentIdByExtraction: [myCurrentExtraction getNumber] type: myBagTrackingMode];

	}
	
	if (myBagTrackingMode == BagTrackingMode_AUTO) { 
	// si es auto, guarda un padre para asociar a los hijos
		bagTrack = [BagTrack new];
		[bagTrack setExtractionNumber: 0];
		[bagTrack setBNumber: ""];
		[bagTrack setBParentId: 0];
		[bagTrack setBType: BagTrackingMode_AUTO];
		myBagTrackingParentId = [[[Persistence getInstance] getExtractionDAO] storeBagTracking: bagTrack];
		[bagTrack free];

		//[myLabelNumbersEntry setCaption: getResourceStringDef(RESID_NEW_BAG_CASSETTE_ID, "Id Bolsa/Cass:")];
		[myLabelNumbersEntry setCaption: getResourceStringDef(RESID_BAG_CASS_ID, "Id Bolsa/Cass:")];
	}

}

/**/
- (void) setCurrentExtraction: (id) anExtraction
{
	myCurrentExtraction = anExtraction;
}

/**/
- (void) setBagTrackingMode: (int) aMode
{
	myBagTrackingMode = aMode;
}

//getResourceStringDef(RESID_BACK_KEY, myBackMessage);

@end
