#include "StateImasConfiguration.h"
#include "CommercialStateFacade.h"
#include "system/util/all.h"

#include "SystemTime.h"

//#define printd(args...)
#define printd(args...)//doLog(0,args)

@implementation StateImasConfiguration

/**/
-(int) verifyUse: (datetime_t) aDate
{
	return ([SystemTime getLocalTime]>= aDate);	
}

/**/
-(int) applyConfiguration:(char *) filename destination:(char*) dest
{
	datetime_t uDate;
	int year, month,day,hour, min;
  char commercialStateStr[1];
  int commercialState;
	char fechaVigencia[13]; /*'ddmmyyyyhh24mi'  	12*/
	char *buf;
  int fSize;
  CIPHER_MANAGER cipherManager;
  char tmpFileName[255];
	
	printd("applyConfiguration: %s\n",filename);

  fSize = [[FileManager getDefaultInstance] getFilesize: filename];
  cipherManager = [CipherManager new];
  sprintf(tmpFileName, "%sdec", filename);
  [cipherManager decodeFile: filename destination: tmpFileName size: fSize];
  [cipherManager free];
  
  buf = loadFile(tmpFileName, TRUE);
	if (buf == NULL)
		THROW(TSUP_FILE_NOT_FOUND_EX);

  // Elimino el archivo temporal	
  [[FileManager getDefaultInstance] deleteFile: tmpFileName];

	/*cargo los parametros*/
  memcpy(fechaVigencia, buf, 12);
	fechaVigencia[12]=0;

  /*estado comercial se encuentra en el ultimo byte */
	commercialStateStr[0] = buf[strlen(buf)-1];

	/*verifico vigencia*/
	day   = (fechaVigencia[0]-48)*10 + (fechaVigencia[1]-48);
	month = (fechaVigencia[2]-48)*10 + (fechaVigencia[3]-48);
	year	= (fechaVigencia[4]-48)*1000 + (fechaVigencia[5]-48)*100+ (fechaVigencia[6]-48)*10+ (fechaVigencia[7]-48);
	hour 	= (fechaVigencia[8]-48)*10 + (fechaVigencia[9]-48);
	min 	= (fechaVigencia[10]-48)*10 + (fechaVigencia[11]-48);	
	uDate	= [SystemTime encodeTime: year mon: month day: day hour: hour min: min sec: 0];	
	
	if ([self verifyUse:uDate]){
		/*si es vigente la aplico y la borro*/
		printd("Vigencia cumplida  \n");
		commercialState = *commercialStateStr - 48;

    if (commercialState == 1) {
      printd("Estado comercial: SYSTEM_ENABLE \n");
      [[CommercialStateFacade getInstance] setParamAsInteger: "State" 
        value: SYSTEM_ENABLE];
    } else if (commercialState == 2) {
      printd("Estado comercial: SYSTEM_SUSPENDED \n");
      [[CommercialStateFacade getInstance] setParamAsInteger: "State" 
        value: SYSTEM_SUSPENDED];
    } else {
    //  doLog(0,"Estado comercial: DESCONOCIDO (%d)\n", commercialState);
    }

    [[CommercialStateFacade getInstance] applyChanges];
		
		/*borro el archivo*/
		[[FileManager getDefaultInstance] deleteFile:filename];

	}
	else
		printd("Vigencia NO cumplida  \n");

	return 1;
}

@end
