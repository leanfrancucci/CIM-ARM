#ifndef CT_TYPES_H
#define CT_TYPES_H

/**
*	InitSignalType. Tipos de se�ales de inicio esperadas por la cabina,
*	enviadas por el LineController.
*/

typedef enum {
	FIFTY_HZ,
	SIXTEEN_KHZ,
	POLARITY_INVERSION,
	SPECIAL_DIGIT_SIGNAL,
	TIME_SIGNAL
} InitSignalType;

/**
*	CabinStateType.Estados en los que se puede encontrar una cabina.
*/

typedef enum {
	ENABLE,
	DISABLE,
	BLOCKED,
	CABIN_DISCONNECTED,
	HANG_UP,	
	PICK_UP,
	TARIFYING,
	CABIN_DISABLING,
	LINE_TELESUP_MODE
}	CabinStateType;

/**
*	CallClass. Tipos de llamada que se pueden presentar: con monto m�ximo,
*	o sin monto m�ximo.
*/

typedef enum {
	VALUED_CALL_T,
	STANDARD_CALL_T
}	CallClass;

/**
*	CallFlowType. Tipo de llamada de acuerdo a su flujo: entrante o saliente.
*/

typedef enum {
	INCOMING,
	OUT
} CallFlowType;

/**
*	Tipo de DigitManager.
*/
typedef enum {
	DUMMY_DIGIT_MANAGER, /**Digit Manager que se utiliza antes de haber encontrado el destino*/
	IN_CALL_DIGIT_MANAGER, /**Digit Manager que se utiliza para llamada entrante*/
	OUT_CALL_DIGIT_MANAGER_BEFORE_ISIGNAL, /**Digit Manager que se utiliza para llamada saliente y aun no ha llegado senal de inicio*/
	OUT_CALL_DIGIT_MANAGER_AFTER_ISIGNAL /**Digit Manager que se utiliza para llamada saliente y ya ha llegado senal de inicio*/
} DigitManagerType;

/**
*	Tipo de InitSignalManager.
*/

typedef enum {
	DUMMY_IS_MANAGER, /**InitSignalManager que se utiliza antes de haber encontrado el destino*/
	REMOTE_IS_MANAGER, /**InitSignalManager que se utiliza para llamada teletasada*/
	CONNECTED_ST_IS_MANAGER, /**InitSignalManager que se utiliza para llamada standard cuando ya ha llegado la primera senal de inicio*/
	CONNECTED_INCOMING_CALL_IS_MANAGER, /**InitSignalManager que se utiliza para llamada entrante cuando ya ha comenzado la llamada */
	NOT_CONNECTED_ST_IS_MANAGER, /**InitSignalManager que se utiliza para llamada standard y aun no ha llegado la senal de inicio y ya se ha encontrado el destino*/
	TEMPORIZABLE_NOT_CONNECTED_ST_IS_MANAGER /**InitSignalManager que se utiliza para llamada standard y ademas de utilizar las diferentes senales de inicio se utiliza un timer*/
} ISManagerType;

/**
*	Tipo de estado de cabina de acuerdo a si se encuentra con una comunicaci�n e curso
* o no.
*/
typedef enum {
	KEY_NOT_FOUND,
	KEY_FOUND,
	CONNECTED,
}	ConnectionStateType;


/**
 * AccumulatorType. Esta enumeraci�n define los tipos de acumuladores que pueden existir
 * en el sistema.
 */
typedef enum {
	SALE_ACC,
	COST_ACC,
  PROMOTION_ACC
} AccumulatorType;


/**
 * SemaphoreState. Enumeraci�n de los estados de un semaforo.
 */
typedef enum {
	SMPH_NEW,
	SMPH_READY,
	SMPH_RUNNING,
	SMPH_BLOCKED,
	SMPH_ZOMBIE
} SemaphoreState ;

/**
 * SearchResultType. El resultado que puede arrojar la busqueda en la tabla de claves.
 */
typedef enum {
	NO_MATCH,
	PARTIAL_MATCH,
	MATCH
} SearchResultType;

/**
 * RouteType. Tipos de ruteo posible.
 */
typedef enum {
	ROUTE_NONE,			/** no efectua ningun ruteo */
	ROUTE_CARRIER,			/** rutea por carrier */
	ROUTE_PREPAID			/** rutea por plataforma prepaga*/
} RouteType;

