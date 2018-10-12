#ifndef EVENT_H
#define EVENT_H

#define EVENT id

#include <Object.h>
#include "ctapp.h"

/**
 *	Especifica los eventos.
 */

#define AUDIT_EVENT_NOT_DEFINED                 (0) //0  - Evento no definido
#define Event_SYSTEM_STARTUP 										(1) //1	 - Encendido del equipo
#define Event_SYSTEM_SHUTDOWN										(2) //2  - Apagado del equipo
#define Event_LOGIN_PIN_USER										(3) //3	 - Logueo al sistema
#define Event_LOGOUT_USER									      (4) //4  - Deslogueo del sistema
#define Event_ABNORMAL_SYSTEM_SHUTDOWN					(5) //5  - Apagado del sistema de forma anormal
#define INEXISTENT_TARIFF_TABLE							    (6) //6  - Tabla de tarifas inexistente
#define Event_WRONG_PIN												  (7) //7  - Password erroneo
#define SOFTWARE_UPDATE											    (8) //8  - Actualizacion de software
#define FORBIDDEN_NUMBER											  (9) //9  - Numero prohibido en cabina
#define INEXISTENT_NUMBER									      (10) //10 - Numero inexistente en cabina
#define OPERATOR_CALL_ENABLED							      (11) //11 - Habilitacion de llamada por operadora
#define ABSENT_INIT_SIGNAL_IN_KEY_FOUND		      (12) //12 - Ausencia de senal de inicio y ya se ha encontrado la clave
#define DIGIT_DETECTION_PROBLEM									(13) //13 - Problema en la deteccion de digitos
#define TARIFF_TABLE_PROBLEM										(14) //14 - Problema con la tabla de tarifas
#define INIT_SIGNAL_ARRIVAL_IN_KEY_NOT_FOUND		(15) //15 - Llegada de senal de inicio y no se ha encontrado la clave
#define DESTINATION_ERROR												(16) //16 - Error en el destino
#define CASH_REGISTER_OPENING										(17) //17 - Apertura de caja
#define CASH_REGISTER_CLOSING										(18) //18 - Cierre de caja
#define TICKET_CANCELLATION											(19) //19 - Anulacion de tickets
#define TOTALIZE_EMISSION												(20) //20 - Emision de total
#define TICKET_NUMERATION_INITIALIZATION				(21) //21 - Reinicio de la numeracion de tickets
#define CALL_CANCELLATION												(22) //22 - Anulacion de llamada
#define BILL_SETTING														(23) //23 - Configuracion de la facturacion
#define AMOUNT_SETTING													(24) //24 - Configuracion de montos
#define PRINTING_SETTING												(25) //25 - Configuracion de la impresion
#define REGIONAL_SETTING												(26) //26 - Configuracion regional
#define GENERAL_SETTING													(27) //27 - Configuracion general
#define VISOR_SETTING														(28) //28 - Configuracion de los visores
#define TAX_INSERTED														(29) //29 - Alta impuesto
#define TAX_DELETED															(30) //30 - Baja impuesto
#define TAX_UPDATED															(31) //31 - Modificacion impuesto
#define CABIN_ACTIVATED													(32) //32 - Activacion de cabina
#define CABIN_DEACTIVATED												(33) //33 - Desactivacion de cabina
#define LINE_INSERTED														(34) //34 - Alta de linea
#define LINE_DELETED														(35) //35 - Baja de linea
#define LINE_UPDATED														(36) //36 - Modificacion de linea
#define TELESUPERVISION_INSERTED								(37) //37 - Alta de telesupervision
#define TELESUPERVISION_DELETED									(38) //38 - Baja de telesupervision
#define TELESUPERVISION_UPDATED									(39) //39 - Modificacion de telesupervision
#define CONNECTION_INSERTED											(40) //40 - Alta de conexion
#define CONNECTION_DELETED											(41) //41 - Baja de conexion
#define CONNECTION_UPDATED											(42) //42 - Modificacion de comexion
#define PROFILE_INSERTED												(43) //43 - Alta de perfil
#define PROFILE_DELETED													(44) //44 - Baja de perfil
#define PROFILE_UPDATED													(45) //45 - Modificacion de perfil
#define Event_NEW_USER													(46) //46 - Alta de usuario
#define Event_DELETE_USER												(47) //47 - Baja de usuario
#define Event_EDIT_USER													(48) //48 - Modificacion de usuario
#define VISOR_TRANSMITION_PROBLEM								(49) //49 - Problema en la transmision con el visor
#define VISOR_TRANSMITION_OUT_TX								(50) //50 - Transmision visores salida TX
#define VISOR_TRANSMITION_IN_RX									(51) //51 - Transmision visores entrada RX
#define NOT_ENOUGH_AMOUNT												(52) //52 - Monto insuficiente para realizar llamada
#define OPERATOR_CALL_FORBIDDEN									(53) //53 - Llamada por operadora prohibida
#define CANNOT_RECOVER_CALL											(54) //54 - No se pueden recuperar llamadas
#define BAR_CODE_SETTING                        (55) //55 - Configuracion de codigo de barras
#define CALL_TYPE_INSERTED                      (56) //56 - Alta de tipo de llamada
#define CALL_TYPE_DELETED                       (57) //57 - Baja de tipo de llamada
#define CALL_TYPE_UPDATED                       (58) //58 - Modificacion de tipo de llamada
#define TAX_BY_CALL_TYPE_INSERTED               (59) //59 - Asociacion de impuesto a tipo de llamada
#define TAX_BY_CALL_TYPE_DELETED                (60) //60 - Baja asociacion de impuesto a tipo de llamada
#define COLLECTOR_TOTAL_SETTING                 (61) //61 - Configuracion del total del recaudador
#define COMMERCIAL_STATE_SETTING                (62) //62 - Cambio el estado comercial

