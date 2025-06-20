#import <React/RCTBridgeModule.h>
#import <React/RCTBridge.h>
#import <React/RCTRootView.h>
#import "AppDelegate.h"

@interface WindowManager : NSObject <RCTBridgeModule>
@property (nonatomic, weak) RCTBridge *bridge;
@property (nonatomic, strong) NSMutableArray<NSWindow *> *openWindows;
@end

@implementation WindowManager

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(openWindow:(NSString *)moduleName
                  withTitle:(nullable NSString *)customTitle)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    if (!self.bridge) {
      NSLog(@"[WindowManager] Bridge is nil — cannot open window.");
      return;
    }
    
    if (!self.openWindows) {
      self.openWindows = [NSMutableArray new];
    }
    
    if(self.openWindows.count > 0) {
      [self.openWindows[0] makeKeyAndOrderFront:nil];
      [NSApp activateIgnoringOtherApps:YES];
      return;
    }
    
    NSRect frame = NSMakeRect(0, 0, 400, 345);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                   styleMask:(NSWindowStyleMaskTitled |
                                                              NSWindowStyleMaskClosable)
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    window.title = customTitle ?: moduleName;
    [window center];
    window.backgroundColor = [[NSColor windowBackgroundColor] colorWithAlphaComponent:0.95];
    
    RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:self.bridge
                                                     moduleName:moduleName
                                              initialProperties:nil];
    
    [window setContentView:rootView];
    [window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    
    [self.openWindows addObject:window];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification
                                                      object:window
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
      [self.openWindows removeObject:window];
    }];
  });
}

RCT_EXPORT_METHOD(closePopover:(BOOL)automaticPasteShortcut)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    AppDelegate *delegate = (AppDelegate *)[NSApp delegate];
    if (delegate.popover.isShown) {
      [delegate.popover performClose:nil];
      if (delegate.lastActiveAppBundleID) {
        NSArray *runningApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:delegate.lastActiveAppBundleID];
        NSRunningApplication *appToActivate = runningApps.firstObject;
        if (appToActivate) {
          [appToActivate activateWithOptions:0];
          
          if(automaticPasteShortcut) {
          // Simulate Cmd+V after a short delay
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
              CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
              
              CGEventRef keyVDown = CGEventCreateKeyboardEvent(source, (CGKeyCode)9, true);  // 9 = 'v'
              CGEventRef keyVUp   = CGEventCreateKeyboardEvent(source, (CGKeyCode)9, false);
              
              CGEventSetFlags(keyVDown, kCGEventFlagMaskCommand);
              CGEventSetFlags(keyVUp,   kCGEventFlagMaskCommand);
              
              CGEventPost(kCGHIDEventTap, keyVDown);
              CGEventPost(kCGHIDEventTap, keyVUp);
              
              CFRelease(keyVDown);
              CFRelease(keyVUp);
              CFRelease(source);
            });
          }
        }
        delegate.lastActiveAppBundleID = nil;
      }
    }
  });
}

RCT_EXPORT_METHOD(quitApp)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [NSApp terminate:nil];
  });
}

@end
