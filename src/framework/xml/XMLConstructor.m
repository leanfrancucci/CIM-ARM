#include "XMLConstructor.h"

@implementation XMLConstructor

static id singleInstance = NULL;

/**/
+ new
{
	return [[super new] initialize];
}

/**/
+ getInstance
{
	if (singleInstance) return singleInstance;
	singleInstance = [self new];
	return singleInstance;
}

/**/
- initialize
{
	return self;
}

/**/
- (scew_tree*) buildXML: (id) anEntity isReprint: (BOOL) isReprint
{
  THROW(ABSTRACT_METHOD_EX);
	return NULL;
} 

/**/
- (scew_tree*) buildXML: (id) anEntity entityType: (int) anEntityType isReprint: (BOOL) isReprint
{
  THROW(ABSTRACT_METHOD_EX);
	return NULL;	
}

/**/
- (scew_tree*) buildXML: (char*) aText
{
	scew_tree* tree;
  scew_element* root = NULL;
  /**/
  /*
  char fName[50];
  char path[50];
  */
	tree = scew_tree_create();

  root = scew_tree_add_root(tree, "text");
  scew_element_set_contents(root, aText);

  //Save an XML tree to a file.
  /*  
  sprintf(fName, "%s", "prueba.xml");
  
  //Concatena el nombre del archivo con el path  
  strcpy(path, [[Configuration getDefaultInstance] getParamAsString: "XML_FILES_PATH"]);

  strcat(path, fName); 
  
  if (!scew_writer_tree_file(tree, path)) {
      doLog("Unable to create %s\n", path);
      return NULL;
  }
  */
	return tree;
	  
}

@end
