#include <objc/runtime.h>
// not in lion
extern void objc_setProperty(id self, SEL _cmd, ptrdiff_t offset, id newValue, BOOL atomic, BOOL shouldCopy);

void objc_setProperty_atomic(id self, SEL _cmd, id newValue, ptrdiff_t offset) {
	objc_setProperty(self,_cmd,offset,newValue,YES,NO);
}
