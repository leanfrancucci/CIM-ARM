#include <stdio.h>
#include <stdlib.h>

#ifdef __WIN32
#include <windows.h>
#include <tchar.h>
#endif

#ifdef __UCLINUX
#include <net.h>
#endif

int block_count;
static unsigned char encryptMatrix[256] = {167,243,104,103,169,18,36,185,137,131,204,72,147,96,28,161,162,34,231,201,77,149,230,199,192,11,136,220,23,227,148,60,241,228,7,174,69,83,31,255,209,124,65,78,146,46,5,216,66,84,180,89,178,212,9,115,102,87,29,198,42,68,129,94,236,155,39,197,151,41,160,32,163,80,186,164,49,108,120,139,122,109,43,184,152,98,219,217,193,233,76,112,252,150,239,251,138,99,58,126,156,0,203,25,218,187,254,229,116,240,153,248,97,135,222,38,125,91,225,62,133,13,213,189,242,33,53,118,176,190,130,50,234,51,27,56,172,44,30,194,158,143,26,15,12,24,165,170,235,64,117,249,221,154,157,119,171,205,10,253,67,232,195,173,6,200,4,175,196,105,226,224,59,106,211,61,74,237,90,145,207,93,75,95,247,179,1,48,45,238,132,210,144,246,113,142,114,22,57,177,52,85,3,134,168,71,159,127,215,244,86,208,2,81,14,182,123,107,191,141,40,214,183,128,206,250,73,35,181,37,16,8,202,100,166,47,140,19,223,88,82,101,20,21,54,110,245,17,121,79,55,111,92,188,63,70};
static unsigned char decryptMatrix[256] = {101,186,212,202,166,46,164,34,231,54,158,25,144,121,214,143,230,247,5,237,242,243,197,28,145,103,142,134,14,58,138,38,71,125,17,227,6,229,115,66,220,69,60,82,137,188,45,235,187,76,131,133,200,126,244,250,135,198,98,172,31,175,119,254,149,42,48,160,61,36,255,205,11,226,176,182,90,20,43,249,73,213,240,37,49,201,210,57,239,51,178,117,252,181,63,183,13,112,85,97,233,241,56,3,2,169,173,217,77,81,245,251,91,194,196,55,108,150,127,155,78,248,80,216,41,116,99,207,223,62,130,9,190,120,203,113,26,8,96,79,236,219,195,141,192,179,44,12,30,21,93,68,84,110,153,65,100,154,140,206,70,15,16,72,75,146,234,0,204,4,147,156,136,163,35,167,128,199,52,185,50,228,215,222,83,7,74,105,253,123,129,218,24,88,139,162,168,67,59,23,165,19,232,102,10,157,224,180,211,40,191,174,53,122,221,208,47,87,104,86,27,152,114,238,171,118,170,29,33,107,22,18,161,89,132,148,64,177,189,94,109,32,124,1,209,246,193,184,111,151,225,95,92,159,106,39};

int operation_type;
unsigned char disc_name[1];
int i;
char s[20];
char *aux;
char *aux2;
char *buffer;    
int service_count = 0;
int service_type = 0;
unsigned char str[100];
unsigned char str_result[100];
unsigned char str_block1[100];
unsigned char str_block2[100];
short int str_result_info[100];
short int str_result_final[100];
unsigned char str_service_info[100];
unsigned char str_service[100];


void maskValue(unsigned char * str, unsigned char * str_result);
void makeBlocks(int service_count, unsigned char * str_result, short int * str_result_info);
void setInfo(int service_count, unsigned char * str_service, short int * str_result_info, short int * str_result_final);
void getServiceInfo(int service_count, unsigned char * str_service_info, short int * str_result_info, short int * str_result_final);
void createLic(short int * str_result_info, short int * str_result_final, char * buffer);
void createLicBlock(unsigned char * str_block1, unsigned char * str_block2, char * buffer);
void createFile(char * file_name, unsigned char * str_result);

