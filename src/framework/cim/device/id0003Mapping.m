#include <math.h>
#include <string.h>
#include "id0003Mapping.h" 
#include "system/util/endian.h"

#define CURMAP_FILE		"curconfig"

const unsigned char cmdsTable[2][CMDQTY]={
	 { 0x50, 0x40, 0x42, 0x11, 0xC3, 0x43, 0x8A, 0x88, downloadStartCmd, downloadDataCmd, downloadEndCmd, downloadEndStatusCmd, downloadStatusCmd }  //ID003
	,{ 0x00, 0x30, 0x35, 0x33, 0x34, 0x36, 0x41, 0x37, 0xD0, 0xD1, 0xD2, 0xD3, 0xD4 }  //CASHCODE
};

typedef struct {
	unsigned char cashCodeVal;
	unsigned char jcmMapVal;
} MapRecord;

#define FAILURETAB_SIZE		8

MapRecord mapFailureTable[] = {
	 { 0x50, 0xA2 } 	// STACK MOTOR FAILURE
	,{ 0x51, 0xA5 } 	// MOTOR SPEED FAILURE
	,{ 0x52, 0xA6 }  	// MOTOR FEED FAILURE 
	,{ 0x53, 0xB4 } 	// ALIGN MOTOR FAILURE 
	,{ 0x54, 0xB5 }		// CASSETTE STATUS FAILURE 
	,{ 0x55, 0xB6 } 	// OPTIC CANAL FAILURE 
	,{ 0x56, 0xB7 } 	// MAGNETIC CANAL FAILURE 
	,{ 0x5F, 0xB8 }		// CAPACITANCE CANAL FAILURE 
}; 

#define REJECTTAB_SIZE		13

MapRecord mapRejectTable[] = {
	 { 0x60, 0x71 } 	// insertion error
	,{ 0x61, 0x72 } 	// magnetic
	,{ 0x62, 0x75 }  	// feed error 
	,{ 0x63, 0x74 } 	// data amplitude error
	,{ 0x64, 0x7C }		// transport error
	,{ 0x65, 0x77 } 	// photo pattern error
	,{ 0x66, 0x78 } 	// photo level error
	,{ 0x67, 0x7E }		// color pattern error
	,{ 0x68, 0x79 }  	// inhibit denomination
	,{ 0x69, 0x73 }		// sensor detected something wrong moment
	,{ 0x6A, 0x7B }		// operation error
	,{ 0x6C, 0x7D }	 	// length error
	,{ 0x6D, 0x76 }		// denomination assesing error
}; 

#define ERRORTAB_SIZE 20

MapRecord mapStatusTable[] = {
	 { CCNET_POWER_UP, 				ID003_POWER_UP } 			
	,{ CCNET_POWER_UP_ACCEPTOR, 	ID003_POWER_UP_ACCEPTOR } 	
	,{ CCNET_POWER_UP_BILL_STACKER, ID003_POWER_UP_BILL_STACKER }  	
	,{ CCNET_INITIALIZING, 			ID003_INITIALIZING }
	,{ CCNET_IDLING, 				ID003_IDLING } 		
	,{ CCNET_ACCEPTING,				ID003_ACCEPTING }	
	,{ CCNET_STACKING, 				ID003_STACKING }	
	,{ CCNET_RETURNING,				ID003_RETURNING }  	
	,{ CCNET_DISABLED, 				ID003_DISABLED }  	
	,{ CCNET_HOLDING, 				ID003_HOLDING } 	
	,{ CCNET_BUSY,				 	0xDE} 			
	,{ CCNET_REJECTING,				ID003_REJECTING} 			
	,{ CCNET_STACKER_FULL, 			ID003_STACKER_FULL }		
	,{ CCNET_STACKER_OPEN, 			ID003_STACKER_OPEN } 		
	,{ CCNET_JAM_IN_ACCEPTOR, 		ID003_JAM_IN_ACCEPTOR }		
	,{ CCNET_JAM_IN_STACKER, 		ID003_JAM_IN_STACKER }		
	,{ CCNET_CHEATED, 				ID003_CHEATED }			
	,{ CCNET_PAUSE, 				ID003_PAUSE }			
	,{ CCNET_FAILURE, 				ID003_FAILURE } 		
	,{ CCNET_COMM_ERROR, 			ID003_COMM_ERROR }		
}; 


unsigned char getCommandCode( int protocol, unsigned char commdReq )
{
	if ( commdReq < CMDQTY && protocol < 2 )
		return cmdsTable[protocol][commdReq]; 
	return commdReq; //si hay error retorno lo mismo
}

