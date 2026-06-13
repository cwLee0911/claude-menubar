import AppKit

private final class AppDelegateHolder {
    let delegate = AppDelegate()
}

private let delegateHolder = AppDelegateHolder()
private let application = NSApplication.shared
application.delegate = delegateHolder.delegate
application.setActivationPolicy(.accessory)
application.run()
