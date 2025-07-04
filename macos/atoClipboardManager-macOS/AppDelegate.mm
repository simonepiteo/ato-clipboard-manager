#import "AppDelegate.h"
#import <React/RCTBridge.h>
#import <React/RCTRootView.h>
#import <React/RCTBundleURLProvider.h>
#import <Cocoa/Cocoa.h>
#import "atoClipboardManager-Swift.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  
  self.moduleName = @"atoClipboardManager";
  self.initialProps = @{};
  self.jsBundleURLForBundleRoot = @"index";
  __weak __typeof(self) weakSelf = self;
  
  NSURL *jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:self.jsBundleURLForBundleRoot];
  RCTBridge *bridge = [[RCTBridge alloc] initWithBundleURL:jsCodeLocation moduleProvider:nil launchOptions:nil];
  RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:bridge moduleName:self.moduleName initialProperties:self.initialProps];
  rootView.frame =  NSMakeRect(0, 0, 350, 436);
  
  NSViewController *contentViewController = [NSViewController new];
  contentViewController.view = rootView;
  
  self.popover = [[NSPopover alloc] init];
  self.popover.contentViewController = contentViewController;
  self.popover.behavior = NSPopoverBehaviorTransient;
  self.popover.animates = YES;
  
  
  self.statusItem = [[NSStatusBar systemStatusBar]
                     statusItemWithLength:NSVariableStatusItemLength];
  
  self.statusItem.button.title = @"📋";
  self.statusItem.button.target = self;
  self.statusItem.button.action = @selector(togglePopover:);
  
  self.eventMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDown handler:^(NSEvent *event) {
    if (weakSelf.popover.isShown) {
      [weakSelf.popover performClose:nil];
    }
  }];
  
  [[HotKeyManager shared] registerCommandShiftV];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(togglePopover:)
                                               name:@"TogglePopoverFromHotKey"
                                             object:nil];
}

- (void)togglePopover:(id)sender {
  if (self.popover.isShown) {
    [self.popover performClose:sender];
  } else {
    NSRunningApplication *frontApp = [[NSWorkspace sharedWorkspace] frontmostApplication];
    self.lastActiveAppBundleID = frontApp.bundleIdentifier;
    [self.popover showRelativeToRect:[self.statusItem.button bounds]
                              ofView:self.statusItem.button
                       preferredEdge:NSRectEdgeMinY];
    [NSApp activateIgnoringOtherApps:YES];
  }
}

- (void)showPopoverFromHotKey {
  [self togglePopover:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  if (self.eventMonitor) {
    [NSEvent removeMonitor:self.eventMonitor];
    self.eventMonitor = nil;
  }
}

@end
