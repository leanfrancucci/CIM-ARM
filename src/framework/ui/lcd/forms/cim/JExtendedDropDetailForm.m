#include "JExtendedDropDetailForm.h"
#include "CimManager.h"
#include "MessageHandler.h"
#include "UICimUtils.h"
#include "Option.h"
#include "AmountSettings.h"

#define OPTION_AMOUNT_VIEW			1
#define OPTION_QTY_VIEW					2

#define LOG(args...) //doLog(0,args)
//#define printd(args...)

@implementation  JExtendedDropDetailForm

- (void) updateAmounts;

/**/
- (void) setDeposit: (DEPOSIT) aDeposit
{
	myDeposit = aDeposit;
}

/**/
- (void) doOpenForm
{
	COLLECTION acceptors;
	int i;
	char buf[21];

	[super doOpenForm];

	myTimer = [OTimer new];
  [myTimer initTimer: PERIODIC period: 2000 object: self callback: "updateAmounts"];
  [myTimer start];

	// tarigo el cash
	myCimCash = [myDeposit getCimCash];
  // traigo el usuario
  myUser = [myDeposit getUser];

	myTotalDecimals = [[AmountSettings getInstance] getTotalRoundDecimalQty];
	myCurrentView = ExtendedDropView_AMOUNT;
	myLabelTitle = [JLabel new];
	//[myLabelTitle setCaption: getResourceStringDef(RESID_AMOUNT_VIEW_WAITING, "Vista importe-Esperando")];
	[myLabelTitle setCaption: [myUser getFullName]];
	[myLabelTitle setWidth: 20];
	[self addFormComponent: myLabelTitle];
	[self addFormEol];

	myGrid = [JGrid new];
	[myGrid setOwnObjects: TRUE];
	[myGrid setHeight: 2];
	
	acceptors = [myCimCash getAcceptorSettingsList];

	for (i = 0; i < [acceptors size]; ++i) {

		// >Valx: ARS      0.00
		// 01234567890123456789
		sprintf(buf, "Val%1d: %-3s      0.00", [[acceptors at: i] getAcceptorId], [[[acceptors at: i] getDefaultCurrency] getCurrencyCode]);
    [myGrid addString: buf];

	}

	[self addFormComponent: myGrid];
	
  [self updateAmounts];

}

/**/
- (void) onMenu1ButtonClick
{
	COLLECTION options = [Collection new];
	OPTION option;
	int keyOption = -1;

	[options add: [Option newOption: OPTION_AMOUNT_VIEW value: getResourceStringDef(RESID_AMOUNT_VIEW, "Vista imp.")]];
	[options add: [Option newOption: OPTION_QTY_VIEW value: getResourceStringDef(RESID_QTY_VIEW, "Vista cant")]];

	option = [UICimUtils selectFromCollection: self
		collection: options
		title: ""
		showItemNumber: TRUE];

	if (option != NULL) keyOption = [option getKeyOption];

	[options freeContents];
	[options free];

	[myLabelTitle setCaption: [myUser getFullName]];
	if (keyOption == OPTION_AMOUNT_VIEW) {
		//[myLabelTitle setCaption: getResourceStringDef(RESID_AMOUNT_VIEW_WAITING, "Vista imp.-Esperando")];
		myCurrentView = ExtendedDropView_AMOUNT;
	} else if (keyOption == OPTION_QTY_VIEW) {
		//[myLabelTitle setCaption: getResourceStringDef(RESID_QTY_VIEW_WAITING, "Vista cant-Esperando")];
		myCurrentView = ExtendedDropView_QTY;
	}

	[self updateAmounts];
}

/**/
- (void) onMenu2ButtonClick
{
  [myTimer stop];
  [myTimer free];
  [self closeForm];
}

/**/
- (char *) getCaption1
{	
	return getResourceStringDef(RESID_MORE, "mas");
}

/**/
- (char *) getCaption2
{
	return getResourceStringDef(RESID_CLOSE_KEY, "cerrar");
}

/**/
- (void) onMenuXButtonClick
{
}

/**/
- (char *) getCaptionX
{
	return NULL;
}

/**/
- (void) updateAmounts
{
	COLLECTION acceptors;
	char buf[21];
	char moneyStr[30];
	int i;

	acceptors = [myCimCash getAcceptorSettingsList];

	for (i = 0; i < [acceptors size]; ++i) {

		if (myCurrentView == ExtendedDropView_AMOUNT) {

			formatMoney(moneyStr, "", [myDeposit getAmountByAcceptorSettings: [acceptors at: i]], myTotalDecimals, 9);
			sprintf(buf, "Val%1d: %-3s %9s", [[acceptors at: i] getAcceptorId], [[[acceptors at: i] getDefaultCurrency] getCurrencyCode], moneyStr);
		} else {

			sprintf(buf, "Val%1d: %-3s       %03d", [[acceptors at: i] getAcceptorId], [[[acceptors at: i] getDefaultCurrency] getCurrencyCode],
				[myDeposit getQtyByAcceptorSettings: [acceptors at: i]]);

		}

		[myGrid setString: buf index: i];

	}

	[myGrid paintComponent];

}

@end
