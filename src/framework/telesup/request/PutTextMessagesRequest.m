#include "PutTextMessagesRequest.h"
#include "assert.h"
#include "system/util/all.h"
#include "PrinterSpooler.h"
#include "XMLConstructor.h"


/* macro para debugging */
//#define printd(args...) doLog(args)
#define printd(args...)

static PUT_TEXT_MESSAGES_REQUEST mySingleInstance = nil;
static PUT_TEXT_MESSAGES_REQUEST myRestoreSingleInstance = nil;

#define FROM_SIZE				70
#define TO_SIZE   			70
#define SUBJECT_SIZE 	 120
#define DATE_SIZE				25
#define BODY_SIZE     1024
#define HEADER_SIZE 	(FROM_SIZE + TO_SIZE + SUBJECT_SIZE + DATE_SIZE)

@implementation PutTextMessagesRequest	

/**/
+ getSingleVarInstance
{
	 return mySingleInstance; 
};
+ (void) setSingleVarInstance: (id) aSingleVarInstance
{
	 mySingleInstance =  aSingleVarInstance;
};

/**/
+ getRestoreVarInstance 
{
	 return myRestoreSingleInstance; 
};

+ (void) setRestoreVarInstance: (id) aRestoreVarInstance
{
	 myRestoreSingleInstance = aRestoreVarInstance; 
};

/**/
- initialize
{
	[super initialize];
	[self setReqType: PUT_TEXT_MESSAGES_REQ];
	return self;
}

- (void) printMessage: (datetime_t) aDateTime from: (char*) aFrom to: (char*) aTo
				 subject: (char*) aSubject body: (char*) aBody
{
	char *text ;
	char buf[50];

	// El body y el header mas un changui
	// La memoria dinamica solicitada es liberada por el Spooler
	text = malloc(BODY_SIZE + 512);
	
	sprintf(text,	"\n \n"
								"------------------------\n"
								"Fecha: %s\n"
								"De: %s\n"
								"Para: %s\n"
								"Asunto: %s\n"
								"------------------------\n"
								"%s"
								"\n \n \n \n \n \n",
								formatDateTime(aDateTime, buf),
								aFrom,
								aTo,
								aSubject,
								aBody);

										
	// Mando a imprimir el documento generado
//////////////////  CIM: DESCOMENTAR //////////////////////////////////////// 
//	tree = [[XMLConstructor getInstance] buildXML: text];
//	[[PrinterSpooler getInstance] addPrintingJob: TEXT_PRT copiesQty: 1 ignorePaperOut: TRUE tree: tree];

	free(text);
	
}

/**/
- (void) processMessages
{
	FILE *f;
	char body[1025];
	char date[DATE_SIZE+1];
	char from[FROM_SIZE+1];
	char to[TO_SIZE+1];
	char subject[SUBJECT_SIZE+1];
	int size;
	int i = 0;
	char c;
	int charCount = 0;
	int index = 0;
	
	/** Por ahora esta cableado a solo un mensaje de texto.
	    @todo: hacer que funcione para n mensajes.*/
			
	f = fopen(myTargetFileName, "rb");
	if (!f) return;

	fseek(f, 0, SEEK_END);
	size = ftell(f);
	rewind(f);
	
	fread(date, 1, DATE_SIZE, f);
	date[DATE_SIZE] = 0;
	
	fread(from, 1, FROM_SIZE, f);
	from[FROM_SIZE] = 0;
	
	fread(to, 1, TO_SIZE, f);
	to[TO_SIZE] = 0;

	fread(subject, 1, SUBJECT_SIZE, f);
	subject[SUBJECT_SIZE] = 0;

	/** todo el codigo que viene a continuacion lo hago porque la impresora
	    termina no acepta texto libre (lo corta).
			@todo: con el spooler nuevo esto deberia pasar al driver. */
	while (i < size - HEADER_SIZE)
	{

		fread(&c, 1, 1, f);

		// Si hay un enter, reinicio la cantidad de caracteres
		if (c == 10 || c == 13 ) {
			charCount = -1;
		}

		// Si la cantidad de caracteres es mayor a 23, pongo un enter
		if (charCount >  23) {
			body[index] = 10;			
			index++;
			charCount = 0;
		} 

		body[index] = c;
		index++;
		i++;
		charCount++;
				
	}

	body[index] = 0;

	fclose(f);

	// Elimino el archivo luego de imprimir el mensaje
	
/** @todo: deberia cambiarse al incorporarse la nueva version del spooler, se deberia
	    generar un XML con el mensaje y nada mas */

	[self printMessage: ISO8106ToDatetime(date)
										  from: from
											to: to
											subject: subject
											body: body];

}

/**/
- (void) endRequest
{
	[super endRequest];

	// Procesa el archivo
	[self processMessages];	
}


@end



