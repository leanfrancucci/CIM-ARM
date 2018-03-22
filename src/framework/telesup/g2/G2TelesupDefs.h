#ifndef G2TELESUPDEFS_H
#define G2TELESUPDEFS_H


/**/
#define G2_TELESUP_MESSAGE_HEADER 				"Message"
/* Este si se define vacio debe sacarse el '\n' tambien */
#define G2_TELESUP_MESSAGE_HEADER_PLUS_ENTER 	"Message\012"

//#define G2_TELESUP_MESSAGE_HEADER 				""
//#define G2_TELESUP_MESSAGE_HEADER_PLUS_ENTER 	""


/* El numero maximo de bytes que puede contener un mensaje (incluye \n's per
   no incluye  la linea inicial que indica el tama� del mensaje */
#define		PIC_MSG_SIZE			1028


#endif
