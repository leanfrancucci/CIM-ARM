#ifndef __PTSM_H__
#define __PTSM_H__

/* Los tipos definidos para las maquinas de estado */
typedef int (ProtoFHandler)( int handle );

/* La transición 
 *		Las maquinitas de estado son tupla de cuatro elementos 
 *			(current_state, event, next_state, fhandler)
 *		en donde:
 *			estando en el estado "current_state" recibiendo el evento "event" se pasa 
 *			al nuevo estado "next_state" y se ejecuta la funcion "fhandler"
 */
typedef struct 
{
	char			 current_state;
	char			 event;
	char			 next_state;
	ProtoFHandler	*fhandler;
	
} ProtoTransition;

extern int logActive;
/**
 * Ejecuta el protocolo recorriendo las transiciones de read o write segun la tabla pasada por parametro.
 * @param sm referencia a la maquina de estados sobre la cual va a funcionar
 * @param size tamaño de la maquina de estados
 * @param wevent referencia a funcion de espera de evento
 * @param clean_freferencia a funcion de inicializacion del estado 
 * @param no_event valor que debe asignar esta funcion cuando no se producen eventos
 * @param init_state estado inicial de la maquina de estados
 * @param final_state estado final de la maquina de estados
 * @param handle handle del dmodem
 * @return si la operacion fue completada con exito
 */ 
int
proto_engine( 	ProtoTransition *sm, int size, 
					int(wevent)(int handle), void(clean_f)(int handle), 
					int no_event, int init_state, int final_state,const int handle );
						


#endif