/** Rutinas de encriptacion/desencriptacion por sustitucion simple */
char *encryptSimpleLic(unsigned char *dest, unsigned char *source, int qty);
char *decryptSimpleLic(unsigned char *dest, unsigned char *source, int qty);
char *decryptFileLic(char *fileName);
void init(void);


void LIBLIC_createLicToBlocks(char * buffer, unsigned char * str_block1, unsigned char * str_block2)
{
    /* creo el archivo de licencia encriptado */
    createLicBlock(str_block1, str_block2, buffer);
    
    /* creo el archivo de licencia encriptado */
    createFile("licencia.enc", buffer);     
} 

void LIBLIC_createLic(char * buffer, int service_count, unsigned char * str_result, int * vs)
{
    int x;

    /*inicializo las variables*/
    init();
    
    /*cargo los servicios*/
    for (x=0; x<service_count; ++x) {
      str_service[x] = vs[x];
    }    
    
    /* creo los bloques sin servicios*/
    makeBlocks(service_count, str_result, str_result_info);  

    /* creo los bloques con los servicios*/
    setInfo(service_count, str_service, str_result_info, str_result_final);
    
    /* creo las cadenas de la licencia encriptada */
    createLic(str_result_info, str_result_final, buffer);
    
    /* creo el archivo de licencia encriptado */
    createFile("licencia.enc", buffer);                     
}

void LIBLIC_maskDiscMac(char * buffer, unsigned char * str)
{
    /*inicializo las variables*/
    init();
    
    /* enmascaro el nro de serie del disco o mac address */
    maskValue(str, str_result);
    
    strcpy(buffer, str_result);        
}

int LIBLIC_verifieLic(char * buffer, int service_count, unsigned char * str_result)
{
    /*inicializo las variables*/
    init();
        
    buffer[0] = '\0';
                      
    /* creo los bloques sin servicios*/
    makeBlocks(service_count, str_result, str_result_info);  

    /* creo los bloques con los servicios*/
    setInfo(service_count, str_service, str_result_info, str_result_final);
    
    /* desencripto el archivo y obtengo la secuencia de bloques */
    aux = decryptFileLic("licencia.enc");
    if (aux == NULL)
      return 2; // si no existe devuelvo error 
                          
    i=0;
    s[0] = '\0';
    while((i < strlen(aux)) && (aux[i] != '\n')){
      sprintf(s,"%c",aux[i]);
      strcat(str, s); 
      i++;    
    }
        
    /* paso los bloques que tengo en memoria a una cadena de caracteres para poder compararlos */     
    aux2 = malloc(block_count);
    strcpy(buffer, "");
    aux2[0] = '\0';      
    for (i=0; i<block_count; ++i) {
      if (aux2[0] == '\0')
        sprintf(aux2, "%d",str_result_info[i]);
      else
        sprintf(aux2, "%c%d",'-',str_result_info[i]);
            
      strcat(buffer, aux2);       
    }            
                                                      
    if (strcmp(str, buffer) == 0){
      strcpy(buffer, aux);
      return 0; /*validacion exitosa*/                
    }else{      
      if (strcmp(str, "Dgroup-5231") == 0){
        // creo nuevamente el archivo de licencia.enc que permite el acceso ilimitado        
        strcat(buffer, "\n");  
        strcat(buffer, str);
        // encripto la info  
        encryptSimpleLic(buffer, buffer, strlen(buffer));        
        createFile("licencia.enc", buffer);  
        return 0; /*validacion exitosa no verifica licenciamiento*/
      }
      else
        return 1; /*Licencia corrupta*/
     } 
}

