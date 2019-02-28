#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <stdint.h>
#include <CoreFoundation/CoreFoundation.h>

// I hate this as much as you do.

typedef OSStatus (pr_realVTDecompressionSessionCreate) (CFAllocatorRef, void *, CFDictionaryRef, CFDictionaryRef, const void *, void *);
typedef pr_realVTDecompressionSessionCreate* pt_pr_realVTDecompressionSessionCreate;
static pt_pr_realVTDecompressionSessionCreate realVTDecompressionSessionCreate;

typedef OSStatus (pr_realVTDecompressionSessionDecodeFrame) (void *, void *, uint32_t, void *, uint32_t *);
typedef pr_realVTDecompressionSessionDecodeFrame* pt_pr_realVTDecompressionSessionDecodeFrame;
static pt_pr_realVTDecompressionSessionDecodeFrame realVTDecompressionSessionDecodeFrame;

typedef void (pr_realVTDecompressionSessionInvalidate) (void *);
typedef pr_realVTDecompressionSessionInvalidate* pt_pr_realVTDecompressionSessionInvalidate;
static pt_pr_realVTDecompressionSessionInvalidate realVTDecompressionSessionInvalidate;

typedef OSStatus (pr_realVTDecompressionSessionWaitForAsynchronousFrames) (void *);
typedef pr_realVTDecompressionSessionWaitForAsynchronousFrames* pt_pr_realVTDecompressionSessionWaitForAsynchronousFrames;
static pt_pr_realVTDecompressionSessionWaitForAsynchronousFrames realVTDecompressionSessionWaitForAsynchronousFrames;

typedef OSStatus (pr_realVTSessionCopyProperty) (void *, CFStringRef, CFAllocatorRef, void *);
typedef pr_realVTSessionCopyProperty* pt_pr_realVTSessionCopyProperty;
static pt_pr_realVTSessionCopyProperty realVTSessionCopyProperty;

const CFStringRef kVTVideoDecoderSpecification_EnableHardwareAcceleratedVideoDecoder = CFSTR("EnableHardwareAcceleratedVideoDecoder");

const CFStringRef kVTDecompressionPropertyKey_UsingHardwareAcceleratedVideoDecoder = CFSTR("UsingHardwareAcceleratedVideoDecoder");

/*
 _kVTDecompressionPropertyKey_UsingHardwareAcceleratedVideoDecoder - we need to fake this
 */

__attribute__((constructor)) static void initVTShim(){
    void *handle = dlopen ("/System/Library/Frameworks/VideoToolbox.framework/Versions/A/VideoToolbox", RTLD_NOW);
    if (!handle) {
        handle = dlopen ("/System/Library/PrivateFrameworks/VideoToolbox.framework/Versions/A/VideoToolbox", RTLD_NOW);
        if (!handle) {
            puts (dlerror());
            abort();
        }
    }
    realVTDecompressionSessionCreate = (pt_pr_realVTDecompressionSessionCreate) dlsym(handle, "VTDecompressionSessionCreate");
    if(!realVTDecompressionSessionCreate) {
        puts ("No VTDecompressionSessionCreate");
        abort();
    }
    realVTDecompressionSessionDecodeFrame = (pt_pr_realVTDecompressionSessionDecodeFrame) dlsym(handle, "VTDecompressionSessionDecodeFrame");
    if(!realVTDecompressionSessionDecodeFrame) {
        puts ("No VTDecompressionSessionDecodeFrame");
        abort();
    }
    realVTDecompressionSessionInvalidate = (pt_pr_realVTDecompressionSessionInvalidate) dlsym(handle, "VTDecompressionSessionInvalidate");
    if(!realVTDecompressionSessionInvalidate) {
        puts ("No VTDecompressionSessionInvalidate");
        abort();
    }
    realVTDecompressionSessionWaitForAsynchronousFrames = (pt_pr_realVTDecompressionSessionWaitForAsynchronousFrames) dlsym(handle, "VTDecompressionSessionWaitForAsynchronousFrames");
    if(!realVTDecompressionSessionWaitForAsynchronousFrames) {
        puts ("No VTDecompressionSessionWaitForAsynchronousFrames");
        abort();
    }
    realVTSessionCopyProperty = (pt_pr_realVTSessionCopyProperty) dlsym(handle, "VTSessionCopyProperty");
    if(!realVTSessionCopyProperty) {
        puts ("No VTSessionCopyProperty");
        abort();
    }
}

OSStatus VTDecompressionSessionCreate(CFAllocatorRef allocator, void *videoFormatDescription, CFDictionaryRef videoDecoderSpecification, CFDictionaryRef destinationImageBufferAttributes, const void *outputCallback, void *decompressionSessionOut) {
    return realVTDecompressionSessionCreate(allocator,videoFormatDescription,videoDecoderSpecification,destinationImageBufferAttributes,outputCallback,decompressionSessionOut);
}

OSStatus VTDecompressionSessionDecodeFrame(void *session, void *sampleBuffer, uint32_t decodeFlags, void *sourceFrameRefCon, uint32_t *infoFlagsOut) {
    return realVTDecompressionSessionDecodeFrame(session,sampleBuffer, decodeFlags, sourceFrameRefCon,infoFlagsOut);
}

void VTDecompressionSessionInvalidate(void *session) {
    realVTDecompressionSessionInvalidate(session);
}

OSStatus VTDecompressionSessionWaitForAsynchronousFrames(void *session) {
    return realVTDecompressionSessionWaitForAsynchronousFrames(session);
}

OSStatus VTSessionCopyProperty(void *session, CFStringRef propertyKey, CFAllocatorRef allocator, void *propertyValueOut) {
    if(CFEqual(propertyKey,kVTDecompressionPropertyKey_UsingHardwareAcceleratedVideoDecoder)){
        //puts("Pretend to use HW decoder always, fixme");
        propertyValueOut = (void *)kCFBooleanTrue;
        return noErr;
    }
    return realVTSessionCopyProperty(session,propertyKey,allocator,propertyValueOut);
}
