#ifndef LICENSE_H
#define LICENSE_H

#define LICENSE id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"
#include "LicUtil.h"

/**
 * Clase  
 */
 
@interface License: Object
{

}

+ new;
- initialize;

- (void) createLicToBlocks: (char *) aBuffer strBlock1: (unsigned char *) aStrBlock1 strBlock2: (unsigned char *) aStrBlock2;

- (void) createLic: (char *) aBuffer serviceCount: (int) aServiceCount strResult: (unsigned char *) aStrResult vs: (int *) aVs;

- (void) maskDiscMac: (char *) aBuffer str: (unsigned char *) aStr;

- (int) verifieLic: (char *) aBuffer serviceCount: (int) aServiceCount strResult: (unsigned char *) aStrResult;

/*
 * Si no debe validar licencia devuelve -1 en caso contrario devuelve 0 cuando no esta habilitado el 
 * servicio y 1 cuando esta habilitado el servicio. Para el caso de las cabinas y puestos de pc devuelve
 * un numero que puede ser mayor a 1 indicando la cantidad de cabinas o puestos habilitados.
 */
- (int) getServiceValue: (int) aServiceType;

#ifdef __WIN32
- (int) getDiscNumber: (char *) aBuffer discName: (unsigned char *) aDiscName;
#endif

#ifdef __UCLINUX
- (int) getMacAddess: (char *) aBuffer;
#endif

- (void) getBlockNumber: (char *) aBuffer serviceCount: (int) aServiceCount strResult: (unsigned char *) aStrResult vs: (int *) aVs;

- (int) hasVerifiedLic: (int) aServiceCount strResult: (unsigned char *) aStrResult;

@end

#endif