#define FORBIDDEN_CALL_TYPE_INSERTED            (66) //66 - Alta de tipo de llamada prohibida
#define FORBIDDEN_CALL_TYPE_DELETED             (67) //67 - Baja de tipo de llamada prohibida
#define FORBIDDEN_CALL_TYPE_UPDATED             (68) //68 - Modificacion de tipo de llamada prohibida
#define LINE_TYPE_INSERTED                      (69) //69 - Alta de tipo de linea
#define LINE_TYPE_DELETED                       (70) //70 - Baja de tipo de linea
#define LINE_TYPE_UPDATED                       (71) //71 - Modificacion de tipo de linea
#define CABIN_UPDATED                           (72) //72 - Modificacion de cabina
#define DATE_TIME_CHANGED                       (73) //73 - Cambio de fecha/hora
#define DATE_TIME_CHANGED_BLOCKED               (74) //74 - Cambio de fecha/hora bloqueado
#define LINE_TELESUP_SETTING                    (75) //75 - Modificacion de Supervision de lineas
#define TICKET_REPRINT                          (76) //76 - Reimpresion de ticket
#define TICKET_GENERATED                        (77) //77 - Emision de ticket
#define APPLY_TARIFF_TABLE                      (78) //78 - Se comenzo a utilizar una nueva tabla de tarifas    
#define AUTHORIZATION_CODE_UPDATED              (79) //79 - Cambio el codigo de autorizacion
#define AUDIT_REQUEST                           (80) //80 - Generacion de listado de auditoria
#define CATEGORY_INSERTED												(81) //81 - Alta de categoria
#define CATEGORY_DELETED												(82) //82 - Baja de categoria
#define CATEGORY_UPDATED												(83) //83 - Modificacion de categoria
#define CUSTOMER_INSERTED												(84) //84 - Alta de cliente
#define CUSTOMER_DELETED												(85) //85 - Baja de cliente
#define CUSTOMER_UPDATED												(86) //86 - Modificacion de cliente
#define PRODUCT_INSERTED												(87) //87 - Alta de producto
#define PRODUCT_DELETED													(88) //88 - Baja de producto
#define PRODUCT_UPDATED													(89) //89 - Modificacion de producto
#define TAX_BY_CATEGORY_INSERTED                (90) //90 - Asociacion de impuesto a categoria
#define TAX_BY_CATEGORY_DELETED                 (91) //91 - Baja asociacion de impuesto a categoria

