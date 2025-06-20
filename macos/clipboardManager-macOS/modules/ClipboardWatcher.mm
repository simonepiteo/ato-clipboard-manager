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
  NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
  NSString *currentText = [pasteboard stringForType:NSPasteboardTypeString];
  NSData *currentImageData = nil;
  NSString *base64Image = nil;

  // Check for image
  NSImage *image = [[NSImage alloc] initWithPasteboard:pasteboard];
  if (image != nil && [image isValid]) {
    // Convert NSImage to PNG data
    CGImageRef cgRef = [image CGImageForProposedRect:NULL context:nil hints:nil];
    if (cgRef) {
      NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
      [newRep setSize:[image size]];
      currentImageData = [newRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
      base64Image = [currentImageData base64EncodedStringWithOptions:0];
    }
  }

  // Only send event if text or image changed
  BOOL textChanged = currentText && ![currentText isEqualToString:self.lastPasteboardString];
  BOOL imageChanged = base64Image && ![base64Image isEqualToString:self.lastPasteboardString];

if (textChanged) {
  self.lastPasteboardString = currentText;
  [self sendEventWithName:@"ClipboardChanged" body:@{@"type": @"text", @"content": currentText ?: @""}];
} else if (imageChanged) {
  self.lastPasteboardString = base64Image;
  [self sendEventWithName:@"ClipboardChanged" body:@{@"type": @"image", @"content": base64Image ?: @""}];
}
}

- (void)invalidate {
  [self.timer invalidate];
  self.timer = nil;
  [super invalidate];
}

@end
