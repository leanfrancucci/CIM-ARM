#ifndef CtSystem_H
#define CtSystem_H

#define CT_SYSTEM id

#include <objpak.h>
#include <stdio.h>
#include <Object.h>
#include <time.h>
#include <assert.h>
#include "OSServices.h"
#include "MessageHandler.h"
#include "ConsoleAcceptor.h"


/**
 *	
 *
 *	<<singleton>>	
 */
@interface CtSystem: Object
{
  char databasePath[255];
  char telesupPath[255];
  id splash;
	BOOL errorInDB;
}

+ getInstance;
- (BOOL) startSystem: (id) anObserver;
- (void) shutdownSystem;
- (void) shutdownSystemWoVirtualScreen;
- (id) getSplash;
- (void) setSplash: (id) anObserver;

@end

#endif