// TELESUPERVISION 	
#define CANNOT_CONVERT_TARIFF_TABLE			100 	// No se puede convertir la tabla de tarifas
#define TELESUP_FAILED									101		// Fallo la supervision
#define TELESUP_SUCCESS                 102   // Supervision exitosa
#define NEW_TARIFF_TABLE								110		// Hay una nueva tabla de tarifas
#define TELESUP_START								    111		// se inicia la telesupervision
#define TELESUP_INIT_PIC						    112		// ejecucion del pic
#define TELESUP_PIC_OK						      113		// pic ok
#define TELESUP_PIC_ERROR						    114 	// pic error
#define TELESUP_INIT_LOGIN_ME				    115 	// ejecucion del login
#define TELESUP_LOGIN_ME_OK					    116 	// login ok
#define TELESUP_LOGIN_ME_ERROR			    117 	// login error
#define TELESUP_INIT_LOGIN_HIM			    118 	// ejecucion del login
#define TELESUP_LOGIN_HIM_OK				    119 	// login ok
#define TELESUP_LOGIN_HIM_ERROR			    120 	// login error
#define TELESUP_SET_DATE_TIME           121 
#define TELESUP_GET_DATE_TIME           122
#define TELESUP_SET_REGIONAL_SETTING    123
#define TELESUP_GET_REGIONAL_SETTING    124
#define TELESUP_GET_CALL_TRAFFIC        125
#define TELESUP_GET_TICKETS             126
#define TELESUP_GET_AUDITS              127
#define TELESUP_GET_TARIFF_TABLE        128 
#define TELESUP_PUT_TARIFF_TABLE        129
#define AUDIT_LINE_TELESUP_ERROR        130   // Error en la supervision de linea