int LIBLIC_getServiceValue(int service_type)
{
    /*inicializo las variables*/
    init();
    
    /* desencripto el archivo y obtengo la secuencia de bloques */
    aux = decryptFileLic("licencia.enc");
    if (aux == NULL)
      return 0; // si no existe devuelvo error 
      
    // cargo el primer bloque y me paro en el \n 
    i=0;
    s[0] = '\0';
    while((i < strlen(aux)) && (aux[i] != '\n')){
      if (aux[i] != '-'){
        sprintf(s,"%c",aux[i]);
        strcat(str, s); 
        i++; 
      }else{
        str_result_info[block_count] = atoi(str);
        str[0] = '\0';
        block_count++;
        i++;
      }             
    }
    str_result_info[block_count] = atoi(str);
    str[0] = '\0';
    block_count++;
                                
    i++; // paso al primer caracter despues del \n y cargo el segundo bloque
    block_count = 0;
    s[0] = '\0';      
    while((i < strlen(aux))){
      if (aux[i] != '-'){
        sprintf(s,"%c",aux[i]);
        strcat(str, s); 
        i++;
      }else{
        str_result_final[block_count] = atoi(str);
        str[0] = '\0';
        block_count++;
        i++;
      }            
    }
    // cargo el ultimo bloque
    str_result_final[block_count] = atoi(str);
    block_count++;     
                           
    //****** Obtengo los servicios de los bloques.
    service_count = block_count;
    getServiceInfo(service_count, str_service_info, str_result_info, str_result_final);
    
    return str_service_info[service_type];
}

#ifdef __WIN32
int LIBLIC_getDiscNumber(char * buffer, unsigned char * disc_name)
{
    /* obtengo el nro de serie del disco */                            
    char VolumeNameBuffer[300];
    unsigned long VolumeSerialNumber; 
    long MaximumComponentLength; 
    long FileSystemFlags; 
    char FileSystemNameBuffer[300];
    char hexValue[50];
    char hexAux[50];
    int j = 0;

    /*inicializo las variables*/
    init();
        
    //strcat(disc_name, ":\\");
   
    if (!GetVolumeInformation(disc_name, VolumeNameBuffer, 255, &VolumeSerialNumber, &MaximumComponentLength, &FileSystemFlags, FileSystemNameBuffer, 255))                          
        return 1;                 
     
    hexValue[0] = '\0';
    hexAux[0] = '\0';            
    /* el resultado esta en decimal y hay que pasarlo a hexadecimal */
    sprintf(hexValue,"%X", VolumeSerialNumber);            
  
    /* lo paso a mayuscula y le concateno el guion en el medio */
    i = 0;      
    while((i < strlen(hexValue))){
      hexAux[j] = hexValue[i];
      hexAux[j+1] = '\0';
      if (((i+1) < strlen(hexValue)) && (((i+1) % 4) == 0)){          
        j++;
        strcat(hexAux, "-");
      }                 
      i++; j++;
    }      
    
    strcpy(buffer, hexAux);  
                     
    return 0;    
}
#endif

#ifdef __UCLINUX
int LIBLIC_getMacAddess(char * buffer)
{
    char strmac[100];
    int i = 0;
    
    strmac[0] = '\0';
    // llamo a la funcion if_netInfo para obtener la macaddress    
    i = if_netInfo("eth0", strmac);    
    strcpy(buffer, strmac);
    
    return i;  
}
#endif

void LIBLIC_getBlockNumber(char * buffer, int service_count, unsigned char * str_result, int * vs)
{
    int x;
    char aux[50];

    /*inicializo las variables*/
    init();
    
    /*cargo los servicios*/
    for (x=0; x<service_count; ++x) {
      str_service[x] = vs[x];
    }   
    
    /* creo los bloques sin servicios*/
    makeBlocks(service_count, str_result, str_result_info);

    /* creo los bloques con los servicios*/
    setInfo(service_count, str_service, str_result_info, str_result_final);
    
    /* creo el archivo con el nro de licencia sin encriptar */
    strcpy(buffer, "");
    aux[0] = '\0';
    for (i=0; i<block_count; ++i) {
      if (aux[0] == '\0')
        sprintf(aux, "%d",str_result_info[i]);
      else
        sprintf(aux, "%c%d",'-',str_result_info[i]);
            
      strcat(buffer, aux);       
    }
    
    strcat(buffer, "\n");      
    aux[0] = '\0';
    for (i=0; i<block_count; ++i) {
      if (aux[0] == '\0')
        sprintf(aux, "%d",str_result_final[i]);
      else
        sprintf(aux, "%c%d",'-',str_result_final[i]);
            
      strcat(buffer, aux);    
    }           
}

