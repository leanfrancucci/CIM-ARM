#include "InstaDrop.h"
#include "MessageHandler.h"

@implementation InstaDrop

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
  myFunctionKey = 0;
  [self clear];
	return self;
}

/**/
- (BOOL) isAvaliable
{
  return myUser == NULL;
}

/**/
- (void) clear
{
  myUser = NULL;
  myCimCash = NULL;
	myCashReference = NULL;
	*myEnvelopeNumber = '\0';
}

/**/
- (void) setUser: (USER) aUser { myUser = aUser; }
- (USER) getUser { return myUser; }

/**/
- (void) setCimCash: (CIM_CASH) aCimCash { myCimCash = aCimCash; }
- (CIM_CASH) getCimCash { return myCimCash; }

/**/
- (void) setFunctionKey: (int) aFunctionKey { myFunctionKey = aFunctionKey; }
- (int) getFunctionKey { return myFunctionKey; }

/**/
- (void) setCashReference: (CASH_REFERENCE) aCashReference { myCashReference = aCashReference; }
- (CASH_REFERENCE) getCashReference { return myCashReference; }

/**/
- (void) setEnvelopeNumber: (char *) anEnvelopeNumber { stringcpy(myEnvelopeNumber, anEnvelopeNumber); }
- (char *) getEnvelopeNumber { return myEnvelopeNumber; }

/**/
- (void) setApplyTo: (char *) anApplyTo { stringcpy(myApplyTo, anApplyTo); }
- (char *) getApplyTo { return myApplyTo; }

/**/
- (STR) str
{

  if ([self isAvaliable]) {
    formatResourceStringDef(myBuffer, RESID_AVAILABLE, "%d.Disponible", myFunctionKey);
  } else {
    sprintf(myBuffer, "%d.%s", myFunctionKey, [myUser getFullName]);
  }
  
  return myBuffer;
  
  
}

@end
