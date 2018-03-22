#include "GeneralImasConfiguration.h"
#include "TelesupExcepts.h"
#include "system/util/all.h"
#include "Request.h"
#include "TelesupFacade.h"
#include "BillSettings.h"
#include "cttypes.h"

#define printd(args...) //doLog(0,args)

@implementation GeneralImasConfiguration

/**/
-(int) verifyUse: (datetime_t) aDate
{
	return ([SystemTime getLocalTime]>= aDate);	
}

/**/
-(int) applyConfiguration:(char *) filename destination:(char*) dest
{
	FILE *f;
	datetime_t uDate;
	int year, month,day,hour, min;
	int sendTraffic, sendAudits;
	TELESUP_FACADE facade = [TelesupFacade getInstance];	
	BILL_FACADE bFacade = [BillSettings getInstance];
	int ticketType;
  int maxTimeWithoutTelAllowed = 0;
  int fSize;
  CIPHER_MANAGER cipherManager;
  char tmpFileName[255];
	
	printd("applyConfiguration: %s\n",filename);

  fSize = [[FileManager getDefaultInstance] getFilesize: filename];
  cipherManager = [CipherManager new];
  sprintf(tmpFileName, "%sdec", filename);
  [cipherManager decodeFile: filename destination: tmpFileName size: fSize];
  [cipherManager free];
  
	f=fopen(tmpFileName,"rb");
	
	if (f== NULL)
		THROW(TSUP_FILE_NOT_FOUND_EX);
	
	/*cargo los parametros*/
	fread(fechaVigencia,12,1,f);
	fechaVigencia[12]=0;
	
	fread(tiempoTelesupervision,12,1,f);
	tiempoTelesupervision[12]=0;
	
	fread(enviarAuditoria,1,1,f);	
	enviarAuditoria[1]=0;
	
	fread(enviarTrafico,1,1,f);
	enviarTrafico[1]=0;
	

	fread(prefijoTicket,6,1,f);
	prefijoTicket[6]=0;
	
	fread(numeroInicialTicket,4,1,f);
	numeroInicialTicket[4]=0;

	fread(tipoTicket,1,1,f);	
	tipoTicket[1]=0;
	
	fread(valorImpuesto1,10,1,f);
	valorImpuesto1[10]=0;

	fread(siglaImpuesto1,10,1,f);
	siglaImpuesto1[10]=0;

	fread(valorImpuesto2,10,1,f);
	valorImpuesto2[10]=0;

	fread(siglaImpuesto2,10,1,f);
	siglaImpuesto2[10]=0;
	
	fread(valorImpuesto3,10,1,f);
	valorImpuesto3[10]=0;

	fread(siglaImpuesto3,10,1,f);
	siglaImpuesto3[10]=0;		
	
	fclose(f);

  // Elimino el archivo temporal	
  [[FileManager getDefaultInstance] deleteFile: tmpFileName];

	/*verifico vigencia*/
	day   	= (fechaVigencia[0]-48)*10 + (fechaVigencia[1]-48);
	month 	= (fechaVigencia[2]-48)*10 + (fechaVigencia[3]-48);
	year	= (fechaVigencia[4]-48)*1000 + (fechaVigencia[5]-48)*100+ (fechaVigencia[6]-48)*10+ (fechaVigencia[7]-48);
	hour 	= (fechaVigencia[8]-48)*10 + (fechaVigencia[9]-48);
	min 	= (fechaVigencia[10]-48)*10 + (fechaVigencia[11]-48);	
	uDate	= [SystemTime encodeTime: year mon: month day: day hour: hour min: min sec: 0];	
	
	if ([self verifyUse:uDate]){
		/*si es vigente la aplico y la borro*/
		printd("Vigencia cumplida  \n");
		
		/*grabo los valores de envio de informacion*/
		sendTraffic = (*enviarTrafico == '1');
		sendAudits = (*enviarAuditoria == '1');
		ticketType = atoi(tipoTicket);

    /*grabo la cantidad de dias sin supervisar*/
    // Viene en segundos y yo lo necesito en dias
    maxTimeWithoutTelAllowed = atoi(tiempoTelesupervision) / 86400;

    printd("maxTimeWithoutTelAllowed = %d", maxTimeWithoutTelAllowed);fflush(stdout);
    [facade setTelesupParamAsInteger: "MaxTimeWithoutTelAllowed" value: maxTimeWithoutTelAllowed telesupRol: myTelesupId];

    /**/
		printd("Grabo Send traffic = %d\n",sendTraffic);
		[facade setTelesupParamAsInteger: "SendTraffic" value: sendTraffic telesupRol: myTelesupId];
		printd("Grabo Send audits = %d\n",sendAudits);		
		[facade setTelesupParamAsInteger: "SendAudits" value: sendAudits telesupRol: myTelesupId];

		/*grabo el numero incial de ticket*/
		printd("Numero inicial de ticket %ld\n",atol(numeroInicialTicket));
		[bFacade setInitialNumber: atol(numeroInicialTicket)];
		
		/*grabo el prefijo de ticket*/				
		[bFacade setPrefix: prefijoTicket];

		/*grabo si es ticket unitario o totalizador*/
		printd("Tipo de ticket = %d\n", ticketType);
		if (ticketType == 0)
			[bFacade setTicketType: UNIQUE_BILL];
		else if (ticketType == 1)
			[bFacade setTicketType: RESUME_BILL];

		[bFacade billSettingsApplyChanges];

		[facade telesupApplyChanges:myTelesupId];
		
		/*borro el archivo*/
		[[FileManager getDefaultInstance] deleteFile: filename];

	}
	else
		printd("Vigencia NO cumplida  \n");
	
	return 1;
}

@end
