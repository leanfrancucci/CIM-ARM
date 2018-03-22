#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include "ptsm.h"
#include "dmodem.h"

#define __SHOW_STATES__

#define printd(args...)	

#ifdef __SHOW_STATES__
//#include "log.h"
#include "statesst.h"
#endif

/*
 * Procesa la maquina de estados de los protocolos de transporte
 */


/***
 * Devuelve el siguiente estado en la maquinita de estados.
 * Si no encuentra una transicion valida desde elestado actual hacia otro estado
 * con event devuelve INITIAL_ST
 */ 
static
int dm_get_next_state(ProtoTransition *sm, int size, int state, int event)
{
	ProtoTransition *p;
	
	for (p = sm; p < &sm[size] ; p++) {
		if (p->current_state == state && p->event == event)
			return p->next_state;
	}
	return -1;
};

/***
 * Devuelve la funcionque hay que ejecutar en latransicion.
 * Si no encuentra una transicion valida desde el estado actual hacia otro estado
 * con event devuelve NULL
 */ 
static
ProtoFHandler *dm_get_fhandler(ProtoTransition *sm, int size, int state, int event)
{
	ProtoTransition *p;
	
	for (p = sm; p < &sm[size] ; p++) {	
		if (p->current_state == state && p->event == event)
			return p->fhandler;
	}
	return NULL;
};



/**/
int
proto_engine( 	ProtoTransition  *sm, int size, 
						int(wevent)(int handle), void(clean_f)(int handle), 
						int no_event, int init_state, int final_state ,const int handle)
{
	int state,currState, event, new_event;
	ProtoFHandler *fhandler;
	printd("IN PROTO ENGINE\n");	
 	/*
 	  Los fhandler() de write_sm devuelven un nuevo evento valido (new_event)
 	  o un no evento.
 	*/
 	assert(sm);assert(size > 0);	assert(wevent);	

	state = init_state;
	new_event = no_event;
#ifdef __SHOW_STATES__ 
 // if (dmodem_getLogState(handle))
 	  printd("Dmodem - Init State: %s\n",getStateString (state));
#endif	
 	while (1) {
 	
		/* Espera un evento.
		   Si no llega ninguno entonces sale y vuelve a entrar en el siguiente bucle.
		   (la funcion wevent() no queda bloqueada)
		*/
		if ( new_event == no_event ) 
			event = wevent(handle);
		else 
			event = new_event;

 		if ( event != no_event ) {
 			
 			/* obtiene la funcion y el siguiente estado de la transicion */
 			fhandler = dm_get_fhandler(sm, size, state, event);
 			
 			/*resguardo el estado actual por si el evento no existe*/
      currState = state;
      
 			state = dm_get_next_state(sm, size, state, event);
 			//assert(fhandler && state != -1);
 			
 			/* ejecuta el handler de la transicion */
 			if (fhandler && state != -1){
#ifdef __SHOW_STATES__
      //if (dmodem_getLogState(handle))
 			  printd("Dmodem[%d] - Event: %s Next State: %s \n",handle,getEventString(event),getStateString(state));
#endif 			
 			  new_event = fhandler(handle);
 			  /* Si devuelve estado de salida sale */
 			  if ( state == final_state )  
 				 break; 
 			} 			   			  
 			else{
 			  state = currState;
#ifdef __SHOW_STATES__
      //if (dmodem_getLogState(handle))
 			  printd("Dmodem[%d] - Evento (%s) no manejado en el estado: %s" ,getEventString(event),getStateString(state));
#endif 			  
 			  new_event =no_event;
 			}	
 		}
 	}
 	
 	/* resetea todo lo que tiene que resetear */
 	if (clean_f) clean_f(handle);
 		
 	return 1;
 }

