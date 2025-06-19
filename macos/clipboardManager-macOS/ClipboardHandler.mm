#import <React/RCTBridgeModule.h>
#import <Cocoa/Cocoa.h>

@interface ClipboardHandler : NSObject <RCTBridgeModule>
@end

@implementation ClipboardHandler

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(setString:(NSString *)string)
{
  NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
  [pasteboard clearContents];
  [pasteboard setString:string forType:NSPasteboardTypeString];
}

RCT_EXPORT_METHOD(setImage:(NSString *)base64String)
{
  NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
  NSImage *image = [[NSImage alloc] initWithData:imageData];
  if (image) {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard writeObjects:@[image]];
  }
}

@end