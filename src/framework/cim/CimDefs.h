#ifndef CIM_DEFS_H
#define CIM_DEFS_H

#include "system/lang/all.h"

/** Esta variable define si imprime informacion de debuggin para el CIM */
#define __DEBUG_CIM

/** Maxima cantidad de valores que se pueden depositar en un mismo deposito */
#define MAX_DEPOSIT_DETAIL_QTY		20

//#define CHOW_YANKEE				 1


/**
 *	Especifica el tipo de dispositivo "aceptador".
 */
typedef enum {
	AcceptorType_UNDEFINED,
	AcceptorType_VALIDATOR,		/** Validador de billetes / monedas */
	AcceptorType_MAILBOX		  /** Buzon */
} AcceptorType;

/**
 *	Especifica el tipo de valor a depositar.
 */
typedef enum {
	DepositValueType_UNDEFINED,
	DepositValueType_VALIDATED_CASH,	/** Efectivo (validado) */
	DepositValueType_MANUAL_CASH,			/** Efectivo (no validado) */
	DepositValueType_CHECK,						/** Cheques */
	DepositValueType_BOND,						/** Bonos (ej: tickets canasta) */
	DepositValueType_CREDIT_CARD, 		/** Cupones de tarjeta de credito */
	DepositValueType_OTHER,						/** Otros */
	DepositValueType_BOOKMARK	 				/** Bookmarks (no deberia tener importe) */
} DepositValueType;

/**
 *	Especifica el tipo de deposito efectuado.
 */
typedef enum {
	DepositType_UNDEFINED,
	DepositType_AUTO,				/** Deposito automatico (es decir, controlado por un validador) */
	DepositType_MANUAL,			/** Deposito manual (por sobre) */
	DepositType_WITHOUT_DEVICES
} DepositType;

/**
 *	Especifica el tipo de puerta.
 */
typedef enum {
	DoorType_UNDEFINED,
	DoorType_COLLECTOR,			/** Puerta del recaudador, para extraccion de valores */
	DoorType_PERSONAL				/** Puerta personal, funciona como puerta de tesoro personal para el dueno del punto */
} DoorType;

/**
 *	Estado de una denominacion.
 */
typedef enum {
	DenominationState_UNDEFINED,
	DenominationState_ACCEPT,
	DenominationState_REJECT
} DenominationState;

/**
 *	Nivel de seguridad de una denominacion.
 */
typedef enum {
	DenominationSecurity_UNDEFINED,
	DenominationSecurity_STANDARD,
	DenominationSecurity_HIGH
} DenominationSecurity;

/**
 *	Tipos de marcas
 */
typedef enum {
	BrandType_UNDEFINED,
	BrandType_JCM,
	BrandType_CASH_CODE,
	BrandType_MEI,
	BrandType_FUJITSU,
	BrandType_FIREKING,
	BrandType_MONEY_CONTROLS,
    BrandType_RDM
  BrandType_CDM
} BrandType;

/**
 *
 */
typedef struct {
  id user;
  BOOL includeDetails;
  unsigned long auditNumber;
  datetime_t auditDateTime;
	BOOL resumeReport;
	BOOL viewHeader;
	BOOL viewFooter;
} ZCloseReportParam;

/**
 *
 */
typedef struct {
  BOOL includeDetails;
  unsigned long auditNumber;
  datetime_t auditDateTime;
	id cashReference;
} CashReferenceReportParam;

/**
 *
 */
typedef struct {
  id cash;
  unsigned long auditNumber;
  datetime_t auditDateTime;
  BOOL detailReport;
	BOOL showBagNumber;
} CashReportParam;

/**
 *
 */
typedef struct {
  unsigned long auditNumber;
  datetime_t auditDateTime;
  int userStatus;
  BOOL detailReport;
} EnrollOperatorReportParam;

/**
 *
 */
typedef struct {
  unsigned long auditNumber;
  datetime_t auditDateTime;
  datetime_t fromDate;
  datetime_t toDate;
	id device;
	id user;
	id eventCategory;
  char deviceStr[21];
  char userStr[100];
  char eventCategoryStr[100];
  BOOL detailReport;
} AuditReportParam;


/**/
typedef struct {
	int jcmCurrencyId;
	int isoCurrencyId;
} CurrencyMapping;

/**
 *
 */
typedef struct {
  unsigned long auditNumber;
  datetime_t auditDateTime;
} DepositReportParam;

#endif