int LIBLIC_hasVerifiedLic(int service_count, unsigned char * str_result)
{
    /*inicializo las variables*/
    int j;    
    char *auxF;
    char aux[50];
    char buffer[100];

    init();
                                             
    /* desencripto el archivo y obtengo la secuencia de bloques */
    auxF = decryptFileLic("licencia.enc");
    if (auxF == NULL)
      return 0; // si no existe devuelvo error 
            
    i=0;
    s[0] = '\0';        
    while((i < strlen(auxF)) && (auxF[i] != '\n')){
      sprintf(s,"%c",auxF[i]);
      strcat(str, s); 
      i++;    
    }
    
    /* creo los bloques sin servicios*/
    makeBlocks(service_count, str_result, str_result_info);    
    strcpy(buffer, "");
    aux[0] = '\0';
    buffer[0] = '\0';
    for (j=0; j<block_count; ++j) {
      if (aux[0] == '\0')
        sprintf(aux, "%d",str_result_info[j]);
      else
        sprintf(aux, "%c%d",'-',str_result_info[j]);
            
      strcat(buffer, aux);       
    }
                    
    if (strcmp(str, buffer) != 0)  /* no machea el primer bloque, retorno 0*/                               	   
      if (strcmp(str, "Dgroup-5231") == 0){
         // creo nuevamente el archivo de licencia con el bloque sin servicios para evitar la reutilizacion del archivo en otra pc o equipo
         char aBuffer[100];
         aBuffer[0] = '\0';                                    	   
         LIBLIC_createLicToBlocks(aBuffer, buffer, "Dgroup-5231");
         return 1;
      }
       else 
         return 0;     
    
    // copio desde el /n sin incluirlo 
    i++;        
    s[0] = '\0';
    str[0] = '\0';
    while(i < strlen(auxF)){
      sprintf(s,"%c",auxF[i]);
      strcat(str, s); 
      i++;    
    }

    if (strcmp(str, "Dgroup-5231") == 0)                                 	   
      return 1;                    
    else
      return 0;
}

void init(void)
{
  block_count = 0;
  str[0]='\0';
  str_result[0]='\0';
  str_block1[0]='\0';
  str_block2[0]='\0';
  str_service[0]='\0';
  str_result_info[0]='\0';
  str_result_final[0]='\0';
  str_service_info[0]='\0';  
  disc_name[0]= '\0';
}
 

/* metodo que enmascara el nro de disco o mac address a una secuencia de bloques
 * al finalizar deja en str_result los valores obtenidos*/
void maskValue(unsigned char * str, unsigned char * str_result){
  int i = 0;  
  int value = 0;
  char s[20];

  for(i=0; i < strlen(str); i++){    
    if (str[i] != '-'){
      value+= str[i] + (10+((i+1)*2));      
           
      if (((i+1) % 2) == 0){
         s[0] = '\0';
         if (str_result[0] == '\0'){
           sprintf(s,"%d",value);
         }else{
           sprintf(s,"%c%d",'-',value);
         }
         strcat(str_result, s);
         value = 0;
      }
    }
  }
}


/* procedimiento que genera los bloques con la mascara obtenida y la cantidad de servicios utilizados
 * luego los almacena en un vector de unsigned char*/
