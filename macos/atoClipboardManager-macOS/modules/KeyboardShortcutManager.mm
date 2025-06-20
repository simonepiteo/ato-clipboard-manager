#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <Cocoa/Cocoa.h>

@interface KeyboardShortcutManager : RCTEventEmitter <RCTBridgeModule>
@end

@implementation KeyboardShortcutManager

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents {
  return @[@"CommandNumberPressed", @"CommandOption_S_Pressed"];
}

- (void)startObserving {
  
  [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent * _Nullable(NSEvent *event) {
    if ((event.modifierFlags & NSEventModifierFlagCommand) &&
        !(event.modifierFlags & NSEventModifierFlagShift) &&
        !(event.modifierFlags & NSEventModifierFlagOption) &&
        !(event.modifierFlags & NSEventModifierFlagControl)) {
      NSString *chars = event.charactersIgnoringModifiers;
      if (chars.length == 1) {
        unichar c = [chars characterAtIndex:0];
        if (c >= '1' && c <= '9') {
          [self sendEventWithName:@"CommandNumberPressed" body:@{@"number": @(c - '0')}];
          return nil;
        }
      }
    }
    return event;
  }];
  
  [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent * _Nullable(NSEvent *event) {
    if ((event.modifierFlags & NSEventModifierFlagCommand) &&
        (event.modifierFlags & NSEventModifierFlagOption) &&
        !(event.modifierFlags & NSEventModifierFlagShift) &&
        !(event.modifierFlags & NSEventModifierFlagControl)) {
      NSString *chars = event.charactersIgnoringModifiers;
      if ([chars.lowercaseString isEqualToString:@"s"]) {
        [self sendEventWithName:@"CommandOption_S_Pressed" body:@{@"action": @"settings"}];
        return nil;
      }
    }
    return event;
  }];
}

@end
