#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <Cocoa/Cocoa.h>

@interface KeyboardShortcutManager : RCTEventEmitter <RCTBridgeModule>
@end

@implementation KeyboardShortcutManager

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents {
  return @[@"CommandNumberPressed"];
}

- (void)startObserving {
  // Listen for keyDown events globally
  [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent * _Nullable(NSEvent *event) {
    // Check for Command + 1-9
    if ((event.modifierFlags & NSEventModifierFlagCommand) &&
        !(event.modifierFlags & NSEventModifierFlagShift) &&
        !(event.modifierFlags & NSEventModifierFlagOption) &&
        !(event.modifierFlags & NSEventModifierFlagControl)) {
      NSString *chars = event.charactersIgnoringModifiers;
      if (chars.length == 1) {
        unichar c = [chars characterAtIndex:0];
        if (c >= '1' && c <= '9') {
          [self sendEventWithName:@"CommandNumberPressed" body:@{@"number": @(c - '0')}];
          return nil; // Swallow the event
        }
      }
    }
    return event;
  }];
}

@end