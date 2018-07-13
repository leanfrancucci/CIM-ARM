#ifndef __REQ_TYPES_H_
#define __REQ_TYPES_H_
	 
/** Listado de tipos  de Request */
enum
{
	INVALID_REQ = 0

	,SET_TEST_PARAM_REQ

	,START_JOB_REQ

	,END_JOB_REQ
	,COMMIT_JOB_REQ
	,ROLLBACK_JOB_REQ	
	
	,GET_APPLIED_MESSAGES_REQ

	,GET_DATETIME_REQ	 
	,SET_DATETIME_REQ

	,GET_GENERAL_BILL_REQ
	,SET_GENERAL_BILL_REQ

	,GET_CIM_GENERAL_SETTINGS_REQ
	,SET_CIM_GENERAL_SETTINGS_REQ

	,GET_DOOR_REQ
	,SET_DOOR_REQ

	,SET_ACCEPTOR_REQ
	,GET_ACCEPTOR_REQ

	,GET_CURRENCY_DENOMINATION_REQ
	,SET_CURRENCY_DENOMINATION_REQ
    ,GET_DENOMINATION_LIST_REQ
    
	,GET_DEPOSIT_VALUE_TYPE_REQ
	,SET_DEPOSIT_VALUE_TYPE_REQ

	,GET_DEPOSIT_VALUE_TYPE_CURRENCY_REQ
	,SET_DEPOSIT_VALUE_TYPE_CURRENCY_REQ

	,GET_CURRENCY_REQ

	,GET_CURRENCY_BY_ACCEPTOR_REQ

	,SET_CASH_BOX_REQ
	,GET_CASH_BOX_REQ
	,GET_ACCEPTORS_BY_CASH_REQ
	,SET_ACCEPTORS_BY_CASH_REQ

	,SET_BOX_REQ
	,GET_BOX_REQ
	,GET_ACCEPTORS_BY_BOX_REQ
	,SET_ACCEPTORS_BY_BOX_REQ
	,GET_DOORS_BY_BOX_REQ
	,SET_DOORS_BY_BOX_REQ

	,GET_REGIONAL_SETTINGS_REQ	 
	,SET_REGIONAL_SETTINGS_REQ

	,GET_COMMERCIAL_STATE_REQ
	,SET_COMMERCIAL_STATE_REQ

	,GET_PRINT_SYSTEM_REQ
	,SET_PRINT_SYSTEM_REQ

	,GET_AMOUNT_MONEY_REQ
	,SET_AMOUNT_MONEY_REQ
	
	,GET_USER_REQ
	,SET_USER_REQ
	,GET_USER_WITH_CHILDREN_REQ
	,GET_ALL_USER_REQ
	
	,GET_USER_PROFILE_REQ
	,SET_USER_PROFILE_REQ
	,GET_USER_PROFILE_CHILDREN_REQ
	
	,GET_OPERATION_REQ

	,SET_OPERATION_BY_USER_PROFILE_REQ
	,GET_OPERATIONS_BY_USER_REQ

	,SET_OPERATIONS_BY_USER_REQ

	,GET_EVENTS_SETTINGS_REQ
	,SET_EVENTS_SETTINGS_REQ
	
	,GET_TELESUP_SETTINGS_REQ
	,SET_TELESUP_SETTINGS_REQ	

	,SET_CONNECTION_REQ
	,GET_CONNECTION_REQ
  
  ,GET_DOORS_BY_USER_REQ
  ,GET_DOORS_BY_USERS_REQ
  ,SET_DOOR_BY_USER_REQ

  ,GET_DUAL_ACCESS_REQ
  ,SET_DUAL_ACCESS_REQ
  
  ,SET_FORCE_PIN_CHANGE_REQ
  
  ,SET_WORK_ORDER_REQ
  
  ,SET_REPAIR_ORDER_REQ
  ,GET_REPAIR_ORDER_REQ
  	
/* transferencia de archivos */	
	,GET_FILE_REQ
	,PUT_FILE_REQ
	,GET_AUDITS_REQ
	,GET_VERSION_REQ
	,CLEAN_DATA_REQ
	,RESTART_SYSTEM_REQ
	,PUT_TEXT_MESSAGES_REQ
	,GET_SYSTEM_INFO_REQ

/** PIMS */
	,GET_CONNECTION_INTENTION_REQ
	,KEEP_ALIVE_REQ
	,INFORM_REPAIR_ORDER_DATA_REQ
	,GET_CHANGE_STATE_INFO_REQ
	,INFORM_STATE_CHANGE_RESULT_REQ
	,GET_STATE_CHANGE_CONFIRMATION_REQ
	,INFORM_STATE_CHANGE_CONFIRMATION_RESULT_REQ
  ,SET_MODULE_REQ
	,GET_USER_TO_LOGIN_REQ
	,SET_USER_TO_LOGIN_RESPONSE_REQ
	,SET_INSERT_DEPOSIT_RESULT_REQ
	,GET_INTERNAL_USER_ID_REQ

/** CIM **/
	,GET_DEPOSITS_REQ
  ,GET_EXTRACTIONS_REQ
	,GET_CASH_REFERENCE_REQ
	,SET_CASH_REFERENCE_REQ
	,GET_CURRENT_BALANCE_REQ
	,LOGIN_REMOTE_USER_REQ
	,GET_ZCLOSE_REQ
	,GET_XCLOSE_REQ
	,GET_LOG_REQ
	,GET_SETTINGS_DUMP_REQ
	,GET_GENERIC_FILE_REQ
	
/** REMOTE CONSOLE */

	,USER_LOGIN_REQ
	,USER_HAS_CHANGE_PIN_REQ
	,USER_CHANGE_PIN_REQ
	,USER_LOGOUT_REQ

    ,START_VALIDATED_DROP_REQ
	,END_VALIDATED_DROP_REQ
	
	,INIT_EXTRACTION_PROCESS_REQ
	,GET_DOOR_STATE_REQ
	,SET_REMOVE_CASH_REQ
	,USER_LOGIN_FOR_DOOR_ACCESS_REQ
	,START_DOOR_ACCESS_REQ
	,CLOSE_EXTRACTION_REQ
	,CANCEL_DOOR_ACCESS_REQ
	,CANCEL_TIME_DELAY_REQ
	,START_EXTRACTION_REQ
    ,START_MANUAL_DROP_REQ
    ,ADD_MANUAL_DROP_DETAIL_REQ
    ,PRINT_MANUAL_DROP_RECEIPT_REQ
    ,CANCEL_MANUAL_DROP_REQ
    ,FINISH_MANUAL_DROP_REQ              
    ,START_VALIDATION_MODE_REQ
    ,STOP_VALIDATION_MODE_REQ
    
    
    ,GENERATE_OPERATOR_REPORT_REQ
    ,HAS_ALREADY_PRINT_END_DAY_REQ
    ,GENERATE_END_DAY_REQ
    ,GENERATE_ENROLLED_USERS_REPORT_REQ
    ,GET_EVENTS_CATEGORIES_REQ
    ,GENERATE_AUDIT_REPORT_REQ
    ,GENERATE_CASH_REPORT_REQ
    ,GENERATE_X_CLOSE_REPORT_REQ
    ,GENERATE_REFERENCE_REPORT_REQ
    ,GENERATE_SYSTEM_INFO_REPORT_REQ
    ,GENERATE_TELESUP_REPORT_REQ
    ,REPRINT_DEPOSIT_REQ
    ,REPRINT_EXTRACTION_REQ
    ,REPRINT_END_DAY_REQ
    ,REPRINT_PARTIAL_DAY_REQ

};

#endif
