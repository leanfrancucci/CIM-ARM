#include "Transaction.h"
#include "DBExcepts.h"
#include "system/os/all.h"
#include "SQLWrapper.h"

// Mutex global: de esta forma evito que pueda haber mas de una transaccion
// al mismo tiempo. Esta es una limitacion que en un futuro no deberia estar,
// pero hoy en dia la API no me permite mas de una transaccion al mismo tiempo
static TRANSACTION myGlobalTransactionMutex = NULL;

@implementation Transaction

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
  if (myGlobalTransactionMutex == NULL) {
    myGlobalTransactionMutex = [OMutex new];
  }
	return self;
}

/**/
- (void) startTransaction
{
  [myGlobalTransactionMutex lock];
  sqlStartTransaction();
}

/**/
- (void) commitTransaction
{
  sqlCommitTransaction();
  [myGlobalTransactionMutex unLock];
}

/**/
- (void) abortTransaction
{
  sqlRollbackTransaction();
  [myGlobalTransactionMutex unLock];
}


@end
