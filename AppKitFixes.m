#import <AppKit/AppKit.h>

@implementation NSImage (FFLegacyMavAPIs)

- (BOOL)drawInRect:(NSRect)rect {
    [self drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
    return YES;
}

@end
