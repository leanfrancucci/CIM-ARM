#ifndef GENERICSETREQUEST_H
#define GENERICSETREQUEST_H

#define GENERICSETREQUEST id

#include <Object.h>
#include "ctapp.h"

#include "Request.h"
#include "cl_genericpkg.h"


@interface GenericSetRequest: Request
{
  GENERIC_PACKAGE myPackage;
  
  /*nombres de las funciones a ejecutar*/
  char myActivateFnc[100];
  char myDeactivateFnc[100];
  char myAddFnc[100];
  char myRemoveFnc[100];
  char mySettingFnc[100];
  char mySendKeyValueResponseFnc[100];
  
  //referencia a retornar
  int myEntityRef;
  id myIDRef;
	int myTelesupRol; 
}		

/**/
- (void) loadPackage: (char*) aMessage;

/**/
- (void) setTelesupRol: (int) aTelesupRol;

@end
#endif
