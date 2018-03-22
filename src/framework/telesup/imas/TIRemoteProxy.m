#include <string.h>
#include "system/util/all.h"
#include "TIRemoteProxy.h"
#include "TelesupExcepts.h"
#include "FileManager.h"
#include "ClientSocket.h"
#include "MessagesImas.h"


#define printd(args...)// doLog(0,args)
//#define printd(args...)

@implementation TIRemoteProxy

/**/
- initialize
{
	[super initialize];

//	ctSocket 	  		= [ClientSocket new];
//	[self setReader: [ctSocket getReader]];
//	[self setWriter: [ctSocket getWriter]];
//	assert(myWriter);
//	assert(myReader);	
/*	[[ImasMsg getDefaultInstance] setWriter:[ctSocket getWriter]];
	[[ImasMsg getDefaultInstance] setReader:[ctSocket getReader]];*/
	myMessage = (char *) malloc( TELESUP_MSG_SIZE + 1);
	strcpy(myMessage, "");

	return self;
}

/**/
- free
{
	//[ctSocket close];
	//[ctSocket free];
	return [super free];
}

/**/
-(int) parseAnswer: (int) bSize
{
	int i,j=-1,offset=0;
		
//	printd("Parse\n");
	if (bSize<=0){
		printd("0 Bytes contenidos\n");
		return -1;
	}
	
	++j;
	memset(aParameters[j],0,25);
//	printd("    * Respuesta Recibida %s\n",myMessage);
	for (i=0;i<bSize;++i){
		if (myMessage[i]==','){
			aParameters[j][offset]='\0';
//			printd("      - Par.%i : %s\n",j,aParameters[j]);
			++j;
			memset(aParameters[j],0,25);
			offset=0;
		}
		else{
			aParameters[j][offset]=myMessage[i];
			++offset;
		}
	}
//	printd("      - Par.%i : %s\n",j,aParameters[j]);
	++j;
	return j;
}

/**/
- (WRITER) getWriter { return myWriter; }

/**/
- (READER) getReader { return myReader; }


/**/
- (int) initConnection: (char * ) ipAddress port: (int) portNumber
{
	/*conecto via socket al servidor*/
	printd("\n  #Intentando conexion a %s:%i\n\n\n\n\n\n\n",ipAddress,portNumber);
	assert(ctSocket);
	
	TRY
		printd("InicioSocket\n");
		[ctSocket initWithHost:ipAddress port:portNumber];

		printd("SocketIniciado %s %d\n",ipAddress,portNumber);
		[ctSocket connect];
		
	CATCH
		
		printd("  #Conexion Fallida!!!\n");
		ex_printfmt();
		return 0;

	END_TRY;
	
	return TRUE;

}

/**/
- (void) newMessage: (const char *) aMessageName
{	
	strcpy(myMessage,aMessageName);
}

/**/
- (void) newResponseMessage
{	
}

/**/
- (int) receiveMessage:(int)aSize
{
	int sizeR;
	
	memset(myMessage,0,TELESUP_MSG_SIZE + 1);
	//sizeR = [ctSocket read: myMessage qty: aSize];
	sizeR = [myReader read: myMessage qty: aSize];

	if (sizeR == -1 )
		return 	-1;
		
	return 	sizeR;
}

/**/
- (void) sendMessage
{	
	//printd("sendMessage size: %d\n Message: [%s]", strlen(myMessage), myMessage);
	
	//[ctSocket write: myMessage qty:strlen(myMessage)];
	[myWriter write: myMessage qty:strlen(myMessage)];
};


/**/
-(int) sendAndVerifyPkt:(char *)pData size:(int) rSize qty:(int) pQty
{
	int aSize;
	
	[self newMessage: pData];
	
	/*si no pudo enviar aborto*/
	//printd("%s\n",pData);
	[self sendMessage];

	/*espero la respuesta*/
	aSize = [self receiveMessage: rSize];

	/*si no recibio nada aborto*/
	if ( aSize <= 0){
		printd("  ERROR: No recibio Nada\n");
		return 0;
	}
	printd("PASO4\n");

	/*valido la cantidad de parametros*/
	return ([self parseAnswer:aSize] == pQty);
}

/**/
- (char *) getParameterNumber:(int) pNumber
{
	return aParameters[pNumber];
}

/**/
- (char *) getMsgReceived
{
	return myMessage;
}

/**/
-(int) sendBuffer:(char *) pData qty:(int)dQty
{
	//return ([ctSocket write: pData qty:dQty] == dQty);
	return ([myWriter write: pData qty:dQty] == dQty);
}

/**/
- (void) sendAckMessage
{
};

- (void) sendAckDataFileMessage
{
};

/* Transferecnia de informacion */

- (void) sendFile: (char *)aSourceFileName targetFileName: (char *) aTargetFileName
				 appendMode: (BOOL) anAppendMode
{
	
	printd("TIRemoteProxy -> sendFile. sourceFileName = %s, targetFileName = %s\n", aSourceFileName, aTargetFileName);
	[[FileManager getDefaultInstance] setTelesupViewer: myTelesupViewer];

	if (![[FileManager getDefaultInstance] sendFile:aSourceFileName proxy: self])
		THROW(TSUP_GENERAL_EX);
	
	[myTelesupViewer finishFileTransfer];

	printd("OK\n");
}

/**/
- (char *) receiveFile: (char *)aSourceFileName targetFileName: (char *) aTargetFileName
{
  long fsize = atol([self getParameterNumber:2]);
  long fsizeWithoutChk = 0;

  if (fsize >= 2) fsizeWithoutChk = fsize -2;

	[myTelesupViewer startFileTransfer: aTargetFileName download: TRUE totalBytes: fsizeWithoutChk];
	
	printd("TCRemoteProxy -> receiveFile. sourceFileName = %s, targetFileName = %s\n", aSourceFileName, aTargetFileName);
	
	if (![[FileManager getDefaultInstance] receiveFile:aSourceFileName fSize: fsize proxy: self])	
		THROW(TSUP_GENERAL_EX);
		
	printd("OK\n");

	[myTelesupViewer finishFileTransfer];
	
	return aSourceFileName;
		
}

/**/
- (void) logout
{
	[myTelesupViewer updateText: "Liberando conexion..."];
	[self newMessage: MSG_ENDTELESUP];
	[self sendMessage];
	
//	[ctSocket close];
}

/**/
- (int) sendVersion: (char*) versionSup
{
  char st[100];

	[myTelesupViewer updateText: "Enviando Version..."];

	sprintf(st,"%s\xD\xA",versionSup);
	
	[self newMessage: st];
	[self sendMessage];
		
	return 1;
}

/**/
- (void) login: (char*) aUserName
			   password: (char*) aPassword
		     extension: (char*) anExtension
		     appVersion: (char*) anAppVersion
{	
	char st[300];
	
	[myTelesupViewer updateText: "Identificandose..."];

	sprintf(st,"'%s','%s','%s','%s',%s,'%s',NULL\xD\xA",MSG_CLIENTE,aUserName,aPassword,MSG_CT8016,anExtension,anAppVersion);
	
//	printd("    * Cadena Conexion: %s",st);
	
	[self newMessage: st];
	[self sendMessage];
	
/*	if ([self sendAndVerifyPkt:st size:30 qty:2])
		if (strcmp([self getParameterNumber:0],MSG_ALLOW)!=0)
			THROW(TSUP_BAD_LOGIN_EX);*/
}	

/**/
- (void) setTelesupViewer: (id) aTelesupViewer
{
	myTelesupViewer = aTelesupViewer;
}


@end
