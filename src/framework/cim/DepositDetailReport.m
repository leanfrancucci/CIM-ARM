#include "DepositDetailReport.h"
#include "Persistence.h"
#include "DepositDAO.h"

@implementation DepositDetailReport

static DEPOSIT_DETAIL_REPORT singleInstance = NULL;

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
	return self;
}

/**/
- (void) addDetail: (COLLECTION) aDetailList 
  depositsRS: (ABSTRACT_RECORDSET) aDepositsRS
  depositDetailsRS: (ABSTRACT_RECORDSET) aDepositDetailsRS
{
  int i;
  ReportDetailItem *item;
  
  for (i = 0; i < [aDetailList size]; ++i) {
    
    item = (ReportDetailItem *) [aDetailList at: i];
    
    // Agrupo por moneda/cash/tipo de valor
    if (item->currencyId != [aDepositDetailsRS getShortValue: "CURRENCY_ID"]) continue;
    if (item->cimCashId != [aDepositsRS getShortValue: "CIM_CASH_ID"]) continue;
    if (item->depositValueType != [aDepositDetailsRS getCharValue: "DEPOSIT_VALUE_TYPE"]) continue;
    
    item->qty += [aDepositDetailsRS getShortValue: "QTY"];
    
    if ([aDepositsRS getCharValue: "DEPOSIT_TYPE"] == DepositType_AUTO) {
      item->amount += ([aDepositDetailsRS getMoneyValue: "AMOUNT"] * [aDepositDetailsRS getShortValue: "QTY"]);
    } else {
      item->amount += [aDepositDetailsRS getMoneyValue: "AMOUNT"];
    }
     
    
    return;
    
  }

  item = malloc(sizeof(ReportDetailItem));
  item->depositType = [aDepositsRS getCharValue: "DEPOSIT_TYPE"];
  item->number = [aDepositsRS getLongValue: "NUMBER"];
  [aDepositsRS getStringValue: "ENVELOPE_NUMBER" buffer: item->envelopeNumber];
  item->currencyId = [aDepositDetailsRS getShortValue: "CURRENCY_ID"];
  item->cimCashId = [aDepositsRS getShortValue: "CIM_CASH_ID"];
  item->qty = [aDepositDetailsRS getShortValue: "QTY"];
  item->depositValueType = [aDepositDetailsRS getCharValue: "DEPOSIT_VALUE_TYPE"];
  
  if ([aDepositsRS getCharValue: "DEPOSIT_TYPE"] == DepositType_AUTO) {
    item->amount = [aDepositDetailsRS getMoneyValue: "AMOUNT"] * [aDepositDetailsRS getShortValue: "QTY"];
  } else {
    item->amount = [aDepositDetailsRS getMoneyValue: "AMOUNT"];
  }
  
  [aDetailList add: item];
    
}

/**/
- (void) insertDetailInOrder: (COLLECTION) aList detail: (ReportDetailItem *) aDetail
{
  int i;
  BOOL inCurrency = FALSE;
  ReportDetailItem *item;
  int index = -1;
   
  for (i = 0; i < [aList size]; ++i) {
    item = (ReportDetailItem*)[aList at: i];
    if (inCurrency && item->currencyId != aDetail->currencyId) {
      index = i;
      break;
    }
    if (item->currencyId == aDetail->currencyId) inCurrency = TRUE;  
  }

  if (index == -1)
    [aList add: aDetail];
  else
    [aList at: index insert: (id)aDetail];
  
}


/**/
- (COLLECTION) generateDepositDetailReport: (unsigned long) aFromDepositNumber
  toDepositNumber: (unsigned long) aToDepositNumber
  referenceId: (int) myReferenceId
{
  ABSTRACT_RECORDSET depositsRS;
  ABSTRACT_RECORDSET depositDetailsRS;
  COLLECTION list;
  COLLECTION details;
  int i;
  int count;
  unsigned long number;
  
  //if (aUser != NULL) userId = [aUser getUserId];
  
  list = [Collection new];
  details = [Collection new];
  
  depositsRS = [[[Persistence getInstance] getDepositDAO] getNewDepositRecordSet];
  [depositsRS open];
  
	if (![depositsRS findById: "NUMBER" value: aFromDepositNumber]) {
		[depositsRS close];
		[depositsRS free];
		return list;
	}
  		
  // Detalle del deposito
	depositDetailsRS = [[[Persistence getInstance] getDepositDAO] getNewDepositDetailRecordSet];
	[depositDetailsRS open];
	[depositDetailsRS moveFirst];
	TRY

		while (![depositsRS eof]) {
    
      number = [depositsRS getLongValue: "NUMBER"];
      
			// Verifica si ya me pase del numero de deposito hasta (solo para filtro por numero)
			if (number > aToDepositNumber) break;

      // Verifico si el cash reference se corresponde
      if (myReferenceId != 0 && [depositsRS getShortValue: "REFERENCE_ID"] != myReferenceId) {
        if (![depositsRS moveNext]) break;
        continue;
      }
      
      
			// Me paro en el registro de detalle (si es que no estoy ahi ya)
			if ([depositDetailsRS eof] || [depositDetailsRS getLongValue: "NUMBER"] != number)
				[depositDetailsRS findFirstById: "NUMBER" value: number];

				while (![depositDetailsRS eof] && [depositDetailsRS getLongValue: "NUMBER"] == number) {
  
          [self addDetail: details depositsRS: depositsRS depositDetailsRS: depositDetailsRS];
                    
	       	[depositDetailsRS moveNext];

	     }

       //
       count = [details size];
       for (i = 0; i < count; ++i) {
         [self insertDetailInOrder: list detail: (ReportDetailItem*)[details at: 0]];
         [details removeFirst];               
       }
       
  		 if (![depositsRS moveNext]) break;
			
		}
	
	FINALLY

    [depositsRS close];
    [depositsRS free];
	
		[depositDetailsRS close];
		[depositDetailsRS free];
	
	END_TRY;

  [details free];
  
  return list;  
}

