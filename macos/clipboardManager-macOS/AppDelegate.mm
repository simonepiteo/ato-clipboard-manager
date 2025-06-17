#import "AppDelegate.h"
#import <React/RCTBridge.h>
#import <React/RCTRootView.h>
#import <React/RCTBundleURLProvider.h>
#import <Cocoa/Cocoa.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  
  self.moduleName = @"clipboardManager";
  self.initialProps = @{};
  self.jsBundleURLForBundleRoot = @"index";
  
  NSURL *jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:self.jsBundleURLForBundleRoot];
  RCTBridge *bridge = [[RCTBridge alloc] initWithBundleURL:jsCodeLocation moduleProvider:nil launchOptions:nil];
  RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:bridge moduleName:self.moduleName initialProperties:self.initialProps];
  
  NSViewController *contentViewController = [NSViewController new];
  contentViewController.view = rootView;
  
  self.popover = [[NSPopover alloc] init];
  self.popover.contentViewController = contentViewController;
  self.popover.behavior = NSPopoverBehaviorTransient;
  
  self.statusItem = [[NSStatusBar systemStatusBar]
                     statusItemWithLength:NSVariableStatusItemLength];
  
  self.statusItem.button.title = @"📋";
  self.statusItem.button.target = self;
  self.statusItem.button.action = @selector(togglePopover:);
}

- (void)togglePopover:(id)sender {
  if (self.popover.isShown) {
    [self.popover performClose:sender];
  } else {
    [self.popover showRelativeToRect:[self.statusItem.button bounds]
                              ofView:self.statusItem.button
                       preferredEdge:NSRectEdgeMinY];
  }
}

@end