/**
 * AppraiserType. Tipos de Tarifadores.
 */
typedef enum {
	STANDARD_APPRAISER_TYPE,
	REMOTE_APPRAISER_TYPE,
	MULTIBAND_APPRAISER_TYPE,
	FIXED_APPRAISER_TYPE,
  PROMOTION_APPRAISER_TYPE
} AppraiserType;


/**
 *	AppraiserSubType. Subtipo de tarifadores.
 */
typedef enum {
	AIR_APPRAISER_SUBTYPE,
	LAND_APPRAISER_SUBTYPE,
	NO_SUBTYPE
} AppraiserSubType;


/**
 *	RouterType. Tipos de ruteadores.
 */
typedef enum {
	DUMMY_ROUTER_TYPE,
	SWITCH_ROUTER_TYPE,
	CARRIER_ROUTER_TYPE,
	PREPAID_ROUTER_TYPE,
	STANDARD_ROUTER_TYPE
} RouterType;

/**
* Estados en los que se puede encontrar el InitSignalManager.
*/

typedef enum {
	INITIAL_IS_MANAGER,
	HAS_TO_START_CALL,
	CALL_STARTED
} InitSignalManagerStateType;

/**
* Acciones que se pueden realizar cuando se trata de una llamada teletasada y no llegan 
* las senales de inicio por un tiempo establecido.
*/

typedef enum {
	END_CALL,
	BLOCK_CALL
} RemoteCall;


/**
 * Enumeracion que define los tipos de Localizadores existentes en el sistema.
 */
typedef enum {
	PROTOTYPE_LOCATOR_TYPE
} LocatorType ;

/**
* Cambios que se pueden realizar en las vistas del LCDVisor y de la interfaz.	
*/

typedef enum {
	AMOUNT_CHANGE,
	NUMBER_DIALED_CHANGE,
	SECONDS_PASSED_CHANGE,
	RING_ON_CHANGE,
	RING_OFF_CHANGE,
	STATE_CHANGE,
  FORB_OPERATOR_CALL,
	PROMOTIONED_CALL,
  SMS_CHANGE
} ViewerChangeType;

/**
 *	Estructura que contiene los valores de una tarifa a aplicar.
 *	Son los datos b�sicos necesarios para saber acerca del costo y el
 *	tiempo de caida de una ficha.
 */
typedef struct {
	long timeout ;		// Tiempo de caida de la proxima ficha desde la caida previa
	money_t amount ;		// Monto asociado a la caida de la proxima ficha
	long cuttime ; 		// Calculado dinamicamente segun configuracion 
				// durante el proceso de simulacion
} BasicTariffContainer ;

/**
 *	Estructura utilizada para el ordenamiento en la simulaci�n de las
 *	llamadas con monto m�ximo.
 */
typedef struct {
	BasicTariffContainer tariff ;   // Datos asociados al tarifador
	void* appraiser ;			// Tarifador
} AppraiserTariffContainer ;

/**
* Enumeracion que define los modos de pago
*/

typedef enum {
	UNDEFINED_PAY_MODE,
	CASH_PAY_MODE,
	CHECK_PAY_MODE,
	COMBINED_PAY_MODE
} PayModeType;

/**
* Enumeracion que define la forma de facturar
*/

typedef enum {
	UNDEFINED_BILL,
	UNIQUE_BILL,
	RESUME_BILL
} BillModeType;

/**
* Enumeracion que define los cambios del CurrentConsumption
*/

typedef enum {
	ADD_CHANGE,
	CLOSE_CHANGE,  
	PARTIAL_CLOSE
} CurrentConsumptionChangeType;

/**
* Define los tipos de comprobantes.
*/

typedef enum {
	TICKET_VOUCHER
} VoucherType;

/**
* Define los tipos de numeracion de comprobantes (standard, ano fiscal, por rangos)
*/

typedef enum {
	NOT_DEFINED,
	STANDARD,
	FISCAL_YEAR,
	FIXED_RANGE
} TicketNumeratorType;


/**
* Define el modo de operacion del uso de cabina (Cobrar, No cobrar, Cobrar si el total es cero).
*/

typedef enum {
	ALWAYS_BILL = 1,
	TOTAL_ZERO_BILL,
	NEVER_BILL
} CabinUseModeType;


/**
* Define el modo de operacion de la llamada entrante (Bloquear, Cobrar cero, Cobrar con respecto a la 
* tarifa en la tabla de tarifas).
*/

