#include "JSystemInfoForm.h"
#include "ctversion.h"
#include "SystemTime.h"
#include "TelesupervisionManager.h"
#include "PrinterSpooler.h"
#include "XMLConstructor.h"
#include "MessageHandler.h"
#include <sys/vfs.h>

//#define printd(args...) doLog(args)
#define printd(args...)

#define MAX_TEXT_SIZE 4096

/**/
int
getFileSystemInfo(char *fs, long *space, long *free)
{
	struct statfs buf;
	if (statfs(fs, &buf) != 0 ) return -1;

	*space = buf.f_bsize * buf.f_blocks;
	*free  = buf.f_bsize * buf.f_bfree;

	return 0;
}


@implementation  JSystemInfoForm

static char myBackMessage[] 			= "atras";
static char myPrintMessage[]			= "imprime";

- (void) generateForm;

/**/
- (void) onCreateForm
{
	[super onCreateForm];

	[self generateForm];

}


/**/
- (char *) generateInfo: (BOOL) aWithSpaces
{
	char *text;
	char line[100];
	char aux[100];
	int  i;
	long total, free;
	float percUsed;
	COLLECTION telesups = [[TelesupervisionManager getInstance] getTelesups];
	TELESUP_SETTINGS telesup;
	char *kernelVersion = getKernelVersion();
	
	printd("JSystemInfoForm -> printInfo\n");
	
	text = (char*) malloc(MAX_TEXT_SIZE);
	strcpy(text, "");

	strcat(text, "------------------------\n");
	
	// Numero de version
	formatResourceStringDef(line, RESID_VERSION_NUMBER, "Nro. Version: \n%s\n", APP_VERSION_STR);
	strcat(text, line);
	if (aWithSpaces) strcat(text, "\n");

	// Numero de release
	formatResourceStringDef(line, RESID_RELEASE, "Release: \n%s\n", APP_RELEASE_DATE);
	strcat(text, line);
	if (aWithSpaces) strcat(text, "\n");

	// Version del sistema operativo
	formatResourceStringDef(line, RESID_OS_VERSION, "Version OS: \n%s\n", kernelVersion != NULL ? kernelVersion: getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));
	strcat(text, line);
	if (aWithSpaces) strcat(text, "\n");

	// Espacio disponible en flash
	if ( getFileSystemInfo(BASE_PATH "", &total, &free) == 0 ) {
		percUsed = (float)(total-free)/(float)total*100.0;
		sprintf(aux, "%.1f%%", percUsed );
	}	else
	  formatResourceStringDef(aux, RESID_NOT_AVAILABLE, "NO DISPONIBLE");

	formatResourceStringDef(line, RESID_USE_FLASH, "Uso flash (%%): \n%s\n", aux);
	strcat(text, line);
	if (aWithSpaces) strcat(text, "\n");

	
	/* Supervisiones **********************************************/
	for (i = 0; i < [telesups size]; ++i)
	{
		telesup = [telesups at: i];
		assert(telesup);

		strcat(text, "------------------------\n");
		
    // Descripcion de la supervision
    formatResourceStringDef(line, RESID_SUPERV2, "Supervision: \n%-15s\n", [telesup getTelesupDescription]);
    strcat(text, line);
		if (aWithSpaces) strcat(text, "\n");		

    // Fecha/hora del ultimo intento
		if ([telesup getLastAttemptDateTime] == 0)
			formatResourceStringDef(aux, RESID_NOT_AVAILABLE, "NO DISPONIBLE");
		else
			formatDateTime([telesup getLastAttemptDateTime], aux);

		formatResourceStringDef(line, RESID_LAST_TRY_SUPERV, "Ult.int.supervision:\n%s\n", aux);
		strcat(text, line);
		if (aWithSpaces) strcat(text, "\n");		

    // Fecha/hora de ultima supervision exitosa
		if ([telesup getLastSuceedTelesupDateTime] == 0)
			formatResourceStringDef(aux, RESID_NOT_AVAILABLE, "NO DISPONIBLE");
		else
			formatDateTime([telesup getLastSuceedTelesupDateTime], aux);

		formatResourceStringDef(line, RESID_LAST_SUPERV, "Ult.supervision:\n%s\n", aux);
		strcat(text, line);
		if (aWithSpaces) strcat(text, "\n");		

    // Fecha/hora de proxima supervision
		if ([telesup getNextTelesupDateTime] == 0)
			formatResourceStringDef(aux, RESID_NOT_AVAILABLE, "NO DISPONIBLE");
		else
			formatDateTime([telesup getNextTelesupDateTime], aux);

		formatResourceStringDef(line, RESID_NEXT_SUPERV, "Prox. superv.:\n%s\n", aux);
		strcat(text, line);
		if (aWithSpaces) strcat(text, "\n");		
		
    // Fecha/hora de segundo intento de supervision
		if ([telesup getNextSecondaryTelesupDateTime] == 0)
			formatResourceStringDef(aux, RESID_NOT_AVAILABLE, "NO DISPONIBLE");
		else
			formatDateTime([telesup getNextSecondaryTelesupDateTime], aux);

		formatResourceStringDef(line, RESID_NEXT_SECOND_SUPERV, "Prox. superv. sec.:\n%s\n", aux);
		strcat(text, line);
		if (aWithSpaces) strcat(text, "\n");		
    
    // Marco de supervision
		formatResourceStringDef(line, RESID_FRAME_MIN, "Marco:\n%d min\n", [telesup getTelesupFrame]);
		strcat(text, line);		    		
		if (aWithSpaces) strcat(text, "\n");		
		
    // Tiempo inactividad de la cabina    
		//sprintf(line, "Tpo. inac. cabina:\n%d min\n", [telesup getCabinIdleWaitTime]);
		//strcat(text, line);		
		//if (aWithSpaces) strcat(text, "\n");		

	}	

	printd("%s", text);
	
	return text;	
}

/**/
- (void) generateForm
{
	char *text;
	char *p;
	char line[100];
	char *index;
	JLABEL label;
	int size;
	BOOL firstTime = TRUE;
	
	text = [self generateInfo: TRUE];
	p = text;
	
	while (*p != 0) {

		index = strchr(p, '\n');
		size = index-p;

		if (size > 20) size = 20;
		strncpy(line, p, size);
		line[size] = 0;

		// Si comienza con un guion, se ignora la linea
		if (*line != '-') {

			if (firstTime) firstTime = FALSE; else [self addFormEol];
			
			label = [JLabel new];
			[label setCaption: line];
			[self addFormComponent: label];


		}
		
		printd("[LINE] = |%s|\n", line);
		
		p = index+1;
		
	}

	free(text);
	
}

/**/
- (void) printInfo
{
	scew_tree* tree;
	char *text;
	char *p;
	
	text = [self generateInfo: FALSE];

	p = malloc(MAX_TEXT_SIZE);
	formatResourceStringDef(p, RESID_SYSTEM_INFO, "DELSAT CT8016\nInfo. del sistema\n");
	strcat(p, text);
	
	free(text);

	// Mando a imprimir el documento generado
	tree = [[XMLConstructor getInstance] buildXML: p];
	[[PrinterSpooler getInstance] addPrintingJob: TEXT_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree];
	
	free(p);

}

/**/
- (void) onMenu1ButtonClick
{
	[self closeForm];
}

/**/
- (void) onMenu2ButtonClick
{
	[self printInfo];
}

/**/
- (char *) getCaption1
{	
	return getResourceStringDef(RESID_BACK_KEY, myBackMessage);
}

/**/
- (char *) getCaption2
{	
	return getResourceStringDef(RESID_PRINT, myPrintMessage);
}



@end

