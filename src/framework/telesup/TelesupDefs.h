#ifndef TELESUPDEFS_H
#define TELESUPDEFS_H

#include <stdlib.h>
#include "ctapp.h"

#include "SettingsExcepts.h"
#include "DAOExcepts.h"
#include "TelesupExcepts.h"

/**/
//#define TELESUP_MESSAGE_HEADER 				"Message"
/* Este si se define vacio debe sacarse el '\n' tambien */
//#define TELESUP_MESSAGE_HEADER_PLUS_ENTER 	"Message\n"

#define TELESUP_MESSAGE_HEADER 				""
#define TELESUP_MESSAGE_HEADER_PLUS_ENTER 	""

/* El numero maximo de bytes que puede contener un mensaje (incluye \n's per
   no incluye  la linea inicial que indica el tama� del mensaje */
#define		TELESUP_MSG_SIZE			32768
/* El numero maximo de bytes que puede contener cada linea (incluye el \n)*/
#define		TELESUP_MSGLINE_SIZE		1024
/*ale*/
#define TELESUP_RESPONSE_MSGLINE_SIZE 32768
/* El tamanio maximo del nombre de un Request */
#define		TELESUP_REQUEST_NAME_SIZE	TELESUP_MSGLINE_SIZE
/**/
#define		TANSFER_FILE_PACKET_SIZE	512
/* El tama� del string de identificacion de sistemas remotos */
#define		TELESUP_SYSTEMID_SIZE		32
/* El tama� del string del nombre de usuario */
#define		TELESUP_USERNAME_SIZE		15
/* El tama� del string del password */
#define		TELESUP_PASSWORD_SIZE		15
/* El numero maximo de digitos de un numero de telefono de una linea en una cabina*/
#define		MAX_CABIN_PHONE_NUMBER		32
		    
/*  */
//#define 	USER_NAME_SIZE		15
//#define 	PASSWORD_SIZE		15
#define 	TELESUP_SYSTEM_ID_LEN  		32
#define 	TELESUP_USER_NAME_LEN 		16
#define 	TELESUP_PASSWORD_LEN 		16
	
#define		MONEY		float
#define 	DATETIME 	time_t

/* El numero maximo de bytes que puede contener un mensaje (incluye \n's per
   no incluye  la linea inicial que indica el tama� del mensaje */
#define		PIC_MSG_SIZE			1028

/* Cadena para comenzar y terminar el envio de una entidad. */
#define BEGIN_ENTITY "Entity"
#define END_ENTITY   "EndEntity"

/**/
enum
{	 
	 SARII_TSUP_ID = 1
	,G2_TSUP_ID //2
	,TELEFONICA_TSUP_ID // 3
	,TELECOM_TSUP_ID // 4
	,SARI_TSUP_ID // 5
	,IMAS_TSUP_ID // 6
	,SARII_PTSD_TSUP_ID // 7
	,PIMS_TSUP_ID // 8
	,CMP_TSUP_ID // 9
	,CMP_OUT_TSUP_ID // 10
	,STT_ID //11
	,FTP_SERVER_TSUP_ID //12
	,POS_TSUP_ID //13
	,HOYTS_BRIDGE_TSUP_ID //14
	,BRIDGE_TSUP_ID //15
    ,CONSOLE_TSUP_ID //16

};

typedef enum { 
  CommunicationIntention_DO_SALE = 1,
  CommunicationIntention_GET_TRANSACTION_STATE, // 2
  CommunicationIntention_TELESUP,								// 3
	CommunicationIntention_INFORM_DEPOSITS,       // 4
	CommunicationIntention_INFORM_EXTRACTIONS,    // 5
	CommunicationIntention_INFORM_ALARMS,         // 6
	CommunicationIntention_GENERATE_REPAIR_ORDER, // 7
	CommunicationIntention_CHANGE_STATE_REQUEST   // 8
	CommunicationIntention_TEST_TELESUP   				// 9
	CommunicationIntention_EXPIRED_MODULES				// 10
	CommunicationIntention_LOGIN									// 11
	CommunicationIntention_INFORM_Z_CLOSE	 = 15		// 15
    CommunicationIntention_INFORM_SUPPORT_TASK	 = 16		// 16

} CommunicationIntention;

/**/
enum
{
     UNKNOWN_PROTOCOL = 1
    ,MAC_ADDRESS_ERROR = 11
    ,DUPLICATED_MAC_ADDRESS = 10
    ,NOT_REGISTERED_EQ = 3
    ,LOGIN_INFO_ERROR = 4
    ,REMOTE_LOGIN_INFO_ERROR = 5
    ,EQ_TYPE_ERROR = 12
    ,INACTIVE_EQ = 13
};


#endif
