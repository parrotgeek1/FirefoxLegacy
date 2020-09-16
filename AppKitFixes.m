#import <AppKit/AppKit.h>
#import <objc/runtime.h>

static BOOL my_drawInRect(id self, SEL _cmd, NSRect rect) {
    [self drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
    return YES;
}

@implementation NSImage (FFLegacyMavAPIs)

+(void)load {
@autoreleasepool {
    if(![NSImage instancesRespondToSelector:@selector(drawInRect:)]) {
        const char *types = [[NSString stringWithFormat:@"c@:%s", @encode(NSRect)] UTF8String];
        class_addMethod([NSImage class], @selector(drawInRect:), (IMP)my_drawInRect, types);
    }
}
}
@end