unsigned char mapRecord( MapRecord *mappingTable, int tableSize, unsigned char searchVal )
{
	int i;

	for ( i = 0; i < tableSize && mappingTable[i].cashCodeVal != searchVal ; ++i )
			;
	
	if ( i < tableSize ) 
		return mappingTable[i].jcmMapVal;
	else
		return searchVal; 
}

unsigned char mapRejectCause( int protocol, unsigned char rejectCause )
{
	//mapea todo a jcm..
	if ( protocol == 0 )  //id003 se mantiene igual
		return rejectCause;
	else 
		return mapRecord( mapRejectTable, REJECTTAB_SIZE, rejectCause );
}

unsigned char mapStatus( int protocol, unsigned char cashCodeStatus )
{
	//mapea todo a jcm..
	if ( protocol == 0 )  //id003 se mantiene igual
		return cashCodeStatus;
	else 
		return mapRecord( mapStatusTable, ERRORTAB_SIZE, cashCodeStatus );
}

int mapFailureCode( int protocol, unsigned char failureCode )
{
	//mapea todo a jcm..
	if ( protocol == 0 )	
		return failureCode;
	else
		return mapRecord( mapFailureTable, FAILURETAB_SIZE, failureCode );
}

FILE *fpCurrencies = NULL;

typedef struct	 {
	char cashCodeVal[4]; //single note
	char isoStrVal[4]; //mei
	unsigned short jcmVal;
	unsigned short currencyId;
} fCurrType;

/*

	Para agregar un codigo de pais para un modelo de validador, se debe insertar en la tabla a continuacion

	y no olvidar modificar el define COUNTRTY_QTY 	

	Para que se genere el nuevo archivo de configuracion curConfig es necesario eliminar del directorio

	dicho archivo.

*/



#define COUNTRY_QTY 108

