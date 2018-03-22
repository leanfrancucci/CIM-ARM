#include "CommercialUtils.h"
#include "MessageHandler.h"

@implementation CommercialUtils

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

/**/
+ (char*) encodeSignature: (unsigned char*) aSignature bytesQty: (int) aBytesQty buffer: (char*) aBuffer
{
	int i;
	int j;
	int number;
	char temp[10];
	char formattedNumber[20];

	stringcpy(aBuffer, "");

	for (i=0; i<aBytesQty; ++i) {

		number = aSignature[i];
		//doLog(0,"int = %d\n", number); fflush(stdout);
		sprintf(temp, "%d", number);
		//doLog(0,"number = %s\n", temp);

		stringcpy(formattedNumber, "");

		//doLog(0,"strlen temp = %d\n", strlen(temp));

		for (j=0; j<(3-strlen(temp)); ++j) 
			strcat(formattedNumber, "0");

		strcat(formattedNumber, temp);
		//doLog(0,"%s\n", formattedNumber);
		strcat(formattedNumber, " ");
		strcat(aBuffer, formattedNumber);
	}

	//doLog(0,"buffer = %s\n", aBuffer);
	return aBuffer;
}

/**/
+ (int) decodeSignature: (char*) aSource signature: (unsigned char*) aSignature
{
	STRING_TOKENIZER myTokenizer;
	char token[20];
	int i;
	int number;
	int sigLen = 0;

	myTokenizer = [StringTokenizer new];
	[myTokenizer setDelimiter: " "];
	[myTokenizer setTrimMode: TRIM_NONE];

	[myTokenizer setText: aSource];
	i = 0;	

	while ([myTokenizer hasMoreTokens]) {
		[myTokenizer getNextToken: token];
		//doLog(0,"token = %s\n", token);
	
		number = 0;

		number = atoi(token);
		aSignature[i] = number;
		++ i;

		//doLog(0,"number = %d\n", number);
		++sigLen;
	}

	aSignature[sigLen] = '\0';
	//doLog(0,"signature = %s\n", aSignature);

	// Retorna la cantidad de bytes de la firma
	return sigLen;
}

/**/
+ (int) verifySignature: (DSA*) dsa data: (unsigned char*) aData signature: (unsigned char*) aSignature signatureLen: (int) aSignatureLen
{
  SHA_CTX       ctx;   
  unsigned char hash[25]; // SHA1 has a 20-byte digest.  
	int result = 0;

	// Genera el hash
  SHA1_Init(&ctx);   
  SHA1_Update(&ctx, aData, strlen(aData)); 
  SHA1_Final(hash, &ctx); 

	result = DSA_verify(NID_sha1, hash, 20, aSignature, aSignatureLen, dsa);

	return result;

}

/**/
+ (char*) signAndEncodeData: (DSA*) dsa data: (unsigned char*) aData signature: (char*) aSignature
{
  SHA_CTX       ctx;   
  unsigned char hash[25]; // SHA1 has a 20-byte digest.  
	unsigned char sig[50];
  unsigned int  sigLen;
	int i;

	// Genera el hash
  SHA1_Init(&ctx);   
  SHA1_Update(&ctx, aData, strlen(aData)); 
	SHA1_Final(hash, &ctx); 
	
	// Firma el hash
	sig[0] = '\0';

  DSA_sign(NID_sha1, hash, 20, sig, &sigLen, dsa);
	
  // conversion a numero 
	sig[sigLen] = '\0';
	//doLog(0,"sig = %s\n", sig);

	// Codifica la firma
	[self encodeSignature: sig bytesQty: sigLen buffer: aSignature];

	return aSignature;
}

@end
