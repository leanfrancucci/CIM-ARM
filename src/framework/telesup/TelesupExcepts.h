#ifndef TELESUP_EXCEPT_H
#define TELESUP_EXCEPT_H

#define TELESUP_EXCEPT		107000

/* TELESUPERVISION */
#define TSUP_GENERAL_EX						(TELESUP_EXCEPT)
#define TSUP_NAME_TOO_LARGE_EX				(TELESUP_EXCEPT + 1)
#define TSUP_INVALID_REQUEST_EX				(TELESUP_EXCEPT + 2)	
#define TSUP_INVALID_ID_EX					(TELESUP_EXCEPT + 3)
#define TSUP_INVALID_OPERATION_EX			(TELESUP_EXCEPT + 4)	
#define TSUP_PARAM_NOT_FOUND_EX				(TELESUP_EXCEPT + 5)
#define TSUP_READ_TIMEOUT_EX				(TELESUP_EXCEPT + 6)
#define TSUP_TYPE_EX						(TELESUP_EXCEPT + 7)
#define TSUP_KEY_NOT_FOUND					(TELESUP_EXCEPT + 8)
#define TSUP_INVALID_DATETIME_VAL_EX		(TELESUP_EXCEPT + 9)
#define TSUP_NOAVAIL_REQ_VIGENCY_EX			(TELESUP_EXCEPT  + 10)
#define TSUP_FILE_NOT_FOUND_EX				(TELESUP_EXCEPT  + 11)
#define TSUP_BAD_LOGIN_EX					(TELESUP_EXCEPT  + 12)
#define TSUP_BAD_LOGOUT_EX					(TELESUP_EXCEPT  + 13)
#define TSUP_MSG_TOO_LARGE_EX				(TELESUP_EXCEPT  + 14)
#define TS_INVALID_JOB_REQUEST_EX			(TELESUP_EXCEPT  + 15)
#define TS_JOB_RUNNING_EX					(TELESUP_EXCEPT  + 16)
#define TS_JOB_NOT_RUNNING_EX				(TELESUP_EXCEPT  + 17)
#define TS_JOB_EXECUTED						(TELESUP_EXCEPT  + 18)
#define TS_JOB_NULLED						(TELESUP_EXCEPT  + 19)
#define TS_JOB_COMMITED 					(TELESUP_EXCEPT  + 20)
#define TS_JOB_NOT_COMMITED 				(TELESUP_EXCEPT  + 21)
#define TSUP_INVALID_FILTER_EX				(TELESUP_EXCEPT  + 22)
#define TSUP_INVALID_TELESUP_ROL_EX			(TELESUP_EXCEPT  + 23)
#define TSUP_INVALID_TELESUP_ID_EX			(TELESUP_EXCEPT  + 24)

#define TSUP_CONNECTION_TIMEOUT_EX				(TELESUP_EXCEPT + 25)
#define TSUP_PPP_CONNECTION_EX						(TELESUP_EXCEPT + 26)

#define TSUP_TEST_EX						(TELESUP_EXCEPT + 30)
#define TSUP_FILE_GENERATION_EX   (TELESUP_EXCEPT + 31)

#define TSUP_MAC_ADDRESS_ERROR_EX                   (TELESUP_EXCEPT  + 32)
#define TSUP_DUPLICATED_MAC_ADDRESS_EX      (TELESUP_EXCEPT  + 33)
#define TSUP_NOT_REGISTERED_EQ_EX                   (TELESUP_EXCEPT  + 34)
#define TSUP_LOGIN_INFO_ERROR_EX                    (TELESUP_EXCEPT  + 35)
#define TSUP_REMOTE_LOGIN_INFO_ERROR_EX     (TELESUP_EXCEPT  + 36)
#define TSUP_EQ_TYPE_ERROR_EX                           (TELESUP_EXCEPT  + 37)
#define TSUP_INACTIVE_EQ_EX                             (TELESUP_EXCEPT  + 38)
#define TSUP_INVALID_PTSD_PROTOCOL_EX           (TELESUP_EXCEPT  + 39)


/* TRANSPORT CONNECTIONS */
#define TRANSPORT_INVALID_CONNECTION_EX		(TELESUP_EXCEPT + 100)


/* FILE TRANSFER */
#define FT_INVALID_PROTO_EX						(TELESUP_EXCEPT + 201)
#define FT_READ_ERR_EX 								(TELESUP_EXCEPT + 202)
#define FT_WRITE_ERR_EX 							(TELESUP_EXCEPT + 203)
#define FT_INVALID_HEADER_EX	 				(TELESUP_EXCEPT + 204)
#define FT_INVALID_FILE_EX	 					(TELESUP_EXCEPT + 205)
#define FT_FILE_TRANSFER_ERROR 				(TELESUP_EXCEPT + 206)
#define INVALID_UPDATE_FILE_NAME_EX		(TELESUP_EXCEPT + 207)

/* GENERALES */
#define TSUP_CANNOT_START_WITH_CABIN_ENABLED_EX 		    (TELESUP_EXCEPT + 300)

	
#endif