fCurrType defaultCurConfig[COUNTRY_QTY]= {

   {"AIA", "XCD", 00, 951}//ANGUILLA

  ,{"XCD", "XCD", 00, 951}//ANGUILLA

  ,{"ATG", "XCD", 00, 951}//ANTIGUA AND BARBUDA

  ,{"XCD", "XCD", 00, 951}//ANTIGUA AND BARBUDA

  ,{"ARG", "ARS", 14, 32}//ARGENTINA

  ,{"ARS", "ARS", 14, 32}//ARGENTINA

  ,{"ABW", "AWG", 00, 533}//ARUBA

  ,{"AWG", "AWG", 00, 533}//ARUBA

  ,{"AUS", "AUD", 2, 36}//AUSTRALIA

  ,{"AUD", "AUD", 2, 36}//AUSTRALIA

  ,{"AUT", "EUR", 00, 978}//AUSTRIA -- OBSOLETE They Use EUROS 

  ,{"EUR", "EUR", 00, 978}//AUSTRIA -- OBSOLETE They Use EUROS 

  ,{"BHS", "BSD", 00, 44}//BAHAMAS

  ,{"BSD", "BSD", 00, 44}//BAHAMAS

  ,{"BHR", "BHD", 00, 48}//BAHRAIN

  ,{"BEL", "EUR", 35, 978}//BELGIUM -- OBSOLETE They Use EUROS

  ,{"BLZ", "BZD", 00, 84}//BELIZE

  ,{"BZD", "BZD", 00, 84}//BELIZE

  ,{"BOL", "BOB", 00, 68}//BOLIVIA

  ,{"BOB", "BOB", 00, 68}//BOLIVIA

  ,{"BIH", "BAM", 00, 977}//BOSNIA AND HERZEGOVINA

  ,{"BAM", "BAM", 00, 977}//BOSNIA AND HERZEGOVINA

  ,{"BRA", "BRL", 12, 986}//BRAZIL

  ,{"BRL", "BRL", 12, 986}//BRAZIL

  ,{"BGR", "BGN", 00, 975}//BULGARIA

  ,{"BGN", "BGN", 00, 975}//BULGARIA

  ,{"CAN", "CAD", 8, 124}//CANADA

  ,{"CAD", "CAD", 8, 124}//CANADA

  ,{"CAN", "CAD", 72, 124}//CANADA

  ,{"CHL", "CLP", 78, 152}//CHILE

  ,{"CLO", "CLP", 78, 152}//CHILE

  ,{"COL", "COP", 25, 170}//COLOMBIA

  ,{"COP", "COP", 25, 170}//COLOMBIA

  ,{"CRI", "CRC", 77, 188}//COSTA RICA 

  ,{"CRC", "CRC", 77, 188}//COSTA RICA 

  ,{"CUB", "CUP", 00, 192}//CUBA

  ,{"CUP", "CUP", 00, 192}//CUBA

  ,{"CZE", "CZK", 44, 203}//CZECH REPUBLIC

  ,{"CZK", "CZK", 44, 203}//CZECH REPUBLIC

  ,{"DNK", "DKK", 58, 208}//DENMARK

  ,{"DKK", "DKK", 58, 208}//DENMARK

  ,{"DOM", "DOP", 00, 214}//DOMINICAN REPUBLIC

  ,{"DOP", "DOP", 00, 214}//DOMINICAN REPUBLIC

  ,{"ECU", "USD", 00, 840}//ECUADOR  -- They Use AMERICAN DOLLARS

  ,{"SLV", "USD", 00, 840}//EL SALVADOR -- They Use AMERICAN DOLLARS

  ,{"USD", "USD", 00, 849}//EL SALVADOR -- They Use AMERICAN DOLLARS

  ,{"EUR", "EUR", 224, 978}//EUROPEAN UNION

  ,{"FIN", "EUR", 32, 978}//FINLAND -- OBSOLETE They Use EUROS

  ,{"FRA", "EUR", 24, 978}//FRANCE -- OBSOLETE They Use EUROS

  ,{"DEU", "EUR", 4, 978}//GERMANY (Deutschland)

  ,{"DEU", "EUR", 52, 978}//GERMANY (Deutschland)

  ,{"DEU", "EUR", 53, 978}//GERMANY (Deutschland)

  ,{"GBR", "GBP", 23, 826}//GREAT BRITAIN

  ,{"GBP", "GBP", 23, 826}//GREAT BRITAIN

  ,{"GTM", "GTQ", 00, 320}//GUATEMALA

  ,{"GTQ", "GTQ", 00, 320}//GUATEMALA

  ,{"HND", "HNL", 00, 340}//HONDURAS

  ,{"HNL", "HNL", 00, 340}//HONDURAS

  ,{"HKG", "HKD", 00, 344}//HONG KONG (Special Administrative Region of China)

  ,{"HKD", "HKD", 00, 344}//HONG KONG (Special Administrative Region of China)

  ,{"IND", "INR", 00, 356}//INDIA

  ,{"INR", "INR", 00, 356}//INDIA

  ,{"IRL", "EUR", 42, 978}//IRELAND -- OBSOLETE They Use EUROS

  ,{"ISR", "ILS", 86, 376}//ISRAEL

  ,{"ILS", "ILS", 86, 376}//ISRAEL

  ,{"ITA", "EUR", 11, 978}//ITALY -- OBSOLETE They Use EUROS

  ,{"JPN", "JPY", 10, 392}//JAPAN

  ,{"JPY", "JPY", 10, 392}//JAPAN

  ,{"MEX", "MXP", 9, 484}//MEXICO

  ,{"MXN", "MXN", 9, 484}//MEXICO

  ,{"NZL", "NZD", 13, 554}//NEW ZEALAND

  ,{"NZD", "NZD", 13, 554}//NEW ZEALAND

  ,{"NIC", "NIO", 00, 558}//NICARAGUA

  ,{"NIO", "NIO", 00, 558}//NICARAGUA

  ,{"NGA", "NGN", 00, 566}//NIGERIA

  ,{"NGN", "NGN", 00, 566}//NIGERIA

  ,{"PAN", "PAB", 00, 590}//PANAMA

  ,{"PAB", "PAB", 00, 590}//PANAMA

  ,{"PRY", "PYG", 00, 600}//PARAGUAY

  ,{"PYG", "PYG", 00, 600}//PARAGUAY

  ,{"PER", "PEN", 47, 604}//PERU

  ,{"PEN", "PEN", 47, 604}//PERU

  ,{"PHL", "PHP", 74, 608}//PHILIPPINES

  ,{"PHP", "PHP", 74, 608}//PHILIPPINES

  ,{"POL", "PLN", 26, 985}//POLAND

  ,{"PLN", "PLN", 26, 985}//POLAND

  ,{"PRT", "EUR", 20, 978}//PORTUGAL -- OBSOLETE They Use EUROS

  ,{"PRI", "USD", 00, 840}//PUERTO RICO  -- They Use AMERICAN DOLLARS

  ,{"RUS", "RUB", 39, 643}//RUSSIAN FEDERATION

  ,{"RUB", "RUB", 39, 643}//RUSSIAN FEDERATION

  ,{"SAU", "SAR", 00, 682}//SAUDI ARABIA (Kingdom of Saudi Arabia)

  ,{"SAR", "SAR", 00, 682}//SAUDI ARABIA (Kingdom of Saudi Arabia)

  ,{"SGP", "SGD", 34, 702}//SINGAPORE

  ,{"SGD", "SGD", 34, 702}//SINGAPORE

  ,{"ZAF", "ZAR", 6, 710}//SOUTH AFRICA (Zuid Afrika)

  ,{"ZAR", "ZAR", 6, 710}//SOUTH AFRICA (Zuid Afrika)

  ,{"ESP", "EUR", 3, 978}//SPAIN (Espa�a) -- OBSOLETE They Use EUROS

  ,{"SWE", "SEK", 5, 752}//SWEDEN

  ,{"SEK", "SEK", 5, 752}//SWEDEN

  ,{"CHE", "CHE", 22, 947}//SWITZERLAND (Confederation of Helvetia)

  ,{"ARE", "AED", 28, 784}//UNITED ARAB EMIRATES

  ,{"AED", "AED", 28, 784}//UNITED ARAB EMIRATES

  ,{"GBR", "GBP", 23, 826}//UNITED KINGDOM (Great Britain)

  ,{"USA", "USD", 1, 840}//UNITED STATES

  ,{"USD", "USD", 1, 840}//UNITED STATES

  ,{"URY", "UYU", 49, 858}//URUGUAY

  ,{"UYU", "UYU", 49, 858}//URUGUAY

  ,{"VEN", "VEF", 31, 937}//VENEZUELA

  ,{"VEF", "VEF", 31, 937}//VENEZUELA

};



