#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <Cocoa/Cocoa.h>

@interface ClipboardWatcher : RCTEventEmitter <RCTBridgeModule>
@property (strong, nonatomic) NSTimer *timer;
@property (copy, nonatomic) NSString *lastPasteboardString;
@end

@implementation ClipboardWatcher

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents {
  return @[@"ClipboardChanged"];
}

RCT_EXPORT_METHOD(startWatching) {
  /* NSLog(@"startWatching called"); */
  dispatch_async(dispatch_get_main_queue(), ^{
    if (!self.timer) {
      self.lastPasteboardString = [[NSPasteboard generalPasteboard] stringForType:NSPasteboardTypeString];
      self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                    target:self
                                                  selector:@selector(checkClipboard)
                                                  userInfo:nil
                                                   repeats:YES];
    }
  });
}
RCT_EXPORT_METHOD(stopWatching) {
  [self.timer invalidate];
  self.timer = nil;
}

- (void)checkClipboard {
  /* NSLog(@"Checking clipboard..."); */
  NSString *current = [[NSPasteboard generalPasteboard] stringForType:NSPasteboardTypeString];
  if (current && ![current isEqualToString:self.lastPasteboardString]) {
    self.lastPasteboardString = current;
    [self sendEventWithName:@"ClipboardChanged" body:@{@"content": current}];
  }
}

- (void)invalidate {
  [self.timer invalidate];
  self.timer = nil;
  [super invalidate];
}

@end
