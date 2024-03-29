/*
*  C Implementation: statesst
*
* Description: define los strings de los estados de la maquina de estados de envio y recepcion de tramas
*				y la funcion que devuelve el string del estado y evento
*
*
* Author: Lucas Martino,,, <martinol@martino-lnx>, (C) 2005
*
* Copyright: Delsat Group SA
*
*/

char statesStrings[38][60]= 
{
	 {"INVALID_ST"}
	 ,{"EXIT_ST"}
	,{"START_WRST"}
	,{"FRAMESENDED_WRST"}
	,{"CTRLMOREFRAMES_WRST"}
	,{"CTRLRETRANS_WRST"}
	,{"ACKRCV_WRST"}
	,{"NACKRCV_WRST"}
	,{"WAITSOH_RDST"}
	,{"WAITCTRL0_RDST"}
	,{"WAITCTRL1_RDST"}
	,{"WAITSEQ_RDST"}
	,{"WAITSEQCOMP_RDST"}
	,{"WAITLEN0_RDST"}
	,{"WAITLEN1_RDST"}
	,{"WAITLEN0COMP_RDST"}
	,{"WAITLEN1COMP_RDST"}
	,{"WAITPAYLOAD_RDST"}
	,{"WAITCHECKSUM_RDST"}
	,{"CTRLRETRANS_RDST"}
	,{"DISCARDBYTES_RDST"}
	,{"DISCARDRETRANS_RDST"}
	,{"SYNRCV_RDST"}
	,{"SYNCOMPRCV_RDST"}
	,{"EOTRCV_RDST"}
	,{"EOTCOMPRCV_RDST"}
	,{"START_CONNST"}
	,{"SYNSENDED_CONNST"}
	,{"CTRLRETRANS_CONNST"}
	,{"NACKRCV_CONNST"}
	,{"START_DISCONNST"}
	,{"EOTSENDED_DISCONNST"}
	,{"CTRLRETRANS_DISCONNST"}
	,{"ACKRCV_DISCONNST"}
};

/* Los eventos */
char eventsStrings[56][60]=
{
	  {"NO_EVT"}
	 ,{"START_EVT"}
	,{"SENDFRAME_WREVT"}
	,{"ACK_WREVT"}
	,{"ACKCOMP_WREVT"}
	,{"NACK_WREVT"}
 	,{"NACKCOMP_WREVT"} 	
	,{"UNBYTE_WREVT"}	
	,{"TXFRAMETO_WREVT"}
	,{"TXUPLAYERTO_WREVT"}
	,{"MOREFRAMES_WREVT"}
	,{"NOMOREFRAMES_WREVT"}
	,{"MORERETRANS_WREVT"}
	,{"NOMORERETRANS_WREVT"}
	,{"FRAMESENDEDERR_WREVT"}
	,{"RCVSOH_RDEVT"}
	,{"NOTSOH_RDEVT"}
	,{"RCVCTRL0_RDEVT"}
	,{"RCVCTRL1_RDEVT"}
	,{"RCVSEQ_RDEVT"}
	,{"RCVSEQCOMP_RDEVT"}
	,{"RCVLEN0_RDEVT"}
	,{"RCVLEN1_RDEVT"}
	,{"RCVLEN0COMP_RDEVT"}
	,{"RCVLEN1COMP_RDEVT"}
	,{"RCVBYTE_RDEVT"}
	,{"PAYLOADRCV_RDEVT"}
	,{"NOMOREFRAMES_RDEVT"}
	,{"MOREFRAMES_RDEVT"}
	,{"MORERETRANS_RDEVT"}
	,{"NOMORERETRANS_RDEVT"}
	,{"BADFRAME_RDEVT"}
	,{"RETRANS_RDEVT"}
	,{"RXBYTETO_RDEVT"}	
	,{"RXUPLAYERTO_RDEVT"}	
	,{"SYN_RDEVT"}		
	,{"SENDSYN_CONNEVT"}
	,{"UNBYTE_CONNEVT"}
	,{"TXFRAMETO_CONNEVT"}
	,{"TXUPLAYERTO_CONNEVT"}
	,{"NACK_CONNEVT"}
	,{"SYN_SENDEDERR_CONNEVT"}
	,{"MORERETRANS_CONNEVT"}
	,{"NOMORERETRANS_CONNEVT"}
	,{"NACKCOMP_CONNEVT"}
	,{"EOT_RDEVT"}
	,{"SENDEOT_DISCONNEVT"}
	,{"UNBYTE_DISCONNEVT"}
	,{"TXFRAMETO_DISCONNEVT"}
	,{"TXFRAMETO_DISCONNEVT"}
	,{"ACK_DISCONNEVT"}
	,{"EOT_SENDEDERR_DISCONNEVT"}
	,{"MORERETRANS_DISCONNEVT"}
	,{"NOMORERETRANS_DISCONNEVT"}
	,{"ACKCOMP_CONNEVT"}	
	
};
/***
*/
char *getStateString(int stateNumber)
{
	return statesStrings[stateNumber];
}
/***
*/
char *getEventString(int eventNumber)
{
	return eventsStrings[eventNumber];
}
