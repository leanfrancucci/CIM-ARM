#include "AbstractAcceptor.h"


@implementation AbstractAcceptor

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myAcceptorSettings = NULL;
	myObserver = NULL;
	*myVersion = '\0';
	return self;
}

/**/
- (void) setAcceptorSettings: (ACCEPTOR_SETTINGS) aValue { myAcceptorSettings = aValue; }
- (ACCEPTOR_SETTINGS) getAcceptorSettings { return myAcceptorSettings; }

/**/
- (void) setObserver: (id) anObserver { myObserver = anObserver; }

/**/
- (void) initAcceptor { }

/**/
- (void) open 
{
}

/**/
- (void) reopen
{
}

/**/
- (void) close
{
}

/**/
- (BOOL) canReopen
{
  return FALSE;
}

/**/
- (void) setValidatedMode
{
}

/**/
- (char *) getErrorDescription: (int) aCode
{
	return NULL;
}

/**/
- (char *) getCurrentErrorDescription
{
	return NULL;
}

/**/
- (char *) getRejectedDescription: (int) aCode
{
	return NULL;
}

/**/
- (BOOL) isEnabled
{
	return TRUE;
}

/**/
- (BOOL) hasEmitStackerWarning { return myHasEmitStackerWarning; }
- (void) setHasEmitStackerWarning: (BOOL) aValue { myHasEmitStackerWarning = aValue; }
- (BOOL) hasEmitStackerFull { return myHasEmitStackerFull; }
- (void) setHasEmitStackerFull: (BOOL) aValue { myHasEmitStackerFull = aValue; } 

/**/
- (char *) getVersion { return myVersion; }

@end
