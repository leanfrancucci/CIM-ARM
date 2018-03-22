#include "JCashBoxForm.h"
#include "BillValidator.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

static char mySaveMsg[] = "Save ?";

@implementation  JCashBoxForm

static char myBackMessage[] 			= "atras";
static char myCloseCashBoxMessage[] = "retira";

/**/
- (void) onCreateForm
{
	char amountstr[31];
	char line[31];

	[super onCreateForm];

	myBillValidator = [BillValidator getInstance];
	myCashBoxRS = [myBillValidator getLastCashBoxRS];

	myLabelTitle = [JLabel new];

	myLabelTitle = [JLabel new];
	[myLabelTitle setCaption: "TOTAL DEPOSITADO"];
	[myLabelTitle setWidth: 20];
	[self addFormComponent: myLabelTitle];
	[self addFormEol];

	myLabelTotal = [JLabel new];
	[myLabelTotal setWidth: 20];
	[myLabelTotal setCaption: ""];
	[self addFormComponent: myLabelTotal];
	[self addFormEol];

	myLabelQty = [JLabel new];
	[myLabelQty setWidth: 20];
	[myLabelQty setCaption: ""];
	[self addFormComponent: myLabelQty];

	if (myCashBoxRS == NULL || ![myCashBoxRS getBoolValue: "OPEN"]) {

		[myLabelTotal setCaption: "No hay depositos"];	
		[myLabelQty setCaption: "efectuados."];	

	} else {

		// Importe
		formatMoney(amountstr, "$", [myCashBoxRS getMoneyValue: "AMOUNT"], 2, 20);
		sprintf(line, "Total: %s", amountstr);
		[myLabelTotal setCaption: line];	

		// Cantidad
		sprintf(line, "Cantidad: %ld", [myCashBoxRS getLongValue: "BILL_QTY"]);
		[myLabelQty setCaption: line];	

	}

}

/**/
- (void) onMenu1ButtonClick
{
	[self closeForm];
}

/**/
- (void) onMenu2ButtonClick
{

	if (myCashBoxRS != NULL && [myCashBoxRS getBoolValue: "OPEN"]) {
		[myLabelTitle setCaption: getResourceStringDef(RESID_CLOSING, "Cerrando...")];
		[myBillValidator closeCashBox];	
		[self closeForm];
	}

}

/**/
- (char *) getCaption1
{	
	return getResourceStringDef(RESID_BACK_KEY, myBackMessage);
}

/**/
- (char *) getCaption2
{	
	if (myCashBoxRS != NULL && [myCashBoxRS getBoolValue: "OPEN"]) {
		return getResourceStringDef(RESID_RETIRE, myCloseCashBoxMessage);
	}
	return NULL;	
}

/**/
- (char *) getConfirmAcceptMessage: (char *) aMessage toSave: (id) anInstance
{
	return getResourceStringDef(RESID_SAVE_WITH_QUESTION_MARK, mySaveMsg);
}

@end