// EVENTOS CIM
#define Event_BOOKMARK_INSET				(2007) /* Insercion de Bookmark */
#define Event_VALIDATE_BILL		      (2008) /* Verificacion de Billete */
#define AUDIT_CIM_DEPOSIT						(2009) /* Deposito Manual */
#define Event_DEPOSIT_MACRO		      (2010) /* Deposito Macro */
#define Event_AUTO_DROP		          (2011) /* Deposito Automatico o validado */
#define AUDIT_CIM_BILL_REJECTED			(2012) /* Billete rechazado */
#define Event_VALIDATOR_FULL		    (2013) /* Validador Lleno */
#define Event_VALIDATOR_JAM		      (2014) /* Atasco en Validador */
#define Event_COMUNICATION_LOST_WITH_VALIDATOR		 (2015) /* Perdida comunic con validador */
#define Event_STACKER_OUT		        (2016) /* Retiro de Stacker */
#define Event_STACKET_ABSENT		    (2017) /* Stacker Ausente */
#define Event_WRONG_LOGIN		        (2018) /* Login Erroneo */
#define Event_LOGIN_DURESS_PIN_USER	(2019) /* Duress Login */
#define AUDIT_CIM_DOOR_OPEN					(2020) /* Puerta abierta */
#define AUDIT_CIM_DOOR_CLOSE				(2021) /* Puerta cerrada */
#define Event_DOOR_ACCESS_VIOLATION	(2022) /* Violacion de Acceso en puerta */
#define Event_BEGIN_TIME_DELAY		  (2023) /* Inicio de Time Delay */
#define Event_END_TIME_DELAY		    (2024) /* Fin de Time Delay */
#define Event_BEGIN_TIME_LOCK		    (2025) /* Inicio de Time Lock */
#define Event_END_TIME_LOCK		      (2026) /* Fin de Time Lock */
#define Event_BEGIN_TIME_ALARM		  (2027) /* Inicio de Time Alarm */
#define Event_END_TIME_ALARM		    (2028) /* Fin de Time Alarm */
#define Event_SHOT_ALARM		        (2029) /* Disparo de Alarma */
#define Event_CHANGE_PIN		        (2030) /* Cambio de Clave */
#define Event_AUTO_INACTIVATE		    (2031) /* Auto Inactivacion */
#define Event_AUTO_LOGOUT		        (2032) /* Auto Logout */
#define Event_AUTO_DELETE		        (2033) /* Auto Eliminacion */
#define Event_INSTADROP_LOGIN		    (2034) /* Login Deposito instantaneo */
#define Event_INSTADROP_LOGOUT		  (2035) /* Logout Deposito instantaneo */
#define Event_EXTENDEDDROP_LOGIN		(2036) /* Login Deposito extendido */
#define Event_EXTENDEDDROP_LOGOUT		(2037) /* Logout Deposito extendido */
#define Event_WRONG_PIN_BLOCK		    (2038) /* Bloqueo por Clave erronea */
#define Event_PRINTING_ERROR		    (2039) /* Problemas de Impresion */
#define Event_NOT_RECOGNIZED_EXCEPTION	    (2040) /* Evento 40: Excepcion no Capturada */
#define Event_AUTORESTORING_INFORMATION		  (2041) /* Autorecupero de Informacion */
#define Event_DATETIME_SYNCHRONIZE		      (2042) /* Sincronizacion Fecha/Hora */
#define Event_ASSIGNE_OPERATION_BY_PROFILE	(2043) /* Asign. de Permiso por Perfil */
#define Event_DELETE_OPERATION_BY_PROFILE		(2044) /* Quitar Permiso por Perfil */
#define Event_ASSIGNE_DOOR_BY_USER		      (2045) /* Asign. de puerta a usuario */
#define Event_DELETE_DOOR_BY_USER		      	(2046) /* Quitar puerta a usuario */
#define Event_ASSIGN_DUAL_ACCESS					  (2047) /* Asign. de dupla de perfiles */
#define Event_DELETE_DUAL_ACCESS					  (2048) /* Quitar dupla de perfiles */
#define Event_NEW_LOCK		                  (2049) /* Nueva Cerradura */
#define Event_EDIT_LOCK		                  (2050) /* Edicion de Cerradura */
#define Event_DELETE_LOCK		                (2051) /* Borrado de Cerradura */
#define Event_NEW_ACCEPTOR		              (2052) /* Nuevo aceptador */
#define Event_EDIT_ACCEPTOR			            (2053) /* Edicion de aceptador */
#define Event_DELETE_ACCEPTOR			          (2054) /* Borrado de aceptador */
#define Event_OPERATOR_REPORT		            (2055) /* Reporte de Operador */
#define Event_CASH_REPORT		 		            (2056) /* Reporte de Caja */
#define Event_GRAND_Z		 		 		            (2057) /* Cierre Z */
#define AUDIT_CIM_ZCLOSE				            (2058) /* Cierre X */
#define Event_DEPOSIT_REPORT		 		 		    (2059) /* Reporte de Depositos */
#define Event_ENROLLED_USER_REPORT		 		 	(2060) /* Reporte Usuarios creados */
#define Event_CONFIG_REPORT		 		 		 	    (2061) /* Reporte de Configuracion */
#define Event_DROP_RECEIPT		 		 		 	    (2062) /* Recibo de Deposito */
#define Event_SYSTEM_INICIALIZATION		 	    (2063) /* Inicializacion de Sistema */
#define Event_SET_LANGUAGE		 		 	        (2064) /* Seteo de Lenguaje */
#define Event_VALIDATOR_FIRMWARE_UPGRADE    (2065) /* Act. de Firmware Validador */
#define Event_SYSTEM_INFO_REQUEST		        (2066) /* Reporte Info. de sistema */
#define Event_DROP_REQUEST		              (2067) /* Peticion de Deposito */
#define Event_STATUS_ACCOUNT_REQUEST		    (2068) /* Peticion Estado de cuenta */
#define Event_DEPOSIT_REQUEST	   		        (2069) /* Peticion de Extraccion */
#define Event_DOOR_OVERRIDE	   		          (2070) /* Apertura de Puerta Fuera de Hora */
#define Event_EDIT_USER_SETTINGS		        (2071) /* Edicion Config. General de Usuarios */
#define Event_GRAND_Z_REPRINT		            (2072) /* Reimpresion Cierre Z */
#define Event_GRAND_X_REPRINT		            (2073) /* Reimpresion Cierre X */
#define Event_DROP_RECEIPT_REPRINT		      (2074) /* Reimpresion Recibo Deposito */
#define Event_DEPOSIT_REPORT_REPRINT		    (2075) /* Reimpresion Recibo Extraccion */
#define AUDIT_CIM_EXTRACTION				        (2076) /* Extraccion efectuada */
#define AUDIT_CIM_RECOVER_DEPOSIT           (2077) /* Recupero de deposito */
#define EVENT_UNKNOW_BILL_STACKED           (2078) /* Billete Desconocido apilado */
#define EVENT_VALIDATOR_CAPACITY_WARNING    (2079) /* Validador/Buzon comprometido */
#define EVENT_NEW_MACRO                     (2080) /* Nueva Macro */
#define EVENT_DELETE_MACRO                  (2081) /* Borrado de Macro */
#define EVENT_WITHOUT_PERMISSION            (2082) /* Operacion no permitida */
#define EVENT_WITHOUT_DOOR_ACCESS           (2083) /* Puerta no permitida */
#define EVENT_SUPERVISION_REPORT            (2084) /* Reporte de Supervision */
#define EVENT_INVALID_DOOR_OVERRIDE         (2085) /* Codigo Override invalido */
#define EVENT_PURGE_USERS                   (2086) /* Purga de usuarios */
#define EVENT_DEVICE_COMMUNICATION_RECOVERY (2087) /* Recupero comunic c/ disp. */
#define EVENT_EDIT_MACRO                    (2088) /* Edicion de Macro */
#define EVENT_NEW_CASH                      (2089) /* Nuevo Cash */
#define EVENT_EDIT_CASH                     (2090) /* Edicion de Cash */
#define EVENT_DELETE_CASH                   (2091) /* Borrado de Cash */
#define EVENT_PURGE_INFORMATION             (2092) /* Purga de Informacion */
#define EVENT_REMOTE_CONNECTION_STARTED     (2093) /* Inicio Conexion remota */
#define EVENT_REMOTE_CONNECTION_FINISHED    (2094) /* Fin conexion remota */
#define EVENT_ACCESS_TIME_FINISHED          (2095) /* Fin de tiempo de acceso */
#define EVENT_PPWER_SUPPLY_BATTERY          (2096) /* Operacion con bateria */
#define EVENT_LOW_BATTERY_DETECTED          (2097) /* Deteccion bateria baja */
#define EVENT_SHUTDOWN_LOW_BATTERY          (2098) /* Apagado por bateria baja */
#define EVENT_CASH_REFERENCE_REPORT					(2099) /* Reporte de cash reference */	
#define Event_VALIDATOR_FIRMWARE_UPGRADE_ERROR    (2100) /* Act. de Firmware Validador Erronea */
#define Event_VALIDATOR_JAM_IN_STACKER			(2101) /* Billete atorado en el stacker */
#define Event_VALIDATOR_PAUSE								(2102) /* Validador pausado */
#define Event_VALIDATOR_CHEATED							(2103) /* Fraude en el validador */
#define Event_VALIDATOR_FAILURE							(2104) /* Falla en el validador */
#define Event_PRIMARY_HARDWARE_FAILURE			(2105) /* Falla en el hardware primario */
#define Event_STACKER_OUT_WITHOUT_REPORT		(2106) /* Se retiro el stacker habiendo rechazado por menu el retiro del dinero*/
#define Event_NEW_CASH_REFERENCE						(2107) /* Se da de alta un cash reference*/
#define Event_EDIT_CASH_REFERENCE 					(2108) /* Se edita un cash reference*/
#define Event_DELETE_CASH_REFERENCE					(2109) /* Se borra un cash reference*/
#define Event_DOOR_UNLOCK										(2110) /* Se desbloqueo la cerradura */
#define Event_DOOR_UNLOCK_ERROR							(2111) /* Error al desbloquear la cerradura */
#define Event_POWER_UP_WITH_BILL_IN_STACKER (2112)	/* Se inicio el validador con un billete en el stacker */ 
#define Event_POWER_UP_WITH_BILL_IN_ACCEPTOR (2113) /* Se inicio el validador con un billete en el aceptor */
#define Event_BATERY_ABSENT									 (2114) /* La bateria esta ausente */  
#define Event_CMP_TIMEOUT_CONNECT						 (2115) /* Se vencio el timeout de conexion con el CMP */
#define EVENT_NEW_BOX   	                   (2116) /* Nueva caja */
#define EVENT_EDIT_BOX    	                 (2117) /* Edicion de caja */
#define EVENT_DELETE_BOX    	               (2118) /* Borrado de caja */
#define EVENT_ADD_ACCEPTOR_BY_BOX    	       (2119) /* Nuevo aceptador en caja*/
#define EVENT_REMOVE_ACCEPTOR_BY_BOX    	   (2120) /* Eliminacion aceptador en caja*/
#define EVENT_ADD_DOOR_BY_BOX		    	   		 (2121) /* Nueva puerta en caja*/
#define EVENT_REMOVE_DOOR_BY_BOX    	   		 (2122) /* Eliminacion puerta en caja*/
#define EVENT_WORK_ORDER    	   		         (2123) /* Orden de Trabajo*/
#define EVENT_STACKER_FULL_BY_SETTING        (2124) /* Stacker full por aplicacion*/
#define EVENT_ACCEPTOR_SERIAL_NUMBER_CHANGE  (2125) /* Cambio de numero de serie en aceptador*/
#define EVENT_NEW_DENOMINATION							 (2126) /* Nueva denominacion */
#define EVENT_REMOVE_DENOMINATION						 (2127) /* Eliminacion denominacion */
#define EVENT_EDIT_DENOMINATION						 	 (2128) /* Edicion denominacion */
#define EVENT_NEW_DEPOSIT_TYPE						 	 (2129) /* Activacion de tipo de deposito */
#define EVENT_REMOVE_DEPOSIT_TYPE						 (2130) /* Desactivacion de tipo de deposito */
#define EVENT_NEW_CURRENCY									 (2131) /* Activacion de moneda */
#define EVENT_REMOVE_CURRENCY								 (2132) /* Desactivacion de moneda */
#define EVENT_NEW_ACCEPTOR_BY_CASH					 (2133) /* Nuevo aceptador por cash */
#define EVENT_REMOVE_ACCEPTOR_BY_CASH				 (2134) /* Baja aceptador por cash */
#define EVENT_VERSION_UPDATE								 (2135) /* Cambio en la version de software y/o Sistema operativo*/
#define Event_NEW_REPAIR_ORDER_ITEM			     (2136) /* crea la orden de reparacion*/
#define Event_EDIT_REPAIR_ORDER_ITEM			   (2137) /* modifica la orden de reparacion*/
#define Event_DELETE_REPAIR_ORDER_ITEM			 (2138) /* elimina la orden de reparacion*/
#define AUDIT_CIM_PARTIAL_DAY				         (2139) /* Cierre parcial X */
#define AUDIT_FORCE_ADMIN_PASSW				       (2140) /* Forzado password admin */
#define Event_EDIT_COMMERCIAL_STATE		       (2141) /* Edicion del estado comercial */
#define Event_CHANGE_STATE_REQUEST		       (2142) /* Solicitud de cambio de estado */
#define Event_STATE_CHANGE_AUT_ERROR 				 (2143) /* Error en autorizacion de cambio de estado */
#define Event_BLOCK_AUT_ERROR								 (2144) /* Error en autorizacion de baja del equipo */
#define Event_BLOCK_CONFIRMATION_ERROR			 (2145) /* Error en confirmacion de baja de equipo */
#define Event_CONFIRMATION_OK							   (2146) /* Confirmacion de baja OK */
#define Event_MANUAL_STATE_CHANGE_INTENTION	 (2147) /* Intento manual de cambio de estado */
#define Event_MANUAL_CHANGE_ERROR						 (2148) /* Error en el cambio manual de estado */
#define Event_CMP_STATE_CHANGE_INTENTION		 (2149) /* Intento via CMP de cambio de estado */
#define Event_PIMS_STATE_CHANGE_INTENTION		 (2150) /* Intento via PIMS de cambio de estado */
#define Event_SIGNATURE_GENERATION_ERROR     (2151) /* Error en generacion de firma */
#define Event_SIGNATURE_VERIFICATION_ERROR   (2152) /* Error en verificacion de firma */
#define Event_CANNOT_SUPERVISE_SIGN_ERROR    (2153) /* No es posible supervisar no  coinciden las firmas*/	 	
#define Event_SIM_CARD_CHANGE_PIN				  	 (2154) /* Cambio de PIN de tarjeta SIM */
#define Event_SIM_CARD_LOCKED								 (2155) /* Bloqueo de SIM Card */
#define Event_SIM_CARD_UNLOCKED							 (2156) /* Desbloqueo de SIM Card */
#define Event_STACKER_OK										 (2157) /* Se volvio a colocar el stacker/bolsa */
#define Event_ASSIGNE_BALANCE_BY_USER 			 (2158) /* Asignacion de credito por usuario */
#define Event_EDIT_BALANCE_BY_USER 			 		 (2159) /* Edision de credito por usuario */
#define Event_DELETE_BALANCE_BY_USER 			 	 (2160) /* Eliminacion de credito por usuario */
#define Event_UNLOAD_DISPENSER 			 	 			 (2161) /* Descarga de hoppers / columnas */
#define Event_LOAD_DISPENSER 			 	 			 	 (2162) /* Carga de hoppers / columnas */
#define Event_VEND 			 	 			 	 					 (2163) /* Dispensacion de monedas */
#define Event_BUY_CHANGE 			 	 			 	 		 (2164) /* Compra de cambio */
#define Event_LOCKER_ERROR									 (2165) /* Error en la cerradura */
#define Event_OPERATOR_CREDIT_REPORT				 (2166) /* Reporte de credito por operador */
#define Event_HOPPER_ERROR				 					 (2167) /* Error en dispensador */
#define EVENT_TRANSACTIONS_REPORT				 		 (2168) /* Reporte de movimientos */
#define Event_MANUAL_DROP_REQUEST		    		 (2169) /* Peticion de Deposito manual */
#define Event_VEND_REQUEST		    		 			 (2170) /* Peticion de Dispensacion */
#define Event_LOAD_REQUEST		    		 			 (2171) /* Peticion de Carga */
#define Event_UNLOAD_REQUEST		    		 		 (2172) /* Peticion de Descarga */
#define Event_BUY_CHANGE_REQUEST		    		 (2173) /* Peticion de Compra de cambio */
#define Event_ZCLOSE_REQUEST		    		 		 (2174) /* Peticion de Cierres Z */
#define Event_XCLOSE_REQUEST		    		 		 (2175) /* Peticion de Cierres X */
#define Event_SUP_INTENTION_FAILED   		 		 (2176) /* Intento de supervision fallido */
#define Event_TELESUP_INVALID_PTSD_PROTOCOL	 (2177) /* Protocolo PTSD invalido */
#define Event_TELESUP_TEST_OPEN_PORT_ERROR	 (2178) /* Test telesup error. Error abriendo el puerto*/
#define Event_TELESUP_TEST_MODEM_NO_RESPONSE (2179) /* Test telesup error. Modem no responde*/
#define Event_TELESUP_TEST_SIM_CARD_ERROR		 (2180) /* Test telesup error. Error en SIM card*/
#define Event_TELESUP_TEST_SIM_NOT_REGISTERED (2181) /* Test telesup error. Sim no registrado*/
#define Event_TELESUP_TEST_LINE_ERROR				  (2182) /* Test telesup error. Error en linea*/
#define Event_TELESUP_TEST_MODEM_OK					  (2183) /* Test telesup. Modem OK*/
#define Event_OPERATOR_CLOSE								  (2184) /* Cierre de operador*/
#define Event_SAFEBOX_SOFTWARE_UPDATE					(2185)	/* Actualizacion de la Aplicacion del Safebox */
#define Event_SPOOLER_SOFTWARE_UPDATE					(2186) /* Actualizacion del Spooler */
#define Event_CONSOLE_SOFTWARE_UPDATE					(2187) /* Actualizacion de la Console */
#define Event_SHOT_ALARM_BURGLARY							(2188) /* Disparo de alarma de robo */
#define Event_OPERATOR_CLOSE_REPORT_REPRINT		(2189) /* Reimpresion Cierre de operador */
#define Event_OPERATOR_CLOSE_REQUEST		    	(2190) /* Peticion de Cierres de operador */
#define Event_BILL_STACKED_WITHOUT_DROP				(2191) /* Se stackeo un billete y no hay un deposito abierto */
#define Event_NEW_CONSOLE	                    (2192) /* Nueva consola */
#define Event_EDIT_CONSOLE 	                  (2193) /* Edicion de consola */
#define Event_DELETE_CONSOLE 	                (2194) /* Borrado de consola */
#define Event_NEW_DOOR_GROUP	                (2195) /* Nuevo grupo de puertas */
#define Event_EDIT_DOOR_GROUP 	              (2196) /* Edicion de grupo de puertas */
#define Event_DELETE_DOOR_GROUP 	            (2197) /* Borrado de grupo de puertas */
#define Event_UNKNOWN_DISPENSE_RESULT					(2198) /* Llego un mensaje de monedas dispensadas sin ninguna operacion asociada */
#define Event_UNCOMPLETE_OPERATION						(2199) /* Operacion incompleta o sin finalizar correctamente */
#define Event_BOX_DISCONNECTED								(2200) /* Se desconecto una caja */
#define Event_INNERDBOARD_FIRMWARE_UPGRADE_ERROR		(2201) /* Error al actualizar la innerboard */
#define Event_INNERDBOARD_FIRMWARE_UPGRADE					(2202) /* Actualizacion de la innerboard */
#define Event_INFORM_DEPOSIT								 (2203) /* Informar Retiro */
#define Event_EMPTY_MAC								 			 (2204) /* Informar Mac vacia */
#define Event_START_MANUAL_DROP						 	 (2205) /* Comienzo de deposito manual */
#define Event_CANCEL_MANUAL_DROP					 	 (2206) /* Cancelacion de deposito manual */
#define Event_START_VALIDATED_DROP					 (2207) /* Comienzo de deposito validado */
#define Event_CANCEL_VALIDATED_DROP					 (2208) /* Cancelacion de deposito validado */
#define Event_START_BILL_VALIDATION					 (2209) /* Comienzo de validacion de billetes */
#define Event_END_BILL_VALIDATION					 	 (2210) /* Fin de validacion de billetes */

