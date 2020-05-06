#import <Foundation/Foundation.h>
#include <dlfcn.h>
#import <AppKit/AppKit.h>
#import <objc/runtime.h>

static BOOL my_drawInRect(id self, SEL _cmd, NSRect rect) {
    [self drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
    return YES;
}

@implementation NSImage (FFLegacyMavAPIs)

+(void)load {
    if(![NSImage instancesRespondToSelector:@selector(drawInRect:)]) {
        const char *types = [[NSString stringWithFormat:@"c@:%s", @encode(NSRect)] UTF8String];
        class_addMethod([NSImage class], @selector(drawInRect:), (IMP)my_drawInRect, types);
    }
}

@end

// not in 10.7
NSString * const NSSharingServiceNamePostOnTwitter = @"com.apple.share.Twitter.post";

static Class realNSSharingService = nil;

__attribute__((constructor)) static void initNSSharingServiceShim(){
    void *handle = dlopen ("/System/Library/Frameworks/AppKit.framework/Versions/C/AppKit", RTLD_NOW);
    if (!handle) {
        puts (dlerror());
        abort();
    }
    realNSSharingService = (Class) dlsym(handle, "OBJC_CLASS_$_NSSharingService");
}

@interface NSSharingServic2 : NSObject

+(NSArray *)sharingServicesForItems:(NSArray *)items;
+ (id)sharingServiceNamed:(NSString *)serviceName;

@end


@implementation NSSharingServic2

+(NSArray *)sharingServicesForItems:(NSArray *)items {
    if(realNSSharingService)
        return [realNSSharingService sharingServicesForItems:items];
    return [NSArray array];
}

+(id)sharingServiceNamed:(NSString *)serviceName{
    if(realNSSharingService)
        return [realNSSharingService sharingServiceNamed:serviceName];
    return nil;
}

@end
