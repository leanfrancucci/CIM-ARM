#include "CipherManager.h"
#define printd(args...)
/*tabla para encriptar archivos*/ 
unsigned char encodeTable[] = {
      167, 243, 104, 103, 169, 18, 36, 185, 137, 131, 204, 72, 147, 96, 28, 161,
      162, 34, 231, 201, 77, 149, 230, 199, 192, 11, 136, 220, 23, 227, 148, 60,
      241, 228, 7, 174, 69, 83, 31, 255, 209, 124, 65, 78, 146, 46, 5, 216, 66,
      84, 180, 89, 178, 212, 9, 115, 102, 87, 29, 198, 42, 68, 129, 94, 236,
      155, 39, 197, 151, 41, 160, 32, 163, 80, 186, 164, 49, 108, 120, 139, 122,
      109, 43, 184, 152, 98, 219, 217, 193, 233, 76, 112, 252, 150, 239, 251,
      138, 99, 58, 126, 156, 0, 203, 25, 218, 187, 254, 229, 116, 240, 153, 248,
      97, 135, 222, 38, 125, 91, 225, 62, 133, 13, 213, 189, 242, 33, 53, 118,
      176, 190, 130, 50, 234, 51, 27, 56, 172, 44, 30, 194, 158, 143, 26, 15,
      12, 24, 165, 170, 235, 64, 117, 249, 221, 154, 157, 119, 171, 205, 10,
      253, 67, 232, 195, 173, 6, 200, 4, 175, 196, 105, 226, 224, 59, 106, 211,
      61, 74, 237, 90, 145, 207, 93, 75, 95, 247, 179, 1, 48, 45, 238, 132, 210,
      144, 246, 113, 142, 114, 22, 57, 177, 52, 85, 3, 134, 168, 71, 159, 127,
      215, 244, 86, 208, 2, 81, 14, 182, 123, 107, 191, 141, 40, 214, 183, 128,
      206, 250, 73, 35, 181, 37, 16, 8, 202, 100, 166, 47, 140, 19, 223, 88, 82,
      101, 20, 21, 54, 110, 245, 17, 121, 79, 55, 111, 92, 188, 63, 70};

/*tabla para desencriptar archivos*/ 
unsigned char decodeTable[] = {
      101, 186, 212, 202, 166, 46, 164, 34, 231, 54, 158, 25, 144, 121, 214,
      143, 230, 247, 5, 237, 242, 243, 197, 28, 145, 103, 142, 134, 14, 58, 138,
      38, 71, 125, 17, 227, 6, 229, 115, 66, 220, 69, 60, 82, 137, 188, 45, 235,
      187, 76, 131, 133, 200, 126, 244, 250, 135, 198, 98, 172, 31, 175, 119,
      254, 149, 42, 48, 160, 61, 36, 255, 205, 11, 226, 176, 182, 90, 20, 43,
      249, 73, 213, 240, 37, 49, 201, 210, 57, 239, 51, 178, 117, 252, 181, 63,
      183, 13, 112, 85, 97, 233, 241, 56, 3, 2, 169, 173, 217, 77, 81, 245, 251,
      91, 194, 196, 55, 108, 150, 127, 155, 78, 248, 80, 216, 41, 116, 99, 207,
      223, 62, 130, 9, 190, 120, 203, 113, 26, 8, 96, 79, 236, 219, 195, 141,
      192, 179, 44, 12, 30, 21, 93, 68, 84, 110, 153, 65, 100, 154, 140, 206,
      70, 15, 16, 72, 75, 146, 234, 0, 204, 4, 147, 156, 136, 163, 35, 167, 128,
      199, 52, 185, 50, 228, 215, 222, 83, 7, 74, 105, 253, 123, 129, 218, 24,
      88, 139, 162, 168, 67, 59, 23, 165, 19, 232, 102, 10, 157, 224, 180, 211,
      40, 191, 174, 53, 122, 221, 208, 47, 87, 104, 86, 27, 152, 114, 238, 171,
      118, 170, 29, 33, 107, 22, 18, 161, 89, 132, 148, 64, 177, 189, 94, 109,
      32, 124, 1, 209, 246, 193, 184, 111, 151, 225, 95, 92, 159, 106, 39};
	  
@implementation CipherManager

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myReader = [FileReader new];
	myWriter = [FileWriter new];
	return self;
}

-(int) encodeFile: (char *) filename destination: (char *) aDestination size: (long)fSize
{
	FILE *fo;
	FILE *fi;
	long i,j;
	unsigned char buffer[1500];

	printd("  #Codificando Archivo %s de %d bytes...\n",filename,fSize);
	
	fi = fopen(filename, "r+b");
	fo = fopen(aDestination, "w+b");

	if ((fi==NULL) || (fo==NULL)){
		printd("  ERROR: Codificando Archivo %s ...\n",filename);
		return 0;
	}

	[myReader initWithFile:fi];
	[myWriter initWithFile:fo];
	
	for(i=0,j=0;i<fSize;++i,++j){
		if ([myReader read:&buffer[j] qty:1]){
			buffer[j]=encodeTable[buffer[j]];
			if (j==1499){
				//fwrite(buffer,1500,1,fo);
				[myWriter write:buffer qty:1500];
				j=-1;
			}
		}
		else
			printd("  ERROR: Leyendo Archivo %s ...\n",filename);
	}
	
	if (j>0)
		[myWriter write:buffer qty:j];

	[myWriter close];
	[myReader close];
	printd("  #Se genero el archivo %s (codificado)!!!\n",aDestination);
	return 1;
}

-(int) decodeFile: (char *) filename destination: (char *) aDestination size: (long)fSize
{
	FILE *fo;
	FILE *fi;
	long i,j;
	char fne[200];
	unsigned char buffer[1500];
	
	printd("  #Decodificando Archivo %s de %d bytes...\n",filename,fSize);
  strcpy(fne, aDestination);

	printd("  #Se generara el archivo decodificado %s\n",fne);
	fi = fopen(filename, "r+b");
	fo = fopen(fne, "w+b");

	if ((fi==NULL) || (fo==NULL)){
		printd("  ERROR: Decodificando Archivo %s ...\n",filename);
		return 0;
	}
	
	[myReader initWithFile:fi];
	[myWriter initWithFile:fo];
	
	for(i=0,j=0;i<fSize;++i,++j){
		if ([myReader read:&buffer[j] qty:1]){
			buffer[j]=decodeTable[buffer[j]];
			if (j==1499){
				[myWriter write:buffer qty:1500];
				j=-1;
			}
		}
		else
			printd("  ERROR: Leyendo Archivo %s ...\n",filename);
	}
	
	if (j>0)
		[myWriter write:buffer qty:j];
	
	[myWriter close];
	[myReader close];
	printd("  #Se genero el archivo %s (decodificado)!!!\n",fne);
	return 1;
}
/**/
- free
{
	[myWriter free];
	[myReader free];
	return [super free];	
}
@end
