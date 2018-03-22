#ifndef  JCIM_GENERAL_SETTINGS_EDIT_FORM_H
#define  JCIM_GENERAL_SETTINGS_EDIT_FORM_H

#define  JCIM_GENERAL_SETTINGS_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JNumericText.h"
#include "JCombo.h"
#include "JTime.h"

/**
 *
 */
@interface  JCimGeneralSettingsEditForm: JEditForm
{
	JTEXT myTextDepositCopiesQty;
	JTEXT myTextXCopiesQty;
	JTEXT myTextZCopiesQty;
	JTEXT myTextExtractionCopiesQty;
	JCOMBO myComboAutoPrint;
	JCOMBO myComboPrintLogo;
	JCOMBO myComboAskEnvelopeNumber;
	JCOMBO myComboUseCashReference;
	JCOMBO myComboAskQtyInManualDrop;
	JCOMBO myComboAskApplyTo;
	JCOMBO myComboPrintOperatorReport;
	JTEXT  myTextPOSId;
	JTIME  myTimeEndDay;
	JCOMBO myComboEnvelopeIdOpMode;
	JCOMBO myComboApplyToOpMode;
	JCOMBO myComboLoginOpMode;
	JCOMBO myComboUseBarCodeReader;
	JCOMBO myComboBarCodeReaderComPort;
	JCOMBO myComboRemoveBagVerification;
	JCOMBO myComboBagTracking;
	JCOMBO myComboRemoveCashOuterDoor;
	JCOMBO myComboUseEndDay;
	JCOMBO myComboAskBagCode;
	JCOMBO myComboAcceptorsCodeType;
	JCOMBO myComboConfirmCode;

	BOOL myLastUseBarCodeReader;
	int myLastBarCodeReaderComPort;

	BOOL myHasChangedUseEndDay;
}


@end

#endif

