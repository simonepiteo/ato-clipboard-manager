#import <React/RCTBridgeModule.h>
#import <React/RCTBridge.h>
#import <React/RCTRootView.h>

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
    
    NSRect frame = NSMakeRect(0, 0, 600, 400);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                   styleMask:(NSWindowStyleMaskTitled |
                                                              NSWindowStyleMaskClosable)
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    window.title = customTitle ?: moduleName;
    [window center];
    
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

@end
