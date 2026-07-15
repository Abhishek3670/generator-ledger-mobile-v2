import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var secureChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    secureChannel = FlutterMethodChannel(name: "com.ledger.app/secure",
                                              binaryMessenger: controller.binaryMessenger)
    
    secureChannel?.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "enableSecure" || call.method == "disableSecure" {
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    // Register for screenshot notification
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(didTakeScreenshot),
        name: UIApplication.userDidTakeScreenshotNotification,
        object: nil
    )

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  @objc private func didTakeScreenshot() {
    secureChannel?.invokeMethod("onScreenshotTaken", arguments: nil)
  }
}