typedef enum {
	BLOCK_IN_CALL = 1,
	BILL_ZERO_IN_CALL,
  BILL_FIX_TARIFF_IN_CALL,
  BILL_TABLE_IN_CALL
} InCallBillModeType;


/**
*  Define los idiomas con los que se puede operar.
*/

typedef enum {
	LANGUAGE_NOT_DEFINED,
	SPANISH,
	ENGLISH,
	FRENCH
} LanguageType;


/**
*  Define los mensajes del sistema en unico idioma, luego estos se mapean a los diferentes 
*  archivos de idiomas.
*/

typedef enum {
	MSG_LOCAL_CALL_TYPE,							//0     /*Valor como los que estan a continuacion que se deben corresponder con
	MSG_NATIONAL_CALL_TYPE,						//1			la descripcion del tipo de llamada y con el id de la tabla de idiomas*/
	MSG_INTERNATIONA_CALL_TYPE,				//2
 	MSG_CELULAR_CALL_TYPE,						//3
	MSG_INTERRB_CALL_TYPE,						//4
	MSG_FREE_CALL_TYPE,								//5
	MSG_OPERATOR_CALL_TYPE,						//6
	MSG_INCOMING_CALL_TYPE,						//7
	MSG_FIX_LINE_TYPE,								//8			/*Valor como los que estan a continuacion que se deben corresponder con
	MSG_CELULAR_LINE_TYPE,						//9			la descripcion del tipo de linea y con el id de la tabla de idiomas*/
	MSG_IP_LINE_TYPE,	  							//10
	MSG_OPERATION_ACTIVATE_CABIN,			//11
	MSG_OPERATION_DEACTIVATE_CABINA,	//12
	MSG_ADD_LINE,		          				//13
	MSG_REMOVE_LINE,                  //14
	MSG_ENABLE_CABIN,                 //15
	MSG_GENERAL_SETTINGS,             //16
  MSG_CASH_OPERATIONS,              //17
  MSG_TELESUPERVISION,              //18
  MSG_KEYBOARD_BLOCKING,            //19
  MSG_LOG_OFF_USER                  //20
} MessageType;

/**
 *	Define los modos en los que trabaja el telefono.
 */

typedef enum {
	PHONE_MODE_NOT_DEFINED,
	TONE_AND_PULSE_PHONE_MODE,
  PULSE_PHONE_MODE,
  TONE_PHONE_MODE
} PhoneModeType;

/**
 *	Define el modo de actualizacion de la tabla de tarifas.
 */
typedef enum {
	UPDATE_ON_ENABLE,						// siempre que se habilita la cabina
	UPDATE_ON_ALL_DISABLE				// solo cuando se deshabilitan todas las cabinas
} TableUpdateModeType;

/**
 *	Tipo de digito discado, tono dtfm o pulso
 */
typedef enum {
	UNKNOW_DIGIT,
	PULSE_DIGIT,
	TONE_DIGIT	
} DigitType;

/**
*  Define los tipos de redondeos
*/

typedef enum {
	ROUND_NOT_DEFINED,
	NORMAL_ROUND,
	UP_ROUND,
	DOWN_ROUND,
	HALF_ROUND
} RoundType;

/**
*  Define los tipos de impuestos
*/

typedef enum {
	TAX_TYPE_NOT_DEFINED,
	PERCENT_TAX_TYPE,
	FIX_TAX_TYPE
} TaxType;

/**
*  Define los tipos de prestadora
*/

typedef enum {
	TELCO_NOT_DEFINED,
	DELSAT,
	TELEFONICA,
	TELECOM
} TelcoType;


/**
*  Define los tipos de momentos de inicio de la telesupervision
*/

typedef enum {
	StartMomentType_NORMAL,
	StartMomentType_SYSTEM_INIT,
	StartMomentType_DISABLE_CABINS,
	StartMomentType_SYSTEM_SHUTDOWN,
	StartMomentType_BY_TRANSACTION
} StartMomentType;


/**
 *	Define los tipos de entidades para aplicar redondeos y ajustes
 */

typedef enum {
	ITEM_ENTITY,
	SUBTOTAL_ENTITY,
	TAX_ENTITY,
	TOTAL_ENTITY
} EntityType;

/**
 *	Define los tipos de cajas
 */

