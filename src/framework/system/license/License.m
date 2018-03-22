#include "License.h"

@implementation License

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{  
	return self;
}

- (void) createLicToBlocks: (char *) aBuffer strBlock1: (unsigned char *) aStrBlock1 strBlock2: (unsigned char *) aStrBlock2
{    
  LIBLIC_createLicToBlocks(aBuffer, aStrBlock1, aStrBlock2);
}

- (void) createLic: (char *) aBuffer serviceCount: (int) aServiceCount strResult: (unsigned char *) aStrResult vs: (int *) aVs
{
  LIBLIC_createLic(aBuffer, aServiceCount, aStrResult, aVs);
}

- (void) maskDiscMac: (char *) aBuffer str: (unsigned char *) aStr
{
  LIBLIC_maskDiscMac(aBuffer, aStr);
}

- (int) verifieLic: (char *) aBuffer serviceCount: (int) aServiceCount strResult: (unsigned char *) aStrResult
{
  return LIBLIC_verifieLic(aBuffer, aServiceCount, aStrResult);
}

- (int) getServiceValue: (int) aServiceType
{
  char aBuffer[100];
  char mask[100];
  char disc[100];
  int serv;
  int r = 0;

  aBuffer[0] = '\0';
  disc[0] = '\0';
  mask[0] = '\0';
    
  #ifdef __WIN32  
  r = LIBLIC_getDiscNumber(disc, "C:\\");    
  #endif
  
  #ifdef __UCLINUX
  r = LIBLIC_getMacAddess(disc);
  #endif
  
  if (r == 0) {
    LIBLIC_maskDiscMac(mask, disc);
    if (LIBLIC_hasVerifiedLic(4,mask) == 0){
      if (LIBLIC_verifieLic(aBuffer, 4, mask) == 0){
        serv = LIBLIC_getServiceValue(aServiceType);
  ///      doLog(0,"LICENCIA: Valor del servicio: %d\n", serv);
        return serv;      
      }
      else{ // la licencia no es valida
    //    doLog(0,"LICENCIA: La licencia no es válida\n");
        return 0;
      }
    }else{ // No hay que verificar licencia                         
    //    doLog(0,"LICENCIA: No hay que verificar licencia\n");        
        return -1;      
    }
        
  }else{
    // hubo un error al leer el disco
  //  doLog(0,"LICENCIA: Error al leer el nro de serie del disco\n");
    return 0;
  }   
}

#ifdef __WIN32
- (int) getDiscNumber: (char *) aBuffer discName: (unsigned char *) aDiscName
{
  return LIBLIC_getDiscNumber(aBuffer, aDiscName);
}
#endif

#ifdef __UCLINUX
- (int) getMacAddess: (char *) aBuffer
{
  return LIBLIC_getMacAddess(aBuffer);
}
#endif

- (void) getBlockNumber: (char *) aBuffer serviceCount: (int) aServiceCount strResult: (unsigned char *) aStrResult vs: (int *) aVs
{
  LIBLIC_getBlockNumber(aBuffer, aServiceCount, aStrResult, aVs);
}

- (int) hasVerifiedLic: (int) aServiceCount strResult: (unsigned char *) aStrResult
{
  return LIBLIC_hasVerifiedLic(aServiceCount, aStrResult);
}

@end
