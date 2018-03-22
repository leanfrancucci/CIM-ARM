#include "JTelesupTypesListForm.h"
#include "JTelesupervisionEditForm.h"
#include "TelesupervisionManager.h"
#include "TelesupDefs.h"
#include "MessageHandler.h"
#include "FTPSupervision.h"

#define printd(args...)// doLog(0,args)
//#define printd(args...)

@implementation  JTelesupTypesListForm

static char *_caption2 = "select";

/**/
- (void) onConfigureForm
{
	/**/
	[self setAllowNewInstances: FALSE];
	[self setAllowDeleteInstances: FALSE];

//	[self addItem: [String str: "SAR II PTSD"]];
//	[self addItem: [String str: "TELEFONICA"]];
//	[self addItem: [String str: "TELECOM"]];
//	[self addItem: [String str: "G2"]];
//	[self addItem: [String str: "SAR II FTP"]];
//	[self addItem: [String str: "IMAS"]];
	[self addItem: [String str: "PIMS"]];
	[self addItem: [String str: "POS"]];
	[self addItem: [String str: "HOYTS BRIDGE"]];
	[self addItem: [String str: "BRIDGE"]];

	if ([[FTPSupervision getInstance] ftpServerAllowed])
		[self addItem: [String str: "FTP"]];

	//[self addItem: [String str: "CMP OUT"]];


	mySelectedTelesupType = 0;
}


/**/
- (void) onSelectInstance: (id) anInstance
{
	int index = [self getSelectedIndex];
	
	if (index == 0) mySelectedTelesupType = PIMS_TSUP_ID;
	if (index == 1) mySelectedTelesupType = POS_TSUP_ID;
	if (index == 2) mySelectedTelesupType = HOYTS_BRIDGE_TSUP_ID;
	if (index == 3) mySelectedTelesupType = BRIDGE_TSUP_ID;
	//if (index == 3) mySelectedTelesupType = FTP_SERVER_TSUP_ID;
	//if (index == 4) mySelectedTelesupType = BRIDGE_TSUP_ID;
	
	//if (index == 1) mySelectedTelesupType = CMP_OUT_TSUP_ID;
//	else if (index == 1) mySelectedTelesupType = TELEFONICA_TSUP_ID;
//	else if (index == 2) mySelectedTelesupType = TELECOM_TSUP_ID;
//	else if (index == 1) mySelectedTelesupType = G2_TSUP_ID;
	//else if (index == 2) mySelectedTelesupType = SARII_TSUP_ID;
//	else if (index == 2) mySelectedTelesupType = IMAS_TSUP_ID;
//	else if (index == 3) mySelectedTelesupType = PIMS_TSUP_ID;

	[self closeForm];
}

/**/
- (int) getSelectedTelesupType
{
	return mySelectedTelesupType;
}

/**/
- (char*) getCaption2
{
	return getResourceStringDef(RESID_SELECT_KEY, _caption2);
}


@end

