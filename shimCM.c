#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <stdint.h>
#include <CoreFoundation/CoreFoundation.h>

typedef OSStatus (pr_realCMVideoFormatDescriptionGetH264ParameterSetAtIndex) (void *, size_t, const uint8_t * _Nullable *, size_t *, size_t *, int *);
typedef pr_realCMVideoFormatDescriptionGetH264ParameterSetAtIndex* pt_pr_realCMVideoFormatDescriptionGetH264ParameterSetAtIndex;
static pt_pr_realCMVideoFormatDescriptionGetH264ParameterSetAtIndex realCMVideoFormatDescriptionGetH264ParameterSetAtIndex;

__attribute__((constructor)) static void initCMShim(){
    void *handle = dlopen ("/System/Library/Frameworks/CoreMedia.framework/Versions/A/CoreMedia", RTLD_NOW);
    if (!handle) {
        puts (dlerror());
        abort();
    }
    realCMVideoFormatDescriptionGetH264ParameterSetAtIndex = (pt_pr_realCMVideoFormatDescriptionGetH264ParameterSetAtIndex) dlsym(handle, "CMVideoFormatDescriptionGetH264ParameterSetAtIndex");
}

OSStatus CMVideoFormatDescriptionGetH264ParameterSetAtIndex(void * videoDesc, size_t parameterSetIndex, const uint8_t * _Nullable *parameterSetPointerOut, size_t *parameterSetSizeOut, size_t *parameterSetCountOut, int *NALUnitHeaderLengthOut){
    if(realCMVideoFormatDescriptionGetH264ParameterSetAtIndex) {
        return realCMVideoFormatDescriptionGetH264ParameterSetAtIndex(videoDesc, parameterSetIndex, parameterSetPointerOut, parameterSetSizeOut, parameterSetCountOut, NALUnitHeaderLengthOut);
   }
    return -1;
}
