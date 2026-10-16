#include "gbsram.h"
#include <stddef.h>
GBSram_Config *GBSram_LookupConfig(UINTPTR base) {
 GBSram_Config *c=GBSram_ConfigTable;
 while(c->Name) {if(c->BaseAddress==base)return c;++c;}return NULL;
}
