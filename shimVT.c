#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <stdint.h>
#include <CoreFoundation/CoreFoundation.h>

const CFStringRef kVTCompressionPropertyKey_RealTime = CFSTR("RealTime");
const CFStringRef kVTProfileLevel_H264_Baseline_AutoLevel = CFSTR("H264_Baseline_AutoLevel");
const CFStringRef kVTProfileLevel_H264_Main_AutoLevel = CFSTR("H264_Main_AutoLevel");

#define kVTCompressionPropertyKey_ProfileLevel CFSTR("ProfileLevel")

// we need to pretend that setting real time and profile level properties succeeded (don't worry about get, it doesn't do it)

typedef OSStatus (pr_realVTSessionSetProperty) (void *, CFStringRef, CFTypeRef);
typedef pr_realVTSessionSetProperty* pt_pr_realVTSessionSetProperty;
static pt_pr_realVTSessionSetProperty realVTSessionSetProperty;

const CFStringRef kVTVideoDecoderSpecification_EnableHardwareAcceleratedVideoDecoder = CFSTR("EnableHardwareAcceleratedVideoDecoder");

const CFStringRef kVTDecompressionPropertyKey_UsingHardwareAcceleratedVideoDecoder = CFSTR("UsingHardwareAcceleratedVideoDecoder");

__attribute__((constructor)) static void initVTShim(){
    void *handle = dlopen ("/System/Library/Frameworks/VideoToolbox.framework/Versions/A/VideoToolbox", RTLD_NOW);
    if (!handle) {
        puts (dlerror());
        abort();
    }
    realVTSessionSetProperty = (pt_pr_realVTSessionSetProperty) dlsym(handle, "VTSessionSetProperty");
    if(!realVTSessionSetProperty) {
        puts ("No VTSessionSetProperty");
        abort();
    }
}


OSStatus VTSessionSetProperty(void *session, CFStringRef propertyKey, CFTypeRef propertyValue){
    OSStatus ret = realVTSessionSetProperty(session,propertyKey,propertyValue);
    if(ret != noErr && (CFEqual(propertyKey,kVTCompressionPropertyKey_RealTime) || CFEqual(propertyKey,kVTCompressionPropertyKey_ProfileLevel))){
        ret = noErr;
    }
    return ret;
}
