#include "TelesupFactory.h"
#include "PendingRequestTelesupD.h"
#include "InfoFormatter.h"
#include "DummyTelesupViewer.h"
#include "ConnectionSettings.h"
#include "TelesupFacade.h"
#include "TelesupervisionManager.h"

/* G2 */
#include "G2TelesupD.h"
#include "G2RemoteProxy.h"
#include "G2TelesupParser.h"
#include "G2InfoFormatter.h"
#include "G2TelesupErrorManager.h"
#include "G2ActivePIC.h"

/* IMAS */
#include "TITelesupD.h"
#include "TIRemoteProxy.h"
#include "TITelesupParser.h"
#include "TIInfoFormatter.h"

#include "Configuration.h"

/* macro para debugging */
#define printd(args...)		

/**/
@implementation TelesupFactory

static TELESUP_FACTORY myTelesupFactory = nil ;

/**/
+ new
{	
	if ( !myTelesupFactory ) 
		return myTelesupFactory = [[super new] initialize];	 
	
	return myTelesupFactory;
}

/**/
+ getInstance
{
	return [TelesupFactory new];
}; 

/**/
- getNewTelesupDaemon: (int) aTelesupId rol: (int) aRol viewer: (TELESUP_VIEWER) aTelesupViewer
						reader: (READER) aReader  writer: (WRITER) aWriter
{
	TELESUPD 				telesupd = NULL;
	REMOTE_PROXY 			proxy = NULL;
	TELESUP_PARSER 			parser = NULL;
	INFO_FORMATTER 			formatter = NULL;
	
  CONNECTION_SETTINGS connectionSettings;
  TELESUP_FACADE facade = [TelesupFacade getInstance];
	
	G2_ACTIVE_PIC			activePIC = NULL;
	BOOL disablePic = FALSE;
	BOOL disableLogin = FALSE;

	/**/
	assert(aTelesupId > 0);
	assert(aRol > 0);
	assert(aReader);
	assert(aWriter);

	if (aTelesupViewer == NULL)
		aTelesupViewer = [DummyTelesupViewer new];

	[aTelesupViewer setTelesupId: aRol];		
    printf("1!!!!\n");
	switch (aTelesupId) {

		case PIMS_TSUP_ID:
		case G2_TSUP_ID:
		case SARII_PTSD_TSUP_ID:
		case CMP_OUT_TSUP_ID:
		case HOYTS_BRIDGE_TSUP_ID:
		case BRIDGE_TSUP_ID:
		
		//  doLog(0,"TELESUPERVISION G2\n");
		  telesupd = [G2TelesupD new];
			assert(telesupd);
						
			/**/
			activePIC = [G2ActivePIC new];
			assert(activePIC);
			/* hay que configurar el PIC adecuadamente */			
			[telesupd setActivePIC: activePIC];

			// Se fija en el archivo de configuracion si tiene deshabilitado el PIC
			// Esto deberia esta deshabilitado unicamente con motivos de testing
			disablePic = [[Configuration getDefaultInstance] getParamAsInteger: "TELESUP_DISABLE_PIC"
										default: FALSE];
			
			// Se fija en el archivo de configuracion si tiene deshabilitado el LOGIN
			// Esto deberia esta deshabilitado unicamente con motivos de testing			
			disableLogin = [[Configuration getDefaultInstance] getParamAsInteger: "TELESUP_DISABLE_LOGIN"
										default: FALSE];

			[telesupd setExecutePICProtocol: !disablePic];
			[telesupd setExecuteLoginProcess: !disableLogin];
      [telesupd setIsActiveLogger:TRUE];
			proxy = [G2RemoteProxy new];
			parser = [G2TelesupParser new];			
			[parser setExecutionMode: aTelesupId];
			formatter = [G2InfoFormatter new];
			[[telesupd getActivePIC] setConnectionType:0];/*indico que es por PTSD*/
			connectionSettings = [[TelesupervisionManager getInstance] getConnection: [facade getTelesupParamAsInteger:  	"ConnectionId1" 		telesupRol:aRol ]];
			if ([connectionSettings getConnectionType] == ConnectionType_MODEM){			   
         /*LM cambio el reader y el writer por lo del dmodem y al demodem asigno los que vienen*/
         [[telesupd getDmodemProto]setReader:aReader];
         [[telesupd getDmodemProto]setWriter:aWriter];
         
         aReader = [telesupd getDmodemProto];
         aWriter = [telesupd getDmodemProto];
         
         [[telesupd getActivePIC] setConnectionType:1];/*indico que es por modem*/
         
     //    doLog(0,"PROTOCOLO DMODEM\n");
			}
			break;

		case CMP_TSUP_ID:
	//	  doLog(0,"TELESUPERVISION CMP\n");
			telesupd = [G2TelesupD new];
			assert(telesupd);
						
			/**/
			activePIC = [G2ActivePIC new];
			assert(activePIC);
			/* hay que configurar el PIC adecuadamente */			
			[telesupd setActivePIC: activePIC];

			// Se fija en el archivo de configuracion si tiene deshabilitado el PIC
			// Esto deberia esta deshabilitado unicamente con motivos de testing
			disablePic = [[Configuration getDefaultInstance] getParamAsInteger: "TELESUP_DISABLE_PIC"
										default: FALSE];
			
			// Se fija en el archivo de configuracion si tiene deshabilitado el LOGIN
			// Esto deberia esta deshabilitado unicamente con motivos de testing			
			disableLogin = [[Configuration getDefaultInstance] getParamAsInteger: "TELESUP_DISABLE_LOGIN"
										default: FALSE];

			[telesupd setExecutePICProtocol: !disablePic];
			[telesupd setExecuteLoginProcess: !disableLogin];

			proxy = [G2RemoteProxy new];
			parser = [G2TelesupParser new];			
			[parser setExecutionMode: aTelesupId];
			formatter = [G2InfoFormatter new];
			
			
			break;
            
    case CONSOLE_TSUP_ID:

	printf("2!!!!\n");
    telesupd = [G2TelesupD new];
			assert(telesupd);
			/**/
			activePIC = [G2ActivePIC new];
			assert(activePIC);
			/* hay que configurar el PIC adecuadamente */			
			[telesupd setActivePIC: activePIC];
printf("3!!!!\n");
			// Se fija en el archivo de configuracion si tiene deshabilitado el PIC
			// Esto deberia esta deshabilitado unicamente con motivos de testing
			disablePic = [[Configuration getDefaultInstance] getParamAsInteger: "TELESUP_DISABLE_PIC"
										default: FALSE];
			// Se fija en el archivo de configuracion si tiene deshabilitado el LOGIN
			// Esto deberia esta deshabilitado unicamente con motivos de testing			
			disableLogin = [[Configuration getDefaultInstance] getParamAsInteger: "TELESUP_DISABLE_LOGIN"
										default: FALSE];
			//[telesupd setExecutePICProtocol: !disablePic];
			//[telesupd setExecuteLoginProcess: !disableLogin];
printf("4!!!!\n");
            [telesupd setExecutePICProtocol: FALSE];
            [telesupd setExecuteLoginProcess: FALSE];
printf("5!!!!\n");
            proxy = [G2RemoteProxy new];
			parser = [G2TelesupParser new];
			formatter = [G2InfoFormatter new];
printf("6!!!!\n");			
		break;                        

/*		case IMAS_TSUP_ID:
			telesupd = [TITelesupD new];
			parser = [TITelesupParser new];
			formatter = [TIInfoFormatter new];
			proxy = [TIRemoteProxy new];
					
			break;
*/
			default:
	//		doLog(0,"Telesupervision no implementada!\n");
			THROW( TSUP_INVALID_TELESUP_ID_EX );
			break;
	}

	/**/
	assert(telesupd);	
	assert(parser);
	assert(formatter);
	assert(proxy);
		
	/**/
	[formatter setTelesupId: aRol];
	        printf("1!!!!\n");
	/**/	
	[proxy setReader: aReader];
    printf("2!!!!\n");
	[proxy setWriter: aWriter];
	[proxy setTelesupViewer: aTelesupViewer];
	printf("3!!!!\n");
	/**/
	[telesupd setFreeOnExit: FALSE];
	[telesupd setTelesupId: aTelesupId];
	[telesupd setTelesupRol: aRol];
	printf("4!!!!\n");
	[telesupd setTelesupViewer: aTelesupViewer];
	[telesupd setTelesupErrorManager: [self getTelesupErrorManager: aTelesupId]];
	[telesupd setTelesupParser: parser];
	[telesupd setInfoFormatter: formatter];
	[telesupd setRemoteProxy: proxy];
	[telesupd setRemoteReader: aReader];
	[telesupd setRemoteWriter: aWriter];
printf("5!!!!\n");
	if (aTelesupId == PIMS_TSUP_ID) 
		[parser setViewer: aTelesupViewer];

	if (aTelesupId == HOYTS_BRIDGE_TSUP_ID) 
		[parser setViewer: aTelesupViewer];

	if (aTelesupId == BRIDGE_TSUP_ID) 
		[parser setViewer: aTelesupViewer];

	return telesupd;
}

/**/
- (TELESUP_ERROR_MANAGER) getTelesupErrorManager: (int) aTelesupId
{
	TELESUP_ERROR_MANAGER errorMgr = NULL;

	switch (aTelesupId) {

		case PIMS_TSUP_ID:
		case G2_TSUP_ID:
		case SARII_PTSD_TSUP_ID:
		case SARI_TSUP_ID:
		case IMAS_TSUP_ID:
		case CMP_TSUP_ID:
		case CMP_OUT_TSUP_ID:
		case HOYTS_BRIDGE_TSUP_ID:
		case BRIDGE_TSUP_ID:
        case CONSOLE_TSUP_ID:


			errorMgr = [G2TelesupErrorManager new];
			break;

		default:
		//	doLog(0,"Telesupervision no implementada!\n");
			THROW( TSUP_INVALID_TELESUP_ID_EX );
			break;
	}

	return errorMgr;
}

@end

