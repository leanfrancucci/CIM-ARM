#ifndef GENERIC_GET_REQUEST_H
#define GENERIC_GET_REQUEST_H

#define GENERIC_GET_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "Request.h"
#include "cl_genericpkg.h"


/**
 *	Consulta   
 */
@interface GenericGetRequest: Request
{
  GENERIC_PACKAGE myPackage;
  id myReqFacade;
	COLLECTION myEntityList;
  int myRef;
  char myLoadStr[200];
	int myTelesupRol;
}		

/**
 * Carga un paquete con todos los datos enviados por el mensaje.
 */ 
- (void) loadPackage: (char*) aMessage;

- (void) setTelesupRol: (int) aTelesupRol;

@end

#endif
