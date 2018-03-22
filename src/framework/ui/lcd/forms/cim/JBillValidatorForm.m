#include "JBillValidatorForm.h"
#include "BillValidator.h"
#include "MessageHandler.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)


@implementation  JBillValidatorForm

static char myBackMessage[] 			= "atras";
static char myOpenMessage[]			= "abrir";
static char myCloseMessage[]			= "cerrar";

/**/
- (void) onCreateForm
{
	[super onCreateForm];

	myBillValidator = [BillValidator getInstance];
	[myBillValidator setObserver: self];

	myLabelTitle = [JLabel new];

	myLabelTitle = [JLabel new];
	[myLabelTitle setCaption: getResourceStringDef(RESID_CASH_CLOSED, "Caja cerrada")];
	[myLabelTitle setWidth: 20];
	[self addFormComponent: myLabelTitle];
	[self addFormEol];

	myLabelTotalTitle = [JLabel new];
	[myLabelTotalTitle setCaption: getResourceStringDef(RESID_TOTAL_LABEL, "Total:")];
	[self addFormComponent: myLabelTotalTitle];

	myLabelTotal = [JLabel new];
	[myLabelTotal setWidth: 10];
	[myLabelTotal setCaption: "$ 0.00"];
	[self addFormComponent: myLabelTotal];

	myLabelStatus = [JLabel new];
	[myLabelStatus setCaption: getResourceStringDef(RESID_WAITING, "Esperando...")];
	[myLabelStatus setWidth: 20];
	[self addFormComponent: myLabelStatus];

	[self informStatusChange];
}

/**/
- (void) onMenu1ButtonClick
{
	if ([myBillValidator isOpen]) {
		return;
	}

	[myBillValidator setObserver: NULL];
	[self closeForm];
}

/**/
- (void) onMenu2ButtonClick
{
	char label[31];

	if ([myBillValidator isOpen]) {
		[myLabelTitle setCaption: getResourceStringDef(RESID_CLOSING, "Cerrando...")];
		[myBillValidator close];
		sprintf(label, getResourceStringDef(RESID_BILLS, "Billetes: %d"), [myBillValidator getBillCount]);	
		[myLabelStatus setCaption: label];
	}
	else if ([myBillValidator getBillValidatorState] != BillValidatorState_ERROR) {
		[myLabelTitle setCaption: getResourceStringDef(RESID_OPENING, "Abriendo...")];
		[myLabelTotal setCaption: "$ 0.00"];	
		[myLabelStatus setCaption: getResourceStringDef(RESID_WAITING, "Esperando...")];
		[myBillValidator open];
	}
}

/**/
- (char *) getCaption1
{	
	if ([myBillValidator isOpen]) return NULL;
	return getResourceStringDef(RESID_BACK_KEY, myBackMessage);
}

/**/
- (char *) getCaption2
{	
	if ([myBillValidator isOpen]) 
		return getResourceStringDef(RESID_CLOSE_KEY, myCloseMessage);

	if ([myBillValidator getBillValidatorState] != BillValidatorState_ERROR)
		return getResourceStringDef(RESID_OPEN, myOpenMessage);

	return NULL;
}

/**/
- (void) informNewBill: (money_t) anAmount
{
	char label[50];
	char amountstr[30];

	formatMoney(amountstr, "$", [myBillValidator getTotal], 2, 20);
	[myLabelTotal setCaption: amountstr];

	formatMoney(amountstr, "$", anAmount, 2, 20);
	sprintf(label, "%s (%d)", amountstr, [myBillValidator getBillCount]);	
//	doLog(0,"Nuevo billete de valor %s\n", amountstr);
	[myLabelStatus setCaption: label];
}

/**/
- (void) informBillRejected: (int) aCause
{
	char text[21];
	sprintf(text, getResourceStringDef(RESID_REJECTED, "Rechazado: %x"), aCause & 0xFF);
	[myLabelStatus setCaption: text];
}

/**/
- (void) informCommunicationError: (int) aCause
{
	char text[21];
	//"ERROR: %x    "
	sprintf(text, getResourceStringDef(RESID_BILL_COMMUNICATION_ERROR, "ERROR: %x"), aCause & 0xFF);
	strcat(text,"    ");
	[myLabelStatus setCaption: text];
	[self informStatusChange];
}


/**/
- (void) informStatusChange
{
	char text[31];
	BillValidatorState state;

	if ([myBillValidator isOpen]) {
		strcpy(text, getResourceStringDef(RESID_OPENED, "Abierta /"));
		strcat(text, " ");
	} else  {
		strcpy(text, getResourceStringDef(RESID_CLOSED, "Cerrada /"));
		strcat(text, " ");
	}

	state = [myBillValidator getBillValidatorState];

	switch (state) {
		case BillValidatorState_ERROR:
			strcat(text, getResourceStringDef(RESID_ERROR, "Error"));
			strcat(text, "    ");
			break;
		case BillValidatorState_START:
			strcat(text, getResourceStringDef(RESID_ACCEPTING, "Aceptando"));
			break;
		case BillValidatorState_STOP:
			strcat(text, getResourceStringDef(RESID_STOPPED, "Detenido"));
			strcat(text, " ");
			break;
	}

	[myLabelTitle setCaption: text];

	[self doChangeStatusBarCaptions];
}

@end
