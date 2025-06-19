import Foundation
import HotKey

@objc class HotKeyManager: NSObject {
  static let sharedManager = HotKeyManager()
  private var hotKey: HotKey?
  
  @objc class func shared() -> HotKeyManager {
    return HotKeyManager.sharedManager
  }
  
  @objc func registerCommandShiftV() {
    // ⌘⇧V
    hotKey = HotKey(key: .v, modifiers: [.command, .shift])
    hotKey?.keyDownHandler = {
      NotificationCenter.default.post(name: NSNotification.Name("TogglePopoverFromHotKey"), object: nil)
    }
  }
  
}