void makeBlocks(int service_count, unsigned char * str_result, short int * str_result_info){
  int i;
  int value = 0;
  
  for(i=0; i < strlen(str_result); i++){
    if (str_result[i] != '-'){
      value+= str_result[i] + (10+((i+1)*2));      
    
      if (((i+1) % 2) == 0){
          if(block_count < service_count){
            str_result_info[block_count] = value;          
            block_count++;
            value = 0;            
          }
      }
    }
  } 
  // por si quedaron valores sin sumar
  if (value != 0){
    str_result_info[block_count-1] = str_result_info[block_count-1] + value;
  }
 
  // si la cantidad de servicios es mayor a la cantidad de bloques
  // creo mas bloques hasta alcanzar la cantidad de servicios
  if (service_count > block_count){
    for(i = block_count; i < service_count; i++){
        str_result_info[i] = str_result_info[0] + str_result_info[i-1];
        block_count++;
    }
  }else{  // sino quito los bloques sobrantes
    str_result_info[block_count] = '\0';
  }
}


/* procedimiento que incorpora la información de los srvicios a cada uno de los bloques*/
void setInfo(int service_count, unsigned char * str_service, short int * str_result_info, short int * str_result_final){
  int i;

  for(i=0; i < service_count; i++)  
    str_result_final[i] = str_result_info[i] + (str_service[i] * (i+2)) + ((i+1) * 7);
}


/* procedimiento que obtiene la información a cada uno de los servicios incluida en los bloques*/
void getServiceInfo(int service_count, unsigned char * str_service_info, short int * str_result_info, short int * str_result_final){
  int i;

  for(i=0; i < service_count; i++)  
    str_service_info[i] = ((str_result_final[i] - ((i+1) * 7)) - str_result_info[i]) / (i+2);
}


/**/
char *encryptSimpleLic(unsigned char *dest, unsigned char *source, int qty) 
{
  int i;

  for (i = 0; i < qty; i++) {
    dest[i] = encryptMatrix[source[i]];
  }

  return dest;
}

/**/
char *decryptSimpleLic(unsigned char *dest, unsigned char *source, int qty) 
{
  int i;

  for (i = 0; i < qty; i++) {
    dest[i] = decryptMatrix[source[i]];
  }

  return dest;
}

/**/
char *decryptFileLic(char *fileName)
{
  FILE *file;
	char *buffer;
  int  size;

  file = fopen(fileName, "rb");
	if (!file) return NULL;

  fseek(file,0,SEEK_END);
  size = ftell(file);
	buffer = malloc(size+1);

  rewind(file);
  fread(buffer, size, 1, file);
	fclose(file);
  
  decryptSimpleLic(buffer, buffer, size);
  
	buffer[size] = 0;

  return buffer;
}

void createLicBlock(unsigned char * str_block1, unsigned char * str_block2, char * buffer)
{ 
  strcpy(buffer, "");
  strcat(buffer, str_block1);
  strcat(buffer, "\n");   
  strcat(buffer, str_block2);                    
  
  // encripto la info  
  encryptSimpleLic(buffer, buffer, strlen(buffer));
}


void createLic(short int * str_result_info, short int * str_result_final, char * buffer)
{  
  char *aux;
  int i;     
    
  aux = malloc(block_count);

  strcpy(buffer, "");
  aux[0] = '\0';
  for (i=0; i<block_count; ++i) {
    if (aux[0] == '\0')
      sprintf(aux, "%d",str_result_info[i]);
    else
      sprintf(aux, "%c%d",'-',str_result_info[i]);
          
    strcat(buffer, aux);       
  }
  
  strcat(buffer, "\n");
  aux[0] = '\0';
  for (i=0; i<block_count; ++i) {
    if (aux[0] == '\0')
      sprintf(aux, "%d",str_result_final[i]);
    else
      sprintf(aux, "%c%d",'-',str_result_final[i]);
          
    strcat(buffer, aux);    
  } 
  
  // encripto la info  
  encryptSimpleLic(buffer, buffer, strlen(buffer));      
}

void createFile(char * file_name, unsigned char * str_result)
{  
  FILE *file;
               
  file = fopen(file_name, "w+"); // si no existe lo crea
  fwrite(str_result, strlen(str_result), 1, file);
  fclose(file);
}
