#include <string.h>
#include "JUpdateFirmwareForm.h"
#include "util.h"
#include "system/os/all.h"
#include "MessageHandler.h"

#define printd(args...) //doLog(0,args)
//#define printd(args...)

@implementation  JUpdateFirmwareForm

/**/
- (void) setBillAcceptor: (BILL_ACCEPTOR) aBillAccceptor
{
	myBillAcceptor = aBillAccceptor;
	[myLabelAcceptorName setCaption: [[myBillAcceptor getAcceptorSettings] getAcceptorName]];
	myCurrentProgress = 0;
	[self paintComponent];
}

/**/
- (void) setProgress: (int) aProgress
{
	[myProgressBar advanceProgressTo: aProgress];
	[myProgressBar paintComponent];
}

/**/
- (void) onCreateForm
{
	[super onCreateForm];

	//doLog(0,"\n**********startUpgrade**********\n");

	myCurrentProgress = 0;

	[self setWidth: 20];
	[self setHeight: 4];
	
	myLabelTitle = [JLabel new];
	[myLabelTitle setWidth: 20];
	[myLabelTitle setHeight: 1];	
	[myLabelTitle setCaption: getResourceStringDef(RESID_UPDATING_FIRMWARE, "Actualizando Firm...")];
	[self addFormComponent: myLabelTitle];
	[myLabelTitle setVisible: TRUE];
	
	myLabel2Title = [JLabel new];
	[myLabel2Title setWidth: 20];
	[myLabel2Title setHeight: 1];	
	[myLabel2Title setCaption: getResourceStringDef(RESID_UPD_FIRM_DONT_SHOTDOWN_EQUIP, "NO APAGUE EL EQUIPO!")];
	[self addFormComponent: myLabel2Title];
	[myLabel2Title setVisible: TRUE];


	myLabelAcceptorName = [JLabel new];
	[myLabelAcceptorName setWidth: 20];
	[myLabelAcceptorName setHeight: 1];	
	[myLabelAcceptorName setCaption: getResourceStringDef(RESID_UNCOMPRESSIONG_FILE, "Descomprimiendo archivo")];
	[self addFormComponent: myLabelAcceptorName];
	[myLabelAcceptorName setVisible: TRUE];

	
	//
	myProgressBar = [JProgressBar new];
	[myProgressBar setWidth: 17];
	[myProgressBar advanceProgressTo: 0];
	[myProgressBar setFilled: TRUE];
	[myProgressBar showPercent: TRUE];
	[myProgressBar setVisible: TRUE];

	[self addFormComponent: myProgressBar];

	[myGraphicContext clearScreen];
/*	[myGraphicContext setWidth: 20];
	[myGraphicContext setHeight: 4];
	[myGraphicContext setXPosition: 1];
	[myGraphicContext setYPosition: 1];
	[myGraphicContext setCurrentXPosition: 1];
	[myGraphicContext setCurrentYPosition: 1];
*/
	[self setLockedComponent: FALSE];

	[self paintComponent];

}

/**/
- (void) setMessage: (char *) aMessage
{
	[myLabelTitle setCaption: aMessage];
}

/**/
- (void) setMessage2: (char *) aMessage
{
	[myLabel2Title setCaption: aMessage];
}

/**/
- (void) setMessage3: (char *) aMessage
{
	[myLabelAcceptorName setCaption: aMessage];
}

/**/
- (char*) getCaption1
{
   return NULL;
}

@end

