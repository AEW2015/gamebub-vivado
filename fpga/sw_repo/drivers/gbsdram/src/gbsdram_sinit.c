#include "gbsdram.h"
#include <stddef.h>
GBSdram_Config *GBSdram_LookupConfig(UINTPTR base) {GBSdram_Config *c=GBSdram_ConfigTable;while(c->Name){if(c->BaseAddress==base)return c;++c;}return NULL;}