typedef enum {
	USER_CASH_REGISTER,
	TOTAL_CASH_REGISTER,
  Z_CLOSE_CASH_REGISTER
} CashRegisterType;


/**
 *	Tipos de llamadas standards
 */
#define CALL_TYPE_CHARGE_FREE 4 
#define CALL_TYPE_OPERATOR 99



/**
 *	Define las opciones de impresion
 */

typedef enum {
	PRINTING_NOT_DEFINED,
	ALWAYS_PRINT,
	NEVER_PRINT,
	QUESTION_PRINT
} PrintingType;


/**
 *	Define los valores que puede tener el espacio y tono DTMF
 */

typedef enum {
  DTMF_DURATION_NOT_DEFINED,
  DTMF_50,
  DTMF_100,
  DTMF_150,
  DTMF_200
} DTMFSpaceAndToneDurationType;


/**
 *	Define los tipos de tarifas aplicables.
 */
typedef enum {
	TariffType_NORMAL = 1,
	TariffType_AIR,
	TariffType_QUANTUM_CARRIER,
	TariffType_QUANTUM_SERVICE,
	TariffType_PROMOTION,					// Promociones
  TariffType_RANDOM_PROMOTION,  // Promocion al azar
  TariffType_RANDOM_DISCOUNT_PROMOTION, // Promocion descuentos al azar
  TariffType_STEP_DISCOUNT_PROMOTION,   // Promocion con descuentos escalonados
  TariffType_ALTERNATED_PERIODS        // Promocion periodos alernados
} TariffType;

/**
 * Define las acciones a llevar a cabo en caso de no llegar impulso en llamadas
 * teletasadas
 */
typedef enum {
  ACTION_IN_PULSE_ABSENCE_NOT_DEFINED,
  BLOCK_CALL_IN_PULSE_ABSENCE
} ActionInPulseAbsenceType;

/**
 *
 */
typedef enum {
  RESUME_REPORT_TYPE,
  DETAIL_REPORT_TYPE
} ReportType; 

/**
 *
 */
typedef enum {
  TasaTableVersion_REVISION8,
  TasaTableVersion_REVISION9
} TasaTableVersionType; 

/**
 *	Modo en el cual arrancan las cabinas (enable o disable)
 */
typedef enum {
	CabinInitMode_ENABLE,
	CabinInitMode_DISABLE
} CabinInitModeType; 

/**
 *  Tipo de codigo de barras
 */
typedef enum {
	BarCodeType_USER_CASH_REGISTER,
	BarCodeType_TOTAL_CASH_REGISTER,
  BarCodeType_COLLECTOR_TOTAL,
	BarCodeType_TICKET
} BarCodeType;

/**
 *	Tipo de respuesta esperado para la ejecucion de una accion por el spooler de la impresora.
 */
typedef enum {
	PrinterResponse_OK_CANCEL,
	PrinterResponse_OK,
	PrinterResponse_CANCEL
} PrinterResponseType; 

/**
 *	Define los tipos de seleccion (genericos)
 *	1 = All
 *	2 = Select  
 */
typedef enum {
	ITEM_BACK,
	ITEM_ALL,
	ITEM_SELECT
} SelectionType;

typedef enum {
	ITEM_BACK_WORDER,
	ITEM_NEW_WORDER,
	ITEM_INSERT_WORDER
} SelectionWOrder;

/**
 *	Define los tipos de seleccion de reimpresion
 *	1 = Last
 *	2 = Lasts XX
 *	3 = By range 
 */
typedef enum {
	ITEM_REPRINT_BACK,
	ITEM_REPRINT_LAST,
	ITEM_REPRINT_BY_RANGE
} SelectioReprintType;

/**
 *	Define los tipos de seleccion (genericos)
 *	1 = All
 *	2 = Select  
 */
typedef enum {
	ITEM_BACK_PRT_TYPE,
	ITEM_SUMMARY_PRT_TYPE,
	ITEM_DETAILED_PRT_TYPE
} SelectionPrintType;

/**
 *	Define la accion a ejecutar en el extended drop
 *	1 = Ver detalle
 *	2 = Finalizar  
 */
typedef enum {
	ITEM_BACK_EXT_DROP_ACTION,
	ITEM_VEIW_DETAIL_EXT_DROP_ACTION,
	ITEM_FINISH_EXT_DROP_ACTION
} SelectionExtDropAction;

#define IN_CALL_TYPE 9

#endif

