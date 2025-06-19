#import <RCTAppDelegate.h>
#import <Cocoa/Cocoa.h>

@interface AppDelegate : RCTAppDelegate
    @property(strong, nonatomic) NSPopover *popover;
    @property(strong, nonatomic) NSStatusItem *statusItem;
    @property(strong, nonatomic) NSString *jsBundleURLForBundleRoot;
    @property (strong) id eventMonitor;
    @property (copy) NSString *lastActiveAppBundleID;
@end
