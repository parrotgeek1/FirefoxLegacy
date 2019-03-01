#import <Foundation/Foundation.h>
#include <dlfcn.h>

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

@interface NSSharingService : NSObject

+(NSArray *)sharingServicesForItems:(NSArray *)items;
+ (NSSharingService *)sharingServiceNamed:(NSString *)serviceName;

@end


@implementation NSSharingService

+(NSArray *)sharingServicesForItems:(NSArray *)items {
    if(realNSSharingService)
        return [realNSSharingService sharingServicesForItems:items];
    return [NSArray array];
}

+(NSSharingService *)sharingServiceNamed:(NSString *)serviceName{
    if(realNSSharingService)
        return [realNSSharingService sharingServiceNamed:serviceName];
    return nil;
}

@end
