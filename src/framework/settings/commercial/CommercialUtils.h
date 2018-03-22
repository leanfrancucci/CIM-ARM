#ifndef COMMERCIAL_UTILS_H
#define COMMERCIAL_UTILS_H

#define COMMERCIAL_UTILS id

#include <Object.h>
#include "ctapp.h"
#include "JWindow.h"
#include "system/util/all.h"
#include "openssl/dsa.h"
#include "openssl/objects.h"
#include "openssl/x509.h"

/**
 *
 */
@interface CommercialUtils : Object
{

}

/**/
+ (char*) encodeSignature: (unsigned char*) aSignature bytesQty: (int) aBytesQty buffer: (char*) aBuffer;

/**/
+ (int) decodeSignature: (char*) aSource signature: (unsigned char*) aSignature;

/**/
+ (int) verifySignature: (DSA*) dsa data: (unsigned char*) aData signature: (char*) aSignature signatureLen: (int) aSignatureLen;

/**/
+ (char*) signAndEncodeData: (DSA*) dsa data: (unsigned char*) aData signature: (char*) aSignature;

@end

#endif
