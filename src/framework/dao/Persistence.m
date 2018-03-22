#include "Persistence.h"
#include "AmountSettingsDAO.h"
#include "RegionalSettingsDAO.h"
#include "CommercialStateDAO.h"
#include "PrintingSettingsDAO.h"
#include "EventCategoryDAO.h"
#include "ProfileDAO.h"
#include "UserDAO.h"
#include "TelesupSettingsDAO.h"
#include "ConnectionSettingsDAO.h"
#include "OperationDAO.h"
#include "BillSettingsDAO.h"
#include "DepositDAO.h"
#include "CurrencyDAO.h"
#include "ExtractionDAO.h"
#include "TempDepositDAO.h"
#include "ZCloseDAO.h"
#include "CimGeneralSettingsDAO.h"
#include "DoorDAO.h"
#include "AcceptorDAO.h"
#include "CimCashDAO.h"
#include "CashReferenceDAO.h"
#include "BoxDAO.h"
#include "RepairOrderItemDAO.h"
#include "LicenceModulesDAO.h"
#include "BackupsDAO.h"

static PERSISTENCE instance = NULL;

@implementation Persistence

+ (void) setInstance: (id) anObject
{
	instance = anObject;
}

+ (id) getInstance
{
	return instance;
}


- (DATA_OBJECT) getAuditDAO
{
	THROW(ABSTRACT_METHOD_EX);
	return NULL;
}

- (DATA_OBJECT) getEventDAO
{
	THROW(ABSTRACT_METHOD_EX);
	return NULL;
}

- (DATA_OBJECT) getRegionalSettingsDAO
{
	return [RegionalSettingsDAO new];	
}

- (DATA_OBJECT) getBillSettingsDAO
{
	return [BillSettingsDAO new];
}

- (DATA_OBJECT) getCommercialStateDAO
{
	return [CommercialStateDAO new];
}

- (DATA_OBJECT) getLicenceModuleDAO
{
  return [LicenceModulesDAO new];
}

- (DATA_OBJECT) getAmountSettingsDAO
{
	return [AmountSettingsDAO new];
}

- (DATA_OBJECT) getPrintingSettingsDAO
{
	return [PrintingSettingsDAO new];
}

- (DATA_OBJECT) getEventCategoryDAO
{
	return [EventCategoryDAO new];
}

- (DATA_OBJECT) getProfileDAO
{
	return [ProfileDAO new];
}


- (DATA_OBJECT) getUserDAO
{
	return [UserDAO new];
}

- (DATA_OBJECT) getTelesupSettingsDAO
{
	return [TelesupSettingsDAO new];
}

- (DATA_OBJECT) getConnectionSettingsDAO
{
	return [ConnectionSettingsDAO new];
}

- (DATA_OBJECT) getOperationDAO
{
	return [OperationDAO new];
}

/**/
- (DATA_OBJECT) getDepositDAO
{
	return [DepositDAO new];
}

/**/
- (DATA_OBJECT) getCurrencyDAO
{
	return [CurrencyDAO new];
}

/**/
- (DATA_OBJECT) getExtractionDAO
{
	return [ExtractionDAO new];
}

/**/
- (DATA_OBJECT) getTempDepositDAO
{
	return [TempDepositDAO new];
}

/**/
- (DATA_OBJECT) getZCloseDAO
{
	return [ZCloseDAO new];
}

/**/
- (DATA_OBJECT) getCimGeneralSettingsDAO
{
	return [CimGeneralSettingsDAO new];
}

/**/
- (DATA_OBJECT) getBackupsDAO
{
	return [BackupsDAO new];
}	

/**/
- (DATA_OBJECT) getDoorDAO
{
	return [DoorDAO new];
}

/**/
- (DATA_OBJECT) getAcceptorDAO
{	
	return [AcceptorDAO new];
}

/**/
- (DATA_OBJECT) getCimCashDAO
{
	return [CimCashDAO new];
}

/**/
- (DATA_OBJECT) getCashReferenceDAO
{
	return [CashReferenceDAO new];
}

/**/
- (DATA_OBJECT) getBoxDAO
{
	return  [BoxDAO new];
}

- (DATA_OBJECT) getRepairOrderItemDAO
{
	return [RepairOrderItemDAO new];
}

@end