/**/
- (COLLECTION) generateDepositDetailReport: (unsigned long) aFromDepositNumber
  toDepositNumber: (unsigned long) aToDepositNumber
  user: (USER) aUser
	depositType: (DepositType) aDepositType
{

}
         
/**/
- (COLLECTION) generateDepositDetailReport: (unsigned long) aFromDepositNumber
  toDepositNumber: (unsigned long) aToDepositNumber
  user: (USER) aUser
{
  ABSTRACT_RECORDSET depositsRS;
  ABSTRACT_RECORDSET depositDetailsRS;
  COLLECTION list;
  volatile unsigned long userId = 0;
  COLLECTION details;
  int i;
  int count;
  unsigned long number;
  
  if (aUser != NULL) userId = [aUser getUserId];
  
  list = [Collection new];
  details = [Collection new];
  
  depositsRS = [[[Persistence getInstance] getDepositDAO] getNewDepositRecordSet];
  [depositsRS open];
  
	if (![depositsRS findById: "NUMBER" value: aFromDepositNumber]) {
		[depositsRS close];
		[depositsRS free];
		return list;
	}
  		
  // Detalle del deposito
	depositDetailsRS = [[[Persistence getInstance] getDepositDAO] getNewDepositDetailRecordSet];
	[depositDetailsRS open];
	[depositDetailsRS moveFirst];
	TRY

		while (![depositsRS eof]) {

      number = [depositsRS getLongValue: "NUMBER"];
      
			// Verifica si ya me pase del numero de deposito hasta (solo para filtro por numero)
			if (number > aToDepositNumber) break;

      // Verifico si el usuario se corresponde
      if (userId != 0 && [depositsRS getLongValue: "USER_ID"] != userId) {
        if (![depositsRS moveNext]) break;
        continue;
      }
      
      
			// Me paro en el registro de detalle (si es que no estoy ahi ya)
			if ([depositDetailsRS eof] || [depositDetailsRS getLongValue: "NUMBER"] != number)
				[depositDetailsRS findFirstById: "NUMBER" value: number];

				while (![depositDetailsRS eof] && [depositDetailsRS getLongValue: "NUMBER"] == number) {
  
          [self addDetail: details depositsRS: depositsRS depositDetailsRS: depositDetailsRS];
                    
	       	[depositDetailsRS moveNext];

	     }

       //
       count = [details size];
       for (i = 0; i < count; ++i) {
         [self insertDetailInOrder: list detail: (ReportDetailItem*)[details at: 0]];
         [details removeFirst];               
       }

			 if (![depositsRS moveNext]) break;
			
		}
	
	FINALLY

    [depositsRS close];
    [depositsRS free];
	
		[depositDetailsRS close];
		[depositDetailsRS free];
	
	END_TRY;

  [details free];
  
  return list;
}

- (int) getTicketsCountByDepositType: (unsigned long) aFromDepositNumber
  toDepositNumber: (unsigned long) aToDepositNumber 
	depositType: (DepositType) aDepositType
{
  ABSTRACT_RECORDSET depositsRS;
	volatile int count = 0;
  
  depositsRS = [[[Persistence getInstance] getDepositDAO] getNewDepositRecordSet];
  [depositsRS open];
  
	if (![depositsRS findById: "NUMBER" value: aFromDepositNumber]) {
		[depositsRS close];
		[depositsRS free];
		return count;
	}

	TRY

		while (![depositsRS eof]) {
      
			// Verifica si ya me pase del numero de deposito hasta
			if ([depositsRS getLongValue: "NUMBER"] > aToDepositNumber) break;

      if ([depositsRS getCharValue: "DEPOSIT_TYPE"] == aDepositType) count++;

			[depositsRS moveNext];
		}
	
	FINALLY

    [depositsRS close];
    [depositsRS free];
	
	END_TRY;
  
  return count;
}

@end