#define Event_TELESUP_TEST_GPRS_NETWORK_ERROR	 (2216) /* Error en la red GPRS */
#define Event_STACK_MOTOR_FAILURE	 						 (2217) /* Fallo motor Stacker */
#define Event_T_MOTOR_SPEED_FAILURE	 					 (2218) /* Fallo velocidad motor */
#define Event_T_MOTOR_FAILURE	 								 (2219) /* Fallo en motor */
#define Event_CASHBOX_NOT_READY	 							 (2220) /* Validador no listo */
#define Event_VALIDATOR_HEAD_REMOVED	 				 (2221) /* Cabezal removido */
#define Event_BOOT_ROM_FAILURE	 							 (2222) /* Fallo memoria de arranque */
#define Event_EXTERNAL_ROM_FAILURE	 					 (2223) /* Fallo memoria externa */
#define Event_ROM_FAILURE	 										 (2224) /* Fallo en memoria */
#define Event_EXTERNAL_ROM_WRITING_FAILURE	 	 (2225) /* Fallo escritura en memoria externa */
#define Event_DUMP_SETTINGS	 	 								 (2226) /* Dump de configuracion */
#define Event_RESTART_INETD	 	 								 (2227) /* Reiniciar InetD */
#define Event_EDIT_LICENCE_MODULE							 (2228) /* Edicion de modulos de licenciamiento */
#define Event_DISABLE_MODULE									 (2229) /* Inhabilitacion de modulos*/
#define Event_FORCE_DISABLE_MODULE						 (2230) /* Inhabilitacion forzoza de modulos*/	
#define Event_MODULE_EXPIRED_BY_DATE					 (2231) /* Modulo expiro por fechas*/
#define Event_MODULE_EXPIRED_BY_ELAPSED_TIME	 (2232) /* Modulo expiro por tiempo transcurrido*/	
#define Event_MODULE_SIGNATURE_VERIFICATION_ERROR	 (2233) /* Error en verificacion de firma de modulo*/
#define Event_UNKNOWN_CAUSE	 									 (2234) /* causa de falla desconocida en validador */
#define Event_CREATE_SPECIAL_USER	 						 (2235) /* Creacion de usuario especial */
#define Event_REPRINT_CODE_SEAL					 	 		 (2236) /* Reimpresion de Codigo de Cierre */
#define Event_RESET_DYNAMIC_PIN					 	 		 (2237) /* Reseteo Pin Dinamico */
#define Event_NEW_CODE_SEAL					 	 				 (2238) /* Generacion de Nuevo Codigo de Cierre */
#define Event_CHANGE_BOX_MODEL					 	 		 (2239) /* Cambio de modelo fisico de caja */
#define Event_BACKUP_STARTED					 	 		 	 (2240) /* Inicio de backup */
#define Event_BACKUP_FINISHED					 	 		 	 (2241) /* Fin de backup */
#define Event_BACKUP_CANCELED					 	 		 	 (2242) /* Backup cancelado */
#define Event_RESTORE_STARTED					 	 		 	 (2243) /* Inicio de restore (no utilizado)*/
#define Event_RESTORE_APPLIED					 	 	 		 (2244) /* Restore aplicado */
#define Event_RESTORE_ERROR					 	 		 		 (2245) /* Restore finalizado con ERROR */
#define Event_NEW_STACKER								 	 		 (2246) /* Nuevo stacker */
#define Event_BACKUP_ERROR								 	 	 (2247) /* Backup con ERROR */
#define Event_INCOMPATIBLE_FIRMWARE_ERROR			 (2248) /* Firmware incompatible */	
#define Event_INSERT_DEPOSIT_ERROR						 (2249) /* Error al insertar el deposito en el Vista (Hoyts) */	
#define Event_POWER_UP_WITH_ESCROW_STATUS				(2252) /* En el archivo temporal tengo un escrow pero no me llego un stacked ni returned */
#define Event_BILL_ADDED_AFTER_RESET				(2253) /* En el archivo temporal tengo un escrow pero no me llego un stacked ni returned */
#define Event_POWER_UP								(2254) /* El validador reporta un powerup */
#define Event_COMM_ERROR_WITH_OPEN_DEPOSIT  		(2255) /* El validador no responde luego del reset y habia un deposito en curso */
#define Event_MISPLACED_BAG   		(2256) /* El validador no responde luego del reset y habia un deposito en curso */
#define Event_WAIT_BANKNOTE_TO_BE_REMOVED 	(2257) /* El validador no responde luego del reset y habia un deposito en curso */

@interface	Event : Object
{
	int myEventId;
	int myEventCategoryId;
	char myEventName[30];
	int myHasAdditional;
	char myResource[11];
	BOOL myCritical;
}

/**
 *
 */
- (void) setEventId: (int) aValue;
- (void) setEventName: (char *) aName;
- (void) setEventCategoryId: (int) aValue;
- (void) setHasAdditional: (int) aValue;
- (void) setCritical: (BOOL) aValue;
- (void) setResource: (char *) aValue;

/**
 *
 */
- (int) getEventId;
- (int) getEventCategoryId;
- (char *) getEventName;
- (int) getHasAdditional;
- (BOOL) isCritical;
- (char *) getResource;

@end

#endif
