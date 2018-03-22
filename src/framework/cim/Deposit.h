#ifndef DEPOSIT_H
#define DEPOSIT_H

#define DEPOSIT id

#include "Object.h"
#include "CimDefs.h"
#include "AcceptorSettings.h"
#include "DepositDetail.h"
#include "User.h"
#include "Door.h"
#include "CimCash.h"
#include "CashReference.h"

#define ENVELOPE_NUMBER_SIZE 				15
#define BANK_ACCOUNT_NUMBER_SIZE 		30
#define APPLY_TO_SIZE 				      15

/**
 *	Encapsula un deposito.
 *
 *	Basicamente tiene cierta informacion propia del encabezado del deposito
 *	y la lista con el detalle del mismo.
 */
@interface Deposit :  Object
{
	USER myUser;																							/** El usuario que efectuo el deposito */
	unsigned long myNumber;																		/** Numero del deposito */
	datetime_t myOpenTime;																		/** Fecha/hora de apuertura del deposito */
	datetime_t myCloseTime;																		/** Fecha/hora en la cual se cerro el deposito */
	int myRejectedQty;																				/** Cantidad de billetes rechazados en el deposito */
	DepositType myDepositType;																/** Tipo de deposito */
	DOOR myDoor;                      												/** Puerta por la cual se efectuo el deposito */
	COLLECTION myDepositDetails;															/** Detalle del deposito */
	CIM_CASH myCimCash;																				/** Cash asociado al deposito */
	char myEnvelopeNumber[ENVELOPE_NUMBER_SIZE + 1];					/** Numero de sobre en caso de deposito manual */
	char myBankAccountNumber[BANK_ACCOUNT_NUMBER_SIZE + 1];		/** Numero de cuenta bancaria vinculado al deposito */
	CASH_REFERENCE myCashReference;														/** Cash reference asociado al deposito */
	char myApplyTo[APPLY_TO_SIZE + 1];					              /** Descripcion o codigo de referencia para vincular un deposito */
}

				
/**
 *	Devuelve el monto total del deposito.
 */
- (money_t) getAmount;

/**
 *	Devuelve la cantidad de valores depositados.
 */
- (int) getQty;

/**/
- (void) setUser: (USER) aUser;
- (USER) getUser;

/**/
- (void) setNumber: (unsigned long) aNumber;
- (unsigned long) getNumber;
					
/**/
- (void) setOpenTime: (datetime_t) aValue;
- (datetime_t) getOpenTime;

/**/
- (void) setCloseTime: (datetime_t) aValue;
- (datetime_t) getCloseTime;
					
/**/
- (void) setEnvelopeNumber: (char *) anEnvelopeNumber;
- (char *) getEnvelopeNumber;

/**/
- (void) setBankAccountNumber: (char *) aBankAccountNumber;
- (char *) getBankAccountNumber;

/**/
- (void) setCashReference: (CASH_REFERENCE) aCashReference;
- (CASH_REFERENCE) getCashReference;

/**/
- (void) setDoor: (DOOR) aDoor;
- (DOOR) getDoor;
			
/**/
- (void) setRejectedQty: (int) aRejectedQty;
- (void) addRejectedQty: (int) aRejectedQty;
- (int) getRejectedQty;
					
/**/
- (void) setDepositType: (DepositType) aDepositType;
- (DepositType) getDepositType;

/**/
- (void) setCimCash: (CIM_CASH) aValue;
- (CIM_CASH) getCimCash;

/**/
- (void) setApplyTo: (char *) anApplyTo;
- (char *) getApplyTo;

/**
 *	Agrega un detalle al deposito.
 *
 * 	Si el deposito es automatico, en primer lugar evalua si ya existe el detalle para
 *	ese "validador", "tipo de valor", "moneda" y "denominacion" en cuyo caso incrementa
 *	la cantidad ya existente.
 *
 *	Si no existe o es un deposito manual, crea un nuevo detalle y lo agrega a la lista.
 */
- (DEPOSIT_DETAIL) addDepositDetail: (ACCEPTOR_SETTINGS) anAcceptorSettings
		depositValueType: (DepositValueType) aDepositValueType
		currency: (CURRENCY) aCurrency
		qty: (int) aQty
		amount: (money_t) anAmount;

/**
 *	Devuelve la coleccion con los detalles del deposito.
 */
- (COLLECTION) getDepositDetails;

/**
 *	Devuelve la lista de "aceptadores" involucrados en el deposito.
 *	Es responsabilidad del que llama a este metodo liberar la lista (pero no
 *	el contenido).
 */
- (COLLECTION) getAcceptorSettingsList: (COLLECTION) aSourceCollection;

/**
 *	Devuelve la lista con el detalle del deposito para el aceptadore pasado como parametro.
 *	Es responsabilidad del que llama a este metodo liberar la lista (pero no
 *	el contenido).
 */
- (COLLECTION) getDetailsByAcceptor: (COLLECTION) aSourceCollection 
	acceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings;

/**
 *	Devuelve la lista con el detalle del deposito para el aceptadore pasado como parametro.
 *	Es responsabilidad del que llama a este metodo liberar la lista (pero no
 *	el contenido).
 */
- (COLLECTION) getDetailsByCurrency: (COLLECTION) aSourceCollection 
	currency: (CURRENCY) aCurrency;

/**
 *	Devuelve la lista con las monedas utilizadas en el deposito.
 *	Es responsabilidad del que llama a este metodo liberar la lista (pero no
 *	el contenido).
 */
- (COLLECTION) getCurrencies: (COLLECTION) aSourceCollection;

/**
 *	Devuelve la cantidad de "detalles".
 */
- (int) getDetailCount;

/**
 *
 */
- (int) getQty: (COLLECTION) aSourceCollection;

/**
 *
 */
- (money_t) getAmount: (COLLECTION) aSourceCollection;

/**
 *
 */
- (money_t) getAmountByCurrency: (CURRENCY) aCurrency;

/**
 *
 */
- (int) getUnknownBillCountByAcceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings;

/**
 *
 */
- (money_t) getAmountByAcceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings;

/**
 *
 */
- (int) getQtyByAcceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings;

#ifdef __DEBUG_CIM
/**/
- (void) debug;
#endif

@end

#endif

