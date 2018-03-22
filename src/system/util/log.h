#ifndef LOG_MGR_H
#define LOG_MGR_H

/*
*/
void doLog( char addHour, const char *fmt, ... );

/*
	Llamar a la funcion de inicializacion en el main de la aplicacion, antes de realizar algun loggueo
*/
void initLog( void );
FILE * openCreateFile( char *fileName );

#endif