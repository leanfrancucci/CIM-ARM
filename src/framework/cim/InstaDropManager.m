#include "InstaDropManager.h"
#include "CimExcepts.h"
#include "Audit.h"

@implementation InstaDropManager

static INSTA_DROP_MANAGER singleInstance = NULL; 

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}
 
/**/
- initialize
{
  int i;
  INSTA_DROP instaDrop;
  
  myInstaDrops = [Collection new];
  
  // Creo un Insta Drop por cada tecla de funcion
  for (i = 1; i < 10; ++i) {
    instaDrop = [InstaDrop new];
    [instaDrop setFunctionKey: i];
    [myInstaDrops add: instaDrop];
  }
  
	return self;
}

/**/
+ getInstance
{
  return [self new];
}

/**/
- (void) clearAll
{
	int i;

	for (i = 1; i < 10; ++i) {
		[self clearInstaDrop: i];
	}

}

/**/
- (void) setInstaDrop: (int) aFunctionKey 
		user: (USER) aUser 
		cimCash: (CIM_CASH) aCimCash
		cashReference: (CASH_REFERENCE) aCashReference
		envelopeNumber: (char *) anEnvelopeNumber
		applyTo: (char *) anApplyTo
{
  INSTA_DROP instaDrop;
  
  if (aFunctionKey < 1 || aFunctionKey > 9) THROW(CIM_INVALID_INSTA_DROP_EX);
  
  instaDrop = [myInstaDrops at: aFunctionKey - 1];
  [instaDrop setUser: aUser];
  [instaDrop setCimCash: aCimCash];
	[instaDrop setCashReference: aCashReference];
	[instaDrop setEnvelopeNumber: anEnvelopeNumber];
	[instaDrop setApplyTo: anApplyTo];

	[Audit auditEventCurrentUser: Event_INSTADROP_LOGIN additional: [aUser getLoginName] station: 0 logRemoteSystem: FALSE];

}

/**/
- (void) clearInstaDrop: (int) aFunctionKey
{
  INSTA_DROP instaDrop;
  
  if (aFunctionKey < 1 || aFunctionKey > 9) THROW(CIM_INVALID_INSTA_DROP_EX);

  instaDrop = [myInstaDrops at: aFunctionKey - 1];

	if (![instaDrop isAvaliable]) {
		[Audit auditEventCurrentUser: Event_INSTADROP_LOGOUT additional: "" station: 0 logRemoteSystem: FALSE];
	}

  [instaDrop clear];



} 

/**/
- (void) clearInstaDropByUser: (USER) aUser
{
  int i;
  INSTA_DROP instaDrop;
  
  for (i = 0; i < [myInstaDrops size]; ++i) {
    instaDrop = [myInstaDrops at: i];
    if ([instaDrop getUser] != NULL && [[instaDrop getUser] getUserId] == [aUser getUserId]) {
      [instaDrop clear];
			[Audit auditEventCurrentUser: Event_INSTADROP_LOGOUT additional: "" station: 0 logRemoteSystem: FALSE];
    }
  }
}

/**/
- (COLLECTION) getInstaDrops
{
  return myInstaDrops;
}

/**/
- (COLLECTION) getActiveInstaDrops
{
	COLLECTION list = [Collection new];
	int i;

	for (i = 0; i < [myInstaDrops size]; ++i) {
		if (![[myInstaDrops at: i] isAvaliable]) [list add: [myInstaDrops at: i]];
	}

	return list;
}

/**/
- (INSTA_DROP) getInstaDropForKey: (int) aFunctionKey
{
  if (aFunctionKey < 1 || aFunctionKey > 9) THROW(CIM_INVALID_INSTA_DROP_EX);
  
  return [myInstaDrops at: aFunctionKey - 1];
  
}

/**/
- (INSTA_DROP) getInstaDropForCash: (CIM_CASH) aCimCash
{
	int i;

	for (i = 0; i < [myInstaDrops size]; ++i) {
		if ([[myInstaDrops at: i] getCimCash] == aCimCash) return [myInstaDrops at: i];
	}

	return NULL;
}

@end
