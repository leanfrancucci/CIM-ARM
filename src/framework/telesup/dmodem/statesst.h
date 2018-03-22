#ifndef __STATESST_H__
#define __STATESST_H__

/*
*  C Interface: statesst
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
/**
*/
char *getStateString(int stateNumber);

/**
*/
char *getEventString(int eventNumber);

#endif