int openCurFile( void )
{
	if ( fpCurrencies == NULL ) {
		//LOG_INFO( LOG_DEVICES,"Open curConfig File!" );
	    fpCurrencies = fopen( CURMAP_FILE, "rb");
	    if( !fpCurrencies ) {
		    fpCurrencies = fopen( CURMAP_FILE, "a+bx");
			fwrite( defaultCurConfig, COUNTRY_QTY, sizeof(fCurrType), fpCurrencies ); 
		}
	} 
	fseek( fpCurrencies, 0, SEEK_SET );
	return 1;
}

int getCurrencyIdFromCashCode( char* countryStr )
{
	static fCurrType currencyData;

//	doLog(0,"getCurrencyIdFromCashCode countryStr is: %s\n", countryStr); fflush(stdout);
	if ( openCurFile())	{
		while ( fread( &currencyData, 1, sizeof(fCurrType), fpCurrencies ) && memcmp(countryStr, currencyData.cashCodeVal, 3)){
	//		doLog(0,"getCurrencyIdFromCashCode table country %s %s\n", currencyData.cashCodeVal, countryStr); fflush(stdout);
			;
		}			
		if (!memcmp(countryStr, currencyData.cashCodeVal, 3))
			return currencyData.currencyId;
	}
	return 0;
}

int getCurrencyIdFromJcm ( int countryCode )
{
	static fCurrType currencyData;
	
	if ( openCurFile())	{
		while ( fread( &currencyData, 1, sizeof(fCurrType), fpCurrencies ) && ( countryCode != currencyData.jcmVal )) 
			;
		if (countryCode == currencyData.jcmVal )
			return currencyData.currencyId;
	}
	return 0;
}
/*
int getCurrencyIdFromISOStr( char* countryStr )
{
	static fCurrType currencyData;

	if ( openCurFile())	{
		while ( fread( &currencyData, 1, sizeof(fCurrType), fpCurrencies ) && memcmp(countryStr, currencyData.isoStrVal, 3))
			;
		
		if (!memcmp(countryStr, currencyData.isoStrVal, 3))
			return currencyData.currencyId;
	}
	return 0;
	
}
*/
int getCurrencyIdFromISOStr( char* countryStr )
{
	static fCurrType currencyData;

  if ( openCurFile()) {
  
//		doLog(0,"getCurrencyIdFromISOStr searching %s \n",  countryStr); fflush(stdout);
    
		while ( fread( &currencyData, 1, sizeof(fCurrType), fpCurrencies ) && memcmp(countryStr, currencyData.isoStrVal, 3))
			;
//    	doLog(0,"getCurrencyIdFromISOStr %s \n",  currencyData.isoStrVal); fflush(stdout);

    if (!memcmp(countryStr, currencyData.isoStrVal, 3))
    	return currencyData.currencyId;
   //	else
//      doLog(0,"getCurrencyIdFromISOStr not found \n"); fflush(stdout);

  }
  
	return 0;
       
}




